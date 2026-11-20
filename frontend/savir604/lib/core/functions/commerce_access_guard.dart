import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/local_json_cache.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/itemsmodel.dart';

class CommerceAccessGuard {
  CommerceAccessGuard._();

  static Future<void> openRestaurant({
    required String restaurantId,
    Map<String, dynamic>? arguments,
    Map<String, String>? parameters,
  }) async {
    if (restaurantId.trim().isEmpty) {
      return;
    }
    if (!await _canOpenCommerceTarget()) {
      return;
    }

    Get.toNamed(
      AppRoutes.restaurantDetails,
      arguments: arguments ?? {'restaurant_id': restaurantId},
      parameters: parameters ?? {'restaurant_id': restaurantId},
    );
  }

  static Future<void> openProduct({
    required String itemId,
    Map<String, dynamic>? arguments,
    Map<String, String>? parameters,
  }) async {
    if (itemId.trim().isEmpty) {
      return;
    }
    if (!await _canOpenCommerceTarget()) {
      return;
    }

    final rawItem = arguments?['itemsmodel'];
    final item = rawItem is ItemsModel ? rawItem : null;
    final categoryText =
        '${item?.categoriesNameEn ?? ''} ${item?.categoriesNameAr ?? ''}'
            .toLowerCase();
    final looksLikeFreshProduce = categoryText.contains('fresh') ||
        categoryText.contains('fruit') ||
        categoryText.contains('vegetable') ||
        categoryText.contains('\u0641\u0627\u0643\u0647') ||
        categoryText.contains('\u062e\u0636\u0631');
    final isStoreProduct = arguments?['vendor_type']?.toString().toLowerCase() ==
            'store' ||
        item?.vendorType?.toLowerCase() == 'store' ||
        looksLikeFreshProduce ||
        (item?.productType?.trim().isNotEmpty == true &&
            item?.productType != 'food');

    Get.toNamed(
      isStoreProduct ? AppRoutes.productdetails : AppRoutes.foodItemDetails,
      arguments: arguments ?? {'item_id': itemId},
      parameters: parameters ?? {'item_id': itemId},
    );
  }

  static Future<bool> _canOpenCommerceTarget() async {
    if (Get.isDialogOpen == true) {
      return false;
    }

    final services = Get.find<MyServices>();
    final isArabic = Get.locale?.languageCode == 'ar';
    final userId = services.sharedPreferences.getInt('id') ?? 0;
    final isGuest = services.hasGuestSession || userId <= 0;

    if (isGuest) {
      await _showRequiredDialog(
        title: isArabic ? 'تسجيل الدخول مطلوب' : 'Sign-in required',
        message: isArabic
            ? 'يرجى تسجيل الدخول أولًا حتى نتمكن من ربط عنوانك وعرض المطاعم والمنتجات القريبة منك فقط.'
            : 'Please sign in first so we can attach your address and show nearby restaurants and products only.',
        actionLabel: isArabic ? 'تسجيل الدخول' : 'Sign in',
        cancelLabel: isArabic ? 'إلغاء' : 'Cancel',
        onAction: () => Get.toNamed(AppRoutes.login),
      );
      return false;
    }

    final hasAddress = DeliverySelectionStore.readLatitude(
              services.sharedPreferences,
            ) !=
        null &&
        DeliverySelectionStore.readLongitude(services.sharedPreferences) != null;

    if (!hasAddress) {
      await _showRequiredDialog(
        title: isArabic ? 'أضف عنوانك أولًا' : 'Add your address first',
        message: isArabic
            ? 'نُظهر المطاعم والمنتجات القريبة فقط بحسب عنوانك، لذلك نحتاج إلى حفظ عنوان التسليم قبل المتابعة.'
            : 'We only show nearby restaurants and products based on your address, so please save a delivery address first.',
        actionLabel: isArabic ? 'إضافة العنوان' : 'Add address',
        cancelLabel: isArabic ? 'لاحقًا' : 'Later',
        onAction: () => Get.toNamed(AppRoutes.addressadddetails),
      );
      return false;
    }

    return true;
  }

  static Future<void> _showRequiredDialog({
    required String title,
    required String message,
    required String actionLabel,
    required String cancelLabel,
    required VoidCallback onAction,
  }) async {
    final context = Get.context ?? Get.overlayContext;
    final textTheme = context == null ? TextTheme() : Theme.of(context).textTheme;

    await Get.dialog<void>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Get.theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              onAction();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
