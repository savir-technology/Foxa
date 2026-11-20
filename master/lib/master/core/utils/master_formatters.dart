// ignore_for_file: unused_element

part of '../../../master_auth_app.dart';

Color _hexToColor(String? value, {Color fallback = _kPrimaryGreen}) {
  final hex = (value ?? '').replaceAll('#', '').trim();
  if (hex.length == 6) {
    return Color(int.parse('FF$hex', radix: 16));
  }
  if (hex.length == 8) {
    return Color(int.parse(hex, radix: 16));
  }
  return fallback;
}

int _toInt(dynamic value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

double _toDouble(dynamic value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

bool _hasUsableCoordinate(double lat, double lng) {
  return lat.isFinite &&
      lng.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180 &&
      (lat.abs() > 0.000001 || lng.abs() > 0.000001);
}

bool _looksLikeUtf8Mojibake(String value) {
  if (value.isEmpty) {
    return false;
  }
  const markers = <String>['?', '?', 'Ú', 'Û', 'Ð', 'Ñ', 'Ï', '?', '?', '?'];
  return markers.any(value.contains);
}

bool _containsArabicText(String value) {
  return value.runes.any((char) => char >= 0x0600 && char <= 0x06FF);
}

int _mojibakeMarkerScore(String value) {
  const markers = <String>['?', '?', 'Ú', 'Û', 'Ð', 'Ñ', 'Ï', '?', '?', '?'];
  return markers.fold<int>(
    0,
    (score, marker) => score + marker.allMatches(value).length,
  );
}

String _decodeUtf8MojibakeOnce(String value) {
  final bytes = <int>[];
  for (final char in value.runes) {
    if (char <= 0xFF) {
      bytes.add(char);
      continue;
    }
    bytes.addAll(String.fromCharCode(char).codeUnits);
  }
  return utf8.decode(bytes, allowMalformed: true);
}

String _normalizeUtf8Text(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || !_looksLikeUtf8Mojibake(trimmed)) {
    return value;
  }

  try {
    var best = trimmed;
    var bestScore = _mojibakeMarkerScore(trimmed);

    for (var attempt = 0; attempt < 3; attempt++) {
      final normalized = _decodeUtf8MojibakeOnce(best);
      if (normalized == best) {
        break;
      }

      final normalizedScore = _mojibakeMarkerScore(normalized);
      if (_containsArabicText(normalized) || normalizedScore < bestScore) {
        best = normalized;
        bestScore = normalizedScore;
      } else {
        break;
      }

      if (!_looksLikeUtf8Mojibake(best)) {
        break;
      }
    }

    if (best != trimmed) {
      return value.replaceFirst(trimmed, best);
    }
  } catch (_) {
    // Keep the original string when normalization is not possible.
  }

  return value;
}

dynamic _normalizeDecodedValue(dynamic value) {
  if (value is String) {
    return _normalizeUtf8Text(value);
  }
  if (value is List) {
    return value.map(_normalizeDecodedValue).toList();
  }
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), _normalizeDecodedValue(item)),
    );
  }
  return value;
}

String _firstText(List<dynamic> values, [String fallback = '']) {
  for (final value in values) {
    final text = _normalizeUtf8Text((value ?? '').toString()).trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return _normalizeUtf8Text(fallback);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value.map(
      (key, item) => MapEntry(key, _normalizeDecodedValue(item)),
    );
  }
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), _normalizeDecodedValue(item)),
    );
  }
  return <String, dynamic>{};
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => _normalizeUtf8Text(item.toString())).toList();
  }
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded
            .map((item) => _normalizeUtf8Text(item.toString()))
            .toList();
      }
    } catch (_) {
      return [_normalizeUtf8Text(value)];
    }
  }
  return <String>[];
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is List) {
    return value.map((item) => _asMap(item)).toList();
  }
  return <Map<String, dynamic>>[];
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String _formatArabicDateTime(DateTime? value) {
  if (value == null) {
    return 'اليوم';
  }

  const weekDays = <String>[
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  const months = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  final dayName = weekDays[value.weekday - 1];
  final monthName = months[value.month - 1];
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'م' : 'ص';

  return '$dayName، ${value.day} $monthName ${value.year} · $hour:$minute $suffix';
}

String _formatArabicDateLabel(DateTime? value) {
  if (value == null) {
    return 'اليوم';
  }

  const weekDays = <String>[
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  const months = <String>[
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  final dayName = weekDays[value.weekday - 1];
  final monthName = months[value.month - 1];
  return '$dayName، ${value.day} $monthName ${value.year}';
}

String _formatArabicTimeLabel(DateTime? value) {
  if (value == null) {
    return '11:59 ص';
  }

  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'م' : 'ص';
  return '$hour:$minute $suffix';
}

String _masterRoleArabicLabel(int roleId, {String? fallback}) {
  switch (roleId) {
    case 1:
      return 'الأدمن الأساسي';
    case 2:
      return 'مدير الحسابات';
    case 3:
      return 'مدير المطاعم';
    case 4:
      return 'مدير قسم السائقين';
    case 5:
      return 'مدير الدعم الفني';
    default:
      final trimmedFallback = (fallback ?? '').trim();
      return trimmedFallback.isNotEmpty ? trimmedFallback : 'مدير المنصة';
  }
}

IconData _iconFromKey(String? key) {
  switch ((key ?? '').toLowerCase()) {
    case 'home':
    case 'home_rounded':
      return Icons.home_rounded;
    case 'operations':
    case 'grid_view':
    case 'grid_view_rounded':
    case 'dashboard':
    case 'dashboard_rounded':
      return Icons.grid_view_rounded;
    case 'orders':
    case 'receipt_long':
    case 'receipt_long_outlined':
      return Icons.receipt_long_outlined;
    case 'hourglass':
      return Icons.hourglass_top_rounded;
    case 'kitchen':
      return Icons.kitchen_rounded;
    case 'delivery':
    case 'scooter':
    case 'delivery_dining':
    case 'delivery_dining_outlined':
      return Icons.delivery_dining_outlined;
    case 'store':
    case 'storefront':
    case 'storefront_outlined':
    case 'stores':
      return Icons.storefront_outlined;
    case 'restaurants':
      return Icons.restaurant_outlined;
    case 'users':
    case 'people':
    case 'people_alt':
    case 'people_alt_outlined':
      return Icons.people_alt_outlined;
    case 'finance':
    case 'wallet':
    case 'account_balance_wallet':
    case 'account_balance_wallet_outlined':
      return Icons.account_balance_wallet_outlined;
    case 'payments':
      return Icons.payments_outlined;
    case 'refund':
      return Icons.currency_exchange_rounded;
    case 'activity':
      return Icons.monitor_heart_rounded;
    case 'location':
      return Icons.location_on_outlined;
    case 'time':
      return Icons.access_time_rounded;
    case 'truck':
      return Icons.local_shipping_rounded;
    case 'user':
      return Icons.person_rounded;
    case 'marketing':
    case 'campaign':
    case 'campaign_outlined':
      return Icons.campaign_outlined;
    case 'communication':
    case 'notifications':
    case 'notifications_active':
    case 'notifications_active_outlined':
      return Icons.notifications_active_outlined;
    case 'quality':
    case 'shield':
    case 'verified_user':
    case 'verified_user_outlined':
      return Icons.verified_user_outlined;
    case 'reports':
    case 'query_stats':
    case 'query_stats_outlined':
      return Icons.query_stats_outlined;
    case 'inventory':
    case 'inventory_2':
    case 'inventory_2_outlined':
      return Icons.inventory_2_outlined;
    case 'settings':
    case 'settings_outlined':
      return Icons.settings_outlined;
    case 'administration':
    case 'admin':
    case 'admin_panel_settings':
    case 'admin_panel_settings_outlined':
      return Icons.admin_panel_settings_outlined;
    case 'warning':
    case 'alert':
    case 'error':
    case 'error_outline':
      return Icons.error_outline_rounded;
    case 'emergency':
    case 'sos':
      return Icons.emergency_rounded;
    case 'check':
      return Icons.check_circle_outline_rounded;
    case 'cancel':
      return Icons.cancel_outlined;
    case 'add':
      return Icons.add_circle_outline_rounded;
    case 'block':
      return Icons.block_rounded;
    case 'pause':
      return Icons.pause_circle_outline_rounded;
    case 'finance_entry':
      return Icons.currency_exchange_rounded;
    case 'ads':
      return Icons.local_offer_rounded;
    case 'communication_center':
      return Icons.headset_mic_rounded;
    case 'quality_support':
      return Icons.report_gmailerrorred_rounded;
    default:
      return Icons.circle_outlined;
  }
}
