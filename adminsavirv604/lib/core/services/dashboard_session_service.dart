import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DashboardSession {
  const DashboardSession({
    required this.token,
    required this.expiresAt,
    this.role = 'vendor',
    this.vendorId = 0,
    this.vendorName = '',
    this.storeName = '',
    this.storeSlug = '',
    this.email = '',
    this.phone = '',
    this.logo,
    this.vendorDescription,
    this.storeAddress,
    this.storeLatitude,
    this.storeLongitude,
    this.vendorType = 'restaurant',
    this.storeCategory,
  });

  final String token;
  final String expiresAt;
  final String role;
  final int vendorId;
  final String vendorName;
  final String storeName;
  final String storeSlug;
  final String email;
  final String phone;
  final String? logo;
  final String? vendorDescription;
  final String? storeAddress;
  final double? storeLatitude;
  final double? storeLongitude;
  final String vendorType;
  final String? storeCategory;

  bool get isValid {
    if (token.isEmpty) {
      return false;
    }

    if (expiresAt.trim().isEmpty) {
      return true;
    }

    final expiresAtDate = DateTime.tryParse(expiresAt);
    if (expiresAtDate == null) {
      return true;
    }

    return expiresAtDate.isAfter(DateTime.now());
  }

  String get displayName => storeName.isNotEmpty ? storeName : vendorName;

  factory DashboardSession.fromJson(Map<String, dynamic> json) {
    final normalizedRole = _resolveRole(json);
    final profile = normalizedRole == 'master'
        ? (json['master'] as Map?)?.cast<String, dynamic>() ?? json
        : (json['vendor'] as Map?)?.cast<String, dynamic>() ?? json;
    return DashboardSession(
      token: json['token']?.toString() ?? '',
      expiresAt: json['expires_at']?.toString() ?? '',
      role: normalizedRole,
      vendorId: int.tryParse(profile['vendor_id']?.toString() ?? '') ?? 0,
      vendorName: profile['vendor_name']?.toString() ??
          profile['admin_name']?.toString() ?? '',
      storeName: profile['store_name']?.toString() ??
          (normalizedRole == 'master' ? 'Jeeb Master' : ''),
      storeSlug: profile['store_slug']?.toString() ?? '',
      email: profile['vendor_email']?.toString() ??
          profile['admin_email']?.toString() ?? '',
      phone: profile['vendor_phone']?.toString() ??
          profile['admin_phone']?.toString() ?? '',
      logo: profile['vendor_logo']?.toString() ??
          profile['admin_profile_image']?.toString(),
      vendorDescription: profile['vendor_description']?.toString(),
      storeAddress: profile['store_address']?.toString(),
      storeLatitude: double.tryParse(profile['store_latitude']?.toString() ?? ''),
      storeLongitude: double.tryParse(profile['store_longitude']?.toString() ?? ''),
      vendorType: profile['vendor_type']?.toString() ?? 'restaurant',
      storeCategory: profile['store_category']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final profile = role == 'master'
        ? {
            'admin_name': vendorName,
            'admin_email': email,
            'admin_phone': phone,
            'admin_profile_image': logo,
          }
        : {
            'vendor_id': vendorId,
            'vendor_name': vendorName,
            'store_name': storeName,
            'store_slug': storeSlug,
            'vendor_email': email,
            'vendor_phone': phone,
            'vendor_logo': logo,
            'vendor_description': vendorDescription,
            'store_address': storeAddress,
            'store_latitude': storeLatitude,
            'store_longitude': storeLongitude,
            'vendor_type': vendorType,
            'store_category': storeCategory,
          };
    final result = <String, dynamic>{
      'role': role,
      'token': token,
      'expires_at': expiresAt,
    };
    result[role == 'master' ? 'master' : 'vendor'] = profile;
    return result;
  }

  static String _resolveRole(Map<String, dynamic> json) {
    final rawRole = json['role']?.toString().trim().toLowerCase() ?? '';
    if (rawRole == 'master') {
      return 'master';
    }

    if (rawRole == 'vendor') {
      return 'vendor';
    }

    if (json['master'] is Map) {
      return 'master';
    }

    return 'vendor';
  }
}

class DashboardSessionService {
  DashboardSessionService._();

  static final DashboardSessionService instance = DashboardSessionService._();
  static const String _sessionKey = 'vendor_dashboard_session';

  DashboardSession? _cachedSession;

  DashboardSession? get currentSession =>
      _cachedSession?.isValid == true ? _cachedSession : null;

  Future<DashboardSession?> loadSession() async {
    if (_cachedSession != null) {
      if (_cachedSession!.isValid) {
        return _cachedSession;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      _cachedSession = null;
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final session = DashboardSession.fromJson(decoded);
      if (!session.isValid) {
        await prefs.remove(_sessionKey);
        _cachedSession = null;
        return null;
      }

      _cachedSession = session;
      return _cachedSession;
    } catch (_) {
      await prefs.remove(_sessionKey);
      _cachedSession = null;
      return null;
    }
  }

  Future<void> saveSession(DashboardSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, json.encode(session.toJson()));
    _cachedSession = session;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _cachedSession = null;
  }
}
