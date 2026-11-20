// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/cartmodel.dart';
import 'package:tks/data/datasource/model/couponmodel.dart';
import 'package:tks/data/datasource/remote/cart/cart_data.dart';

class CartVendorGroup {
  CartVendorGroup({
    required this.vendorId,
    required this.storeName,
    required this.vendorName,
    required this.vendorLogo,
  });

  final String vendorId;
  final String storeName;
  final String vendorName;
  final String vendorLogo;
  final List<CartModel> items = [];

  String get displayName {
    if (storeName.trim().isNotEmpty) {
      return storeName.trim();
    }
    if (vendorName.trim().isNotEmpty) {
      return vendorName.trim();
    }
    return vendorId.trim().isNotEmpty ? 'Restaurant #$vendorId' : 'Restaurant';
  }

  String get subtitle {
    if (items.isEmpty) {
      return '';
    }
    final totalItems = items.fold<int>(
      0,
      (sum, item) => sum + (int.tryParse(item.countitems ?? '0') ?? 0),
    );
    final isArabic = Get.locale?.languageCode == 'ar';
    if (isArabic) {
      return totalItems == 1 ? 'عنصر واحد' : '$totalItems عناصر';
    }
    return totalItems == 1 ? '1 item' : '$totalItems items';
  }

  double get subtotal => items.fold<double>(
        0,
        (sum, item) => sum + (double.tryParse(item.lineTotal ?? '0') ?? 0),
      );

  int get itemCount => items.fold<int>(
        0,
        (sum, item) => sum + (int.tryParse(item.countitems ?? '0') ?? 0),
      );

  bool get hasLogo => vendorLogo.trim().isNotEmpty;
}

class CartController extends GetxController {
  TextEditingController? controllercoupon;
  CartData cartData = CartData(Get.find());
  double discountcoupon = 0.0;
  String? couponname;
  String? couponid;
  late StatusRequest statusRequest;
  CouponModel? couponModel;
  bool isCheckingCoupon = false;
  MyServices myServices = Get.find();
  List<CartModel> data = [];
  double priceorders = 0.0;
  int totalcountitems = 0;

  List<CartVendorGroup> get vendorGroups {
    final groups = <String, CartVendorGroup>{};
    for (final item in data) {
      final vendorId = item.resolvedVendorId.isNotEmpty
          ? item.resolvedVendorId
          : 'vendor_${item.cartId ?? item.itemsId ?? groups.length}';
      final group = groups.putIfAbsent(
        vendorId,
        () => CartVendorGroup(
          vendorId: vendorId,
          storeName: item.storeName ?? '',
          vendorName: item.vendorName ?? '',
          vendorLogo: item.vendorLogo ?? '',
        ),
      );
      group.items.add(item);
    }
    return groups.values.toList();
  }

  int get restaurantCount => vendorGroups.length;

  bool get hasMultipleRestaurants => restaurantCount > 1;

  Future<void> add(String itemsid, {String? cartid, double? weightStep}) async {
    statusRequest = StatusRequest.loading;
    update();

    final response = await cartData.addCart(
      myServices.sharedPreferences.getInt("id")!.toString(),
      itemsid,
      extraData: {
        if (cartid != null) 'cartid': cartid,
        if (weightStep != null) 'quantity_weight': weightStep,
      },
    );
    print("=============================== Controller $response ");
    statusRequest = handlingData(response);

    if (StatusRequest.success == statusRequest) {
      if (response['status'] == "success") {
        Get.rawSnackbar(
          title: 'Notice'.tr,
          messageText: Text('Item added to cart'.tr),
        );
        await view();
      } else {
        statusRequest = StatusRequest.failure;
      }
    }
    update();
  }

  Future<void> goToPageCheckout() async {
    if (data.isEmpty) {
      Get.snackbar('Notice'.tr, 'Cart is empty'.tr);
      return;
    }

    final result = await Get.toNamed(
      AppRoutes.checkout,
      arguments: {
        "couponid": couponid ?? "0",
        "priceorder": priceorders.toString(),
        "discountcoupon": discountcoupon.toString(),
      },
    );

    if (result == true) {
      clearCart(showMessage: false);
    }
  }

  void clearCart({bool showMessage = true}) {
    data.clear();
    totalcountitems = 0;
    priceorders = 0.0;
    controllercoupon?.clear();
    couponModel = null;
    discountcoupon = 0.0;
    couponname = null;
    couponid = null;
    update();

    if (showMessage) {
      Get.snackbar('Notice'.tr, 'All items were removed from cart'.tr);
    }
  }

  double getTotalPrice() {
    return getFinalTotal();
  }

  double getSubtotal() {
    double subtotal = 0.0;
    for (final item in data) {
      final lineSubtotal = double.tryParse(item.lineSubtotal ?? '0.0') ?? 0.0;
      subtotal += lineSubtotal;
    }
    return subtotal;
  }

  double getTotalAfterItemDiscounts() {
    double total = 0.0;
    for (final item in data) {
      final lineTotal = double.tryParse(item.lineTotal ?? '0.0') ?? 0.0;
      total += lineTotal;
    }
    return total;
  }

  double getTotalItemsDiscountAmount() {
    double discount = 0.0;
    for (final item in data) {
      discount += double.tryParse(item.lineDiscount ?? '0.0') ?? 0.0;
    }
    return discount;
  }

  double getCouponDiscountAmount() {
    final afterItems = getTotalAfterItemDiscounts();
    if (discountcoupon > 0) {
      return afterItems * (discountcoupon / 100);
    }
    return 0.0;
  }

  double getFinalTotal() {
    final afterItems = getTotalAfterItemDiscounts();
    final couponAmt = getCouponDiscountAmount();
    return afterItems - couponAmt;
  }

  Future<void> delete({String? itemsid, String? cartid, double? weightStep}) async {
    statusRequest = StatusRequest.loading;
    update();

    final response = await cartData.deleteCart(
      myServices.sharedPreferences.getInt("id")!.toString(),
      itemsid: itemsid,
      cartid: cartid,
      extraData: weightStep == null ? null : {'quantity_weight': weightStep},
    );
    print("=============================== Controller $response ");
    statusRequest = handlingData(response);

    if (StatusRequest.success == statusRequest) {
      if (response['status'] == "success") {
        Get.rawSnackbar(
          title: "Notice",
          messageText: const Text("Item removed from cart"),
        );
        await view();
      } else {
        statusRequest = StatusRequest.failure;
      }
    }
    update();
  }

  Future<void> checkcoupon() async {
    if (controllercoupon?.text.trim().isEmpty ?? true) return;
    isCheckingCoupon = true;
    update();

    final response = await cartData.checkCoupon(controllercoupon!.text.trim());
    print('checkcoupon response status: ${response.runtimeType}');
    print('checkcoupon response body: $response');
    statusRequest = handlingData(response);

    if (StatusRequest.success == statusRequest) {
      if (response['status'] == "success") {
        final datacoupon = response['data'];
          if (datacoupon == null) {
          Get.snackbar('Warning'.tr, 'Coupon response has empty data'.tr);
        } else if (datacoupon is Map<String, dynamic>) {
          couponModel = CouponModel.fromJson(datacoupon);
        } else {
          try {
            final coerced = Map<String, dynamic>.from(datacoupon);
            couponModel = CouponModel.fromJson(coerced);
          } catch (_) {
            Get.snackbar('Warning'.tr, 'Unexpected coupon data format'.tr);
          }
        }

        if (couponModel == null) {
          Get.snackbar('Warning'.tr, 'Coupon parsing failed'.tr);
        } else {
          final rawDiscount = couponModel!.couponDiscount ?? '0';
          final sanitized = rawDiscount.replaceAll(RegExp(r'[^0-9\.]'), '');
          discountcoupon = double.tryParse(sanitized) ?? 0.0;
          couponname = couponModel!.couponName;
          couponid = couponModel!.couponId;
          Get.snackbar('Coupon applied'.tr, '$couponname - $discountcoupon%');
        }
        update();
      } else {
        discountcoupon = 0.0;
        couponname = null;
        couponid = null;
        Get.snackbar('Warning'.tr, 'Coupon not valid'.tr);
        update();
      }
    }

    isCheckingCoupon = false;
    update();
  }

  void removeCoupon() {
    couponModel = null;
    discountcoupon = 0.0;
    couponname = null;
    couponid = null;
    controllercoupon?.clear();
    Get.snackbar('Coupon removed'.tr, 'Coupon has been cleared'.tr);
    update();
  }

  void resetVarCart() {
    totalcountitems = 0;
    priceorders = 0.0;
    data.clear();
  }

  void refreshPage() {
    resetVarCart();
    view();
  }

  Future<void> view() async {
    statusRequest = StatusRequest.loading;
    update();
    final response = await cartData.viewCart(
      myServices.sharedPreferences.getInt("id")!.toString(),
    );
    print("=============================== Controller $response ");
    statusRequest = handlingData(response);

    if (StatusRequest.success == statusRequest) {
      if (response['status'] == "success") {
        final List dataresponse = response['datacart'];
        final Map dataresponsecountprice = response['countprice'];

        data.clear();
        data.addAll(dataresponse.map((e) => CartModel.fromJson(e)));
        final totalCountText =
            dataresponsecountprice['totalcount']?.toString() ?? '0';
        // Weight-based products return decimal totals (for example 13.500kg),
        // while the cart badge still expects an integer.
        totalcountitems = int.tryParse(totalCountText) ??
            (double.tryParse(totalCountText)?.round() ?? 0);
        priceorders = double.tryParse(
              dataresponsecountprice['totalprice']?.toString() ?? '0',
            ) ??
            0.0;
      } else {
        statusRequest = StatusRequest.failure;
      }
    }
    update();
  }

  @override
  void onInit() {
    controllercoupon = TextEditingController();
    view();
    super.onInit();
  }
}
