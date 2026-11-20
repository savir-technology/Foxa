import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_voice_call_service.dart';
import 'order_voice_call_alert_service.dart';

class VoiceCallOfflineService extends GetxService {
  static const String _offlineCallsKey = 'offline_calls';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _maxOfflineCallsKey = 'max_offline_calls';

  final SharedPreferences _sharedPreferences;
  final OrderVoiceCallService _voiceCallService;
  final OrderVoiceCallAlertService _alertService;

  // معلومات الاتصال
  Timer? _connectivityCheckTimer;
  bool _isConnected = true;

  // معالج الأحداث
  final Function(List<Map<String, dynamic>>)? _onOfflineCallsUpdated;
  final Function()? _onSyncComplete;

  // قائمة المكالمات غير المتصلة
  final List<Map<String, dynamic>> _offlineCalls = [];

  VoiceCallOfflineService({
    required SharedPreferences sharedPreferences,
    required OrderVoiceCallService voiceCallService,
    required OrderVoiceCallAlertService alertService,
    Function(List<Map<String, dynamic>>)? onOfflineCallsUpdated,
    Function()? onSyncComplete,
  })  : _sharedPreferences = sharedPreferences,
        _voiceCallService = voiceCallService,
        _alertService = alertService,
        _onOfflineCallsUpdated = onOfflineCallsUpdated,
        _onSyncComplete = onSyncComplete;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initialize());
  }

  @override
  void onClose() {
    _connectivityCheckTimer?.cancel();
    super.onClose();
  }

  Future<void> _initialize() async {
    // استعادة المكالمات غير المتصلة من التفضيلات المشتركة
    _loadOfflineCalls();

    // بدء التحقق من الاتصال
    _startConnectivityCheck();
  }

  void _startConnectivityCheck() {
    // التحقق من حالة الاتصال الحالية
    _checkConnectivity();

    // التحقق من الاتصال كل 30 ثانية
    _connectivityCheckTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) {
      unawaited(_checkConnectivity());
    });
  }

  Future<void> _checkConnectivity() async {
    final wasConnected = _isConnected;
    try {
      final result = await InternetAddress.lookup('google.com');
      _isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      _isConnected = false;
    }

    if (!wasConnected && _isConnected) {
      unawaited(_syncOfflineCalls());
    }
  }

  void _loadOfflineCalls() {
    final offlineCallsJson = _sharedPreferences.getStringList(_offlineCallsKey);
    if (offlineCallsJson != null) {
      _offlineCalls.clear();
      for (final callJson in offlineCallsJson) {
        try {
          final callData = Map<String, dynamic>.from(json.decode(callJson));
          _offlineCalls.add(callData);
        } catch (e) {
          debugPrint('[OFFLINE SERVICE] Error parsing offline call: $e');
        }
      }
      _onOfflineCallsUpdated?.call(_offlineCalls);
    }
  }

  Future<void> _saveOfflineCalls() async {
    final offlineCallsJson =
        _offlineCalls.map((call) => json.encode(call)).toList();

    await _sharedPreferences.setStringList(_offlineCallsKey, offlineCallsJson);
  }

  Future<void> addOfflineCall(Map<String, dynamic> callData) async {
    // إضافة المكالمة إلى قائمة المكالمات غير المتصلة
    _offlineCalls.add(callData);
    await _saveOfflineCalls();
    _onOfflineCallsUpdated?.call(_offlineCalls);

    debugPrint('[OFFLINE SERVICE] Added offline call: ${callData['orderId']}');
  }

  Future<void> removeOfflineCall(String orderId) async {
    // إزالة المكالمة من قائمة المكالمات غير المتصلة
    _offlineCalls.removeWhere((call) => call['orderId'] == orderId);
    await _saveOfflineCalls();
    _onOfflineCallsUpdated?.call(_offlineCalls);

    debugPrint('[OFFLINE SERVICE] Removed offline call: $orderId');
  }

  Future<void> _syncOfflineCalls() async {
    if (!_isConnected || _offlineCalls.isEmpty) return;

    debugPrint(
        '[OFFLINE SERVICE] Syncing ${_offlineCalls.length} offline calls');

    // مزامنة كل مكالمة غير متصلة
    for (final callData in _offlineCalls) {
      try {
        final orderId = callData['orderId'];
        debugPrint('[OFFLINE SERVICE] Syncing call: $orderId');

        // محاولة مزامنة المكالمة
        await _syncOfflineCall(callData);

        // إزالة المكالمة من القائمة بعد المزامنة الناجحة
        await removeOfflineCall(orderId);
      } catch (e) {
        debugPrint('[OFFLINE SERVICE] Error syncing call: $e');
      }
    }

    // تحديث وقت المزامنة الأخيرة
    await _sharedPreferences.setInt(
      _lastSyncTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    // إعلام المستخدم بالمزامنة الناجحة
    _onSyncComplete?.call();
  }

  Future<void> _syncOfflineCall(Map<String, dynamic> callData) async {
    final sessionRaw = callData['session'];
    if (sessionRaw is Map) {
      await _voiceCallService.createSession(
        OrderVoiceCallSession.fromMap(
          sessionRaw.map((key, value) => MapEntry('$key', value)),
        ),
      );
      return;
    }

    final orderId = callData['orderId']?.toString().trim() ??
        callData['order_id']?.toString().trim() ??
        '';
    if (orderId.isEmpty) {
      throw StateError('Offline voice call is missing orderId');
    }

    final status = callData['status']?.toString().trim();
    if (status != null && status.isNotEmpty) {
      await _voiceCallService.patchSession(orderId, {'status': status});
    }

    if (_alertService.activeOrderId == orderId) {
      debugPrint('[OFFLINE SERVICE] Synced active call: $orderId');
    }
  }

  List<Map<String, dynamic>> getOfflineCalls() {
    return List<Map<String, dynamic>>.from(_offlineCalls);
  }

  int getOfflineCallCount() {
    return _offlineCalls.length;
  }

  DateTime? getLastSyncTime() {
    final timestamp = _sharedPreferences.getInt(_lastSyncTimeKey);
    if (timestamp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> clearOfflineCalls() async {
    _offlineCalls.clear();
    await _saveOfflineCalls();
    _onOfflineCallsUpdated?.call(_offlineCalls);

    debugPrint('[OFFLINE SERVICE] Cleared all offline calls');
  }

  Future<void> setMaxOfflineCalls(int maxCalls) async {
    await _sharedPreferences.setInt(_maxOfflineCallsKey, maxCalls);
    debugPrint('[OFFLINE SERVICE] Max offline calls set to: $maxCalls');
  }

  int getMaxOfflineCalls() {
    return _sharedPreferences.getInt(_maxOfflineCallsKey) ?? 10;
  }

  bool isConnected() {
    return _isConnected;
  }
}
