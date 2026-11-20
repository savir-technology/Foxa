import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'order_voice_call_service.dart';
import 'order_voice_call_alert_service.dart';

class VoiceCallErrorHandler {
  static const String _tag = '[VOICE CALL ERROR HANDLER]';

  final OrderVoiceCallService _voiceCallService;
  final OrderVoiceCallAlertService _alertService;

  static const Map<String, String> _errorMessages = {
    'network_error': 'خطأ في الاتصال بالإنترنت',
    'server_error': 'خطأ في الخادم، حاول مرة أخرى لاحقًا',
    'permission_denied': 'تم رفض الإذن للوصول للميكروفون',
    'call_rejected': 'تم رفض المكالمة',
    'call_missed': 'فوتت المكالمة',
    'call_ended': 'انتهت المكالمة',
    'unknown_error': 'حدث خطأ غير متوقع',
  };

  final Map<String, int> _retryAttempts = {};
  final int _maxRetryAttempts = 3;
  final Duration _retryDelay = const Duration(seconds: 5);

  Timer? _connectivityCheckTimer;
  bool _isConnected = true;

  final Function(String, String)? _onError;

  VoiceCallErrorHandler({
    required OrderVoiceCallService voiceCallService,
    required OrderVoiceCallAlertService alertService,
    Function(String, String)? onError,
  })  : _voiceCallService = voiceCallService,
        _alertService = alertService,
        _onError = onError {
    _initializeConnectivityCheck();
  }

  void _initializeConnectivityCheck() {
    unawaited(_checkConnectivity());
    _connectivityCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(_checkConnectivity());
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      _isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      _isConnected = false;
    }
  }

  Future<void> handleError({
    required String error,
    required String orderId,
    required Function() onRetry,
    Function()? onFallback,
  }) async {
    debugPrint('$_tag: معالجة خطأ: $error لطلب: $orderId');

    _retryAttempts[orderId] = (_retryAttempts[orderId] ?? 0) + 1;

    final errorMessage = _errorMessages[error] ?? _errorMessages['unknown_error']!;
    _showErrorToUser(error, errorMessage);
    _onError?.call(error, errorMessage);

    if (_shouldRetry(error) && _retryAttempts[orderId]! <= _maxRetryAttempts) {
      debugPrint('$_tag: إعادة المحاولة (${_retryAttempts[orderId]}/$_maxRetryAttempts)');
      await Future.delayed(_retryDelay);

      if (_isConnected) {
        onRetry();
      } else {
        debugPrint('$_tag: لا يمكن إعادة المحاولة بسبب فقدان الاتصال');
        onFallback?.call();
      }
    } else {
      debugPrint('$_tag: الوصول إلى الحد الأقصى للمحاولات أو خطأ لا يمكن إعادة محاولته');
      onFallback?.call();
    }
  }

  bool _shouldRetry(String error) {
    return error == 'network_error' ||
        error == 'server_error' ||
        error == 'unknown_error';
  }

  void _showErrorToUser(String error, String message) {
    debugPrint('$_tag: $message');
  }

  void resetRetryAttempts(String orderId) {
    _retryAttempts.remove(orderId);
  }

  int getRetryAttempts(String orderId) {
    return _retryAttempts[orderId] ?? 0;
  }

  void dispose() {
    _connectivityCheckTimer?.cancel();
  }
}
