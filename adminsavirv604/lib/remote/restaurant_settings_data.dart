import 'dart:convert';

import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/core/services/dashboard_session_service.dart';
import 'package:admin_tks/model/restaurant_settings_model.dart';

class RestaurantSettingsData {
  String? lastError;
  int? lastStatusCode;
  static const String _baseUrl =
      '${DashboardApiConfig.dashBaseUrl}/vendor/settings';
  static const String _getUrl = '$_baseUrl/get_settings.php';
  static const String _updateUrl = '$_baseUrl/update_settings.php';

  Future<RestaurantSettingsSnapshot?> getSettings() async {
    lastError = null;
    lastStatusCode = null;
    try {
      final session = await DashboardSessionService.instance.loadSession();
      if (session == null || !session.isValid || session.token.trim().isEmpty) {
        lastStatusCode = 401;
        lastError = 'انتهت جلسة لوحة الإدارة، سجّل الدخول مرة أخرى.';
        return null;
      }
      final response = await DashboardApiClient.getUrl(_getUrl);
      lastStatusCode = response.statusCode;
      if (response.statusCode != 200) {
        lastError = 'HTTP ${response.statusCode}: ${response.body}';
        return null;
      }

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is! Map || decoded['status'] != 'success') {
        lastError = decoded is Map
            ? decoded['message']?.toString() ?? 'Unknown API error'
            : 'Invalid API response';
        return null;
      }

      return RestaurantSettingsSnapshot.fromJson(
        decoded.cast<String, dynamic>(),
      );
    } catch (error) {
      lastError = 'تعذر الاتصال بخادم الإعدادات: $error';
      return null;
    }
  }

  Future<RestaurantSettingsSnapshot?> updateSettings({
    required String vendorName,
    required String storeName,
    required String vendorEmail,
    required String vendorPhone,
    String? vendorLogo,
    String? vendorLogoBase64,
    String? vendorDescription,
    String? storeBannerUrl,
    String? storeBannerBase64,
    String? storeAddress,
    String? coverageArea,
    double? coverageKm,
    double? storeLatitude,
    double? storeLongitude,
    required double minimumOrder,
    required String languageCode,
    required bool isOpen,
    required bool acceptsPreorders,
    required int preorderDaysLimit,
    required bool notificationsEnabled,
    String? temporaryClosedReason,
    required List<StoreWorkingDay> workingHours,
    Map<String, dynamic>? profileSettings,
  }) async {
    lastError = null;
    lastStatusCode = null;
    try {
      // Use the same authenticated client path as every other vendor API.
      // DashboardApiClient loads the current Bearer token from the shared
      // DashboardSessionService and sends Authorization: Bearer <token>.
      final session = await DashboardSessionService.instance.loadSession();
      if (session == null || !session.isValid || session.token.trim().isEmpty) {
        lastStatusCode = 401;
        lastError = 'انتهت جلسة لوحة الإدارة، سجّل الدخول مرة أخرى.';
        return null;
      }
      final response = await DashboardApiClient.postJsonUrl(
        _updateUrl,
        body: {
          'vendor_name': vendorName,
          'store_name': storeName,
          'vendor_email': vendorEmail,
          'vendor_phone': vendorPhone,
          'vendor_logo': vendorLogo,
          'vendor_logo_base64': vendorLogoBase64,
          'vendor_description': vendorDescription,
          'store_banner_url': storeBannerUrl,
          'store_banner_base64': storeBannerBase64,
          'store_address': storeAddress,
          'coverage_km': coverageKm,
          'coverage_area': coverageArea ?? coverageKm?.toStringAsFixed(2),
          'store_latitude': storeLatitude,
          'store_longitude': storeLongitude,
          'minimum_order': minimumOrder,
          'language_code': languageCode,
          'is_open': isOpen ? 1 : 0,
          'accepts_preorders': acceptsPreorders ? 1 : 0,
          'preorder_days_limit': preorderDaysLimit,
          'notifications_enabled': notificationsEnabled ? 1 : 0,
          'temporary_closed_reason': temporaryClosedReason,
          'working_hours': workingHours.map((day) => day.toJson()).toList(),
          if (profileSettings != null) 'profile_settings': profileSettings,
        },
      );
      lastStatusCode = response.statusCode;

      if (response.statusCode != 200) {
        final decoded = _decodeResponse(response);
        lastError = _serverMessage(
          decoded,
          fallback: 'فشل حفظ الإعدادات (HTTP ${response.statusCode}).',
        );
        return null;
      }

      final decoded = _decodeResponse(response);
      if (decoded is! Map || decoded['status'] != 'success') {
        lastError = _serverMessage(decoded, fallback: 'رفض الخادم حفظ الإعدادات.');
        return null;
      }

      return RestaurantSettingsSnapshot.fromJson(
        decoded.cast<String, dynamic>(),
      );
    } catch (error) {
      lastError = 'تعذر الاتصال بخادم الإعدادات. تحقق من الشبكة وCORS: $error';
      return null;
    }
  }

  dynamic _decodeResponse(dynamic response) {
    try {
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  String _serverMessage(dynamic decoded, {required String fallback}) {
    if (decoded is Map) {
      final message = decoded['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    return fallback;
  }
}
