import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:delvery/core/services/driver_api_service.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/data/mappers/driver_remote_parser.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DriverRegistrationStage { none, otp, password, profile }

class DriverSessionService extends GetxService {
  DriverSessionService(this.api);

  final DriverApiService api;

  static const _kLoggedIn = 'driver_logged_in';
  static const _kShiftActive = 'driver_shift_active';
  static const _kDarkMode = 'driver_dark_mode';
  static const _kPhone = 'driver_phone';
  static const _kEmail = 'driver_email';
  static const _kName = 'driver_name';
  static const _kVehicleType = 'driver_vehicle_type';
  static const _kVehicleNumber = 'driver_vehicle_number';
  static const _kVendorId = 'driver_vendor_id';
  static const _kVendorName = 'driver_vendor_name';
  static const _kStoreName = 'driver_store_name';
  static const _kLocale = 'driver_locale';
  static const _kNotificationsEnabled = 'driver_notifications_enabled';
  static const _kVibrationEnabled = 'driver_vibration_enabled';
  static const _kLocationSharingEnabled = 'driver_location_sharing_enabled';
  static const _kThemeModeValue = 'driver_theme_mode_value';
  static const _kShiftStartedAt = 'driver_shift_started_at';
  static const _kAuthToken = 'driver_auth_token';
  static const _kRefreshToken = 'driver_refresh_token';
  static const _kDriverId = 'driver_remote_id';
  static const _kProfileCompleted = 'driver_profile_completed';
  static const _kProfilePhotoUrl = 'driver_profile_photo_url';
  static const _kRegistrationStage = 'driver_registration_stage';
  static const _kPendingRegistrationEmail = 'driver_pending_registration_email';
  static const _kPendingVerificationToken = 'driver_pending_verification_token';
  static const _kVoiceCallActiveOrderId =
      'driver_voice_call_active_order_id_v1';

  final RxBool isLoggedIn = false.obs;
  final RxBool isShiftActive = false.obs;
  final RxBool hasInternet = true.obs;
  final RxBool gpsEnabled = true.obs;
  final Rx<DriverAvailability> availability = DriverAvailability.offline.obs;
  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;
  final RxString localeCode = 'ar'.obs;
  final RxBool notificationsEnabled = true.obs;
  final RxBool vibrationEnabled = true.obs;
  final RxBool locationSharingEnabled = true.obs;
  final RxString otpCode = ''.obs;
  final Rx<DriverRegistrationStage> registrationStage =
      DriverRegistrationStage.none.obs;
  final RxnString pendingRegistrationEmail = RxnString();
  final RxnString pendingVerificationToken = RxnString();
  final RxInt dashboardTick = 0.obs;
  final Rx<DriverWorkingHoursSchedule> officialWorkingHours =
      DriverWorkingHoursSchedule.defaultSchedule().obs;
  final Rx<DriverProfile> profile = const DriverProfile(
    id: 'driver-001',
    name: 'السائق',
    phone: '',
    email: '',
    vendorId: 0,
    vendorName: '',
    storeName: '',
    vehicleType: 'دراجة نارية',
    vehicleNumber: 'AEP-204',
  ).obs;
  final Rxn<DriverCoordinate> liveCoordinate = Rxn<DriverCoordinate>();
  final RxnInt driverId = RxnInt();
  final RxnString authToken = RxnString();
  final RxnString refreshToken = RxnString();

  SharedPreferences? _prefs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<Position>? _positionSub;
  DateTime? _shiftStartedAt;
  Timer? _gpsProbeTimer;
  Timer? _dashboardTicker;
  int _workingHoursRefreshTick = 0;
  bool _officialWorkingHoursSynced = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _restoreState();
    _watchConnectivity();
    await refreshSystemChecks();
    await ensureOfficialWorkingHours(force: true);
    _startDashboardTicker();

    if (isLoggedIn.value &&
        (profile.value.phone.isNotEmpty || profile.value.email.isNotEmpty)) {
      try {
        await loadDriverProfile(
          phone: profile.value.phone.isNotEmpty ? profile.value.phone : null,
          email: profile.value.email.isNotEmpty ? profile.value.email : null,
        );
      } catch (_) {
        // Keep the restored local profile if the backend is unavailable.
      }
    }

    if (isShiftActive.value) {
      _startDashboardTicker();
      unawaited(_resumeShiftRuntime());
    }
  }

  Future<void> _restoreState() async {
    isLoggedIn.value = _prefs?.getBool(_kLoggedIn) ?? false;
    isShiftActive.value = _prefs?.getBool(_kShiftActive) ?? false;
    themeMode.value = ThemeMode.light;
    await _prefs?.setBool(_kDarkMode, false);
    await _prefs?.setString(_kThemeModeValue, ThemeMode.light.name);
    localeCode.value = _prefs?.getString(_kLocale) ?? 'ar';
    notificationsEnabled.value =
        _prefs?.getBool(_kNotificationsEnabled) ?? true;
    vibrationEnabled.value = _prefs?.getBool(_kVibrationEnabled) ?? true;
    locationSharingEnabled.value =
        _prefs?.getBool(_kLocationSharingEnabled) ?? true;
    authToken.value = _prefs?.getString(_kAuthToken);
    refreshToken.value = _prefs?.getString(_kRefreshToken);
    registrationStage.value = _decodeRegistrationStage(
      _prefs?.getString(_kRegistrationStage),
    );
    pendingRegistrationEmail.value = _prefs?.getString(
      _kPendingRegistrationEmail,
    );
    pendingVerificationToken.value = _prefs?.getString(
      _kPendingVerificationToken,
    );

    final storedDriverId = _prefs?.getInt(_kDriverId);
    if (storedDriverId != null) {
      driverId.value = storedDriverId;
    }

    profile.value = profile.value.copyWith(
      phone: _prefs?.getString(_kPhone) ?? '',
      email: _prefs?.getString(_kEmail) ?? profile.value.email,
      name: _prefs?.getString(_kName) ?? profile.value.name,
      vendorId: _prefs?.getInt(_kVendorId) ?? profile.value.vendorId,
      vendorName: _prefs?.getString(_kVendorName) ?? profile.value.vendorName,
      storeName: _prefs?.getString(_kStoreName) ?? profile.value.storeName,
      vehicleType:
          _prefs?.getString(_kVehicleType) ?? profile.value.vehicleType,
      vehicleNumber:
          _prefs?.getString(_kVehicleNumber) ?? profile.value.vehicleNumber,
      photoUrl: _prefs?.getString(_kProfilePhotoUrl) ?? profile.value.photoUrl,
      profileCompleted:
          _prefs?.getBool(_kProfileCompleted) ?? profile.value.profileCompleted,
    );

    final shiftStartedAtMs = _prefs?.getInt(_kShiftStartedAt);
    if (isShiftActive.value && shiftStartedAtMs != null) {
      _shiftStartedAt = DateTime.fromMillisecondsSinceEpoch(shiftStartedAtMs);
    }

    availability.value = isShiftActive.value
        ? DriverAvailability.available
        : DriverAvailability.offline;
  }

  String? get voiceCallActiveOrderId {
    final storedOrderId =
        _prefs?.getString(_kVoiceCallActiveOrderId)?.trim() ?? '';
    if (storedOrderId.isEmpty) {
      return null;
    }

    return storedOrderId;
  }

  Future<void> setVoiceCallActiveOrderId(String? orderId) async {
    final normalizedOrderId = orderId?.trim() ?? '';
    if (normalizedOrderId.isEmpty ||
        normalizedOrderId == '0' ||
        normalizedOrderId.toLowerCase() == 'null') {
      await _prefs?.remove(_kVoiceCallActiveOrderId);
      return;
    }

    await _prefs?.setString(_kVoiceCallActiveOrderId, normalizedOrderId);
  }

  void _watchConnectivity() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      hasInternet.value = results.any(
        (result) => result != ConnectivityResult.none,
      );
    });
  }

  DriverRegistrationStage _decodeRegistrationStage(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'otp':
        return DriverRegistrationStage.otp;
      case 'password':
        return DriverRegistrationStage.password;
      case 'profile':
        return DriverRegistrationStage.profile;
      default:
        return DriverRegistrationStage.none;
    }
  }

  String _encodeRegistrationStage(DriverRegistrationStage stage) {
    switch (stage) {
      case DriverRegistrationStage.none:
        return 'none';
      case DriverRegistrationStage.otp:
        return 'otp';
      case DriverRegistrationStage.password:
        return 'password';
      case DriverRegistrationStage.profile:
        return 'profile';
    }
  }

  Future<void> _persistRegistrationStage(DriverRegistrationStage stage) async {
    registrationStage.value = stage;
    await _prefs?.setString(
      _kRegistrationStage,
      _encodeRegistrationStage(stage),
    );
  }

  Future<void> _setPendingRegistrationEmail(String? email) async {
    final normalized = email?.trim() ?? '';
    pendingRegistrationEmail.value = normalized.isEmpty ? null : normalized;
    if (normalized.isEmpty) {
      await _prefs?.remove(_kPendingRegistrationEmail);
    } else {
      await _prefs?.setString(_kPendingRegistrationEmail, normalized);
    }
  }

  Future<void> _setPendingVerificationToken(String? token) async {
    final normalized = token?.trim() ?? '';
    pendingVerificationToken.value = normalized.isEmpty ? null : normalized;
    if (normalized.isEmpty) {
      await _prefs?.remove(_kPendingVerificationToken);
    } else {
      await _prefs?.setString(_kPendingVerificationToken, normalized);
    }
  }

  Future<void> clearRegistrationDraft() async {
    otpCode.value = '';
    await _persistRegistrationStage(DriverRegistrationStage.none);
    await _setPendingRegistrationEmail(null);
    await _setPendingVerificationToken(null);
  }

  Future<void> requestEmailRegistrationCode(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw StateError('A valid email address is required');
    }

    final response = await api.requestDriverEmailOtp(
      email: normalizedEmail,
      locale: localeCode.value,
    );
    if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
      throw StateError(
        (response['message'] ?? 'Failed to send verification code').toString(),
      );
    }

    otpCode.value = (response['debug_code'] ?? '').toString();
    profile.value = profile.value.copyWith(email: normalizedEmail);
    await _prefs?.setString(_kEmail, normalizedEmail);
    await _setPendingRegistrationEmail(normalizedEmail);
    await _setPendingVerificationToken(null);
    await _persistRegistrationStage(DriverRegistrationStage.otp);
  }

  Future<bool> verifyEmailRegistrationCode(String code) async {
    final email =
        pendingRegistrationEmail.value?.trim() ?? profile.value.email.trim();
    if (email.isEmpty) {
      return false;
    }

    final response = await api.verifyDriverEmailOtp(
      email: email,
      code: code.trim(),
    );
    if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
      return false;
    }

    otpCode.value = '';
    await _setPendingRegistrationEmail(email);
    await _setPendingVerificationToken(
      (response['verification_token'] ?? '').toString(),
    );
    await _persistRegistrationStage(DriverRegistrationStage.password);
    return true;
  }

  Future<bool> completeEmailRegistration({
    required String password,
    required String name,
    required String phone,
    required String vehicleType,
    required String vehicleNumber,
    int vendorId = 0,
    String? imagePath,
  }) async {
    final email =
        pendingRegistrationEmail.value?.trim() ?? profile.value.email.trim();
    final token = pendingVerificationToken.value?.trim() ?? '';
    if (email.isEmpty || token.isEmpty) {
      return false;
    }

    final response = await api.registerDriverEmailAccount(
      verificationToken: token,
      name: name,
      phone: phone,
      email: email,
      password: password,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
      vendorId: vendorId > 0 ? vendorId : null,
      imagePath: imagePath,
      localeCode: localeCode.value,
    );

    if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
      return false;
    }

    final data = response['data'] ?? response['profile'] ?? response['driver'];
    final parsed = DriverRemoteParser.parseProfile(data, fallbackPhone: phone);

    profile.value = profile.value.copyWith(
      id: parsed.id.isNotEmpty ? parsed.id : profile.value.id,
      name: parsed.name.isNotEmpty ? parsed.name : name,
      phone: parsed.phone.isNotEmpty ? parsed.phone : phone,
      email: parsed.email.isNotEmpty ? parsed.email : email,
      vendorId: parsed.vendorId > 0 ? parsed.vendorId : profile.value.vendorId,
      vendorName: parsed.vendorName.isNotEmpty
          ? parsed.vendorName
          : profile.value.vendorName,
      storeName: parsed.storeName.isNotEmpty
          ? parsed.storeName
          : profile.value.storeName,
      photoUrl: parsed.photoUrl.isNotEmpty
          ? parsed.photoUrl
          : profile.value.photoUrl,
      vehicleType: parsed.vehicleType.isNotEmpty
          ? parsed.vehicleType
          : vehicleType,
      vehicleNumber: parsed.vehicleNumber.isNotEmpty
          ? parsed.vehicleNumber
          : vehicleNumber,
      profileCompleted: true,
      approvalStatus: parsed.approvalStatus,
      approvalNote: parsed.approvalNote,
    );

    await _applyPreferenceData(data);
    await ensureOfficialWorkingHours(payload: data);
    await _prefs?.setString(_kName, profile.value.name);
    await _prefs?.setString(_kPhone, profile.value.phone);
    await _prefs?.setString(_kEmail, profile.value.email);
    await _prefs?.setString(_kVehicleType, profile.value.vehicleType);
    await _prefs?.setString(_kVehicleNumber, profile.value.vehicleNumber);
    await _prefs?.setString(_kProfilePhotoUrl, profile.value.photoUrl);
    await _prefs?.setBool(_kProfileCompleted, true);

    final parsedId = int.tryParse(parsed.id);
    if (parsedId != null) {
      driverId.value = parsedId;
      await _prefs?.setInt(_kDriverId, parsedId);
    } else {
      final remoteId =
          response['driver_id'] ?? response['id'] ?? response['user_id'];
      final driverIdValue = int.tryParse(remoteId.toString());
      if (driverIdValue != null) {
        driverId.value = driverIdValue;
        await _prefs?.setInt(_kDriverId, driverIdValue);
      }
    }

    isLoggedIn.value = true;
    await _prefs?.setBool(_kLoggedIn, true);
    await clearRegistrationDraft();
    return true;
  }

  Future<void> refreshSystemChecks() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      hasInternet.value = connectivity.any(
        (result) => result != ConnectivityResult.none,
      );
    } catch (_) {
      // Keep the last known connectivity flag.
    }

    final enabled = await Geolocator.isLocationServiceEnabled();
    gpsEnabled.value = enabled;

    _gpsProbeTimer ??= Timer.periodic(const Duration(seconds: 15), (_) async {
      gpsEnabled.value = await Geolocator.isLocationServiceEnabled();
      if (isShiftActive.value && liveCoordinate.value == null) {
        await _updateFallbackCoordinate();
      }
    });
  }

  void _startDashboardTicker() {
    _dashboardTicker?.cancel();
    _dashboardTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      dashboardTick.value++;
      _workingHoursRefreshTick++;
      if (isLoggedIn.value && _workingHoursRefreshTick % 5 == 0) {
        unawaited(ensureOfficialWorkingHours(force: true));
      }
    });
  }

  Future<void> _updateFallbackCoordinate() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      await _applyLiveCoordinate(position);
    } catch (_) {
      // Fallback stays null if geolocation is unavailable.
    }
  }

  Future<void> requestOtpForPhone(String phone) async {
    final response = await api.sendWhatsAppOtp(
      phone: phone,
      locale: localeCode.value,
    );

    if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
      throw StateError(
        (response['message'] ?? 'تعذر إرسال رمز التحقق').toString(),
      );
    }

    otpCode.value = (response['debug_code'] ?? '').toString();
    profile.value = profile.value.copyWith(phone: phone);
    await _prefs?.setString(_kPhone, phone);
  }

  Future<bool> verifyOtp(String code) async {
    final phone = profile.value.phone.trim();
    if (phone.isEmpty) {
      return false;
    }

    final response = await api.verifyWhatsAppOtp(
      phone: phone,
      code: code,
      locale: localeCode.value,
    );

    if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
      return false;
    }

    isLoggedIn.value = true;
    authToken.value = (response['token'] ?? '').toString();
    refreshToken.value = (response['refresh_token'] ?? '').toString();

    await _prefs?.setBool(_kLoggedIn, true);
    await _prefs?.setString(_kAuthToken, authToken.value ?? '');
    await _prefs?.setString(_kRefreshToken, refreshToken.value ?? '');

    final user = response['user'];
    if (user is Map) {
      final normalized = user.map((key, value) => MapEntry('$key', value));
      final remoteName = normalized['users_name']?.toString().trim();
      if (remoteName != null && remoteName.isNotEmpty) {
        profile.value = profile.value.copyWith(name: remoteName);
        await _prefs?.setString(_kName, remoteName);
      }
    }

    await loadDriverProfile(
      phone: phone,
      email: profile.value.email.isNotEmpty ? profile.value.email : null,
    );
    return true;
  }

  Future<void> loadDriverProfile({String? phone, String? email}) async {
    final targetPhone = (phone ?? profile.value.phone).trim();
    final targetEmail = (email ?? profile.value.email).trim();
    if (targetPhone.isEmpty && targetEmail.isEmpty) {
      return;
    }

    final response = await api.upsertDriverProfile(
      phone: targetPhone.isNotEmpty ? targetPhone : null,
      email: targetEmail.isEmpty ? null : targetEmail,
    );
    if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
      return;
    }

    final data =
        response['data'] ??
        response['profile'] ??
        response['driver'] ??
        response;
    final parsed = DriverRemoteParser.parseProfile(
      data,
      fallbackPhone: targetPhone.isNotEmpty ? targetPhone : profile.value.phone,
    );

    profile.value = profile.value.copyWith(
      id: parsed.id.isNotEmpty ? parsed.id : profile.value.id,
      name: parsed.name.isNotEmpty ? parsed.name : profile.value.name,
      phone: parsed.phone.isNotEmpty
          ? parsed.phone
          : (targetPhone.isNotEmpty ? targetPhone : profile.value.phone),
      email: parsed.email.isNotEmpty
          ? parsed.email
          : (targetEmail.isNotEmpty ? targetEmail : profile.value.email),
      vendorId: parsed.vendorId > 0 ? parsed.vendorId : profile.value.vendorId,
      vendorName: parsed.vendorName.isNotEmpty
          ? parsed.vendorName
          : profile.value.vendorName,
      storeName: parsed.storeName.isNotEmpty
          ? parsed.storeName
          : profile.value.storeName,
      vehicleType: parsed.vehicleType.isNotEmpty
          ? parsed.vehicleType
          : profile.value.vehicleType,
      vehicleNumber: parsed.vehicleNumber.isNotEmpty
          ? parsed.vehicleNumber
          : profile.value.vehicleNumber,
      photoUrl: parsed.photoUrl.isNotEmpty
          ? parsed.photoUrl
          : profile.value.photoUrl,
      profileCompleted:
          parsed.profileCompleted || profile.value.profileCompleted,
    );

    await _applyPreferenceData(data);
    await ensureOfficialWorkingHours(payload: data);

    await _prefs?.setString(_kPhone, profile.value.phone);
    await _prefs?.setString(_kEmail, profile.value.email);
    await _prefs?.setString(_kName, profile.value.name);
    await _prefs?.setInt(_kVendorId, profile.value.vendorId);
    await _prefs?.setString(_kVendorName, profile.value.vendorName);
    await _prefs?.setString(_kStoreName, profile.value.storeName);
    await _prefs?.setString(_kVehicleType, profile.value.vehicleType);
    await _prefs?.setString(_kVehicleNumber, profile.value.vehicleNumber);
    await _prefs?.setString(_kProfilePhotoUrl, profile.value.photoUrl);
    await _prefs?.setBool(_kProfileCompleted, profile.value.profileCompleted);

    final parsedId = int.tryParse(parsed.id);
    if (parsedId != null) {
      driverId.value = parsedId;
      await _prefs?.setInt(_kDriverId, parsedId);
      return;
    }

    if (data is Map) {
      final normalized = data.map((key, value) => MapEntry('$key', value));
      final remoteId = normalized['id']?.toString();
      final driverIdValue = int.tryParse(remoteId ?? '');
      if (driverIdValue != null) {
        driverId.value = driverIdValue;
        await _prefs?.setInt(_kDriverId, driverIdValue);
      }
    }
  }

  Future<bool> ensureDriverProfileLinked({String? phone}) async {
    final targetPhone = (phone ?? profile.value.phone).trim();
    final targetEmail = profile.value.email.trim();
    if (driverId.value != null) {
      return true;
    }

    if (targetPhone.isEmpty && targetEmail.isEmpty) {
      return false;
    }

    try {
      await loadDriverProfile(
        phone: targetPhone.isNotEmpty ? targetPhone : null,
        email: targetEmail.isNotEmpty ? targetEmail : null,
      );
    } catch (_) {
      // Keep trying to start the session even if the sync fails here.
    }

    return driverId.value != null;
  }

  Future<void> saveProfile({
    required String name,
    required String email,
    required String vehicleType,
    required String vehicleNumber,
    int? vendorId,
  }) async {
    final phone = profile.value.phone.trim();
    final targetEmail = email.trim();
    final response = await api.upsertDriverProfile(
      phone: phone.isNotEmpty ? phone : null,
      email: targetEmail.isEmpty ? null : targetEmail,
      name: name,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
      vendorId: vendorId,
    );

    if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
      throw StateError(
        (response['message'] ?? 'تعذر حفظ ملف السائق').toString(),
      );
    }

    final data = response['data'] ?? response['profile'] ?? response['driver'];
    final parsed = DriverRemoteParser.parseProfile(data, fallbackPhone: phone);

    profile.value = profile.value.copyWith(
      id: parsed.id.isNotEmpty ? parsed.id : profile.value.id,
      name: parsed.name.isNotEmpty ? parsed.name : name,
      phone: parsed.phone.isNotEmpty ? parsed.phone : phone,
      email: parsed.email.isNotEmpty ? parsed.email : targetEmail,
      vehicleType: parsed.vehicleType.isNotEmpty
          ? parsed.vehicleType
          : vehicleType,
      vehicleNumber: parsed.vehicleNumber.isNotEmpty
          ? parsed.vehicleNumber
          : vehicleNumber,
      photoUrl: parsed.photoUrl.isNotEmpty
          ? parsed.photoUrl
          : profile.value.photoUrl,
      profileCompleted:
          parsed.profileCompleted || profile.value.profileCompleted,
    );

    await _applyPreferenceData(data);
    await ensureOfficialWorkingHours(payload: data);

    await _prefs?.setString(_kName, profile.value.name);
    await _prefs?.setString(_kPhone, profile.value.phone);
    await _prefs?.setString(_kEmail, profile.value.email);
    await _prefs?.setString(_kVehicleType, profile.value.vehicleType);
    await _prefs?.setString(_kVehicleNumber, profile.value.vehicleNumber);
    await _prefs?.setString(_kProfilePhotoUrl, profile.value.photoUrl);
    await _prefs?.setBool(_kProfileCompleted, profile.value.profileCompleted);

    final parsedId = int.tryParse(parsed.id);
    if (parsedId != null) {
      driverId.value = parsedId;
      await _prefs?.setInt(_kDriverId, parsedId);
    }
  }

  Future<void> registerEmailAccount({
    required String name,
    required String phone,
    required String email,
    required String password,
    int? vendorId,
    String? vehicleType,
    String? vehicleNumber,
  }) async {
    final response = await api.registerDriverEmailAccount(
      name: name,
      phone: phone,
      email: email,
      password: password,
      vendorId: vendorId,
      vehicleType: vehicleType,
      vehicleNumber: vehicleNumber,
    );

    if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
      throw StateError(
        (response['message'] ?? 'تعذر إنشاء الحساب بالإيميل').toString(),
      );
    }

    isLoggedIn.value = true;
    await _prefs?.setBool(_kLoggedIn, true);
    await _prefs?.setString(_kPhone, phone);
    await _prefs?.setString(_kEmail, email);
    await _prefs?.setString(_kName, name);
    if (vendorId != null && vendorId > 0) {
      await _prefs?.setInt(_kVendorId, vendorId);
    }

    if (vehicleType != null && vehicleType.isNotEmpty) {
      await _prefs?.setString(_kVehicleType, vehicleType);
    }
    if (vehicleNumber != null && vehicleNumber.isNotEmpty) {
      await _prefs?.setString(_kVehicleNumber, vehicleNumber);
    }

    final data = response['data'] ?? response['profile'] ?? response['driver'];
    final parsed = DriverRemoteParser.parseProfile(data, fallbackPhone: phone);
    profile.value = profile.value.copyWith(
      id: parsed.id.isNotEmpty ? parsed.id : profile.value.id,
      name: parsed.name.isNotEmpty ? parsed.name : name,
      phone: parsed.phone.isNotEmpty ? parsed.phone : phone,
      email: parsed.email.isNotEmpty ? parsed.email : email,
      vendorId: parsed.vendorId > 0 ? parsed.vendorId : vendorId,
      vendorName: parsed.vendorName.isNotEmpty
          ? parsed.vendorName
          : profile.value.vendorName,
      storeName: parsed.storeName.isNotEmpty
          ? parsed.storeName
          : profile.value.storeName,
      vehicleType: parsed.vehicleType.isNotEmpty
          ? parsed.vehicleType
          : (vehicleType ?? profile.value.vehicleType),
      vehicleNumber: parsed.vehicleNumber.isNotEmpty
          ? parsed.vehicleNumber
          : (vehicleNumber ?? profile.value.vehicleNumber),
    );

    final parsedId = int.tryParse(parsed.id);
    if (parsedId != null) {
      driverId.value = parsedId;
      await _prefs?.setInt(_kDriverId, parsedId);
    } else {
      final remoteId =
          response['driver_id'] ?? response['id'] ?? response['user_id'];
      final driverIdValue = int.tryParse(remoteId.toString());
      if (driverIdValue != null) {
        driverId.value = driverIdValue;
        await _prefs?.setInt(_kDriverId, driverIdValue);
      }
    }

    try {
      await loadDriverProfile(phone: phone, email: email);
    } catch (_) {
      // Registration succeeded; profile sync can happen later.
    }
  }

  Future<List<DriverRestaurantChoice>> fetchAvailableRestaurants() async {
    final response = await api.fetchDriverRestaurants();
    if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
      return const [];
    }

    final raw = response['data'];
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map(
          (entry) => DriverRestaurantChoice(
            id: int.tryParse('${entry['vendor_id'] ?? 0}') ?? 0,
            vendorName: '${entry['vendor_name'] ?? ''}',
            storeName: '${entry['store_name'] ?? ''}',
            description: '${entry['vendor_description'] ?? ''}',
          ),
        )
        .where((choice) => choice.id > 0)
        .toList(growable: false);
  }

  Future<DriverWorkingHoursSchedule> ensureOfficialWorkingHours({
    bool force = false,
    dynamic payload,
  }) async {
    final parsedFromPayload = _scheduleFromPayload(payload);
    if (parsedFromPayload != null) {
      _applyOfficialWorkingHours(parsedFromPayload);
      return officialWorkingHours.value;
    }

    if (!force && _officialWorkingHoursSynced) {
      return officialWorkingHours.value;
    }

    try {
      final workingHoursResponse = await api.fetchDriverWorkingHours();
      final scheduleFromWorkingHours = _scheduleFromWorkingHoursResponse(
        workingHoursResponse,
      );
      if (scheduleFromWorkingHours != null) {
        _applyOfficialWorkingHours(scheduleFromWorkingHours);
        return officialWorkingHours.value;
      }
      _officialWorkingHoursSynced = false;
    } catch (_) {
      // Keep the last known schedule if a refresh fails temporarily.
      _officialWorkingHoursSynced = false;
    }

    return officialWorkingHours.value;
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await api.loginDriverEmailAccount(
      email: email,
      password: password,
    );

    if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
      return false;
    }

    isLoggedIn.value = true;
    await _prefs?.setBool(_kLoggedIn, true);

    final data = response['data'] ?? response['user'] ?? response['driver'];
    final parsed = DriverRemoteParser.parseProfile(
      data,
      fallbackPhone: profile.value.phone,
    );

    profile.value = profile.value.copyWith(
      id: parsed.id.isNotEmpty ? parsed.id : profile.value.id,
      name: parsed.name.isNotEmpty ? parsed.name : profile.value.name,
      phone: parsed.phone.isNotEmpty ? parsed.phone : profile.value.phone,
      email: parsed.email.isNotEmpty ? parsed.email : email,
      vendorId: parsed.vendorId > 0 ? parsed.vendorId : profile.value.vendorId,
      vendorName: parsed.vendorName.isNotEmpty
          ? parsed.vendorName
          : profile.value.vendorName,
      storeName: parsed.storeName.isNotEmpty
          ? parsed.storeName
          : profile.value.storeName,
      vehicleType: parsed.vehicleType.isNotEmpty
          ? parsed.vehicleType
          : profile.value.vehicleType,
      vehicleNumber: parsed.vehicleNumber.isNotEmpty
          ? parsed.vehicleNumber
          : profile.value.vehicleNumber,
      photoUrl: parsed.photoUrl.isNotEmpty
          ? parsed.photoUrl
          : profile.value.photoUrl,
      profileCompleted:
          (response['needs_profile_setup'] ?? response['needsProfileSetup'])
                  .toString()
                  .toLowerCase() ==
              'false'
          ? true
          : parsed.profileCompleted || profile.value.profileCompleted,
    );

    await _applyPreferenceData(data);
    await ensureOfficialWorkingHours(payload: data);

    await _prefs?.setString(_kName, profile.value.name);
    await _prefs?.setString(_kPhone, profile.value.phone);
    await _prefs?.setString(_kEmail, profile.value.email);
    await _prefs?.setString(_kVehicleType, profile.value.vehicleType);
    await _prefs?.setString(_kVehicleNumber, profile.value.vehicleNumber);
    await _prefs?.setString(_kProfilePhotoUrl, profile.value.photoUrl);
    await _prefs?.setBool(_kProfileCompleted, profile.value.profileCompleted);
    if (profile.value.vendorId > 0) {
      await _prefs?.setInt(_kVendorId, profile.value.vendorId);
    }
    await _prefs?.setString(_kVendorName, profile.value.vendorName);
    await _prefs?.setString(_kStoreName, profile.value.storeName);

    final parsedId = int.tryParse(parsed.id);
    if (parsedId != null) {
      driverId.value = parsedId;
      await _prefs?.setInt(_kDriverId, parsedId);
    } else {
      final remoteId =
          response['driver_id'] ?? response['id'] ?? response['user_id'];
      final driverIdValue = int.tryParse(remoteId.toString());
      if (driverIdValue != null) {
        driverId.value = driverIdValue;
        await _prefs?.setInt(_kDriverId, driverIdValue);
      }
    }

    await clearRegistrationDraft();
    return true;
  }

  Future<void> startShift() async {
    final linked = await ensureDriverProfileLinked();
    if (!linked) {
      throw StateError('لم يتم ربط ملف السائق بالباك-إند بعد.');
    }

    if (!profile.value.profileCompleted) {
      throw StateError('Profile setup is required before starting a shift.');
    }

    final remoteDriverId = driverId.value;
    if (remoteDriverId == null) {
      throw StateError('لم يتم ربط ملف السائق بالباك-إند بعد.');
    }

    final schedule = await ensureOfficialWorkingHours(force: true);
    final now = DateTime.now();
    if (!schedule.isOpenAt(now)) {
      throw StateError(
        schedule.blockedMessage(localeCode: localeCode.value, now: now),
      );
    }

    if (!gpsEnabled.value) {
      throw StateError('يجب تفعيل GPS قبل بدء المناوبة.');
    }

    isShiftActive.value = true;
    availability.value = DriverAvailability.available;
    _shiftStartedAt = DateTime.now();
    await _prefs?.setBool(_kShiftActive, true);
    await _prefs?.setInt(
      _kShiftStartedAt,
      _shiftStartedAt!.millisecondsSinceEpoch,
    );
    _startDashboardTicker();

    try {
      await api.updateDriverStatus(driverId: remoteDriverId, status: 'online');
    } catch (_) {
      // The shift can still start locally even if the status sync is delayed.
    }
    unawaited(_resumeShiftRuntime());
  }

  Future<void> endShift() async {
    final remoteDriverId = driverId.value;
    if (remoteDriverId != null) {
      try {
        await api.updateDriverStatus(
          driverId: remoteDriverId,
          status: 'offline',
        );
      } catch (_) {
        // Ignore offline sync failures during shutdown.
      }
    }

    isShiftActive.value = false;
    availability.value = DriverAvailability.offline;
    liveCoordinate.value = null;
    _shiftStartedAt = null;
    await _prefs?.setBool(_kShiftActive, false);
    await _prefs?.remove(_kShiftStartedAt);
    await _positionSub?.cancel();
    _positionSub = null;
  }

  Future<void> _resumeShiftRuntime() async {
    try {
      await _startLocationTracking();
      await _updateFallbackCoordinate();
    } catch (_) {
      // Location tracking is best-effort for the shift runtime.
    }
  }

  Future<void> signOut() async {
    try {
      await _positionSub?.cancel();
      _positionSub = null;
      _dashboardTicker?.cancel();
      _dashboardTicker = null;
      _gpsProbeTimer?.cancel();
    } catch (_) {}

    try {
      await endShift();
    } catch (_) {
      // Logout should continue even if remote status sync fails.
    }

    isLoggedIn.value = false;
    availability.value = DriverAvailability.offline;
    liveCoordinate.value = null;
    authToken.value = null;
    refreshToken.value = null;
    driverId.value = null;
    profile.value = const DriverProfile(
      id: 'driver-001',
      name: 'السائق',
      phone: '',
      email: '',
      vendorId: 0,
      vendorName: '',
      storeName: '',
      vehicleType: 'دراجة نارية',
      vehicleNumber: 'AEP-204',
    );
    officialWorkingHours.value = DriverWorkingHoursSchedule.defaultSchedule();
    _officialWorkingHoursSynced = false;
    _shiftStartedAt = null;
    await clearRegistrationDraft();
    await _prefs?.setBool(_kLoggedIn, false);
    await _prefs?.remove(_kAuthToken);
    await _prefs?.remove(_kRefreshToken);
    await _prefs?.remove(_kDriverId);
    await _prefs?.remove(_kPhone);
    await _prefs?.remove(_kEmail);
    await _prefs?.remove(_kName);
    await _prefs?.remove(_kVendorId);
    await _prefs?.remove(_kVendorName);
    await _prefs?.remove(_kStoreName);
    await _prefs?.remove(_kVehicleType);
    await _prefs?.remove(_kVehicleNumber);
    await _prefs?.remove(_kProfilePhotoUrl);
    await _prefs?.remove(_kVoiceCallActiveOrderId);
    await _prefs?.setBool(_kProfileCompleted, false);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _applyThemeMode(ThemeMode.light);
    await _prefs?.setBool(_kDarkMode, false);
    await _prefs?.setString(_kThemeModeValue, ThemeMode.light.name);
    await _syncDriverPreferences();
  }

  Future<void> setLocale(String code) async {
    final normalized = code.trim().toLowerCase() == 'en' ? 'en' : 'ar';
    localeCode.value = normalized;
    Get.updateLocale(Locale(normalized));
    await _prefs?.setString(_kLocale, normalized);
    await _syncDriverPreferences();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled.value = value;
    await _prefs?.setBool(_kNotificationsEnabled, value);
    await _syncDriverPreferences();
  }

  Future<void> setVibrationEnabled(bool value) async {
    vibrationEnabled.value = value;
    await _prefs?.setBool(_kVibrationEnabled, value);
  }

  Future<void> setLocationSharingEnabled(bool value) async {
    locationSharingEnabled.value = value;
    await _prefs?.setBool(_kLocationSharingEnabled, value);
    await _syncDriverPreferences();
  }

  Future<void> _syncDriverPreferences() async {
    final remoteDriverId = driverId.value;
    if (remoteDriverId == null) {
      return;
    }

    try {
      await api.upsertDriverProfile(
        phone: profile.value.phone.isNotEmpty ? profile.value.phone : null,
        email: profile.value.email.isNotEmpty ? profile.value.email : null,
        vendorId: profile.value.vendorId > 0 ? profile.value.vendorId : null,
        notificationsEnabled: notificationsEnabled.value,
        locationSharingEnabled: locationSharingEnabled.value,
        localeCode: localeCode.value,
        themeMode: themeMode.value == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {
      // Preference sync is best effort.
    }
  }

  Future<void> _applyPreferenceData(dynamic data) async {
    final map = data is Map
        ? data.map((key, value) => MapEntry('$key', value))
        : <String, dynamic>{};
    if (map.isEmpty) {
      return;
    }

    if (map.containsKey('notifications_enabled')) {
      final raw = map['notifications_enabled'];
      final value =
          raw == 1 ||
          raw == '1' ||
          raw == true ||
          raw.toString().toLowerCase() == 'true';
      notificationsEnabled.value = value;
      await _prefs?.setBool(_kNotificationsEnabled, value);
    }
    if (map.containsKey('location_sharing_enabled')) {
      final raw = map['location_sharing_enabled'];
      final value =
          raw == 1 ||
          raw == '1' ||
          raw == true ||
          raw.toString().toLowerCase() == 'true';
      locationSharingEnabled.value = value;
      await _prefs?.setBool(_kLocationSharingEnabled, value);
    }
    final remoteLocale = map['locale_code']?.toString().trim();
    if (remoteLocale != null && remoteLocale.isNotEmpty) {
      localeCode.value = remoteLocale;
      await _prefs?.setString(_kLocale, remoteLocale);
    }
    final String? remoteTheme = map['theme_mode']
        ?.toString()
        .trim()
        .toLowerCase();
    if (remoteTheme == 'dark' || remoteTheme == 'light') {
      await _applyThemeMode(ThemeMode.light);
      await _prefs?.setBool(_kDarkMode, false);
      await _prefs?.setString(_kThemeModeValue, ThemeMode.light.name);
    }
  }

  Future<void> _applyThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    themeMode.refresh();
    Get.changeThemeMode(mode);
    await Get.forceAppUpdate();
  }

  void _applyOfficialWorkingHours(DriverWorkingHoursSchedule schedule) {
    officialWorkingHours.value = schedule.hasDays
        ? schedule
        : DriverWorkingHoursSchedule.defaultSchedule();
    _officialWorkingHoursSynced = true;
  }

  DriverWorkingHoursSchedule? _scheduleFromPayload(dynamic payload) {
    if (payload == null) {
      return null;
    }

    if (payload is String || payload is List) {
      final parsed = DriverWorkingHoursSchedule.fromJson(payload);
      return parsed.hasDays ? parsed : null;
    }

    if (payload is! Map) {
      return null;
    }

    final map = payload.map((key, value) => MapEntry('$key', value));
    final directCandidates = <dynamic>[
      map['delivery_working_hours_json'],
      map['working_hours_json'],
      map['working_hours'],
      map['official_working_hours_json'],
      map['official_working_hours'],
      map['store_working_hours_json'],
      map['store_working_hours'],
    ];

    for (final candidate in directCandidates) {
      if (candidate == null) {
        continue;
      }
      final parsed = DriverWorkingHoursSchedule.fromJson(candidate);
      if (parsed.hasDays) {
        return parsed;
      }
    }

    final nestedCandidates = <dynamic>[
      map['settings'],
      map['vendor_store_settings'],
      map['restaurant_settings'],
      map['vendor'],
      map['store'],
      map['restaurant'],
    ];

    for (final candidate in nestedCandidates) {
      final parsed = _scheduleFromPayload(candidate);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  DriverWorkingHoursSchedule? _scheduleFromWorkingHoursResponse(
    Map<String, dynamic> response,
  ) {
    if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
      return null;
    }

    return _scheduleFromPayload(response['data']);
  }

  Future<void> _startLocationTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      gpsEnabled.value = serviceEnabled;
      if (!serviceEnabled) {
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      await _positionSub?.cancel();
      _positionSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((position) {
            _applyLiveCoordinate(position);
          });
    } catch (_) {
      // Keep the last known coordinate only.
    }
  }

  Future<void> _applyLiveCoordinate(Position position) async {
    liveCoordinate.value = DriverCoordinate(
      latitude: position.latitude,
      longitude: position.longitude,
      heading: position.heading >= 0 && position.heading.isFinite
          ? position.heading
          : null,
      speed: position.speed.isFinite && position.speed >= 0
          ? position.speed
          : null,
    );

    final remoteDriverId = driverId.value;
    final hasActiveOrder =
        Get.isRegistered<DriverOrdersService>() &&
        Get.find<DriverOrdersService>().activeOrder.value != null;
    if (!isShiftActive.value ||
        remoteDriverId == null ||
        (!locationSharingEnabled.value && !hasActiveOrder)) {
      return;
    }

    try {
      await api.updateDriverLocation(
        driverId: remoteDriverId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (Get.isRegistered<DriverOrdersService>()) {
        unawaited(
          Get.find<DriverOrdersService>().pushLiveTrackingFeed(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      }
    } catch (_) {
      // Location sync is best effort.
    }
  }

  bool isWithinOfficialWorkingHours([DateTime? moment]) {
    return officialWorkingHours.value.isOpenAt(moment ?? DateTime.now());
  }

  String officialWorkingHoursTodayText([DateTime? moment]) {
    return officialWorkingHours.value.todayWindowText(
      localeCode: localeCode.value,
      now: moment,
    );
  }

  String officialWorkingHoursBlockedText([DateTime? moment]) {
    return officialWorkingHours.value.blockedMessage(
      localeCode: localeCode.value,
      now: moment,
    );
  }

  String officialWorkingHoursWeeklyText() {
    return officialWorkingHours.value.weeklySummary(
      localeCode: localeCode.value,
    );
  }

  String get shiftElapsedText {
    if (_shiftStartedAt == null) {
      return '0h 0m';
    }
    final hours = shiftElapsedMinutes ~/ 60;
    final minutes = shiftElapsedMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  int get shiftElapsedMinutes {
    if (_shiftStartedAt == null) {
      return 0;
    }
    return DateTime.now().difference(_shiftStartedAt!).inMinutes;
  }
}
