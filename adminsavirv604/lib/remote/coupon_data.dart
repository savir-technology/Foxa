import 'dart:convert';

import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/model/coupon_model.dart';

class CouponData {
  static const String _baseUrl =
      '${DashboardApiConfig.dashBaseUrl}/vendor/promotions';
  static const String _listUrl = '$_baseUrl/get_coupons.php';
  static const String _saveUrl = '$_baseUrl/save_coupon.php';
  static const String _deleteUrl = '$_baseUrl/delete_coupon.php';

  Future<List<CouponModel>> fetchCoupons() async {
    final response = await DashboardApiClient.getUrl(_listUrl);
    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل الكوبونات');
    }

    final decoded = json.decode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['status'] != 'success') {
      throw Exception(decoded is Map
          ? (decoded['message']?.toString() ?? 'تعذر تحميل الكوبونات')
          : 'تعذر تحميل الكوبونات');
    }

    final list = decoded['data'];
    if (list is! List) {
      return <CouponModel>[];
    }

    return list
        .whereType<Map>()
        .map((entry) => CouponModel.fromJson(entry.cast<String, dynamic>()))
        .toList();
  }

  Future<String?> saveCoupon({
    int? couponId,
    required String couponName,
    required int couponCount,
    required DateTime couponExpireDate,
    required int couponDiscount,
  }) async {
    final response = await DashboardApiClient.postUrl(
      _saveUrl,
      body: {
        if (couponId != null) 'coupon_id': couponId.toString(),
        'coupon_name': couponName,
        'coupon_count': couponCount.toString(),
        'coupon_expiredate': couponExpireDate.toIso8601String(),
        'coupon_discount': couponDiscount.toString(),
      },
    );
    final decoded = DashboardApiClient.decodeJson(response);
    if (decoded is Map && decoded['status'] == 'success') {
      return decoded['message']?.toString();
    }
    return decoded is Map ? decoded['message']?.toString() : null;
  }

  Future<String?> deleteCoupon(int couponId) async {
    final response = await DashboardApiClient.postUrl(
      _deleteUrl,
      body: {'coupon_id': couponId.toString()},
    );
    final decoded = DashboardApiClient.decodeJson(response);
    if (decoded is Map && decoded['status'] == 'success') {
      return decoded['message']?.toString();
    }
    return decoded is Map ? decoded['message']?.toString() : null;
  }
}
