import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_voice_call_service.dart';
import 'order_voice_call_alert_service.dart';

class VoiceCallEmergencyService extends GetxService {
  static const String _emergencyContactNumber = 'emergency_contact';
  static const String _emergencyLocationKey = 'emergency_location';
  static const String _emergencyCallCountKey = 'emergency_call_count';
  static const String _lastEmergencyCallKey = 'last_emergency_call';

  final SharedPreferences _sharedPreferences;
  final OrderVoiceCallService _voiceCallService;
  final OrderVoiceCallAlertService _alertService;

  Timer? _emergencyCheckTimer;
  bool _isEmergencyMode = false;
  bool _isInitialized = false;

  String? _emergencyContact;
  StreamSubscription<Position>? _locationSubscription;

  final Function(bool)? _onEmergencyModeChanged;
  final Function(String)? _onEmergencyCall;

  VoiceCallEmergencyService({
    required SharedPreferences sharedPreferences,
    required OrderVoiceCallService voiceCallService,
    required OrderVoiceCallAlertService alertService,
    Function(bool)? onEmergencyModeChanged,
    Function(String)? onEmergencyCall,
  })  : _sharedPreferences = sharedPreferences,
        _voiceCallService = voiceCallService,
        _alertService = alertService,
        _onEmergencyModeChanged = onEmergencyModeChanged,
        _onEmergencyCall = onEmergencyCall;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initialize());
  }

  @override
  void onClose() {
    _emergencyCheckTimer?.cancel();
    _locationSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    _emergencyContact = _sharedPreferences.getString(_emergencyContactNumber);
    _startEmergencyCheck();
    _isInitialized = true;
  }

  void _startEmergencyCheck() {
    _emergencyCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      unawaited(_checkEmergencyConditions());
    });
  }

  Future<void> _checkEmergencyConditions() async {
    try {
      final failedCallCount = _sharedPreferences.getInt(_emergencyCallCountKey) ?? 0;
      if (failedCallCount >= 3) {
        _activateEmergencyMode();
        return;
      }

      final activeOrderId = _alertService.activeOrderId;
      if (activeOrderId != null && activeOrderId.isNotEmpty) {
        final session = await _voiceCallService.loadSession(activeOrderId);
        if (session != null && session.status == 'failed') {
          _incrementFailedCallCount();
        }
      }
    } catch (e) {
      debugPrint('Error checking emergency conditions: $e');
    }
  }

  void _activateEmergencyMode() {
    if (_isEmergencyMode) return;

    _isEmergencyMode = true;
    _onEmergencyModeChanged?.call(true);

    unawaited(_getCurrentLocation());
    _startLocationTracking();
    _makeEmergencyCall();
  }

  void _deactivateEmergencyMode() {
    if (!_isEmergencyMode) return;

    _isEmergencyMode = false;
    _onEmergencyModeChanged?.call(false);

    _locationSubscription?.cancel();
    _sharedPreferences.setInt(_emergencyCallCountKey, 0);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );

      _sharedPreferences.setString(
        _emergencyLocationKey,
        '${position.latitude},${position.longitude}',
      );

      debugPrint('Emergency location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Error getting emergency location: $e');
    }
  }

  void _startLocationTracking() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      ),
    ).listen((position) {
      _sharedPreferences.setString(
        _emergencyLocationKey,
        '${position.latitude},${position.longitude}',
      );

      debugPrint('Updated emergency location: ${position.latitude}, ${position.longitude}');
    });
  }

  void _makeEmergencyCall() {
    if (_emergencyContact == null) return;

    _sharedPreferences.setInt(
      _lastEmergencyCallKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    _onEmergencyCall?.call(_emergencyContact!);
    debugPrint('Making emergency call to: $_emergencyContact');
  }

  void _incrementFailedCallCount() {
    final currentCount = _sharedPreferences.getInt(_emergencyCallCountKey) ?? 0;
    _sharedPreferences.setInt(_emergencyCallCountKey, currentCount + 1);
    debugPrint('Failed call count incremented to: ${currentCount + 1}');
  }

  Future<void> setEmergencyContact(String phoneNumber) async {
    _emergencyContact = phoneNumber;
    await _sharedPreferences.setString(_emergencyContactNumber, phoneNumber);
    debugPrint('Emergency contact set to: $phoneNumber');
  }

  String? getEmergencyContact() {
    return _emergencyContact;
  }

  String? getEmergencyLocation() {
    return _sharedPreferences.getString(_emergencyLocationKey);
  }

  int getFailedCallCount() {
    return _sharedPreferences.getInt(_emergencyCallCountKey) ?? 0;
  }

  DateTime? getLastEmergencyCallTime() {
    final timestamp = _sharedPreferences.getInt(_lastEmergencyCallKey);
    if (timestamp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  bool isEmergencyMode() {
    return _isEmergencyMode;
  }

  void cancelEmergencyMode() {
    _deactivateEmergencyMode();
  }
}
