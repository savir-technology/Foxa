import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum DriverAvailability { offline, available, busy }

enum DriverOrderStatus {
  incoming,
  assigned,
  headingToRestaurant,
  arrivedAtRestaurant,
  pickedUp,
  headingToCustomer,
  arrivedAtCustomer,
  awaitingVerification,
  delivered,
}

class DriverCoordinate {
  const DriverCoordinate({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
  });

  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;

  Offset toOffset() => Offset(longitude, latitude);
}

class DriverRestaurantChoice {
  const DriverRestaurantChoice({
    required this.id,
    required this.vendorName,
    required this.storeName,
    required this.description,
  });

  final int id;
  final String vendorName;
  final String storeName;
  final String description;

  String get displayName => storeName.isNotEmpty ? storeName : vendorName;
}

class DriverProfile {
  const DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.vendorId = 0,
    this.vendorName = '',
    this.storeName = '',
    this.photoUrl = '',
    required this.vehicleType,
    required this.vehicleNumber,
    this.profileCompleted = false,
    this.approvalStatus = 'pending',
    this.approvalNote = '',
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final int vendorId;
  final String vendorName;
  final String storeName;
  final String photoUrl;
  final String vehicleType;
  final String vehicleNumber;
  final bool profileCompleted;
  final String approvalStatus;
  final String approvalNote;

  DriverProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    int? vendorId,
    String? vendorName,
    String? storeName,
    String? photoUrl,
    String? vehicleType,
    String? vehicleNumber,
    bool? profileCompleted,
    String? approvalStatus,
    String? approvalNote,
  }) {
    return DriverProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      storeName: storeName ?? this.storeName,
      photoUrl: photoUrl ?? this.photoUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvalNote: approvalNote ?? this.approvalNote,
    );
  }
}

class DriverOrderItem {
  const DriverOrderItem({
    required this.name,
    required this.quantity,
    this.note,
    this.imageUrl = '',
    this.unitPrice = 0,
    this.totalPrice = 0,
    this.currency = '',
  });

  final String name;
  final int quantity;
  final String? note;
  final String imageUrl;
  final double unitPrice;
  final double totalPrice;
  final String currency;

  bool get hasImage => imageUrl.trim().isNotEmpty;
  bool get hasPrice => unitPrice > 0 || totalPrice > 0;
  double get resolvedUnitPrice {
    if (unitPrice > 0) {
      return unitPrice;
    }
    if (totalPrice > 0 && quantity > 0) {
      return totalPrice / quantity;
    }
    return 0;
  }

  double get resolvedTotalPrice =>
      totalPrice > 0 ? totalPrice : resolvedUnitPrice * quantity;
}

class DriverOrder {
  const DriverOrder({
    required this.id,
    this.vendorId = 0,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.restaurantPhone,
    required this.restaurantLogoUrl,
    required this.restaurantImageUrl,
    required this.customerName,
    required this.customerPhone,
    required this.customerUserId,
    required this.customerAddress,
    required this.zone,
    required this.distanceKm,
    required this.routeDistanceKm,
    required this.etaMinutes,
    required this.status,
    required this.items,
    required this.customerNote,
    required this.giftMessage,
    required this.createdAt,
    required this.restaurantLocation,
    required this.customerLocation,
    required this.deliveryCode,
    required this.totalPrice,
    required this.deliveryFee,
    required this.currency,
  });

  final int id;
  final int vendorId;
  final String restaurantName;
  final String restaurantAddress;
  final String restaurantPhone;
  final String restaurantLogoUrl;
  final String restaurantImageUrl;
  final String customerName;
  final String customerPhone;
  final String customerUserId;
  final String customerAddress;
  final String zone;
  final double distanceKm;
  final double routeDistanceKm;
  final int etaMinutes;
  final DriverOrderStatus status;
  final List<DriverOrderItem> items;
  final String customerNote;
  final String giftMessage;
  final DateTime createdAt;
  final DriverCoordinate restaurantLocation;
  final DriverCoordinate customerLocation;
  final String deliveryCode;
  final double totalPrice;
  final double deliveryFee;
  final String currency;

  bool get isDelivered => status == DriverOrderStatus.delivered;
  bool get isActive => !isDelivered;
  bool get hasRestaurantMedia =>
      restaurantImageUrl.trim().isNotEmpty ||
      restaurantLogoUrl.trim().isNotEmpty;
  String get restaurantMediaUrl => restaurantImageUrl.trim().isNotEmpty
      ? restaurantImageUrl
      : restaurantLogoUrl;
  bool get hasPriceSummary => totalPrice > 0 || deliveryFee > 0;
  double get resolvedTotalPrice => totalPrice > 0
      ? totalPrice
      : items.fold<double>(0, (sum, item) => sum + item.resolvedTotalPrice);

  double resolvedDistanceKm({DriverCoordinate? origin}) {
    final target = _targetLocationForStatus(status);
    if (origin != null &&
        _isValidCoordinate(origin) &&
        target != null &&
        _isValidCoordinate(target)) {
      return _distanceBetween(origin, target);
    }

    if (distanceKm > 0) {
      return distanceKm;
    }

    if (routeDistanceKm > 0) {
      return routeDistanceKm;
    }

    if (_isValidCoordinate(restaurantLocation) &&
        _isValidCoordinate(customerLocation)) {
      return _distanceBetween(restaurantLocation, customerLocation);
    }

    if (origin != null &&
        _isValidCoordinate(origin) &&
        _isValidCoordinate(customerLocation)) {
      return _distanceBetween(origin, customerLocation);
    }

    return 0;
  }

  DriverOrder copyWith({
    int? id,
    String? restaurantName,
    String? restaurantAddress,
    String? restaurantPhone,
    String? restaurantLogoUrl,
    String? restaurantImageUrl,
    String? customerName,
    String? customerPhone,
    String? customerUserId,
    String? customerAddress,
    String? zone,
    double? distanceKm,
    double? routeDistanceKm,
    int? etaMinutes,
    DriverOrderStatus? status,
    List<DriverOrderItem>? items,
    String? customerNote,
    String? giftMessage,
    DateTime? createdAt,
    DriverCoordinate? restaurantLocation,
    DriverCoordinate? customerLocation,
    String? deliveryCode,
    double? totalPrice,
    double? deliveryFee,
    String? currency,
  }) {
    return DriverOrder(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      restaurantPhone: restaurantPhone ?? this.restaurantPhone,
      restaurantLogoUrl: restaurantLogoUrl ?? this.restaurantLogoUrl,
      restaurantImageUrl: restaurantImageUrl ?? this.restaurantImageUrl,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerUserId: customerUserId ?? this.customerUserId,
      customerAddress: customerAddress ?? this.customerAddress,
      zone: zone ?? this.zone,
      distanceKm: distanceKm ?? this.distanceKm,
      routeDistanceKm: routeDistanceKm ?? this.routeDistanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      status: status ?? this.status,
      items: items ?? this.items,
      customerNote: customerNote ?? this.customerNote,
      giftMessage: giftMessage ?? this.giftMessage,
      createdAt: createdAt ?? this.createdAt,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
      customerLocation: customerLocation ?? this.customerLocation,
      deliveryCode: deliveryCode ?? this.deliveryCode,
      totalPrice: totalPrice ?? this.totalPrice,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      currency: currency ?? this.currency,
    );
  }

  DriverCoordinate? _targetLocationForStatus(DriverOrderStatus currentStatus) {
    switch (currentStatus) {
      case DriverOrderStatus.incoming:
      case DriverOrderStatus.assigned:
      case DriverOrderStatus.headingToRestaurant:
      case DriverOrderStatus.arrivedAtRestaurant:
        return restaurantLocation;
      case DriverOrderStatus.pickedUp:
      case DriverOrderStatus.headingToCustomer:
      case DriverOrderStatus.arrivedAtCustomer:
      case DriverOrderStatus.awaitingVerification:
      case DriverOrderStatus.delivered:
        return customerLocation;
    }
  }

  bool _isValidCoordinate(DriverCoordinate coordinate) {
    return coordinate.latitude != 0 && coordinate.longitude != 0;
  }

  double _distanceBetween(DriverCoordinate from, DriverCoordinate to) {
    const earthRadiusKm = 6371.0;
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final deltaLat = _toRadians(to.latitude - from.latitude);
    final deltaLng = _toRadians(to.longitude - from.longitude);

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(math.max(0, 1 - a)));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180.0;
}

class DriverDashboardStats {
  const DriverDashboardStats({
    required this.todayOrders,
    required this.deliveredOrders,
    required this.shiftHours,
    required this.compliance,
    required this.onlineMinutes,
  });

  final int todayOrders;
  final int deliveredOrders;
  final String shiftHours;
  final int compliance;
  final String onlineMinutes;
}

class DriverWorkingDay {
  const DriverWorkingDay({
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

  factory DriverWorkingDay.fromJson(Map<String, dynamic> json) {
    return DriverWorkingDay(
      dayKey: _readText(json['day_key']) ?? '',
      dayLabel: _readText(json['day_label']) ?? '',
      isOpen: _readBool(json['is_open']) ?? true,
      openTime: _readText(json['open_time']) ?? '00:00',
      closeTime: _readText(json['close_time']) ?? '23:59',
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

  DriverWorkingDay copyWith({
    String? dayKey,
    String? dayLabel,
    bool? isOpen,
    String? openTime,
    String? closeTime,
  }) {
    return DriverWorkingDay(
      dayKey: dayKey ?? this.dayKey,
      dayLabel: dayLabel ?? this.dayLabel,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  String localizedLabel(String localeCode) {
    final normalized = localeCode.trim().toLowerCase();
    final label = _localizedDayLabel(dayKey, normalized);
    return label.isNotEmpty ? label : (dayLabel.isNotEmpty ? dayLabel : dayKey);
  }

  String windowLabel(String localeCode) {
    final normalized = localeCode.trim().toLowerCase();
    if (!isOpen) {
      return normalized == 'en' ? 'Closed' : 'مغلق';
    }

    final openLabel = _formatClockLabel(openTime, normalized);
    final closeLabel = _formatClockLabel(closeTime, normalized);
    return normalized == 'en'
        ? '$openLabel to $closeLabel'
        : '$openLabel إلى $closeLabel';
  }
}

class DriverWorkingHoursSchedule {
  const DriverWorkingHoursSchedule({required this.days});

  final List<DriverWorkingDay> days;

  bool get hasDays => days.isNotEmpty;

  static DriverWorkingHoursSchedule defaultSchedule() {
    return const DriverWorkingHoursSchedule(
      days: [
        DriverWorkingDay(
          dayKey: 'mon',
          dayLabel: 'الاثنين',
          isOpen: true,
          openTime: '00:00',
          closeTime: '23:59',
        ),
        DriverWorkingDay(
          dayKey: 'tue',
          dayLabel: 'الثلاثاء',
          isOpen: true,
          openTime: '00:00',
          closeTime: '23:59',
        ),
        DriverWorkingDay(
          dayKey: 'wed',
          dayLabel: 'الأربعاء',
          isOpen: true,
          openTime: '00:00',
          closeTime: '23:59',
        ),
        DriverWorkingDay(
          dayKey: 'thu',
          dayLabel: 'الخميس',
          isOpen: true,
          openTime: '00:00',
          closeTime: '23:59',
        ),
        DriverWorkingDay(
          dayKey: 'fri',
          dayLabel: 'الجمعة',
          isOpen: true,
          openTime: '00:00',
          closeTime: '23:59',
        ),
        DriverWorkingDay(
          dayKey: 'sat',
          dayLabel: 'السبت',
          isOpen: true,
          openTime: '00:00',
          closeTime: '23:59',
        ),
        DriverWorkingDay(
          dayKey: 'sun',
          dayLabel: 'الأحد',
          isOpen: true,
          openTime: '00:00',
          closeTime: '23:59',
        ),
      ],
    );
  }

  factory DriverWorkingHoursSchedule.fromJson(dynamic raw) {
    final rows = _parseWorkingDays(raw);
    return DriverWorkingHoursSchedule(days: rows);
  }

  DriverWorkingDay? dayForWeekday(int weekday) {
    final key = _weekdayKey(weekday);
    for (final day in days) {
      if (day.dayKey.trim().toLowerCase() == key) {
        return day;
      }
    }
    return null;
  }

  DriverWorkingDay? today([DateTime? now]) {
    return dayForWeekday((now ?? DateTime.now()).weekday);
  }

  bool isOpenAt(DateTime moment) {
    if (days.isEmpty) {
      return false;
    }

    final current = today(moment);
    if (current != null && _isOpenWithinDay(current, moment)) {
      return true;
    }

    final previous = dayForWeekday(
      moment.weekday == DateTime.monday ? DateTime.sunday : moment.weekday - 1,
    );
    if (previous != null && previous.isOpen) {
      final openMinutes = _parseMinutes(previous.openTime);
      final closeMinutes = _parseMinutes(previous.closeTime);
      final currentMinutes = moment.hour * 60 + moment.minute;
      if (openMinutes != null &&
          closeMinutes != null &&
          openMinutes > closeMinutes &&
          currentMinutes < closeMinutes) {
        return true;
      }
    }

    return false;
  }

  String todayWindowText({required String localeCode, DateTime? now}) {
    final current = today(now);
    if (current == null) {
      return localeCode.trim().toLowerCase() == 'en'
          ? 'No official hours'
          : 'لا توجد أوقات عمل محددة';
    }

    final normalized = localeCode.trim().toLowerCase();
    final dayLabel = current.localizedLabel(normalized);
    final window = current.isOpen
        ? current.windowLabel(normalized)
        : (normalized == 'en' ? 'Closed today' : 'مغلق اليوم');
    return '$dayLabel: $window';
  }

  String blockedMessage({required String localeCode, DateTime? now}) {
    final normalized = localeCode.trim().toLowerCase();
    final current = today(now);
    if (current == null) {
      return normalized == 'en'
          ? 'You cannot start a shift right now.'
          : 'لا يمكنك بدء المناوبة الآن.';
    }

    final window = current.windowLabel(normalized);
    return normalized == 'en'
        ? 'You cannot start a shift right now. Official hours today are $window.'
        : 'لا يمكنك بدء المناوبة الآن. أوقات العمل الرسمية اليوم هي $window.';
  }

  String weeklySummary({required String localeCode}) {
    final normalized = localeCode.trim().toLowerCase();
    return days
        .map(
          (day) =>
              '${day.localizedLabel(normalized)} ${day.windowLabel(normalized)}',
        )
        .join(' • ');
  }

  bool _isOpenWithinDay(DriverWorkingDay day, DateTime moment) {
    if (!day.isOpen) {
      return false;
    }

    final openMinutes = _parseMinutes(day.openTime);
    final closeMinutes = _parseMinutes(day.closeTime);
    if (openMinutes == null || closeMinutes == null) {
      return true;
    }

    if (openMinutes == closeMinutes) {
      return true;
    }

    final currentMinutes = moment.hour * 60 + moment.minute;
    if (openMinutes < closeMinutes) {
      return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
    }

    return currentMinutes >= openMinutes || currentMinutes < closeMinutes;
  }
}

List<DriverWorkingDay> _parseWorkingDays(dynamic raw) {
  final decoded = _decodeWorkingHoursSource(raw);
  if (decoded is! List) {
    return const [];
  }

  final rows = decoded
      .whereType<Map>()
      .map((entry) => DriverWorkingDay.fromJson(entry.cast<String, dynamic>()))
      .where((day) => day.dayKey.trim().isNotEmpty)
      .toList(growable: false);

  if (rows.isEmpty) {
    return const [];
  }

  final ordered = List<DriverWorkingDay>.from(rows);
  ordered.sort((a, b) {
    final compare = _dayOrder(a.dayKey).compareTo(_dayOrder(b.dayKey));
    if (compare != 0) {
      return compare;
    }
    return a.dayKey.compareTo(b.dayKey);
  });
  return ordered;
}

dynamic _decodeWorkingHoursSource(dynamic raw) {
  if (raw == null) {
    return null;
  }

  if (raw is String) {
    final text = raw.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  if (raw is Map) {
    final map = raw.map((key, value) => MapEntry('$key', value));
    final direct =
        map['delivery_working_hours_json'] ??
        map['working_hours_json'] ??
        map['working_hours'];
    if (direct != null) {
      return _decodeWorkingHoursSource(direct);
    }

    final nestedKeys = <String>[
      'official_working_hours_json',
      'official_working_hours',
      'store_working_hours_json',
      'store_working_hours',
      'settings',
      'vendor_store_settings',
      'restaurant_settings',
    ];
    for (final key in nestedKeys) {
      final nested = map[key];
      final decoded = _decodeWorkingHoursSource(nested);
      if (decoded is List && decoded.isNotEmpty) {
        return decoded;
      }
    }
    return null;
  }

  if (raw is List) {
    return raw;
  }

  return null;
}

int _dayOrder(String dayKey) {
  switch (dayKey.trim().toLowerCase()) {
    case 'mon':
      return 1;
    case 'tue':
      return 2;
    case 'wed':
      return 3;
    case 'thu':
      return 4;
    case 'fri':
      return 5;
    case 'sat':
      return 6;
    case 'sun':
      return 7;
    default:
      return 99;
  }
}

String _weekdayKey(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'mon';
    case DateTime.tuesday:
      return 'tue';
    case DateTime.wednesday:
      return 'wed';
    case DateTime.thursday:
      return 'thu';
    case DateTime.friday:
      return 'fri';
    case DateTime.saturday:
      return 'sat';
    case DateTime.sunday:
      return 'sun';
    default:
      return '';
  }
}

String _localizedDayLabel(String dayKey, String localeCode) {
  final english = localeCode == 'en';
  switch (dayKey.trim().toLowerCase()) {
    case 'mon':
      return english ? 'Monday' : 'الاثنين';
    case 'tue':
      return english ? 'Tuesday' : 'الثلاثاء';
    case 'wed':
      return english ? 'Wednesday' : 'الأربعاء';
    case 'thu':
      return english ? 'Thursday' : 'الخميس';
    case 'fri':
      return english ? 'Friday' : 'الجمعة';
    case 'sat':
      return english ? 'Saturday' : 'السبت';
    case 'sun':
      return english ? 'Sunday' : 'الأحد';
    default:
      return '';
  }
}

String _formatClockLabel(String value, String localeCode) {
  final minuteValue = _parseMinutes(value);
  if (minuteValue == null) {
    return value;
  }

  final english = localeCode == 'en';
  final hour = minuteValue ~/ 60;
  final minute = minuteValue % 60;
  final paddedMinute = minute.toString().padLeft(2, '0');

  if (english) {
    final suffix = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$paddedMinute $suffix';
  }

  final suffix = hour < 12 ? 'صباحاً' : 'مساءً';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:$paddedMinute $suffix';
}

int? _parseMinutes(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return null;
  }

  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(normalized);
  if (match == null) {
    return null;
  }

  final hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null) {
    return null;
  }
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    return null;
  }

  return hour * 60 + minute;
}

String? _readText(dynamic value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

bool? _readBool(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is bool) {
    return value;
  }

  final text = value.toString().trim().toLowerCase();
  if (text.isEmpty) {
    return null;
  }

  if (text == '1' || text == 'true' || text == 'yes') {
    return true;
  }
  if (text == '0' || text == 'false' || text == 'no') {
    return false;
  }
  return null;
}
