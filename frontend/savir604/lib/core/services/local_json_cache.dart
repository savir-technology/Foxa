import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalJsonCache {
  LocalJsonCache(this._prefs);

  final SharedPreferences _prefs;

  Map<String, dynamic>? readEnvelope(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  dynamic readPayload(String key) {
    return readEnvelope(key)?['data'];
  }

  bool isFresh(String key, Duration ttl) {
    final envelope = readEnvelope(key);
    if (envelope == null) {
      return false;
    }

    final savedAt = envelope['saved_at'];
    final stamp = savedAt is int
        ? savedAt
        : int.tryParse(savedAt?.toString() ?? '') ?? 0;
    if (stamp <= 0) {
      return false;
    }

    final savedAtDate =
        DateTime.fromMillisecondsSinceEpoch(stamp, isUtc: false);
    return DateTime.now().difference(savedAtDate) <= ttl;
  }

  Future<void> writePayload(String key, dynamic payload) async {
    await _prefs.setString(
      key,
      jsonEncode({
        'saved_at': DateTime.now().millisecondsSinceEpoch,
        'data': payload,
      }),
    );
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}

class DeliverySelectionStore {
  DeliverySelectionStore._();

  static const String keySelectedAddress =
      'aleppo_selected_delivery_address_snapshot';

  static Future<void> saveAddress(
    SharedPreferences prefs, {
    String? addressId,
    String? addressName,
    String? addressCity,
    String? addressStreet,
    String? addressPhone,
    double? latitude,
    double? longitude,
    String? locationLabel,
  }) async {
    await prefs.setString(
      keySelectedAddress,
      jsonEncode({
        'saved_at': DateTime.now().millisecondsSinceEpoch,
        'data': {
          'address_id': (addressId ?? '').trim(),
          'address_name': (addressName ?? '').trim(),
          'address_city': (addressCity ?? '').trim(),
          'address_street': (addressStreet ?? '').trim(),
          'address_phone': (addressPhone ?? '').trim(),
          'latitude': latitude,
          'longitude': longitude,
          'location_label': (locationLabel ?? '').trim(),
        },
      }),
    );
  }

  static Map<String, dynamic>? readAddress(SharedPreferences prefs) {
    final raw = prefs.getString(keySelectedAddress);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final data = decoded['data'];
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static double? readLatitude(SharedPreferences prefs) {
    final data = readAddress(prefs);
    if (data == null) {
      return null;
    }
    return _readDouble(data['latitude']);
  }

  static double? readLongitude(SharedPreferences prefs) {
    final data = readAddress(prefs);
    if (data == null) {
      return null;
    }
    return _readDouble(data['longitude']);
  }

  static String readLocationLabel(SharedPreferences prefs) {
    final data = readAddress(prefs);
    if (data == null) {
      return '';
    }
    return '${data['location_label'] ?? ''}'.trim();
  }

  static String readAddressId(SharedPreferences prefs) {
    final data = readAddress(prefs);
    if (data == null) {
      return '';
    }
    return '${data['address_id'] ?? ''}'.trim();
  }

  static Future<void> clear(SharedPreferences prefs) async {
    await prefs.remove(keySelectedAddress);
  }

  static double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return double.tryParse(text);
  }
}
