import 'dart:math';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tks/core/services/local_json_cache.dart';

class MyServices extends GetxService {
  static const String keyLang = 'lang';
  static const String keyStep = 'step';
  static const String keyOnboardingDone = 'aleppo_onboarding_done';
  static const String keyPendingPhone = 'aleppo_pending_phone';
  static const String keyPendingProfile = 'aleppo_pending_profile';
  static const String keyPendingGoogleVerification =
      'aleppo_pending_google_verification';
  static const String keyPendingGoogleEmail = 'aleppo_pending_google_email';
  static const String keyPendingGoogleName = 'aleppo_pending_google_name';
  static const String keyPendingGooglePhoto = 'aleppo_pending_google_photo';
  static const String keyPendingGoogleUid = 'aleppo_pending_google_uid';
  static const String keySessionMode = 'aleppo_session_mode';
  static const String keyAccessToken = 'aleppo_access_token';
  static const String keyRefreshToken = 'aleppo_refresh_token';
  static const String keyAccessTokenExpiry = 'aleppo_access_token_expiry';
  static const String keyRefreshTokenExpiry = 'aleppo_refresh_token_expiry';
  static const String keyProfileCompleted = 'aleppo_profile_completed';
  static const String keyCookieConsentMode = 'cookie_consent_mode_v2';
  static const String keyCookieConsentFunctional =
      'cookie_consent_functional_v2';
  static const String keyCookieConsentAnalytics = 'cookie_consent_analytics_v2';
  static const String keyCookieConsentPerformance =
      'cookie_consent_performance_v2';
  static const String keyCookieConsentCommunication =
      'cookie_consent_communication_v2';
  static const String keyCookieConsentThirdParty =
      'cookie_consent_third_party_v2';
  static const String keyCookieConsentUpdatedAt =
      'cookie_consent_updated_at_v2';
  static const String keyCookieConsentNecessary = 'cookie_consent_necessary_v2';
  static const String keyCookieConsentInstallationId =
      'cookie_consent_installation_id_v1';
  static const String keyCookieConsentBackendSynced =
      'cookie_consent_backend_synced_v1';
  static const String keyVoiceCallActiveOrderId =
      'voice_call_active_order_id_v1';

  late SharedPreferences sharedPreferences;

  Future<MyServices> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    return this;
  }

  bool get hasCompletedOnboarding =>
      sharedPreferences.getBool(keyOnboardingDone) ?? false;

  bool get hasGuestSession =>
      sharedPreferences.getString(keySessionMode) == 'guest';

  bool get hasAuthenticatedSession =>
      sharedPreferences.getString(keyStep) == '2' &&
      !hasGuestSession &&
      hasAccessToken;

  bool get hasPendingProfile =>
      sharedPreferences.getBool(keyPendingProfile) ?? false;

  bool get hasPendingGoogleVerification =>
      sharedPreferences.getBool(keyPendingGoogleVerification) ?? false;

  String get accessToken => sharedPreferences.getString(keyAccessToken) ?? '';

  bool get hasAccessToken => accessToken.trim().isNotEmpty;

  String? get pendingPhone => sharedPreferences.getString(keyPendingPhone);

  String get pendingGoogleEmail =>
      sharedPreferences.getString(keyPendingGoogleEmail) ?? '';

  String get pendingGoogleName =>
      sharedPreferences.getString(keyPendingGoogleName) ?? '';

  String get pendingGooglePhoto =>
      sharedPreferences.getString(keyPendingGooglePhoto) ?? '';

  String get pendingGoogleUid =>
      sharedPreferences.getString(keyPendingGoogleUid) ?? '';

  String? get currentLanguage => sharedPreferences.getString(keyLang);

  bool get hasCookieConsent =>
      (sharedPreferences.getString(keyCookieConsentMode) ?? '').isNotEmpty;

  bool get cookieConsentBackendSynced =>
      sharedPreferences.getBool(keyCookieConsentBackendSynced) ?? false;

  Future<void> markOnboardingSeen() async {
    await sharedPreferences.setBool(keyOnboardingDone, true);
  }

  Future<String> ensureCookieConsentInstallationId() async {
    final existing =
        sharedPreferences.getString(keyCookieConsentInstallationId)?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = 'cc-${DateTime.now().microsecondsSinceEpoch}-'
        '${Random().nextInt(1 << 32).toRadixString(16)}';
    await sharedPreferences.setString(
      keyCookieConsentInstallationId,
      generated,
    );
    return generated;
  }

  Future<void> startGooglePhoneVerification({
    required String email,
    required String name,
    required String photoUrl,
    required String uid,
  }) async {
    await sharedPreferences.setBool(keyOnboardingDone, true);
    await sharedPreferences.setString(keyStep, '1');
    await sharedPreferences.setBool(keyPendingGoogleVerification, true);
    await sharedPreferences.setString(keyPendingGoogleEmail, email.trim());
    await sharedPreferences.setString(keyPendingGoogleName, name.trim());
    await sharedPreferences.setString(keyPendingGooglePhoto, photoUrl.trim());
    await sharedPreferences.setString(keyPendingGoogleUid, uid.trim());
    await sharedPreferences.setBool(keyPendingProfile, false);
    await sharedPreferences.remove(keySessionMode);
  }

  Future<void> clearGooglePhoneVerification() async {
    await sharedPreferences.remove(keyPendingGoogleVerification);
    await sharedPreferences.remove(keyPendingGoogleEmail);
    await sharedPreferences.remove(keyPendingGoogleName);
    await sharedPreferences.remove(keyPendingGooglePhoto);
    await sharedPreferences.remove(keyPendingGoogleUid);
  }

  Future<void> storeAuthSession({
    required Map<dynamic, dynamic> user,
    required String accessToken,
    String? refreshToken,
    String? expiresAt,
    String? refreshExpiresAt,
    required bool profileCompleted,
    String? pendingPhone,
    String sessionMode = 'google_backend',
  }) async {
    final dynamic idRaw = user['users_id'] ?? user['id'];
    final int userId = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0;

    await sharedPreferences.setInt('id', userId);
    await sharedPreferences.setString(
        'username', '${user['users_name'] ?? user['username'] ?? ''}');
    await sharedPreferences.setString(
        'email', '${user['users_email'] ?? user['email'] ?? ''}');
    await sharedPreferences.setString('phone',
        '${user['users_phone'] ?? user['phone'] ?? pendingPhone ?? ''}');
    await sharedPreferences.setString(
        'users_image', '${user['users_image'] ?? ''}');
    await sharedPreferences.setString(keyAccessToken, accessToken);
    await sharedPreferences.setString(keyRefreshToken, refreshToken ?? '');
    await sharedPreferences.setString(keyAccessTokenExpiry, expiresAt ?? '');
    await sharedPreferences.setString(
      keyRefreshTokenExpiry,
      refreshExpiresAt ?? '',
    );
    await sharedPreferences.setString(keyStep, '2');
    await sharedPreferences.setBool(keyOnboardingDone, true);
    await sharedPreferences.setBool(keyPendingProfile, !profileCompleted);
    await sharedPreferences.setBool(keyProfileCompleted, profileCompleted);
    await sharedPreferences.setString(keySessionMode, sessionMode);

    if (pendingPhone != null && pendingPhone.trim().isNotEmpty) {
      await sharedPreferences.setString(keyPendingPhone, pendingPhone.trim());
    } else {
      await sharedPreferences.remove(keyPendingPhone);
    }
  }

  Future<void> updateStoredUser(Map<dynamic, dynamic> user) async {
    await sharedPreferences.setString(
        'username', '${user['users_name'] ?? user['username'] ?? ''}');
    await sharedPreferences.setString(
        'email', '${user['users_email'] ?? user['email'] ?? ''}');
    await sharedPreferences.setString(
        'phone', '${user['users_phone'] ?? user['phone'] ?? ''}');
    await sharedPreferences.setString(
        'users_image', '${user['users_image'] ?? ''}');
    final completed = '${user['profile_completed'] ?? 0}' == '1';
    await sharedPreferences.setBool(keyPendingProfile, !completed);
    await sharedPreferences.setBool(keyProfileCompleted, completed);
    if (completed) {
      await sharedPreferences.remove(keyPendingPhone);
    }
  }

  Future<void> clearUserDraftFlow() async {
    await sharedPreferences.remove(keyPendingPhone);
    await sharedPreferences.remove(keyPendingProfile);
    await sharedPreferences.remove(keySessionMode);
    await clearGooglePhoneVerification();
  }

  Future<void> clearAuthSession() async {
    await clearUserDraftFlow();
    await DeliverySelectionStore.clear(sharedPreferences);
    await sharedPreferences.remove(keyAccessToken);
    await sharedPreferences.remove(keyRefreshToken);
    await sharedPreferences.remove(keyAccessTokenExpiry);
    await sharedPreferences.remove(keyRefreshTokenExpiry);
    await sharedPreferences.remove(keyProfileCompleted);
    await sharedPreferences.remove('id');
    await sharedPreferences.remove('username');
    await sharedPreferences.remove('email');
    await sharedPreferences.remove('phone');
    await sharedPreferences.remove('users_image');
    await sharedPreferences.remove(keyVoiceCallActiveOrderId);
    await sharedPreferences.setString(keyStep, '1');
  }

  Future<void> startGuestSession() async {
    await clearAuthSession();
    await sharedPreferences.setBool(keyOnboardingDone, true);
    await sharedPreferences.setString(keyStep, '2');
    await sharedPreferences.setString(keySessionMode, 'guest');
    await sharedPreferences.setBool(keyPendingProfile, false);
    await sharedPreferences.setBool(keyProfileCompleted, false);
  }

  getData(String s) {}
}

initialServices() async {
  await Get.putAsync(() => MyServices().init());
}
