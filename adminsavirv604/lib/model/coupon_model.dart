class CouponModel {
  final int couponId;
  final String couponName;
  final int couponCount;
  final DateTime couponExpireDate;
  final int couponDiscount;

  const CouponModel({
    required this.couponId,
    required this.couponName,
    required this.couponCount,
    required this.couponExpireDate,
    required this.couponDiscount,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      couponId: _toInt(json['coupon_id'] ?? json['id']),
      couponName: json['coupon_name']?.toString().trim() ?? '',
      couponCount: _toInt(json['coupon_count']),
      couponExpireDate:
          _toDateTime(json['coupon_expiredate']) ?? DateTime.now(),
      couponDiscount: _toInt(json['coupon_discount']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(couponExpireDate);

  bool get isActive => !isExpired && couponCount > 0;

  bool get isExpiringSoon =>
      !isExpired &&
      couponExpireDate.difference(DateTime.now()).inDays <= 3;

  String get statusLabelAr {
    if (isExpired) {
      return 'منتهي';
    }
    if (couponCount <= 0) {
      return 'نفدت الكمية';
    }
    if (isExpiringSoon) {
      return 'قريب الانتهاء';
    }
    return 'نشط';
  }

  String get expiryLabel {
    final d = couponExpireDate;
    final year = d.year.toString().padLeft(4, '0');
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  Map<String, String> toFormMap() {
    return {
      'coupon_id': couponId.toString(),
      'coupon_name': couponName,
      'coupon_count': couponCount.toString(),
      'coupon_expiredate': expiryLabel,
      'coupon_discount': couponDiscount.toString(),
    };
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _toDateTime(dynamic value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
}
