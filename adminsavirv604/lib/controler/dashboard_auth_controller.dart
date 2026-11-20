import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/core/services/dashboard_session_service.dart';
import 'package:admin_tks/firebase/admin_notifications.dart';
import 'package:get/get.dart';

class DashboardAuthController extends GetxController {
  final DashboardSessionService _sessionService =
      DashboardSessionService.instance;

  final Rxn<DashboardSession> session = Rxn<DashboardSession>();
  final RxBool isReady = false.obs;

  DashboardSession? get _activeSession =>
      session.value?.isValid == true ? session.value : null;

  bool get isLoggedIn => session.value?.isValid ?? false;
  bool get isMaster => _activeSession?.role == 'master';
  String get authToken => _activeSession?.token ?? '';
  String get storeName => _activeSession?.storeName ?? '';
  String get vendorName => _activeSession?.vendorName ?? '';
  String get displayName => _activeSession?.displayName ?? '';
  String get vendorDescription => _activeSession?.vendorDescription ?? '';
  int get vendorId => _activeSession?.vendorId ?? 0;
  String get vendorType => _activeSession?.vendorType ?? 'restaurant';
  String? get storeCategory => _activeSession?.storeCategory;
  bool get isStore => vendorType == 'store';

  Future<void> restoreSession() async {
    final restored = await _sessionService.loadSession();
    if (restored != null && restored.isValid) {
      session.value = restored;
      await AdminNotifications.setVendorContext(restored.vendorId);
    } else {
      await _sessionService.clearSession();
      session.value = null;
      await AdminNotifications.setVendorContext(0);
    }
    isReady.value = true;
  }

  Future<void> loginVendor({
    required String email,
    required String password,
  }) async {
    // The master console uses a separate authentication namespace. Trying it
    // first keeps the same login form usable for both account types.
    try {
      final masterResponse = await DashboardApiClient.postJsonUrl(
        DashboardApiClient.masterAuthUri('/login.php').toString(),
        authorized: false,
        body: {'email': email.trim(), 'password': password},
      );
      await _saveSessionFromResponse(masterResponse);
      return;
    } catch (_) {
      final vendorResponse = await DashboardApiClient.postJsonUrl(
        DashboardApiClient.authUri('/login.php').toString(),
        authorized: false,
        body: {'email': email.trim(), 'password': password},
      );
      await _saveSessionFromResponse(vendorResponse);
    }
  }

  Future<void> signup({
    required String vendorName,
    required String storeName,
    required String email,
    required String phone,
    required String password,
    String? logoBase64,
    String? storeAddress,
    double? storeLatitude,
    double? storeLongitude,
    String vendorType = 'restaurant',
    String? storeCategory,
  }) async {
    final body = <String, dynamic>{
      'vendor_name': vendorName.trim(),
      'store_name': storeName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'vendor_type': vendorType,
      if (vendorType == 'store' && storeCategory != null)
        'store_category': storeCategory,
    };

    if (logoBase64 != null && logoBase64.trim().isNotEmpty) {
      body['vendor_logo_base64'] = logoBase64.trim();
    }
    if (storeAddress != null && storeAddress.trim().isNotEmpty) {
      body['store_address'] = storeAddress.trim();
    }
    if (storeLatitude != null) {
      body['store_latitude'] = storeLatitude;
    }
    if (storeLongitude != null) {
      body['store_longitude'] = storeLongitude;
    }

    final response = await DashboardApiClient.postJsonUrl(
      DashboardApiClient.authUri('/signup.php').toString(),
      authorized: false,
      body: body,
    );

    _ensureSuccess(response, fallbackMessage: 'Signup failed');
  }

  Future<void> verifySignupCode({
    required String email,
    required String code,
  }) async {
    final response = await DashboardApiClient.postJsonUrl(
      DashboardApiClient.authUri('/verify_signup_code.php').toString(),
      authorized: false,
      body: {
        'email': email.trim(),
        'code': code.trim(),
      },
    );

    _ensureSuccess(response, fallbackMessage: 'Verification failed');
  }

  Future<void> resendSignupCode(String email) async {
    final response = await DashboardApiClient.postJsonUrl(
      DashboardApiClient.authUri('/resend_signup_code.php').toString(),
      authorized: false,
      body: {'email': email.trim()},
    );

    _ensureSuccess(response, fallbackMessage: 'Resend failed');
  }

  Future<Map<String, dynamic>> checkSignupStatus(String email) async {
    final response = await DashboardApiClient.postJsonUrl(
      DashboardApiClient.authUri('/check_signup_status.php').toString(),
      authorized: false,
      body: {'email': email.trim()},
    );

    final decoded = _ensureSuccess(response, fallbackMessage: 'Status check failed');
    return decoded.cast<String, dynamic>();
  }

  Future<void> sendResetCode(String email) async {
    final response = await DashboardApiClient.postJsonUrl(
      DashboardApiClient.authUri('/check_email.php').toString(),
      authorized: false,
      body: {'email': email.trim()},
    );

    _ensureSuccess(response, fallbackMessage: 'Failed to send reset code');
  }

  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final response = await DashboardApiClient.postJsonUrl(
      DashboardApiClient.authUri('/verify_reset_code.php').toString(),
      authorized: false,
      body: {
        'email': email.trim(),
        'code': code.trim(),
      },
    );

    _ensureSuccess(response, fallbackMessage: 'Invalid reset code');
  }

  Future<void> changePassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final response = await DashboardApiClient.postJsonUrl(
      DashboardApiClient.authUri('/change_password.php').toString(),
      authorized: false,
      body: {
        'email': email.trim(),
        'code': code.trim(),
        'password': password,
      },
    );

    _ensureSuccess(response, fallbackMessage: 'Change password failed');
  }

  Future<void> logout() async {
    final logoutUri = isMaster
        ? DashboardApiClient.masterAuthUri('/logout.php').toString()
        : DashboardApiClient.authUri('/logout.php').toString();

    try {
      if (authToken.isNotEmpty) {
        await DashboardApiClient.postJsonUrl(
          logoutUri,
          body: const {},
        );
      }
    } catch (_) {
      // Ignore network logout failure and clear local session anyway.
    } finally {
      await AdminNotifications.setVendorContext(0);
      await _sessionService.clearSession();
      session.value = null;
    }
  }

  Future<void> _saveSessionFromResponse(dynamic response) async {
    final decoded = _ensureSuccess(response, fallbackMessage: 'Login failed');
    final newSession =
        DashboardSession.fromJson(decoded.cast<String, dynamic>());
    await _sessionService.saveSession(newSession);
    session.value = newSession;
    await AdminNotifications.setVendorContext(newSession.vendorId);
  }

  Map _ensureSuccess(
    dynamic response, {
    required String fallbackMessage,
  }) {
    final decoded = DashboardApiClient.decodeJson(response);
    if (decoded is! Map || decoded['status'] != 'success') {
      throw Exception(decoded is Map
          ? decoded['message']?.toString() ?? fallbackMessage
          : fallbackMessage);
    }
    return decoded;
  }
}
