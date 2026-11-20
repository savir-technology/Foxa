import 'dart:convert';

Map<String, dynamic> _decodeProfileSettings(String raw) {
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
  } catch (_) {
    return {};
  }
}

String? _resolveRestaurantMediaUrl(
  dynamic value, {
  required String fallbackFolder,
}) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) {
    return null;
  }

  if (raw.startsWith('http://') ||
      raw.startsWith('https://') ||
      raw.startsWith('data:')) {
    return raw
        .replaceFirst('https://aleppoeats.com/zahra/',
            'https://savir-technology.online/roaqv2/')
        .replaceFirst('https://namlek.net/zahra/',
            'https://savir-technology.online/roaqv2/');
  }

  final normalized = raw.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
  if (normalized.startsWith('uploads/') || normalized.startsWith('uploud/')) {
    return 'https://savir-technology.online/roaqv2/$normalized';
  }

  return 'https://savir-technology.online/roaqv2/$fallbackFolder/$normalized';
}

double? _parseNullableDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) {
    return null;
  }

  final normalized = raw.replaceAll(',', '.');
  final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(normalized);
  if (match != null) {
    return double.tryParse(match.group(0)!);
  }

  return double.tryParse(normalized);
}

class StoreWorkingDay {
  const StoreWorkingDay({
    required this.dayKey,
    required this.dayLabel,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  final String dayKey;
  final String dayLabel;
  final bool isOpen;
  final String openTime;
  final String closeTime;

  factory StoreWorkingDay.fromJson(Map<String, dynamic> json) {
    return StoreWorkingDay(
      dayKey: json['day_key']?.toString() ?? '',
      dayLabel: json['day_label']?.toString() ?? '',
      isOpen: json['is_open']?.toString() == '1' ||
          json['is_open']?.toString().toLowerCase() == 'true',
      openTime: json['open_time']?.toString() ?? '10:00',
      closeTime: json['close_time']?.toString() ?? '23:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_key': dayKey,
      'day_label': dayLabel,
      'is_open': isOpen ? 1 : 0,
      'open_time': openTime,
      'close_time': closeTime,
    };
  }

  StoreWorkingDay copyWith({
    String? dayKey,
    String? dayLabel,
    bool? isOpen,
    String? openTime,
    String? closeTime,
  }) {
    return StoreWorkingDay(
      dayKey: dayKey ?? this.dayKey,
      dayLabel: dayLabel ?? this.dayLabel,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}

class RestaurantSettingsSnapshot {
  const RestaurantSettingsSnapshot({
    required this.vendorId,
    required this.vendorName,
    required this.storeName,
    required this.storeSlug,
    required this.vendorEmail,
    required this.vendorPhone,
    required this.vendorLogo,
    required this.vendorDescription,
    required this.storeBannerUrl,
    required this.storeAddress,
    required this.coverageArea,
    required this.coverageKm,
    required this.storeLatitude,
    required this.storeLongitude,
    required this.minimumOrder,
    required this.languageCode,
    required this.isOpen,
    required this.acceptsPreorders,
    required this.preorderDaysLimit,
    required this.notificationsEnabled,
    required this.temporaryClosedReason,
    required this.workingHours,
    required this.branchCount,
    required this.deliveryFee,
    required this.estimatedMinMinutes,
    required this.estimatedMaxMinutes,
    this.profileSettings = const <String, dynamic>{},
  });

  final int vendorId;
  final String vendorName;
  final String storeName;
  final String storeSlug;
  final String vendorEmail;
  final String vendorPhone;
  final String? vendorLogo;
  final String? vendorDescription;
  final String? storeBannerUrl;
  final String? storeAddress;
  final String? coverageArea;
  final double? coverageKm;
  final double? storeLatitude;
  final double? storeLongitude;
  final double minimumOrder;
  final String languageCode;
  final bool isOpen;
  final bool acceptsPreorders;
  final int preorderDaysLimit;
  final bool notificationsEnabled;
  final String? temporaryClosedReason;
  final List<StoreWorkingDay> workingHours;
  final int branchCount;
  final double? deliveryFee;
  final int estimatedMinMinutes;
  final int estimatedMaxMinutes;
  final Map<String, dynamic> profileSettings;

  bool get isCurrentlyOpen {
    if (!isOpen || workingHours.isEmpty) {
      return false;
    }

    final now = DateTime.now();
    final dayKeys = const ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final todayIndex = now.weekday - 1;

    bool inside(StoreWorkingDay day, DateTime reference) {
      if (!day.isOpen) return false;
      final open = _parseScheduleTime(day.openTime, reference);
      var close = _parseScheduleTime(day.closeTime, reference);
      if (open == null || close == null) return false;
      if (!close.isAfter(open)) {
        close = close.add(const Duration(days: 1));
      }
      return !reference.isBefore(open) && reference.isBefore(close);
    }

    final todayKey = dayKeys[todayIndex];
    final today = workingHours.firstWhere(
      (day) => day.dayKey.toLowerCase() == todayKey,
      orElse: () => const StoreWorkingDay(
        dayKey: '',
        dayLabel: '',
        isOpen: false,
        openTime: '00:00',
        closeTime: '00:00',
      ),
    );
    if (inside(today, now)) return true;

    // Support schedules that cross midnight, e.g. 18:00 → 02:00.
    final previousKey = dayKeys[(todayIndex + 6) % 7];
    final previous = workingHours.firstWhere(
      (day) => day.dayKey.toLowerCase() == previousKey,
      orElse: () => const StoreWorkingDay(
        dayKey: '',
        dayLabel: '',
        isOpen: false,
        openTime: '00:00',
        closeTime: '00:00',
      ),
    );
    if (!previous.isOpen) return false;
    final previousDate = now.subtract(const Duration(days: 1));
    final previousOpen = _parseScheduleTime(previous.openTime, previousDate);
    var previousClose = _parseScheduleTime(previous.closeTime, previousDate);
    if (previousOpen == null || previousClose == null) return false;
    if (!previousClose.isAfter(previousOpen)) {
      previousClose = previousClose.add(const Duration(days: 1));
    }
    return !now.isBefore(previousOpen) && now.isBefore(previousClose);
  }

  factory RestaurantSettingsSnapshot.fromJson(Map<String, dynamic> json) {
    final vendor = (json['vendor'] as Map?)?.cast<String, dynamic>() ?? json;
    final settings =
        (json['settings'] as Map?)?.cast<String, dynamic>() ?? json;

    List<StoreWorkingDay> parseWorkingHours(dynamic raw) {
      final decoded = raw is String
          ? (() {
              try {
                return jsonDecode(raw);
              } catch (_) {
                return null;
              }
            })()
          : raw;
      if (decoded is! List) {
        return _defaultWorkingHours();
      }
      final rows = decoded
          .whereType<Map>()
          .map((entry) => StoreWorkingDay.fromJson(
                entry.cast<String, dynamic>(),
              ))
          .toList();
      return rows.isEmpty ? _defaultWorkingHours() : rows;
    }

    final rawProfileSettings = settings['profile_settings'] ??
        settings['profile_settings_json'];
    final profileSettings = rawProfileSettings is String
        ? _decodeProfileSettings(rawProfileSettings)
        : rawProfileSettings is Map
            ? Map<String, dynamic>.from(rawProfileSettings)
            : <String, dynamic>{};

    return RestaurantSettingsSnapshot(
      vendorId: int.tryParse(vendor['vendor_id']?.toString() ?? '') ?? 0,
      vendorName: vendor['vendor_name']?.toString() ?? '',
      storeName: vendor['store_name']?.toString() ?? '',
      storeSlug: vendor['store_slug']?.toString() ?? '',
      vendorEmail: vendor['vendor_email']?.toString() ?? '',
      vendorPhone: vendor['vendor_phone']?.toString() ?? '',
      vendorLogo: _resolveRestaurantMediaUrl(
        vendor['vendor_logo'],
        fallbackFolder: 'uploads/vendors/logo',
      ),
      vendorDescription: vendor['vendor_description']?.toString(),
      storeBannerUrl: _resolveRestaurantMediaUrl(
        settings['store_banner_url'],
        fallbackFolder: 'uploads/vendors/banner',
      ),
      storeAddress: settings['store_address']?.toString(),
      coverageArea: settings['coverage_area']?.toString(),
      coverageKm: _parseNullableDouble(settings['coverage_km']) ??
          _parseNullableDouble(settings['coverage_area']),
      storeLatitude:
          double.tryParse(settings['store_latitude']?.toString() ?? ''),
      storeLongitude:
          double.tryParse(settings['store_longitude']?.toString() ?? ''),
      minimumOrder:
          double.tryParse(settings['minimum_order']?.toString() ?? '') ?? 0.0,
      languageCode: settings['language_code']?.toString() ?? 'ar',
      isOpen: settings['is_open']?.toString() == '1' ||
          settings['is_open']?.toString().toLowerCase() == 'true',
      acceptsPreorders: settings['accepts_preorders']?.toString() == '1' ||
          settings['accepts_preorders']?.toString().toLowerCase() == 'true',
      preorderDaysLimit:
          int.tryParse(settings['preorder_days_limit']?.toString() ?? '') ?? 7,
      notificationsEnabled: settings['notifications_enabled']?.toString() ==
              '1' ||
          settings['notifications_enabled']?.toString().toLowerCase() == 'true',
      temporaryClosedReason: settings['temporary_closed_reason']?.toString(),
      workingHours: parseWorkingHours(
          settings['working_hours_json'] ?? settings['working_hours']),
      branchCount:
          int.tryParse(settings['branch_count']?.toString() ?? '') ?? 0,
      deliveryFee: double.tryParse(settings['delivery_fee']?.toString() ?? ''),
      estimatedMinMinutes:
          int.tryParse(settings['estimated_min_minutes']?.toString() ?? '') ??
              25,
      estimatedMaxMinutes:
          int.tryParse(settings['estimated_max_minutes']?.toString() ?? '') ??
              45,
      profileSettings: profileSettings,
    );
  }

  Map<String, dynamic> toUpdatePayload() {
    return {
      'vendor_name': vendorName,
      'store_name': storeName,
      'vendor_email': vendorEmail,
      'vendor_phone': vendorPhone,
      'vendor_logo': vendorLogo,
      'vendor_description': vendorDescription,
      'store_banner_url': storeBannerUrl,
      'store_address': storeAddress,
      'coverage_area': coverageArea,
      'coverage_km': coverageKm,
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
      'profile_settings': profileSettings,
    };
  }

  RestaurantSettingsSnapshot copyWith({
    int? vendorId,
    String? vendorName,
    String? storeName,
    String? storeSlug,
    String? vendorEmail,
    String? vendorPhone,
    String? vendorLogo,
    String? vendorDescription,
    String? storeBannerUrl,
    String? storeAddress,
    String? coverageArea,
    double? coverageKm,
    double? storeLatitude,
    double? storeLongitude,
    double? minimumOrder,
    String? languageCode,
    bool? isOpen,
    bool? acceptsPreorders,
    int? preorderDaysLimit,
    bool? notificationsEnabled,
    String? temporaryClosedReason,
    List<StoreWorkingDay>? workingHours,
    int? branchCount,
    double? deliveryFee,
    int? estimatedMinMinutes,
    int? estimatedMaxMinutes,
    Map<String, dynamic>? profileSettings,
  }) {
    return RestaurantSettingsSnapshot(
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      storeName: storeName ?? this.storeName,
      storeSlug: storeSlug ?? this.storeSlug,
      vendorEmail: vendorEmail ?? this.vendorEmail,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      vendorLogo: vendorLogo ?? this.vendorLogo,
      vendorDescription: vendorDescription ?? this.vendorDescription,
      storeBannerUrl: storeBannerUrl ?? this.storeBannerUrl,
      storeAddress: storeAddress ?? this.storeAddress,
      coverageArea: coverageArea ?? this.coverageArea,
      coverageKm: coverageKm ?? this.coverageKm,
      storeLatitude: storeLatitude ?? this.storeLatitude,
      storeLongitude: storeLongitude ?? this.storeLongitude,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      languageCode: languageCode ?? this.languageCode,
      isOpen: isOpen ?? this.isOpen,
      acceptsPreorders: acceptsPreorders ?? this.acceptsPreorders,
      preorderDaysLimit: preorderDaysLimit ?? this.preorderDaysLimit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      temporaryClosedReason:
          temporaryClosedReason ?? this.temporaryClosedReason,
      workingHours: workingHours ?? this.workingHours,
      branchCount: branchCount ?? this.branchCount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      estimatedMinMinutes: estimatedMinMinutes ?? this.estimatedMinMinutes,
      estimatedMaxMinutes: estimatedMaxMinutes ?? this.estimatedMaxMinutes,
      profileSettings: profileSettings ?? this.profileSettings,
    );
  }
}

DateTime? _parseScheduleTime(String value, DateTime date) {
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null || hour < 0 || hour > 23 || minute > 59) {
    return null;
  }
  return DateTime(date.year, date.month, date.day, hour, minute);
}

List<StoreWorkingDay> _defaultWorkingHours() {
  return const [
    StoreWorkingDay(
      dayKey: 'mon',
      dayLabel: 'الاثنين',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    ),
    StoreWorkingDay(
      dayKey: 'tue',
      dayLabel: 'الثلاثاء',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    ),
    StoreWorkingDay(
      dayKey: 'wed',
      dayLabel: 'الأربعاء',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    ),
    StoreWorkingDay(
      dayKey: 'thu',
      dayLabel: 'الخميس',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    ),
    StoreWorkingDay(
      dayKey: 'fri',
      dayLabel: 'الجمعة',
      isOpen: true,
      openTime: '12:00',
      closeTime: '23:30',
    ),
    StoreWorkingDay(
      dayKey: 'sat',
      dayLabel: 'السبت',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    ),
    StoreWorkingDay(
      dayKey: 'sun',
      dayLabel: 'الأحد',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    ),
  ];
}
