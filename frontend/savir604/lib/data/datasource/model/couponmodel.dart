class CouponModel {
  String? couponId;
  String? couponName;
  String? couponCount;
  String? couponDiscount;
  String? couponExpiredate;

  CouponModel(
      {this.couponId,
      this.couponName,
      this.couponCount,
      this.couponDiscount,
      this.couponExpiredate});

  String get codeLabel {
    final raw = couponName?.trim() ?? '';
    return raw.isEmpty ? 'CODE' : raw;
  }

  String get discountLabel {
    final raw = couponDiscount?.trim() ?? '';
    if (raw.isEmpty) return '0%';

    final sanitized = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    final parsed = double.tryParse(sanitized);
    if (parsed == null) return raw;

    final display =
        parsed % 1 == 0 ? parsed.toStringAsFixed(0) : parsed.toStringAsFixed(1);
    return '$display%';
  }

  int get remainingUses {
    final raw = couponCount?.trim() ?? '';
    if (raw.isEmpty) return 0;

    final sanitized = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(sanitized) ?? 0;
  }

  DateTime? get expireDate {
    final raw = couponExpiredate?.trim() ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool get isExpired {
    final raw = couponExpiredate?.trim() ?? '';
    if (raw.isEmpty) return false;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return false;

    final normalized = raw.contains('T') || raw.contains(':')
        ? parsed
        : DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
    return normalized.isBefore(DateTime.now());
  }

  bool get isActive {
    return !isExpired &&
        (couponCount == null ||
            couponCount!.trim().isEmpty ||
            remainingUses > 0);
  }

  CouponModel.fromJson(Map<String, dynamic> json) {
    // Some backends return numeric values (int) for these fields.
    // Convert safely to String to avoid type errors when assigning to String? fields.
    couponId = json['coupon_id']?.toString();
    couponName = json['coupon_name']?.toString();
    couponCount = json['coupon_count']?.toString();
    couponDiscount = json['coupon_discount']?.toString();
    couponExpiredate = json['coupon_expiredate']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['coupon_id'] = couponId;
    data['coupon_name'] = couponName;
    data['coupon_count'] = couponCount;
    data['coupon_discount'] = couponDiscount;
    data['coupon_expiredate'] = couponExpiredate;
    return data;
  }
}
