import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_voice_call_service.dart';
import 'order_voice_call_alert_service.dart';

class VoiceCallStateManager extends GetxService {
  static const String _keyLastCallTime = 'last_call_time';
  static const String _keyCallCount = 'call_count';
  static const String _keyLastCallStatus = 'last_call_status';
  static const String _keyCallHistory = 'call_history';

  final SharedPreferences _sharedPreferences;
  final OrderVoiceCallService _voiceCallService;
  final OrderVoiceCallAlertService _alertService;

  Timer? _callCheckTimer;
  bool _isInitialized = false;

  // المتغيرات المراقبة
  final RxString lastCallStatus = ''.obs;
  final RxInt callCount = 0.obs;
  final Rx<DateTime> lastCallTime = DateTime.now().obs;
  final RxList<Map<String, dynamic>> callHistory = <Map<String, dynamic>>[].obs;

  VoiceCallStateManager(
    this._sharedPreferences,
    this._voiceCallService,
    this._alertService,
  );

  @override
  void onInit() {
    super.onInit();
    unawaited(_initialize());
  }

  @override
  void onClose() {
    _callCheckTimer?.cancel();
    super.onClose();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    // استعادة الحالة من التفضيلات المشتركة
    await _restoreState();

    // بدء التحقق الدوري من المكالمات
    _startCallCheck();

    _isInitialized = true;
  }

  Future<void> _restoreState() async {
    // استعادة آخر حالة للمكالمة
    final savedStatus = _sharedPreferences.getString(_keyLastCallStatus);
    if (savedStatus != null) {
      lastCallStatus.value = savedStatus;
    }

    // استعداد عدد المكالمات
    final savedCount = _sharedPreferences.getInt(_keyCallCount) ?? 0;
    callCount.value = savedCount;

    // استعادة وقت آخر مكالمة
    final savedTime = _sharedPreferences.getInt(_keyLastCallTime);
    if (savedTime != null) {
      lastCallTime.value = DateTime.fromMillisecondsSinceEpoch(savedTime);
    }

    // استعادة تاريخ المكالمات
    final savedHistory = _sharedPreferences.getStringList(_keyCallHistory);
    if (savedHistory != null) {
      callHistory.assignAll(
        savedHistory
            .map((item) => Map<String, dynamic>.from(jsonDecode(item) as Map))
            .toList(),
      );
    }
  }

  void _startCallCheck() {
    // بدء فحص دوري للمكالمات
    _callCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      unawaited(_checkCallStatus());
    });
  }

  Future<void> _checkCallStatus() async {
    try {
      final activeOrderId = _alertService.activeOrderId;
      if (activeOrderId != null && activeOrderId.isNotEmpty) {
        final session = await _voiceCallService.loadSession(activeOrderId);
        if (session != null) {
          // تحديث حالة المكالمة
          _updateCallStatus(session.status);

          // إضافة للتاريخ إذا كانت مكالمة جديدة
          if (session.status == 'ringing' &&
              lastCallStatus.value != 'ringing') {
            _addToCallHistory(session);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking call status: $e');
    }
  }

  void _updateCallStatus(String status) {
    if (lastCallStatus.value != status) {
      lastCallStatus.value = status;
      _sharedPreferences.setString(_keyLastCallStatus, status);

      // تحديث وقت آخر مكالمة
      lastCallTime.value = DateTime.now();
      _sharedPreferences.setInt(
        _keyLastCallTime,
        lastCallTime.value.millisecondsSinceEpoch,
      );

      // تحديث عدد المكالمات
      callCount.value++;
      _sharedPreferences.setInt(_keyCallCount, callCount.value);
    }
  }

  void _addToCallHistory(OrderVoiceCallSession session) {
    final callRecord = {
      'orderId': session.orderId,
      'callerName': session.callerName,
      'callerRole': session.callerRole,
      'calleeName': session.calleeName,
      'calleeRole': session.calleeRole,
      'status': session.status,
      'timestamp': DateTime.now().toIso8601String(),
    };

    callHistory.insert(0, callRecord);

    // الاحتفاظ بأحدث 10 مكالمات فقط
    if (callHistory.length > 10) {
      callHistory.removeLast();
    }

    // حفظ التاريخ
    final historyJson = callHistory.map(jsonEncode).toList();
    _sharedPreferences.setStringList(_keyCallHistory, historyJson);
  }

  Future<void> resetCallHistory() async {
    callHistory.clear();
    await _sharedPreferences.remove(_keyCallHistory);
  }

  Future<void> resetCallCount() async {
    callCount.value = 0;
    await _sharedPreferences.remove(_keyCallCount);
  }

  Future<void> resetLastCallTime() async {
    lastCallTime.value = DateTime.now();
    await _sharedPreferences.setInt(
      _keyLastCallTime,
      lastCallTime.value.millisecondsSinceEpoch,
    );
  }

  // الحصول على إحصائيات المكالمات
  Map<String, dynamic> getCallStatistics() {
    return {
      'totalCalls': callCount.value,
      'lastCallTime': lastCallTime.value,
      'lastCallStatus': lastCallStatus.value,
      'callHistory': callHistory,
    };
  }
}
