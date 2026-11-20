import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/functions/commerce_access_guard.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/data/datasource/model/aleppo_home_model.dart';
import 'package:tks/data/datasource/model/couponmodel.dart';
import 'package:tks/data/datasource/remote/cart/cart_data.dart';
import 'package:tks/data/datasource/remote/home/homedata.dart';
import 'package:tks/data/datasource/remote/offers/offers_data.dart';

class OffersController extends GetxController {
  OffersController({
    HomeData? homeData,
    OffersData? offersData,
    CartData? cartData,
  })  : homeData = homeData ?? Get.put(HomeData(Get.find())),
        offersData = offersData ?? OffersData(Get.find()),
        cartData = cartData ?? CartData(Get.find());

  final HomeData homeData;
  final OffersData offersData;
  final CartData cartData;

  final TextEditingController couponController = TextEditingController();
  final GlobalKey couponsSectionKey = GlobalKey();
  final GlobalKey specialOffersSectionKey = GlobalKey();

  StatusRequest statusRequest = StatusRequest.none;
  List<CouponModel> coupons = [];
  List<AleppoHomeBannerModel> specialOffers = [];
  CouponModel? appliedCoupon;
  bool isApplyingCoupon = false;
  bool isRefreshing = false;
  int selectedTab = 0;

  bool get hasContent => coupons.isNotEmpty || specialOffers.isNotEmpty;
  bool get hasCoupons => coupons.isNotEmpty;
  bool get hasSpecialOffers => specialOffers.isNotEmpty;
  bool get isArabic => Get.locale?.languageCode == 'ar';

  String localize(String ar, String en, {String fallback = ''}) {
    if (isArabic) {
      return ar.trim().isNotEmpty
          ? ar.trim()
          : en.trim().isNotEmpty
              ? en.trim()
              : fallback;
    }
    return en.trim().isNotEmpty
        ? en.trim()
        : ar.trim().isNotEmpty
            ? ar.trim()
            : fallback;
  }

  Future<void> fetchOffers({bool refresh = false}) async {
    final shouldShowLoading = !refresh || !hasContent;
    if (shouldShowLoading) {
      statusRequest = StatusRequest.loading;
    } else {
      isRefreshing = true;
    }
    update();

    try {
      final responses = await Future.wait<dynamic>([
        offersData.getCoupons(),
        homeData.getData(),
      ]);

      final couponResponse = responses[0];
      final homeResponse = responses[1];

      final couponStatus = handlingData(couponResponse);
      final homeStatus = handlingData(homeResponse);

      if (couponStatus == StatusRequest.success) {
        coupons = _parseCoupons(couponResponse)
            .where((coupon) => coupon.isActive)
            .toList();
        appliedCoupon = _syncAppliedCoupon(appliedCoupon, coupons);
      }

      if (homeStatus == StatusRequest.success) {
        specialOffers = _parseSpecialOffers(homeResponse);
      }

      if (hasContent ||
          couponStatus == StatusRequest.success ||
          homeStatus == StatusRequest.success) {
        statusRequest = StatusRequest.success;
      } else if (couponStatus != StatusRequest.success) {
        statusRequest = couponStatus;
      } else if (homeStatus != StatusRequest.success) {
        statusRequest = homeStatus;
      } else {
        statusRequest = StatusRequest.failure;
      }
    } catch (_) {
      if (!hasContent) {
        statusRequest = StatusRequest.serverfailure;
      }
    } finally {
      isRefreshing = false;
      update();
    }
  }

  void selectTab(int index) {
    selectedTab = index;
    update();

    final key = index == 0 ? couponsSectionKey : specialOffersSectionKey;
    final context = key.currentContext;
    if (context != null) {
      unawaited(
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.08,
        ),
      );
    }
  }

  Future<void> applyCoupon() async {
    final code = couponController.text.trim();
    if (code.isEmpty) {
      Get.snackbar(
        localize('تنبيه', 'Warning', fallback: 'Warning'),
        localize(
          'أدخل كود الكوبون أولاً',
          'Please enter a coupon code first',
        ),
      );
      return;
    }

    isApplyingCoupon = true;
    update();

    try {
      final response = await cartData.checkCoupon(code);
      final status = handlingData(response);

      if (status == StatusRequest.success &&
          response is Map &&
          response['status'] == 'success') {
        final coupon = _couponFromResponse(response);
        if (coupon != null && coupon.isActive) {
          appliedCoupon = coupon;
          couponController.text = coupon.codeLabel;
          Get.snackbar(
            localize('تم تفعيل الكوبون', 'Coupon applied'),
            '${coupon.codeLabel} - ${coupon.discountLabel}',
          );
        } else {
          appliedCoupon = null;
          Get.snackbar(
            localize('تحذير', 'Warning'),
            localize(
              'تنسيق بيانات الكوبون غير متوقع',
              'Unexpected coupon data format',
            ),
          );
        }
      } else {
        appliedCoupon = null;
        Get.snackbar(
          localize('تحذير', 'Warning'),
          localize('الكوبون غير صالح', 'Coupon not valid'),
        );
      }
    } catch (_) {
      appliedCoupon = null;
      Get.snackbar(
        localize('تحذير', 'Warning'),
        localize(
          'تعذر التحقق من الكوبون حالياً',
          'Unable to validate the coupon right now',
        ),
      );
    } finally {
      isApplyingCoupon = false;
      update();
    }
  }

  void clearAppliedCoupon() {
    appliedCoupon = null;
    update();
  }

  void openBanner(AleppoHomeBannerModel banner) {
    final target = banner.ctaTarget.trim();
    final restaurantId = int.tryParse(target) ?? _extractRestaurantId(target);
    if (restaurantId != null && restaurantId > 0) {
      unawaited(
        CommerceAccessGuard.openRestaurant(
          restaurantId: restaurantId.toString(),
          arguments: {'restaurant_id': restaurantId.toString()},
          parameters: {'restaurant_id': restaurantId.toString()},
        ),
      );
      return;
    }

    Get.snackbar(
      localize(banner.titleAr, banner.titleEn, fallback: 'Offer'),
      localize(
        'سيتم ربط هذا العرض من لوحة الإدارة.',
        'This offer will be linked from the admin panel.',
      ),
    );
  }

  int? _extractRestaurantId(String target) {
    final digits = RegExp(r'(\d+)').firstMatch(target)?.group(1);
    return digits == null ? null : int.tryParse(digits);
  }

  List<CouponModel> _parseCoupons(dynamic response) {
    final records = _extractRecords(response);
    return records.map(CouponModel.fromJson).toList();
  }

  List<AleppoHomeBannerModel> _parseSpecialOffers(dynamic response) {
    final model = _parseHomeModel(response);
    return model?.banners ?? const <AleppoHomeBannerModel>[];
  }

  AleppoHomeModel? _parseHomeModel(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        return AleppoHomeModel.fromJson(Map<String, dynamic>.from(data));
      }

      return AleppoHomeModel.fromJson(response);
    }

    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      final data = map['data'];
      if (data is Map) {
        return AleppoHomeModel.fromJson(Map<String, dynamic>.from(data));
      }
      return AleppoHomeModel.fromJson(map);
    }

    return null;
  }

  List<Map<String, dynamic>> _extractRecords(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      final candidates = [map['data'], map['coupons'], map['items']];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }

      if (map.isNotEmpty) {
        return [map];
      }
    }

    return const <Map<String, dynamic>>[];
  }

  CouponModel? _couponFromResponse(dynamic response) {
    if (response is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(response);
    final data = map['data'];

    if (data is Map<String, dynamic>) {
      return CouponModel.fromJson(data);
    }

    if (data is Map) {
      return CouponModel.fromJson(Map<String, dynamic>.from(data));
    }

    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map<String, dynamic>) {
        return CouponModel.fromJson(first);
      }
      if (first is Map) {
        return CouponModel.fromJson(Map<String, dynamic>.from(first));
      }
    }

    return null;
  }

  CouponModel? _syncAppliedCoupon(
    CouponModel? current,
    List<CouponModel> availableCoupons,
  ) {
    if (current == null) {
      return null;
    }

    final code = current.codeLabel.toLowerCase();
    for (final coupon in availableCoupons) {
      if (coupon.codeLabel.toLowerCase() == code) {
        return coupon;
      }
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    fetchOffers();
  }

  @override
  void onClose() {
    couponController.dispose();
    super.onClose();
  }
}
