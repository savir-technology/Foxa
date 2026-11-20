import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class DriverApiService {
  DriverApiService({
    String? authBaseUrl,
    String? driverBaseUrl,
    HttpClient? client,
  }) : authBaseUrl = _normalizeBase(
         authBaseUrl ??
             const String.fromEnvironment(
               'ALEPPO_EATS_AUTH_BASE',
               defaultValue: 'https://savir-technology.online/roaqv2',
             ),
       ),
       driverBaseUrl = _normalizeBase(
         driverBaseUrl ??
             const String.fromEnvironment(
               'ALEPPO_EATS_DRIVER_BASE',
               defaultValue: 'https://savir-technology.online/roaqv2',
             ),
       ),
       _client = client ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 15);
  }

  final String authBaseUrl;
  final String driverBaseUrl;
  final HttpClient _client;

  Future<Map<String, dynamic>> sendWhatsAppOtp({
    required String phone,
    required String locale,
  }) {
    return _postJson(_uri(authBaseUrl, 'auth/whatsapp_send_code.php'), {
      'phone': phone,
      'locale': locale,
    });
  }

  Future<Map<String, dynamic>> requestDriverEmailOtp({
    required String email,
    required String locale,
  }) {
    return _postForm(_uri(driverBaseUrl, 'driver_email_request_code.php'), {
      'email': email,
      'locale': locale,
    });
  }

  Future<Map<String, dynamic>> verifyDriverEmailOtp({
    required String email,
    required String code,
  }) {
    return _postForm(_uri(driverBaseUrl, 'driver_email_verify_code.php'), {
      'email': email,
      'code': code,
    });
  }

  Future<Map<String, dynamic>> verifyWhatsAppOtp({
    required String phone,
    required String code,
    required String locale,
    String? fcmToken,
  }) {
    return _postJson(_uri(authBaseUrl, 'auth/whatsapp_verify_code.php'), {
      'phone': phone,
      'code': code,
      'locale': locale,
      'fcm_token': fcmToken ?? '',
    });
  }

  Future<Map<String, dynamic>> upsertDriverProfile({
    String? phone,
    String? email,
    String? name,
    int? vendorId,
    String? vehicleType,
    String? vehicleNumber,
    bool? notificationsEnabled,
    bool? locationSharingEnabled,
    String? localeCode,
    String? themeMode,
    String? imagePath,
  }) {
    final fields = <String, String>{
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (name != null && name.isNotEmpty) 'name': name,
      if (vendorId != null && vendorId > 0) 'vendor_id': vendorId.toString(),
      if (vehicleType != null && vehicleType.isNotEmpty)
        'vehicle_type': vehicleType,
      if (vehicleNumber != null && vehicleNumber.isNotEmpty)
        'vehicle_number': vehicleNumber,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled ? '1' : '0',
      if (locationSharingEnabled != null)
        'location_sharing_enabled': locationSharingEnabled ? '1' : '0',
      if (localeCode != null && localeCode.isNotEmpty)
        'locale_code': localeCode,
      if (themeMode != null && themeMode.isNotEmpty) 'theme_mode': themeMode,
    };

    if (imagePath != null && imagePath.isNotEmpty) {
      return _sendMultipart(
        _uri(driverBaseUrl, 'driver_profile.php'),
        fields: fields,
        filePath: imagePath,
        fileFieldName: 'profile_image',
      );
    }

    return _postForm(_uri(driverBaseUrl, 'driver_profile.php'), fields);
  }

  Future<Map<String, dynamic>> registerDriverEmailAccount({
    String verificationToken = '',
    required String name,
    required String phone,
    required String email,
    required String password,
    int? vendorId,
    String? vehicleType,
    String? vehicleNumber,
    String? imagePath,
    String? localeCode,
  }) {
    final fields = <String, String>{
      if (verificationToken.isNotEmpty) 'verification_token': verificationToken,
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      if (vendorId != null && vendorId > 0) 'vendor_id': vendorId.toString(),
      if (vehicleType != null && vehicleType.isNotEmpty)
        'vehicle_type': vehicleType,
      if (vehicleNumber != null && vehicleNumber.isNotEmpty)
        'vehicle_number': vehicleNumber,
      if (localeCode != null && localeCode.isNotEmpty)
        'locale_code': localeCode,
    };

    if (imagePath != null && imagePath.isNotEmpty) {
      return _sendMultipart(
        _uri(driverBaseUrl, 'driver_email_register.php'),
        fields: fields,
        filePath: imagePath,
        fileFieldName: 'profile_image',
      );
    }

    return _postForm(_uri(driverBaseUrl, 'driver_email_register.php'), fields);
  }

  Future<Map<String, dynamic>> fetchDriverRestaurants() {
    return _getJson(_uri(driverBaseUrl, 'driver_restaurants.php'));
  }

  Future<Map<String, dynamic>> fetchDriverWorkingHours() {
    return _getJson(_uri(driverBaseUrl, 'driver_working_hours.php'));
  }

  Future<Map<String, dynamic>> fetchDriverNotifications({
    required int driverId,
    int limit = 150,
  }) {
    return _postForm(_driverUri('notifications/get_all.php'), {
      'driver_id': driverId.toString(),
      'limit': limit.toString(),
    });
  }

  Future<Map<String, dynamic>> markDriverNotificationRead({
    required int driverId,
    required int notificationId,
  }) {
    return _postForm(_driverUri('notifications/mark_read.php'), {
      'driver_id': driverId.toString(),
      'notification_id': notificationId.toString(),
    });
  }

  Future<Map<String, dynamic>> markAllDriverNotificationsRead({
    required int driverId,
  }) {
    return _postForm(_driverUri('notifications/mark_all_read.php'), {
      'driver_id': driverId.toString(),
    });
  }

  Future<Map<String, dynamic>> saveDriverPushToken({
    required int driverId,
    required String pushToken,
    String? platform,
    String? deviceName,
  }) {
    return _postForm(_driverUri('driver_save_push_token.php'), {
      'driver_id': driverId.toString(),
      'push_token': pushToken,
      if (platform != null && platform.isNotEmpty) 'platform': platform,
      if (deviceName != null && deviceName.isNotEmpty)
        'device_name': deviceName,
    });
  }

  Future<Map<String, dynamic>> loginDriverEmailAccount({
    required String email,
    required String password,
  }) {
    return _postForm(_uri(driverBaseUrl, 'driver_email_login.php'), {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> fetchDriverDashboard({required int driverId}) {
    return _postForm(_uri(driverBaseUrl, 'driver_dashboard.php'), {
      'driver_id': driverId.toString(),
    });
  }

  Future<Map<String, dynamic>> updateDriverStatus({
    required int driverId,
    required String status,
  }) {
    return _postForm(_uri(driverBaseUrl, 'update_status.php'), {
      'driver_id': driverId.toString(),
      'status': status,
    });
  }

  Future<Map<String, dynamic>> updateDriverLocation({
    required int driverId,
    required double latitude,
    required double longitude,
  }) {
    return _postForm(_uri(driverBaseUrl, 'update_location.php'), {
      'driver_id': driverId.toString(),
      'latitude': latitude.toStringAsFixed(6),
      'longitude': longitude.toStringAsFixed(6),
    });
  }

  Future<Map<String, dynamic>> updateTrackingFeed({
    required int driverId,
    required int orderId,
    required String status,
    required double driverLatitude,
    required double driverLongitude,
    double? restaurantLatitude,
    double? restaurantLongitude,
    double? recipientLatitude,
    double? recipientLongitude,
    int? etaMinutes,
    String? driverName,
    String? driverPhone,
    String? vehicleType,
    String? vehicleNumber,
  }) {
    final payload = <String, dynamic>{
      'driver_id': driverId,
      'order_id': orderId,
      'status': status,
      'driver_latitude': driverLatitude,
      'driver_longitude': driverLongitude,
    };
    if (etaMinutes != null) {
      payload['eta_minutes'] = etaMinutes;
    }
    if (restaurantLatitude != null) {
      payload['restaurant_latitude'] = restaurantLatitude;
    }
    if (restaurantLongitude != null) {
      payload['restaurant_longitude'] = restaurantLongitude;
    }
    if (recipientLatitude != null) {
      payload['recipient_latitude'] = recipientLatitude;
    }
    if (recipientLongitude != null) {
      payload['recipient_longitude'] = recipientLongitude;
    }
    if (driverName != null && driverName.isNotEmpty) {
      payload['driver_name'] = driverName;
    }
    if (driverPhone != null && driverPhone.isNotEmpty) {
      payload['driver_phone'] = driverPhone;
    }
    if (vehicleType != null && vehicleType.isNotEmpty) {
      payload['vehicle_type'] = vehicleType;
    }
    if (vehicleNumber != null && vehicleNumber.isNotEmpty) {
      payload['vehicle_number'] = vehicleNumber;
    }

    return _postJson(_uri(driverBaseUrl, 'update_tracking_feed.php'), payload);
  }

  Future<Map<String, dynamic>> updateOrderAction({
    required int driverId,
    required int orderId,
    required String action,
    int? vendorId,
    String? proofCode,
    String? emergencyReason,
  }) {
    return _postForm(_uri(driverBaseUrl, 'driver_order_action.php'), {
      'driver_id': driverId.toString(),
      'order_id': orderId.toString(),
      'action': action,
      if (vendorId != null && vendorId > 0) 'vendor_id': vendorId.toString(),
      if (proofCode != null && proofCode.isNotEmpty) 'proof_code': proofCode,
      if (emergencyReason != null && emergencyReason.isNotEmpty)
        'emergency_reason': emergencyReason,
    });
  }

  Future<Map<String, dynamic>> reportEmergency({
    required int driverId,
    required int orderId,
    required String reason,
  }) {
    return _postForm(_uri(driverBaseUrl, 'driver_emergency.php'), {
      'driver_id': driverId.toString(),
      'order_id': orderId.toString(),
      'reason': reason,
    });
  }

  Future<Map<String, dynamic>> uploadDeliveryProof({
    required int driverId,
    required int orderId,
    required String proofType,
    String? proofCode,
    String? imageBase64,
    String? imageName,
  }) {
    return _postJson(_uri(driverBaseUrl, 'driver_delivery_proof.php'), {
      'driver_id': driverId,
      'order_id': orderId,
      'proof_type': proofType,
      if (proofCode != null && proofCode.isNotEmpty) 'proof_code': proofCode,
      if (imageBase64 != null && imageBase64.isNotEmpty)
        'image_base64': imageBase64,
      if (imageName != null && imageName.isNotEmpty) 'image_name': imageName,
    });
  }

  Future<Map<String, dynamic>> logOrderVoiceCall({
    required int orderId,
    required String eventType,
    required String status,
    String? callerRole,
    String? callerRefId,
    String? callerName,
    String? calleeRole,
    String? calleeRefId,
    String? calleeName,
    int? eventAtMs,
  }) {
    final payload = <String, String>{
      'order_id': orderId.toString(),
      'event_type': eventType,
      'status': status,
    };
    if (callerRole != null && callerRole.isNotEmpty) {
      payload['caller_role'] = callerRole;
    }
    if (callerRefId != null && callerRefId.isNotEmpty) {
      payload['caller_ref_id'] = callerRefId;
    }
    if (callerName != null && callerName.isNotEmpty) {
      payload['caller_name'] = callerName;
    }
    if (calleeRole != null && calleeRole.isNotEmpty) {
      payload['callee_role'] = calleeRole;
    }
    if (calleeRefId != null && calleeRefId.isNotEmpty) {
      payload['callee_ref_id'] = calleeRefId;
    }
    if (calleeName != null && calleeName.isNotEmpty) {
      payload['callee_name'] = calleeName;
    }
    if (eventAtMs != null) {
      payload['event_at_ms'] = eventAtMs.toString();
    }

    return _postForm(
      _uri(driverBaseUrl, 'calls/order_voice_call_events.php'),
      payload,
    );
  }

  Future<Map<String, dynamic>> fetchOrderChat({
    required int orderId,
    required String scope,
  }) {
    return _postForm(_uri(driverBaseUrl, 'chat/order/get_messages.php'), {
      'order_id': orderId.toString(),
      'chat_scope': scope,
    });
  }

  Future<Map<String, dynamic>> sendOrderChatMessage({
    required int orderId,
    required String scope,
    required int senderId,
    required String senderRole,
    required String message,
    String? audioFilePath,
  }) {
    if (audioFilePath != null && audioFilePath.isNotEmpty) {
      return _sendMultipart(
        _uri(driverBaseUrl, 'chat/order/send_message.php'),
        fields: {
          'order_id': orderId.toString(),
          'chat_scope': scope,
          'sender_ref_id': senderId.toString(),
          'sender_role': senderRole,
          'message': message,
        },
        filePath: audioFilePath,
        fileFieldName: 'audio',
      );
    }

    return _postForm(_uri(driverBaseUrl, 'chat/order/send_message.php'), {
      'order_id': orderId.toString(),
      'chat_scope': scope,
      'sender_ref_id': senderId.toString(),
      'sender_role': senderRole,
      'message': message,
    });
  }

  Future<Map<String, dynamic>> fetchDriverSupportMessages({
    required int driverId,
    bool markRead = true,
  }) {
    return _postForm(_driverUri('support/get_messages.php'), {
      'driver_id': driverId.toString(),
      'mark_read': markRead ? '1' : '0',
    });
  }

  Future<Map<String, dynamic>> sendDriverSupportMessage({
    required int driverId,
    required String message,
    String senderRole = 'driver',
    String? audioFilePath,
  }) {
    if (audioFilePath != null && audioFilePath.isNotEmpty) {
      return _sendMultipart(
        _driverUri('support/send_message.php'),
        fields: {
          'driver_id': driverId.toString(),
          'sender_role': senderRole,
          'message': message,
        },
        filePath: audioFilePath,
        fileFieldName: 'audio',
      );
    }

    return _postForm(_driverUri('support/send_message.php'), {
      'driver_id': driverId.toString(),
      'sender_role': senderRole,
      'message': message,
    });
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> payload,
  ) {
    return _send(
      uri,
      headers: const {
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        HttpHeaders.acceptHeader: 'application/json',
      },
      body: jsonEncode(payload),
    );
  }

  Future<Map<String, dynamic>> _postForm(Uri uri, Map<String, String> payload) {
    return _send(
      uri,
      headers: const {
        HttpHeaders.contentTypeHeader:
            'application/x-www-form-urlencoded; charset=utf-8',
        HttpHeaders.acceptHeader: 'application/json',
      },
      body: Uri(queryParameters: payload).query,
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) {
    return _sendGet(
      uri,
      headers: const {HttpHeaders.acceptHeader: 'application/json'},
    );
  }

  Future<Map<String, dynamic>> _sendGet(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    final request = await _client.getUrl(uri);
    headers.forEach(request.headers.set);

    final response = await request.close();
    final raw = await utf8.decoder.bind(response).join();
    final trimmed = raw.trimLeft();
    final looksLikeHtml =
        trimmed.startsWith('<!DOCTYPE') ||
        trimmed.startsWith('<html') ||
        trimmed.startsWith('<');
    final decoded = raw.isEmpty || looksLikeHtml
        ? <String, dynamic>{}
        : _decodeJson(raw);

    if (looksLikeHtml) {
      return {
        'status': 'error',
        'message': 'Unexpected HTML response',
        'http_status': response.statusCode,
        'raw': raw,
      };
    }

    if (response.statusCode >= 400 && decoded.isEmpty) {
      return {
        'status': 'error',
        'message': 'HTTP ${response.statusCode}',
        'http_status': response.statusCode,
      };
    }

    if (decoded.isEmpty) {
      return {
        'status': response.statusCode < 400 ? 'success' : 'error',
        'http_status': response.statusCode,
        'raw': raw,
      };
    }

    decoded['http_status'] = response.statusCode;
    return decoded;
  }

  Future<Map<String, dynamic>> _send(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
  }) async {
    final request = await _client.postUrl(uri);
    headers.forEach(request.headers.set);
    request.write(body);

    final response = await request.close();
    final raw = await utf8.decoder.bind(response).join();
    final trimmed = raw.trimLeft();
    final looksLikeHtml =
        trimmed.startsWith('<!DOCTYPE') ||
        trimmed.startsWith('<html') ||
        trimmed.startsWith('<');
    final decoded = raw.isEmpty || looksLikeHtml
        ? <String, dynamic>{}
        : _decodeJson(raw);

    if (looksLikeHtml) {
      return {
        'status': 'error',
        'message': 'Unexpected HTML response',
        'http_status': response.statusCode,
        'raw': raw,
      };
    }

    if (response.statusCode >= 400 && decoded.isEmpty) {
      return {
        'status': 'error',
        'message': 'HTTP ${response.statusCode}',
        'http_status': response.statusCode,
      };
    }

    if (decoded.isEmpty) {
      return {
        'status': response.statusCode < 400 ? 'success' : 'error',
        'http_status': response.statusCode,
        'raw': raw,
      };
    }

    decoded['http_status'] = response.statusCode;
    return decoded;
  }

  Future<Map<String, dynamic>> _sendMultipart(
    Uri uri, {
    required Map<String, String> fields,
    required String filePath,
    String fileFieldName = 'file',
  }) async {
    final request = http.MultipartRequest('POST', uri);
    fields.forEach((key, value) {
      request.fields[key] = value;
    });
    request.files.add(
      await http.MultipartFile.fromPath(fileFieldName, filePath),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    final trimmed = body.trimLeft();
    final looksLikeHtml =
        trimmed.startsWith('<!DOCTYPE') ||
        trimmed.startsWith('<html') ||
        trimmed.startsWith('<');
    final decoded = body.isEmpty || looksLikeHtml
        ? <String, dynamic>{}
        : _decodeJson(body);

    if (looksLikeHtml) {
      return {
        'status': 'error',
        'message': 'Unexpected HTML response',
        'http_status': streamed.statusCode,
        'raw': body,
      };
    }

    if (streamed.statusCode >= 400 && decoded.isEmpty) {
      return {
        'status': 'error',
        'message': 'HTTP ${streamed.statusCode}',
        'http_status': streamed.statusCode,
      };
    }

    if (decoded.isEmpty) {
      return {
        'status': streamed.statusCode < 400 ? 'success' : 'error',
        'http_status': streamed.statusCode,
        'raw': body,
      };
    }

    decoded['http_status'] = streamed.statusCode;
    return decoded;
  }

  Map<String, dynamic> _decodeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
      return <String, dynamic>{'data': decoded};
    } on FormatException {
      return <String, dynamic>{};
    }
  }

  Uri _uri(String base, String relativePath) {
    final normalizedBase = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    final normalizedPath = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    return Uri.parse('$normalizedBase/$normalizedPath');
  }

  Uri _driverUri(String relativePath) {
    final baseEndsWithDel = driverBaseUrl.endsWith('/del');
    final normalizedPath = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    return _uri(
      driverBaseUrl,
      baseEndsWithDel ? normalizedPath : 'del/$normalizedPath',
    );
  }

  String resolveUrl(String? url) {
    return _resolveMediaUrl(url, driverBaseUrl);
  }

  static String _normalizeBase(String value) {
    return value.trim().replaceAll(RegExp(r'/+$'), '');
  }

  static String _resolveMediaUrl(String? url, String baseUrl) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) return '';

    final normalized = raw.replaceAll('\\', '/');
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized.replaceAll(' ', '%20');
    }

    final base = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final path = normalized.replaceFirst(RegExp(r'^/+'), '');
    return '$base/$path'.replaceAll(' ', '%20');
  }
}
