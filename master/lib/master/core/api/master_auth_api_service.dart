// ignore_for_file: unused_element

part of '../../../master_auth_app.dart';

class MasterApiException implements Exception {
  MasterApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class MasterRoleProfile {
  const MasterRoleProfile({
    required this.roleId,
    required this.roleName,
    required this.roleScope,
    required this.permissions,
    required this.tintHex,
    required this.sortOrder,
  });

  final int roleId;
  final String roleName;
  final String roleScope;
  final List<String> permissions;
  final String tintHex;
  final int sortOrder;

  Color get tintColor => _hexToColor(tintHex);

  factory MasterRoleProfile.fromJson(Map<String, dynamic> json) {
    return MasterRoleProfile(
      roleId: _toInt(json['role_id']),
      roleName: (json['role_name'] ?? '').toString(),
      roleScope: (json['role_scope'] ?? '').toString(),
      permissions: _asStringList(
        json['permissions'] ?? json['permissions_json'],
      ),
      tintHex: (json['tint_hex'] ?? '#3B82F6').toString(),
      sortOrder: _toInt(json['sort_order']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role_id': roleId,
      'role_name': roleName,
      'role_scope': roleScope,
      'permissions': permissions,
      'tint_hex': tintHex,
      'sort_order': sortOrder,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is MasterRoleProfile && other.roleId == roleId;
  }

  @override
  int get hashCode => roleId.hashCode;
}

class MasterUser {
  const MasterUser({
    required this.adminId,
    required this.adminName,
    required this.adminEmail,
    required this.adminPhone,
    required this.adminApprove,
    required this.adminRoleId,
    required this.role,
    required this.adminLastLoginAt,
    required this.adminCreate,
  });

  final int adminId;
  final String adminName;
  final String adminEmail;
  final String adminPhone;
  final int adminApprove;
  final int adminRoleId;
  final MasterRoleProfile? role;
  final String? adminLastLoginAt;
  final String? adminCreate;

  factory MasterUser.fromJson(Map<String, dynamic> json) {
    final roleJson = _asMap(json['role']);
    MasterRoleProfile? role;
    if (roleJson.isNotEmpty) {
      role = MasterRoleProfile.fromJson(roleJson);
    } else if (json['master_role_id'] != null ||
        json['admin_role_id'] != null) {
      role = MasterRoleProfile(
        roleId: _toInt(json['master_role_id'] ?? json['admin_role_id'], 1),
        roleName: (json['master_role_name'] ?? '').toString(),
        roleScope: (json['master_role_scope'] ?? '').toString(),
        permissions: _asStringList(json['master_role_permissions_json']),
        tintHex: (json['master_role_tint_hex'] ?? '#3B82F6').toString(),
        sortOrder: _toInt(json['master_role_sort_order']),
      );
    }

    return MasterUser(
      adminId: _toInt(json['admin_id'] ?? json['adminId']),
      adminName: (json['admin_name'] ?? '').toString(),
      adminEmail: (json['admin_email'] ?? '').toString(),
      adminPhone: (json['admin_phone'] ?? '').toString(),
      adminApprove: _toInt(json['admin_approve']),
      adminRoleId: _toInt(json['admin_role_id'] ?? json['master_role_id'], 1),
      role: role,
      adminLastLoginAt: json['admin_last_login_at']?.toString(),
      adminCreate: json['admin_create']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'admin_id': adminId,
      'admin_name': adminName,
      'admin_email': adminEmail,
      'admin_phone': adminPhone,
      'admin_approve': adminApprove,
      'admin_role_id': adminRoleId,
      'admin_last_login_at': adminLastLoginAt,
      'admin_create': adminCreate,
      'role': role?.toJson(),
    };
  }
}

class MasterSession {
  const MasterSession({
    required this.token,
    required this.expiresAt,
    required this.master,
    this.portal,
  });

  final String token;
  final DateTime? expiresAt;
  final MasterUser master;
  final String? portal;

  bool get isExpired {
    if (expiresAt == null) {
      return false;
    }
    return DateTime.now().isAfter(
      expiresAt!.subtract(const Duration(minutes: 1)),
    );
  }

  MasterSession copyWith({
    String? token,
    DateTime? expiresAt,
    MasterUser? master,
    String? portal,
  }) {
    return MasterSession(
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      master: master ?? this.master,
      portal: portal ?? this.portal,
    );
  }

  factory MasterSession.fromJson(Map<String, dynamic> json) {
    return MasterSession(
      token: (json['token'] ?? '').toString(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      master: MasterUser.fromJson(_asMap(json['master'] ?? json['data'])),
      portal: (json['portal'] ?? '').toString().trim().isEmpty
          ? null
          : json['portal'].toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expires_at': expiresAt?.toIso8601String(),
      'portal': portal,
      'master': master.toJson(),
    };
  }
}

class MasterSignupResult {
  const MasterSignupResult({
    required this.email,
    required this.role,
    required this.verificationRequired,
    required this.expiresIn,
    required this.message,
  });

  final String email;
  final MasterRoleProfile role;
  final bool verificationRequired;
  final int expiresIn;
  final String message;
}

class MasterRolesResult {
  const MasterRolesResult({
    required this.roles,
    required this.canCreateSuperAdmin,
  });

  final List<MasterRoleProfile> roles;
  final bool canCreateSuperAdmin;
}

class _DashboardZoneData {
  const _DashboardZoneData({
    required this.id,
    required this.label,
    this.city = '',
    this.vendorCount = 0,
    this.driverCount = 0,
  });

  final String id;
  final String label;
  final String city;
  final int vendorCount;
  final int driverCount;

  factory _DashboardZoneData.fromJson(Map<String, dynamic> json) {
    return _DashboardZoneData(
      id: (json['id'] ?? json['zone_id'] ?? '').toString(),
      label: (json['label'] ?? json['zone_name'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      vendorCount: _toInt(json['vendor_count']),
      driverCount: _toInt(json['driver_count']),
    );
  }
}

class _MasterDashboardHomeData {
  const _MasterDashboardHomeData({
    required this.serverNow,
    required this.platformTitle,
    required this.platformSubtitle,
    required this.displayName,
    required this.roleLabel,
    required this.notificationBadge,
    required this.statusLabel,
    required this.alertCount,
    required this.alertMessage,
    required this.sidebarItems,
    required this.stats,
    required this.sections,
    required this.statusItems,
    required this.footerVersion,
    required this.availableZones,
  });

  final DateTime? serverNow;
  final String platformTitle;
  final String platformSubtitle;
  final String displayName;
  final String roleLabel;
  final int notificationBadge;
  final String statusLabel;
  final int alertCount;
  final String alertMessage;
  final List<_DashboardMenuItemData> sidebarItems;
  final List<_DashboardStatData> stats;
  final List<_DashboardSectionData> sections;
  final List<_DashboardStatusItemData> statusItems;
  final String footerVersion;
  final List<_DashboardZoneData> availableZones;

  factory _MasterDashboardHomeData.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data'] ?? json);
    final master = _asMap(json['master'] ?? data['master']);
    final profile = _asMap(data['profile']);
    final alert = _asMap(data['alert']);
    final masterRole = _asMap(master['role']);

    final sidebarItems = <_DashboardMenuItemData>[];
    final sidebarJson = data['sidebar_items'];
    if (sidebarJson is List) {
      for (final item in sidebarJson) {
        sidebarItems.add(_DashboardMenuItemData.fromJson(_asMap(item)));
      }
    }

    final stats = <_DashboardStatData>[];
    final statsJson = data['stats'];
    if (statsJson is List) {
      for (final item in statsJson) {
        stats.add(_DashboardStatData.fromJson(_asMap(item)));
      }
    }

    final sections = <_DashboardSectionData>[];
    final sectionsJson = data['sections'];
    if (sectionsJson is List) {
      for (final item in sectionsJson) {
        sections.add(_DashboardSectionData.fromJson(_asMap(item)));
      }
    }

    final statusItems = <_DashboardStatusItemData>[];
    final statusJson = data['status_items'];
    if (statusJson is List) {
      for (final item in statusJson) {
        statusItems.add(_DashboardStatusItemData.fromJson(_asMap(item)));
      }
    }

    final availableZones = <_DashboardZoneData>[];
    final zonesJson = data['available_zones'];
    if (zonesJson is List) {
      for (final item in zonesJson) {
        final zone = _DashboardZoneData.fromJson(_asMap(item));
        if (zone.id.isNotEmpty && zone.label.trim().isNotEmpty) {
          availableZones.add(zone);
        }
      }
    }

    return _MasterDashboardHomeData(
      serverNow: _parseDateTime(data['server_now']),
      platformTitle: (data['platform_title'] ?? 'لوحة تحكم صاحب المنصة')
          .toString(),
      platformSubtitle: (data['platform_subtitle'] ?? 'Platform Control Center')
          .toString(),
      displayName: (profile['display_name'] ?? master['admin_name'] ?? '')
          .toString(),
      roleLabel: (profile['role_label'] ?? masterRole['role_name'] ?? '')
          .toString(),
      notificationBadge: _toInt(
        profile['notification_badge'] ?? alert['count'],
        0,
      ),
      statusLabel: (data['status_label'] ?? 'جميع الخدمات تعمل').toString(),
      alertCount: _toInt(alert['count']),
      alertMessage: (alert['message'] ?? '').toString(),
      sidebarItems: sidebarItems,
      stats: stats,
      sections: sections,
      statusItems: statusItems,
      footerVersion: (data['footer_version'] ?? 'FOXA Platform v1.0.0')
          .toString(),
      availableZones: availableZones,
    );
  }
}

class MasterAuthStorage {
  static const String _sessionKey = 'master_auth_session';

  Future<MasterSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) {
        return null;
      }
      return MasterSession.fromJson(data);
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> saveSession(MasterSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}

class _MasterReadCacheEntry {
  const _MasterReadCacheEntry({required this.createdAt, required this.value});

  final DateTime createdAt;
  final Map<String, dynamic> value;
}

class MasterAuthApiService {
  MasterAuthApiService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 20);
  static const Duration _uploadTimeout = Duration(minutes: 10);
  static const Duration _readCacheTtl = Duration(seconds: 20);
  final Map<String, _MasterReadCacheEntry> _readCache = {};

  void dispose() {
    _readCache.clear();
    _client.close();
  }

  void clearReadCache() => _readCache.clear();

  Future<Map<String, dynamic>> fetchMasterDeploymentHealth(String token) async {
    final decoded = await _sendGet(
      'dash/master/deployment_health.php',
      token: token,
    );
    return _asMap(decoded['data'] ?? decoded);
  }

  Uri _uri(String path) => Uri.parse('$_kApiBaseUrl$path');

  Future<http.Response> _performRequest(http.BaseRequest request) async {
    try {
      final streamed = await _client.send(request).timeout(_requestTimeout);
      return await http.Response.fromStream(streamed).timeout(_requestTimeout);
    } on TimeoutException {
      throw MasterApiException(
        'تعذر الاتصال بخادم المنصة في الوقت المحدد. تحقق من اتصال الخادم أو حاول مرة أخرى.',
      );
    } on http.ClientException {
      throw MasterApiException(
        'تعذر الوصول إلى خادم المنصة. تأكد من أن خدمة الـ API متاحة ثم حاول مرة أخرى.',
      );
    } catch (error) {
      throw MasterApiException(
        'حدث خطأ أثناء الاتصال بخادم المنصة. حاول مرة أخرى بعد قليل.',
      );
    }
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final request = http.Request(method.toUpperCase(), _uri(path));
    request.headers['Accept'] = 'application/json';
    request.headers['Content-Type'] = 'application/json; charset=utf-8';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final response = await _performRequest(request);
    final decoded = _decodeJsonBytes(response.bodyBytes, response.body);

    final status = response.statusCode;
    final isSuccess = status >= 200 && status < 300;
    final apiStatus = decoded['status']?.toString().toLowerCase();

    if (!isSuccess || apiStatus == 'error' || apiStatus == 'fail') {
      throw MasterApiException(
        _responseMessage(decoded, fallback: _requestFailureFallback(status)),
        statusCode: status,
      );
    }

    // A successful write can change any read model. Drop cached GET results
    // so the next visit reflects the mutation immediately.
    if (method.toUpperCase() != 'GET') {
      _readCache.clear();
    }
    return decoded;
  }

  Future<Map<String, dynamic>> _sendGet(
    String path, {
    String? token,
    Map<String, String>? queryParameters,
  }) async {
    final baseUri = _uri(path);
    final requestUri = queryParameters == null || queryParameters.isEmpty
        ? baseUri
        : baseUri.replace(queryParameters: queryParameters);
    final cacheKey = '${token ?? ''}|$requestUri';
    final cached = _readCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.createdAt) < _readCacheTtl) {
      return cached.value;
    }

    final request = http.Request('GET', requestUri);
    request.headers['Accept'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final response = await _performRequest(request);
    final decoded = _decodeJsonBytes(response.bodyBytes, response.body);

    final status = response.statusCode;
    final isSuccess = status >= 200 && status < 300;
    final apiStatus = decoded['status']?.toString().toLowerCase();

    if (!isSuccess || apiStatus == 'error' || apiStatus == 'fail') {
      throw MasterApiException(
        _responseMessage(decoded, fallback: _requestFailureFallback(status)),
        statusCode: status,
      );
    }

    _readCache[cacheKey] = _MasterReadCacheEntry(
      createdAt: DateTime.now(),
      value: decoded,
    );
    return decoded;
  }

  Map<String, dynamic> _decodeJson(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(trimmed);
      return _asMap(_normalizeDecodedValue(decoded));
    } catch (_) {
      return <String, dynamic>{'raw': _normalizeUtf8Text(body)};
    }
  }

  Map<String, dynamic> _decodeJsonBytes(
    List<int> bodyBytes,
    String fallbackBody,
  ) {
    final decodedBody = bodyBytes.isEmpty
        ? fallbackBody
        : utf8.decode(bodyBytes, allowMalformed: true);
    return _decodeJson(decodedBody);
  }

  dynamic _decodeJsonValueBytes(List<int> bodyBytes, String fallbackBody) {
    final decodedBody = bodyBytes.isEmpty
        ? fallbackBody
        : utf8.decode(bodyBytes, allowMalformed: true);
    final trimmed = decodedBody.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      return _normalizeDecodedValue(jsonDecode(trimmed));
    } catch (_) {
      return _normalizeUtf8Text(decodedBody);
    }
  }

  Future<List<Map<String, dynamic>>> _sendGetList(
    String path, {
    String? token,
  }) async {
    final request = http.Request('GET', _uri(path));
    request.headers['Accept'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await _performRequest(request);
    final decoded = _decodeJsonValueBytes(response.bodyBytes, response.body);

    final apiStatus = decoded is Map<String, dynamic>
        ? decoded['status']?.toString().toLowerCase()
        : null;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        apiStatus == 'error' ||
        apiStatus == 'fail') {
      final fallback = decoded is Map<String, dynamic>
          ? _responseMessage(
              decoded,
              fallback: _requestFailureFallback(response.statusCode),
            )
          : _requestFailureFallback(response.statusCode);
      throw MasterApiException(fallback, statusCode: response.statusCode);
    }

    if (decoded is List) {
      return decoded.map((item) => _asMap(item)).toList();
    }
    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      return _asMapList(decoded['data']);
    }
    return const <Map<String, dynamic>>[];
  }

  String _responseMessage(
    Map<String, dynamic> decoded, {
    required String fallback,
  }) {
    final message = decoded['message'] ?? decoded['error'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
    return fallback;
  }

  String _requestFailureFallback(int statusCode) {
    if (statusCode >= 500) {
      return 'خادم المنصة أرجع خطأ داخليًا (HTTP $statusCode). راجع إعدادات PHP وقاعدة البيانات.';
    }
    if (statusCode >= 400) {
      return 'تعذر تنفيذ الطلب (HTTP $statusCode). راجع بيانات الدخول أو صلاحيات الحساب.';
    }
    return 'تعذر تنفيذ الطلب من خادم المنصة.';
  }

  Future<MasterRolesResult> fetchRoles() async {
    final decoded = await _sendGet('dash/master_auth/roles.php');
    final rolesJson = decoded['roles'];
    final roles = <MasterRoleProfile>[];
    if (rolesJson is List) {
      for (final item in rolesJson) {
        roles.add(MasterRoleProfile.fromJson(_asMap(item)));
      }
    }
    return MasterRolesResult(
      roles: roles,
      canCreateSuperAdmin:
          decoded['can_create_super_admin'] == true ||
          decoded['can_create_super_admin'] == 1,
    );
  }

  Future<MasterSignupResult> signup({
    required String adminName,
    required String email,
    required String phone,
    required String password,
    required int roleId,
    String? ownerEmail,
    String? ownerCode,
  }) async {
    final decoded = await _send(
      'POST',
      'dash/master_auth/signup.php',
      body: {
        'admin_name': adminName,
        'email': email,
        'phone': phone,
        'password': password,
        'role_id': roleId,
        'owner_email': ?ownerEmail,
        'owner_code': ?ownerCode,
      },
    );
    final data = _asMap(decoded['data']);
    final role = MasterRoleProfile.fromJson(_asMap(data['role']));
    return MasterSignupResult(
      email: (data['email'] ?? email).toString(),
      role: role,
      verificationRequired:
          data['verification_required'] == true ||
          data['verification_required'] == 1,
      expiresIn: _toInt(data['expires_in'], 900),
      message: _responseMessage(decoded, fallback: 'Signup completed'),
    );
  }

  Future<String> requestEmployeeSignupCode() async {
    try {
      final decoded = await _send(
        'POST',
        'dash/master_auth/request_employee_signup_code.php',
      );
      return (decoded['email'] ?? '').toString();
    } on MasterApiException {
      // Backward compatibility with servers that have not received the new
      // endpoint yet. This is the primary-master email in the current DB.
      const legacyOwnerEmail = 'supplysmp@gmail.com';
      final decoded = await _send(
        'POST',
        'dash/master_auth/check_email.php',
        body: {'email': legacyOwnerEmail},
      );
      return (decoded['email'] ?? legacyOwnerEmail).toString();
    }
  }

  Future<MasterSession> login({
    required String email,
    required String password,
    String? portal,
  }) async {
    final decoded = await _send(
      'POST',
      'dash/master_auth/login.php',
      body: {
        'email': email,
        'password': password,
        if (portal != null && portal.trim().isNotEmpty) 'portal': portal.trim(),
      },
    );
    final master = MasterUser.fromJson(
      _asMap(decoded['master'] ?? decoded['data']),
    );
    final token = (decoded['token'] ?? '').toString();
    return MasterSession(
      token: token,
      expiresAt: decoded['expires_at'] != null
          ? DateTime.tryParse(decoded['expires_at'].toString())
          : null,
      master: master,
      portal: (decoded['portal'] ?? '').toString().trim().isEmpty
          ? null
          : decoded['portal'].toString().trim(),
    );
  }

  Future<MasterUser> me(String token) async {
    final decoded = await _sendGet('dash/master_auth/me.php', token: token);
    return MasterUser.fromJson(_asMap(decoded['master'] ?? decoded['data']));
  }

  Future<_MasterUsersData> _fetchMasterUsersOverview(String token) async {
    final decoded = await _sendGet(
      'dash/master/users/overview.php',
      token: token,
    );
    return _MasterUsersData.fromJson(_asMap(decoded['data'] ?? decoded));
  }

  Future<void> _ensureMasterUserWallet(
    String token, {
    required int userId,
  }) async {
    await _send(
      'POST',
      'dash/master/users/ensure_wallet.php',
      token: token,
      body: {'user_id': userId},
    );
  }

  Future<void> _runMasterUserAction(
    String token, {
    int userId = 0,
    required String action,
    Map<String, dynamic>? data,
  }) async {
    final body = <String, dynamic>{
      if (userId > 0) 'user_id': userId,
      'action': action,
    };
    if (data != null) {
      body['data'] = data;
    }
    await _send(
      'POST',
      'dash/master/users/action.php',
      token: token,
      body: body,
    );
  }

  Future<void> _runMasterUserAddressAction(
    String token, {
    required int addressId,
    int? userId,
    required String action,
    Map<String, dynamic>? data,
  }) async {
    final body = <String, dynamic>{
      'address_id': addressId,
      'user_id': ?userId,
      'action': action,
    };
    if (data != null) {
      body['data'] = data;
    }
    await _send(
      'POST',
      'dash/master/users/action.php',
      token: token,
      body: body,
    );
  }

  Future<List<_RestaurantProfile>> _fetchMasterRestaurants(String token) async {
    final decoded = await _sendGet(
      'dash/master/vendors/get_vendors.php',
      token: token,
    );
    return _asMapList(
      decoded['data'],
    ).map(_RestaurantProfile.fromJson).toList();
  }

  Future<Map<String, dynamic>> _fetchMasterRestaurantsOverviewRaw(
    String token, {
    String? vendorType,
  }) async {
    final normalizedType = vendorType?.trim().toLowerCase();
    final query = normalizedType == 'restaurant' || normalizedType == 'store'
        ? '?vendor_type=$normalizedType'
        : '';
    final decoded = await _sendGet(
      'dash/master/vendors/overview.php$query',
      token: token,
    );
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<Map<String, dynamic>> _fetchOperationsVendorDetails(
    String token,
    int vendorId,
  ) async {
    return _fetchOperationsEntityDetails(token, type: 'vendor', id: vendorId);
  }

  Future<Map<String, dynamic>> _fetchOperationsEntityDetails(
    String token, {
    required String type,
    required int id,
  }) async {
    final decoded = await _sendGet(
      'dash/master/operations/entity.php?type=$type&id=$id',
      token: token,
    );
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<void> _updateMasterRestaurantStatus(
    String token, {
    required int vendorId,
    required String status,
  }) async {
    await _send(
      'POST',
      'dash/master/vendors/update_status.php',
      token: token,
      body: {'vendor_id': vendorId, 'vendor_status': status},
    );
  }

  Future<void> _runMasterRestaurantEntityAction(
    String token, {
    required String entity,
    required int id,
    required String action,
  }) async {
    await _send(
      'POST',
      'dash/master/vendors/entity_action.php',
      token: token,
      body: {'entity': entity, 'id': id, 'action': action},
    );
  }

  Future<int> _saveMasterRestaurantEntity(
    String token, {
    required String entity,
    required String mode,
    int? id,
    required Map<String, dynamic> data,
  }) async {
    final decoded = await _send(
      'POST',
      'dash/master/vendors/save_entity.php',
      token: token,
      body: {
        'entity': entity,
        'mode': mode,
        if (id != null && id > 0) 'id': id,
        'data': data,
      },
    );
    return _toInt(_asMap(decoded['data'])['id']);
  }

  Future<List<Map<String, dynamic>>> _fetchMasterStoreSpecialties(
    String token,
  ) async {
    final decoded = await _sendGet(
      'dash/master/vendors/store_specialties.php',
      token: token,
    );
    return _asMapList(decoded['data']);
  }

  Future<Map<String, dynamic>> _fetchMasterBranchesAndHours(
    String token, {
    String? vendorType,
  }) async {
    final type = vendorType?.trim().toLowerCase();
    final query = type == 'restaurant' || type == 'store'
        ? '?vendor_type=$type'
        : '';
    final decoded = await _sendGet(
      'dash/master/vendors/branches_hours.php$query',
      token: token,
    );
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<void> _saveMasterBranchOrHours(
    String token,
    Map<String, dynamic> data,
  ) async {
    await _send(
      'POST',
      'dash/master/vendors/branches_hours.php',
      token: token,
      body: data,
    );
  }

  Future<void> _saveMasterStoreSpecialty(
    String token, {
    int? id,
    required String categoryKey,
    required String nameAr,
    required String nameEn,
    bool isActive = true,
  }) async {
    await _send(
      'POST',
      'dash/master/vendors/store_specialties.php',
      token: token,
      body: {
        'action': 'save',
        if (id != null && id > 0) 'id': id,
        'category_key': categoryKey,
        'name_ar': nameAr,
        'name_en': nameEn,
        'is_active': isActive ? 1 : 0,
      },
    );
  }

  Future<void> _deleteMasterStoreSpecialty(String token, int id) async {
    await _send(
      'POST',
      'dash/master/vendors/store_specialties.php',
      token: token,
      body: {'action': 'delete', 'id': id},
    );
  }

  Future<String> _uploadMasterEntityImage(
    String token, {
    required String entity,
    required String dataUrl,
  }) async {
    final data = UriData.parse(dataUrl);
    final bytes = data.contentAsBytes();
    final extension = (data.mimeType.split('/').last == 'jpeg')
        ? 'jpg'
        : data.mimeType.split('/').last;
    final request = http.MultipartRequest(
      'POST',
      _uri('dash/master/vendors/upload_image.php'),
    );
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['entity'] = entity;
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'upload.$extension',
      ),
    );
    final response = await http.Response.fromStream(
      await _client.send(request).timeout(_requestTimeout),
    ).timeout(_requestTimeout);
    final decoded = _decodeJsonBytes(response.bodyBytes, response.body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['status']?.toString() != 'success') {
      throw MasterApiException(
        _responseMessage(decoded, fallback: 'Image upload failed'),
        statusCode: response.statusCode,
      );
    }
    return (_asMap(decoded['data'])['filename'] ?? '').toString();
  }

  Future<String> _uploadMasterMarketingImage(
    String token, {
    required html.File file,
  }) async {
    final reader = html.FileReader();
    final completer = Completer<List<int>>();
    reader.onLoadEnd.listen((event) {
      if (completer.isCompleted) return;
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(result.asUint8List());
      } else if (result is Uint8List) {
        completer.complete(result);
      } else if (result is List<int>) {
        completer.complete(Uint8List.fromList(result));
      } else {
        completer.completeError('تعذر قراءة الصورة');
      }
    });
    reader.onError.listen((event) {
      if (!completer.isCompleted) completer.completeError('تعذر قراءة الصورة');
    });
    reader.readAsArrayBuffer(file);
    final bytes = await completer.future.timeout(
      _uploadTimeout,
      onTimeout: () => throw MasterApiException('File reading timed out'),
    );
    if (bytes.isEmpty || bytes.length > 8 * 1024 * 1024) {
      throw MasterApiException('حجم صورة الغلاف يجب ألا يتجاوز 8 ميجابايت');
    }
    final request = http.MultipartRequest(
      'POST',
      _uri('dash/master/vendors/upload_image.php'),
    );
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['entity'] = 'marketing';
    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: file.name),
    );
    final response = await http.Response.fromStream(
      await _client.send(request).timeout(_uploadTimeout),
    ).timeout(_uploadTimeout);
    final decoded = _decodeJsonBytes(response.bodyBytes, response.body);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['status']?.toString() != 'success') {
      throw MasterApiException(
        _responseMessage(decoded, fallback: 'تعذر رفع الصورة'),
        statusCode: response.statusCode,
      );
    }
    final data = _asMap(decoded['data']);
    return (data['path'] ?? '').toString();
  }

  Future<Map<String, dynamic>> _fetchMasterProductEditRaw(
    String token,
    int itemId,
  ) async {
    return _sendGet(
      'dash/items/get/get_item_edit_data.php?item_id=$itemId',
      token: token,
    );
  }

  Future<void> _saveMasterProductAttributes(
    String token, {
    required int itemId,
    required List<Map<String, dynamic>> attributes,
  }) async {
    await _send(
      'POST',
      'dash/items/attributes/save.php',
      token: token,
      body: {'item_id': itemId, 'attributes': attributes},
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMasterProductVariants(
    String token,
    int itemId,
  ) async {
    final decoded = await _sendGet(
      'dash/variant/get/get_variants.php?item_id=$itemId',
      token: token,
    );
    return _asMapList(decoded['data']);
  }

  Future<void> _saveMasterProductVariant(
    String token, {
    int? variantId,
    required Map<String, dynamic> data,
  }) async {
    final payload = <String, dynamic>{...data};
    if (variantId != null && variantId > 0) {
      payload['variant_id'] = variantId;
    }
    await _send(
      'POST',
      variantId != null && variantId > 0
          ? 'dash/variant/update/update_variant.php'
          : 'dash/variant/add/add_variant.php',
      token: token,
      body: payload,
    );
  }

  Future<void> _deleteMasterProductVariant(String token, int variantId) async {
    await _send(
      'POST',
      'dash/variant/delete/delete_variant.php',
      token: token,
      body: {'variant_id': variantId},
    );
  }

  Future<void> _updateDeliveryZoneStatus(
    String token, {
    required int zoneId,
    required bool enabled,
  }) async {
    await _send(
      'POST',
      'dash/master/delivery/update_zone_status.php',
      token: token,
      body: {'zone_id': zoneId, 'enabled': enabled ? 1 : 0},
    );
  }

  Future<int> _saveDeliveryZone(
    String token, {
    int? zoneId,
    required Map<String, dynamic> data,
  }) async {
    final decoded = await _send(
      'POST',
      'dash/master/delivery/save_zone.php',
      token: token,
      body: {if (zoneId != null && zoneId > 0) 'zone_id': zoneId, 'data': data},
    );
    return _toInt(_asMap(decoded['data'])['zone_id']);
  }

  Future<void> _saveAccountingAccount(
    String token, {
    int? accountId,
    required String name,
    required String type,
  }) async {
    await _send(
      'POST',
      'dash/master/finance/action.php',
      token: token,
      body: {
        'entity': 'accounting_account',
        'action': accountId != null && accountId > 0 ? 'update' : 'create',
        if (accountId != null && accountId > 0) 'id': accountId,
        'data': {'account_name': name, 'account_type': type},
      },
    );
  }

  Future<void> _deleteAccountingAccount(String token, int accountId) async {
    await _send(
      'POST',
      'dash/master/finance/action.php',
      token: token,
      body: {
        'entity': 'accounting_account',
        'action': 'delete',
        'id': accountId,
      },
    );
  }

  Future<Map<String, dynamic>> _fetchMasterLegalContentRaw(String token) {
    return _sendGet('dash/master/legal/content.php', token: token);
  }

  Future<void> _saveMasterLegalContent(
    String token, {
    required String entity,
    int? id,
    required Map<String, dynamic> data,
  }) async {
    await _send(
      'POST',
      'dash/master/legal/content.php',
      token: token,
      body: {
        'entity': entity,
        'action': id != null && id > 0 ? 'update' : 'create',
        if (id != null && id > 0) 'id': id,
        'data': data,
      },
    );
  }

  Future<void> _deleteMasterLegalContent(
    String token, {
    required String entity,
    required int id,
  }) async {
    await _send(
      'POST',
      'dash/master/legal/content.php',
      token: token,
      body: {'entity': entity, 'action': 'delete', 'id': id},
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMasterRestaurantCategoriesRaw(
    String token,
  ) async {
    final decoded = await _sendGet(
      'dash/sections/get/get_categories.php',
      token: token,
    );
    return _asMapList(decoded['data']);
  }

  Future<List<Map<String, dynamic>>> _fetchMasterRestaurantProductsRaw(
    String token,
  ) async {
    final decoded = await _sendGet(
      'dash/items/get/get_items.php',
      token: token,
    );
    return _asMapList(decoded['data']);
  }

  Future<Map<String, dynamic>> _fetchMasterFinanceOverviewRaw(
    String token,
  ) async {
    final decoded = await _sendGet(
      'dash/master/finance/overview.php',
      token: token,
    );
    return _asMap(decoded['data']);
  }

  // Reports API
  Future<Map<String, dynamic>> _fetchReportsOverviewRaw(String token) async {
    final decoded = await _sendGet(
      'dash/master/reports/overview.php',
      token: token,
    );
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<List<Map<String, dynamic>>> _fetchReportsTopRestaurantsRaw(
    String token,
  ) async {
    return await _sendGetList(
      'dash/master/reports/top_restaurants.php',
      token: token,
    );
  }

  Future<Map<String, dynamic>> _fetchReportsUsersMetricsRaw(
    String token,
  ) async {
    final decoded = await _sendGet(
      'dash/master/reports/users_metrics.php',
      token: token,
    );
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<Map<String, dynamic>> _fetchReportsDriversMetricsRaw(
    String token,
  ) async {
    final decoded = await _sendGet(
      'dash/master/reports/drivers_metrics.php',
      token: token,
    );
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<void> _runMasterFinanceAction(
    String token, {
    required String entity,
    required String action,
    int? id,
    Map<String, dynamic>? data,
  }) async {
    final body = <String, dynamic>{'entity': entity, 'action': action};
    if (id != null && id > 0) {
      body['id'] = id;
    }
    if (data != null) {
      body['data'] = data;
    }
    await _send(
      'POST',
      'dash/master/finance/action.php',
      token: token,
      body: body,
    );
  }

  Future<Map<String, dynamic>> _refundCancelledOrderToWallet(
    String token, {
    required int orderId,
    String note = '',
  }) async {
    final decoded = await _send(
      'POST',
      'dash/master/finance/refund_to_wallet.php',
      token: token,
      body: {
        'order_id': orderId,
        if (note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<Map<String, dynamic>> _fetchMasterMarketingOffersRaw(
    String token,
  ) async {
    final decoded = await _sendGet(
      'dash/master/marketing/offers.php',
      token: token,
    );
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<void> _runMasterMarketingAction(
    String token, {
    required String entity,
    required String action,
    int? id,
    Map<String, dynamic>? data,
  }) async {
    final body = <String, dynamic>{'entity': entity, 'action': action};
    if (id != null && id > 0) {
      body['id'] = id;
    }
    if (data != null) {
      body['data'] = data;
    }
    await _send(
      'POST',
      'dash/master/marketing/action.php',
      token: token,
      body: body,
    );
  }

  Future<String> _uploadMasterMarketingVideo(
    String token, {
    required html.File file,
  }) async {
    final reader = html.FileReader();
    final completer = Completer<List<int>>();
    reader.onLoadEnd.listen((event) {
      if (completer.isCompleted) {
        return;
      }
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(result.asUint8List());
      } else if (result is Uint8List) {
        completer.complete(result);
      } else if (result is List<int>) {
        completer.complete(Uint8List.fromList(result));
      } else {
        completer.completeError('تعذر قراءة ملف الفيديو');
      }
    });
    reader.onError.listen((event) {
      if (!completer.isCompleted) {
        completer.completeError('تعذر قراءة ملف الفيديو');
      }
    });
    reader.readAsArrayBuffer(file);
    final bytes = await completer.future.timeout(
      _uploadTimeout,
      onTimeout: () => throw MasterApiException('Video reading timed out'),
    );
    if (bytes.isEmpty || bytes.length > 120 * 1024 * 1024) {
      throw MasterApiException('حجم الفيديو يجب ألا يتجاوز 120 ميجابايت');
    }

    final request = http.MultipartRequest(
      'POST',
      _uri('dash/master/marketing/upload_video.php'),
    );
    request.headers['Accept'] = 'application/json';
    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes('video_file', bytes, filename: file.name),
    );

    final streamed = await _client.send(request).timeout(_uploadTimeout);
    final response = await http.Response.fromStream(
      streamed,
    ).timeout(_uploadTimeout);
    final decoded = _decodeJsonBytes(response.bodyBytes, response.body);
    final status = response.statusCode;
    final isSuccess = status >= 200 && status < 300;
    final apiStatus = decoded['status']?.toString().toLowerCase();
    if (!isSuccess || apiStatus == 'error' || apiStatus == 'fail') {
      throw MasterApiException(
        _responseMessage(decoded, fallback: 'Video upload failed'),
        statusCode: status,
      );
    }
    final data = _asMap(decoded['data']);
    final returnedUrl =
        (data['video_url'] ??
                data['file_url'] ??
                data['path'] ??
                decoded['video_url'] ??
                decoded['url'] ??
                '')
            .toString()
            .trim();
    if (returnedUrl.isNotEmpty) return returnedUrl;
    final rawUrl = RegExp(
      r'"(?:video_url|file_url|path|url)"\s*:\s*"([^"]+)"',
    ).firstMatch(response.body);
    if (rawUrl != null) {
      final url = rawUrl.group(1)!.replaceAll(r'\/', '/').trim();
      if (url.isNotEmpty) return url;
    }
    final fileName = (data['file_name'] ?? '').toString().trim();
    if (fileName.isNotEmpty) {
      return _uri('uploud/video/${Uri.encodeComponent(fileName)}').toString();
    }
    throw MasterApiException('لم يرجع الخادم رابط الفيديو بعد الرفع');
  }

  Future<Map<String, dynamic>> _fetchMasterGovernanceOverviewRaw(
    String token,
  ) async {
    final decoded = await _sendGet(
      'dash/master/governance/get_overview.php',
      token: token,
    );
    return _asMap(decoded['data']);
  }

  Future<void> updateMasterReturnStatus(
    String token, {
    required int returnId,
    required String statusLabel,
  }) async {
    await _send(
      'POST',
      'dash/master/governance/return_action.php',
      token: token,
      body: {'return_id': returnId, 'status_label': statusLabel},
    );
  }

  Future<void> updateMasterStockRuleStatus(
    String token, {
    required int ruleId,
    required bool isActive,
  }) async {
    await _send(
      'POST',
      'dash/master/governance/stock_action.php',
      token: token,
      body: {'rule_id': ruleId, 'is_active': isActive ? 1 : 0},
    );
  }

  Future<void> updateMasterPrintSettings(
    String token, {
    required int invoiceCopies,
    required bool printLogo,
    int vendorId = 0,
  }) async {
    await _send(
      'POST',
      'dash/master/orders/print_settings_action.php',
      token: token,
      body: {
        'invoice_copies': invoiceCopies,
        'print_logo': printLogo ? 1 : 0,
        'vendor_id': vendorId,
      },
    );
  }

  Future<void> updateMasterScheduledReportStatus(
    String token, {
    required int reportId,
    required bool isActive,
  }) async {
    await _send(
      'POST',
      'dash/master/governance/scheduled_report_action.php',
      token: token,
      body: {'report_id': reportId, 'is_active': isActive ? 1 : 0},
    );
  }

  Future<Map<String, dynamic>> _fetchMasterAdministrationOverviewRaw(
    String token,
  ) async {
    final decoded = await _sendGet(
      'dash/master/administration/overview.php',
      token: token,
    );
    return _asMap(decoded['data'] ?? decoded);
  }

  Future<void> _runMasterAdministratorAction(
    String token, {
    required String action,
    int? adminId,
    Map<String, dynamic>? data,
  }) async {
    await _send(
      'POST',
      'dash/master/administration/administrators.php',
      token: token,
      body: {
        'action': action,
        if (adminId != null && adminId > 0) 'admin_id': adminId,
        'data': ?data,
      },
    );
  }

  Future<void> _runMasterRoleAction(
    String token, {
    required String action,
    int? roleId,
    Map<String, dynamic>? data,
  }) async {
    await _send(
      'POST',
      'dash/master/administration/roles.php',
      token: token,
      body: {
        'action': action,
        if (roleId != null && roleId > 0) 'role_id': roleId,
        'data': ?data,
      },
    );
  }

  Future<void> _runMasterApprovalAction(
    String token, {
    required String type,
    required String action,
    required int id,
    String note = '',
  }) async {
    await _send(
      'POST',
      'dash/master/administration/approvals.php',
      token: token,
      body: {
        'type': type,
        'action': action,
        'id': id,
        if (note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
  }

  Future<void> createAdministrator(
    String token, {
    required String adminName,
    required String email,
    required String phone,
    required String password,
    required int roleId,
  }) async {
    await _runMasterAdministratorAction(
      token,
      action: 'create',
      data: {
        'admin_name': adminName,
        'admin_email': email,
        'admin_phone': phone,
        'password': password,
        'admin_role_id': roleId,
      },
    );
  }

  Future<void> updateAdministrator(
    String token, {
    required int adminId,
    required String adminName,
    required String email,
    required String phone,
    required int roleId,
  }) async {
    await _runMasterAdministratorAction(
      token,
      action: 'update',
      adminId: adminId,
      data: {
        'admin_name': adminName,
        'admin_email': email,
        'admin_phone': phone,
        'admin_role_id': roleId,
      },
    );
  }

  Future<void> toggleAdministrator(
    String token, {
    required int adminId,
    required bool enabled,
  }) async {
    await _runMasterAdministratorAction(
      token,
      action: enabled ? 'enable' : 'disable',
      adminId: adminId,
    );
  }

  Future<void> resetAdministratorPassword(
    String token, {
    required int adminId,
    required String password,
  }) async {
    await _runMasterAdministratorAction(
      token,
      action: 'reset_password',
      adminId: adminId,
      data: {'password': password},
    );
  }

  Future<void> deleteAdministrator(String token, {required int adminId}) async {
    await _runMasterAdministratorAction(
      token,
      action: 'delete',
      adminId: adminId,
    );
  }

  Future<void> createRole(
    String token, {
    required String roleName,
    required String roleScope,
    required List<String> permissions,
    required String tintHex,
    required int sortOrder,
  }) async {
    await _runMasterRoleAction(
      token,
      action: 'create',
      data: {
        'role_name': roleName,
        'role_scope': roleScope,
        'permissions': permissions,
        'tint_hex': tintHex,
        'sort_order': sortOrder,
      },
    );
  }

  Future<void> updateRole(
    String token, {
    required int roleId,
    required String roleName,
    required String roleScope,
    required List<String> permissions,
    required String tintHex,
    required int sortOrder,
  }) async {
    await _runMasterRoleAction(
      token,
      action: 'update',
      roleId: roleId,
      data: {
        'role_name': roleName,
        'role_scope': roleScope,
        'permissions': permissions,
        'tint_hex': tintHex,
        'sort_order': sortOrder,
      },
    );
  }

  Future<void> deleteRole(String token, {required int roleId}) async {
    await _runMasterRoleAction(token, action: 'delete', roleId: roleId);
  }

  Future<void> approveAdministrationItem(
    String token, {
    required String type,
    required String action,
    required int id,
    String note = '',
  }) async {
    await _runMasterApprovalAction(
      token,
      type: type,
      action: action,
      id: id,
      note: note,
    );
  }

  Future<void> logout(String token) async {
    await _send('POST', 'dash/master_auth/logout.php', token: token);
  }

  Future<_MasterDashboardHomeData> _fetchDashboardHome(
    String token, {
    String? zone,
    String? period,
    DateTime? date,
  }) async {
    final query = <String, String>{
      if (zone != null && zone.isNotEmpty && zone != 'all') 'zone': zone,
      if (period != null && period.isNotEmpty) 'period': period,
      if (date != null)
        'date':
            '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    };
    final decoded = await _sendGet(
      'dash/master/home.php',
      token: token,
      queryParameters: query,
    );
    return _MasterDashboardHomeData.fromJson(decoded);
  }

  Future<Map<String, dynamic>> _fetchMasterPlatformSettings(
    String token,
  ) async {
    final decoded = await _sendGet(
      'dash/master/settings/get_platform_settings.php',
      token: token,
      // Settings can be changed directly from phpMyAdmin or another Master
      // session, so force a fresh server response every time this screen is opened.
      queryParameters: {
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    // The current endpoint wraps the row in `data`, while older deployed
    // endpoints may return the row at the top level. Support both shapes so
    // the form never falls back to Saudi defaults when the row is available.
    final nested = _asMap(decoded['data']);
    if (nested.containsKey('default_currency_code')) {
      return nested;
    }
    final topLevel = _asMap(decoded);
    if (topLevel.containsKey('default_currency_code')) {
      return topLevel;
    }
    throw MasterApiException(
      'لم تصل إعدادات المنصة من قاعدة البيانات. تحقق من نسخة API المنشورة.',
    );
  }

  Future<void> refreshMasterCurrency(String token) async {
    final settings = await _fetchMasterPlatformSettings(token);
    MasterCurrency.apply(settings);
  }

  Future<void> _saveMasterPlatformSettings(
    String token,
    Map<String, dynamic> settings,
  ) async {
    await _send(
      'POST',
      'dash/master/settings/get_platform_settings.php',
      token: token,
      body: settings,
    );
  }

  Future<_MasterOperationsData> _fetchOperationsSummary(String token) async {
    final decoded = await _sendGet(
      'dash/master/operations/summary.php',
      token: token,
    );
    final data = _MasterOperationsData.fromJson(decoded);
    if (data.overviewMapMarkers.isNotEmpty ||
        data.trackingMapMarkers.isNotEmpty) {
      return data;
    }

    final liveMarkers = await _fetchOperationsMapMarkersFromLiveEndpoints(
      token,
    );
    if (liveMarkers.isEmpty) {
      return data;
    }
    return data.copyWith(
      overviewMapMarkers: liveMarkers,
      trackingMapMarkers: liveMarkers,
    );
  }

  Future<List<_OperationsMapMarkerData>>
  _fetchOperationsMapMarkersFromLiveEndpoints(String token) async {
    final markers = <_OperationsMapMarkerData>[];

    try {
      final decoded = await _sendGet(
        'dash/master/drivers/get_drivers.php?limit=80',
        token: token,
      );
      for (final row in _asMapList(decoded['data'])) {
        final lat = _toDouble(
          row['latitude_value'] ?? row['latitude'],
          double.nan,
        );
        final lng = _toDouble(
          row['longitude_value'] ?? row['longitude'],
          double.nan,
        );
        if (!_hasUsableCoordinate(lat, lng)) {
          continue;
        }
        final isOnline =
            _toInt(row['is_online']) == 1 ||
            (row['status'] ?? '').toString().toLowerCase() == 'online';
        markers.add(
          _OperationsMapMarkerData(
            type: 'driver',
            label: _firstText([
              row['display_name'],
              row['driver_name'],
              row['name'],
              'سائق',
            ]),
            subtitle: _firstText([
              row['live_status_label'],
              row['display_vehicle'],
              row['status'],
            ]),
            point: LatLng(lat, lng),
            icon: _iconFromKey('delivery'),
            color: _hexToColor(isOnline ? '#1E7D3F' : '#D92C2C'),
          ),
        );
      }
    } catch (_) {
      // Keep operations usable if a secondary endpoint is unavailable.
    }

    try {
      final decoded = await _sendGet(
        'dash/master/vendors/get_vendors.php',
        token: token,
      );
      for (final row in _asMapList(decoded['data'])) {
        final lat = _toDouble(row['store_latitude'], double.nan);
        final lng = _toDouble(row['store_longitude'], double.nan);
        if (!_hasUsableCoordinate(lat, lng)) {
          continue;
        }
        final status = (row['vendor_status'] ?? '').toString().toLowerCase();
        final isActive = status == 'active' || status == 'open';
        markers.add(
          _OperationsMapMarkerData(
            type: 'restaurant',
            label: _firstText([row['store_name'], row['vendor_name'], 'مطعم']),
            subtitle: _firstText([row['store_address'], row['vendor_status']]),
            point: LatLng(lat, lng),
            icon: _iconFromKey('store'),
            color: _hexToColor(isActive ? '#F59E0B' : '#D92C2C'),
          ),
        );
      }
    } catch (_) {
      // The map should still show any driver coordinates collected above.
    }

    return markers;
  }

  Future<_MasterOrdersData> _fetchOrdersPage(
    String token, {
    int page = 1,
    int limit = 20,
    String query = '',
    String status = 'all',
    String payment = 'all',
    String type = 'all',
    bool scheduledOnly = false,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (scheduledOnly) 'scheduled': '1',
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (status != 'all') 'status': status,
      if (payment != 'all') 'payment': payment,
      if (type != 'all') 'type': type,
    };
    final uri = Uri(
      path: 'dash/master/orders/list.php',
      queryParameters: params,
    );
    final decoded = await _sendGet(uri.toString(), token: token);
    return _MasterOrdersData.fromJson(decoded);
  }

  Future<_MasterOrderChatsData> _fetchMasterOrderChats(
    String token, {
    int page = 1,
    int limit = 30,
    String query = '',
    String status = 'all',
    String state = 'all',
    int? orderId,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (status != 'all') 'status': status,
      if (state != 'all') 'state': state,
      if (orderId != null && orderId > 0) 'order_id': orderId.toString(),
    };
    final uri = Uri(
      path: 'dash/master/orders/chats.php',
      queryParameters: params,
    );
    final decoded = await _sendGet(uri.toString(), token: token);
    return _MasterOrderChatsData.fromJson(decoded);
  }

  Future<void> _sendMasterOrderChatMessage(
    String token, {
    required int orderId,
    required String message,
  }) async {
    await _send(
      'POST',
      'dash/master/orders/chats.php',
      token: token,
      body: {'order_id': orderId, 'message': message},
    );
  }

  Future<void> _uploadMasterOrderChatMedia(
    String token, {
    required int orderId,
    required html.File file,
    String message = '',
  }) async {
    final reader = html.FileReader();
    final completer = Completer<List<int>>();
    reader.onLoadEnd.listen((event) {
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(result.asUint8List());
      } else {
        completer.completeError('تعذر قراءة الملف');
      }
    });
    reader.onError.listen((event) {
      completer.completeError('تعذر قراءة الملف');
    });
    reader.readAsArrayBuffer(file);
    final bytes = await completer.future;

    final request = http.MultipartRequest(
      'POST',
      _uri('dash/master/orders/upload_chat_media.php'),
    );
    request.headers['Accept'] = 'application/json';
    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['order_id'] = orderId.toString();
    if (message.trim().isNotEmpty) {
      request.fields['message'] = message.trim();
    }
    request.files.add(
      http.MultipartFile.fromBytes('media', bytes, filename: file.name),
    );

    final streamed = await _client.send(request).timeout(_requestTimeout);
    final response = await http.Response.fromStream(
      streamed,
    ).timeout(_requestTimeout);
    final decoded = _decodeJsonBytes(response.bodyBytes, response.body);
    final status = response.statusCode;
    final isSuccess = status >= 200 && status < 300;
    final apiStatus = decoded['status']?.toString().toLowerCase();
    if (!isSuccess || apiStatus == 'error' || apiStatus == 'fail') {
      throw MasterApiException(
        _responseMessage(decoded, fallback: 'Upload failed'),
        statusCode: status,
      );
    }
  }

  Future<_MasterSupportChatsData> _fetchMasterSupportChats(
    String token, {
    String query = '',
    int? userId,
  }) async {
    final params = <String, String>{
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (userId != null && userId > 0) 'user_id': userId.toString(),
    };
    final uri = Uri(
      path: 'dash/master/support/chats.php',
      queryParameters: params.isEmpty ? null : params,
    );
    final decoded = await _sendGet(uri.toString(), token: token);
    return _MasterSupportChatsData.fromJson(decoded);
  }

  Future<void> _sendMasterSupportMessage(
    String token, {
    required int userId,
    required String message,
  }) async {
    await _send(
      'POST',
      'dash/master/support/chats.php',
      token: token,
      body: {'user_id': userId, 'message': message},
    );
  }

  Future<void> _uploadMasterSupportAudio(
    String token, {
    required int userId,
    required html.File file,
    String message = '',
  }) async {
    final reader = html.FileReader();
    final completer = Completer<List<int>>();
    reader.onLoadEnd.listen((event) {
      if (completer.isCompleted) {
        return;
      }
      final result = reader.result;
      if (result is ByteBuffer) {
        completer.complete(result.asUint8List());
      } else {
        completer.completeError('تعذر قراءة الملف');
      }
    });
    reader.onError.listen((event) {
      if (!completer.isCompleted) {
        completer.completeError('تعذر قراءة الملف');
      }
    });
    reader.readAsArrayBuffer(file);
    final bytes = await completer.future;

    final request = http.MultipartRequest(
      'POST',
      _uri('dash/master/support/chats.php'),
    );
    request.headers['Accept'] = 'application/json';
    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['user_id'] = userId.toString();
    if (message.trim().isNotEmpty) {
      request.fields['message'] = message.trim();
    }
    request.files.add(
      http.MultipartFile.fromBytes('audio', bytes, filename: file.name),
    );

    final streamed = await _client.send(request).timeout(_requestTimeout);
    final response = await http.Response.fromStream(
      streamed,
    ).timeout(_requestTimeout);
    final decoded = _decodeJsonBytes(response.bodyBytes, response.body);
    final status = response.statusCode;
    final isSuccess = status >= 200 && status < 300;
    final apiStatus = decoded['status']?.toString().toLowerCase();
    if (!isSuccess || apiStatus == 'error' || apiStatus == 'fail') {
      throw MasterApiException(
        _responseMessage(decoded, fallback: 'Upload failed'),
        statusCode: status,
      );
    }
  }

  Future<void> _runMasterOrderAction(
    String token, {
    required int orderId,
    required String action,
    String? status,
    String note = '',
  }) async {
    await _send(
      'POST',
      'dash/master/orders/action.php',
      token: token,
      body: {
        'order_id': orderId,
        'action': action,
        if (status != null && status.trim().isNotEmpty) 'status': status,
        if (note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> _fetchMasterNotificationsRaw(String token) {
    return _sendGet('dash/master/notifications/get_all.php', token: token);
  }

  Future<void> _markMasterNotificationRead(
    String token,
    int notificationId,
  ) async {
    await _send(
      'POST',
      'dash/master/notifications/mark_read.php',
      token: token,
      body: {'notification_id': notificationId},
    );
  }

  Future<void> _markAllMasterNotificationsRead(String token) async {
    await _send(
      'POST',
      'dash/master/notifications/mark_all_read.php',
      token: token,
    );
  }

  Future<void> _sendMasterBroadcast(
    String token, {
    required String audience,
    required String title,
    required String body,
  }) async {
    await _send(
      'POST',
      'dash/master/governance/send_broadcast.php',
      token: token,
      body: {'audience': audience, 'title': title, 'body': body},
    );
  }

  Future<void> verifySignupCode({
    required String email,
    required String code,
  }) async {
    await _send(
      'POST',
      'dash/master_auth/verify_signup_code.php',
      body: {'email': email, 'code': code},
    );
  }

  Future<void> resendSignupCode(String email) async {
    await _send(
      'POST',
      'dash/master_auth/resend_signup_code.php',
      body: {'email': email},
    );
  }

  Future<void> requestPasswordReset(String email) async {
    await _send(
      'POST',
      'dash/master_auth/check_email.php',
      body: {'email': email},
    );
  }

  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    await _send(
      'POST',
      'dash/master_auth/verify_reset_code.php',
      body: {'email': email, 'code': code},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await _send(
      'POST',
      'dash/master_auth/reset_password.php',
      body: {'email': email, 'code': code, 'password': password},
    );
  }
}
