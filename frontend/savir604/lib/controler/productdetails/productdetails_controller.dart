import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/cart/cart_controller.dart';
import 'package:tks/controler/home/home_controller.dart';
import 'package:tks/controler/items/items_controller.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/item_image_model.dart';
import 'package:tks/data/datasource/model/itemsmodel.dart';
import 'package:tks/data/datasource/model/product_variant_model.dart';
import 'package:tks/data/datasource/model/ratingmodel.dart';
import 'package:tks/data/datasource/remote/cart/cart_data.dart';
import 'package:tks/data/datasource/remote/items/item_images_data.dart';
import 'package:tks/data/datasource/remote/items/product_variants_data.dart';
import 'package:tks/data/datasource/remote/ratings/ratings_data.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class ProductDetailsController extends GetxController {}

class ProductDetailsControllerImp extends ProductDetailsController {
  late ItemsModel itemsModel;

  final CartData cartData = CartData(Get.find());
  final ItemImagesData imagesData = ItemImagesData(Get.find());
  final ProductVariantsData variantsData = ProductVariantsData(Get.find());
  final RatingsData ratingsData = RatingsData(Get.find());
  final MyServices myServices = Get.find();
  final PageController imagesPageController = PageController();
  final ScrollController thumbnailsScrollController = ScrollController();
  final TextEditingController ratingCommentController = TextEditingController();

  StatusRequest statusRequest = StatusRequest.loading;
  StatusRequest imagesStatus = StatusRequest.loading;
  StatusRequest variantsStatus = StatusRequest.loading;
  StatusRequest ratingsStatus = StatusRequest.loading;

  int currentImageIndex = 0;
  int countitems = 0;
  List<ItemImageModel> images = [];
  List<ProductVariantModel> variants = [];
  List<VariantColorOption> availableColors = [];
  List<VariantSizeOption> availableSizes = [];
  List<ProductAttribute> attributes = [];
  final Map<String, String> selectedAttributeValues = {};
  bool isFavorite = false;
  bool isAddingSelectedVariant = false;
  bool isSubmittingRating = false;
  double averageRating = 0;
  int ratingsCount = 0;
  int ratingPercentage = 0;
  double selectedUserRating = 0;
  String? userRatingId;
  bool canSubmitRating = false;
  List<RatingModel> ratings = [];

  String? selectedColorId;
  String? selectedSizeId;
  String? selectedVariantId;
  double selectedFreshWeight = 1.0;

  bool get isArabic => Get.locale?.languageCode == 'ar';
  bool get isStoreProduct =>
      itemsModel.vendorType?.toLowerCase() == 'store' ||
      (itemsModel.productType?.isNotEmpty == true &&
          itemsModel.productType != 'food');
  bool get isFreshFoodProduct {
    final type = itemsModel.productType?.trim().toLowerCase();
    if (type == 'fresh_food' || type == 'fresh-food' || type == 'fresh') {
      return true;
    }

    // Older catalogue rows were saved as `food`. Recognize fresh-produce
    // products from the store metadata and their selling characteristics so
    // they never fall back to the generic color/size template.
    final storeType = itemsModel.vendorType?.trim().toLowerCase();
    final storeCategory = itemsModel.storeCategory?.trim().toLowerCase();
    final category = '${itemsModel.storeCategory ?? ''} '
        '${itemsModel.categoriesNameEn ?? ''} ${itemsModel.categoriesNameAr ?? ''}'
        .toLowerCase();
    final freshCategory = category.contains('fresh') ||
        category.contains('fruit') ||
        category.contains('vegetable') ||
        category.contains('tomato') ||
        category.contains('\u0641\u0627\u0643\u0647') ||
        category.contains('\u062e\u0636\u0631') ||
        category.contains('\u0637\u0645\u0627\u0637\u0645');
    final weightUnit = ['kg', 'g', '\u0643\u064a\u0644\u0648', '\u062c\u0631\u0627\u0645']
        .contains(itemsModel.stockUnit?.trim().toLowerCase());
    final freshAttributes = attributes.any((attribute) {
      final name = '${attribute.nameAr} ${attribute.nameEn}'.toLowerCase();
      return name.contains('origin') ||
          name.contains('storage') ||
          name.contains('sale') ||
          name.contains('\u0645\u0646\u0634\u0627') ||
          name.contains('\u062d\u0641\u0638');
    });
    final explicitFreshType = type == 'fresh_food' ||
        type == 'fresh-food' ||
        type == 'fresh';
    return explicitFreshType ||
        (storeType == 'store' && storeCategory == 'fresh_food') ||
        (storeType == 'store' && freshCategory) ||
        (storeType == 'store' && weightUnit) ||
        freshCategory ||
        (weightUnit && freshAttributes);
  }
  String get stockUnit =>
      selectedVariant?.unit.isNotEmpty == true
          ? selectedVariant!.unit
          : (itemsModel.stockUnit ?? 'piece');
  String stockUnitLabel(bool arabic) {
    switch (stockUnit) {
      case 'ml':
        return arabic ? 'مل' : 'ml';
      case 'kg':
        return arabic ? 'كيلو' : 'kg';
      case 'g':
        return arabic ? 'جرام' : 'g';
      case 'pack':
        return arabic ? 'عبوة' : 'pack';
      default:
        return arabic ? 'قطعة' : 'piece';
    }
  }
  String get variantSectionTitle =>
      isStoreProduct ? 'خصائص المنتج' : 'اختيار اللون والمقاس';
  String get variantSectionTitleEn =>
      isStoreProduct ? 'Product options' : 'Choose color and size';
  bool get isPerfumeProduct {
    if (itemsModel.productType?.trim().toLowerCase() == 'perfume') return true;
    return attributes.any((attribute) {
      final name = '${attribute.nameAr} ${attribute.nameEn}'.toLowerCase();
      return name.contains('عطر') ||
          name.contains('perfume') ||
          name.contains('note') ||
          name.contains('sillage') ||
          name.contains('longevity') ||
          name.contains('bottle');
    });
  }
  bool get isReviewMode =>
      (Get.parameters['mode'] ?? '').toString().toLowerCase() == 'review';

  @override
  void onInit() async {
    itemsModel = Get.arguments['itemsmodel'];
    if (isReviewMode) {
      statusRequest = StatusRequest.success;
      countitems = 0;
    } else {
      await getVariants();
      await getImages(colorId: selectedColorId);
      await intialData();
    }
    await fetchRatings();
    super.onInit();
  }

  Future<void> getImages({String? colorId}) async {
    imagesStatus = StatusRequest.loading;
    final response = await imagesData.getImages(
      itemsModel.itemsId!,
      colorId: colorId,
    );
    imagesStatus = handlingData(response);

    if (imagesStatus == StatusRequest.success &&
        response['status'] == 'success') {
      images = (response['data'] as List)
          .map((e) => ItemImageModel.fromJson(e))
          .take(isFreshFoodProduct ? 1 : 999999)
          .toList();
      currentImageIndex = 0;
      try {
        imagesPageController.jumpToPage(0);
      } catch (_) {}
    } else {
      images = _fallbackGalleryImages();
    }
    update();
  }

  Future<void> getVariants() async {
    variantsStatus = StatusRequest.loading;
    update();

    final response = await variantsData.getVariants(itemsModel.itemsId!);
    variantsStatus = handlingData(response);

    final responseData = response['data'];
    final responseAttributes = response['attributes'];
    if (responseData is List) {
      variants = responseData
          .map((e) => ProductVariantModel.fromJson(e))
          .toList();
      availableColors = (response['colors'] as List? ?? const [])
          .map((e) => VariantColorOption.fromJson(e))
          .toList();
      availableSizes = (response['sizes'] as List? ?? const [])
          .map((e) => VariantSizeOption.fromJson(e))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      attributes = (responseAttributes as List? ?? const [])
          .whereType<Map>()
          .map((e) => ProductAttribute.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _bootstrapSelections();
    } else {
      variants = [];
      availableColors = [];
      availableSizes = [];
      attributes = [];
    }
    update();
  }

  Future<void> intialData() async {
    statusRequest = StatusRequest.loading;
    if (isReviewMode) {
      countitems = 0;
    } else {
      countitems = await getCountItems(itemsModel.itemsId!);
    }
    statusRequest = StatusRequest.success;
    averageRating = itemsModel.averageRatingValue;
    ratingsCount = itemsModel.ratingsCountValue;
    ratingPercentage = itemsModel.ratingPercentageValue;
    update();
  }

  Future<int> getCountItems(String itemsid) async {
    final userId = myServices.sharedPreferences.getInt('id');
    if (userId == null || userId <= 0) {
      return 0;
    }
    final response = await cartData.getCountCart(
      userId.toString(),
      itemsid,
    );

    statusRequest = handlingData(response);
    if (StatusRequest.success == statusRequest &&
        response['status'] == 'success') {
      return int.tryParse(response['data'].toString()) ?? 0;
    }
    return 0;
  }

  Future<void> selectColor(String colorId) async {
    selectedColorId = colorId;
    final sizeExists = variants.any(
      (variant) =>
          variant.colorId == selectedColorId &&
          variant.sizeId == selectedSizeId,
    );
    if (!sizeExists) {
      selectedSizeId = variants
          .firstWhereOrNull((variant) => variant.colorId == selectedColorId)
          ?.sizeId;
    }
    await getImages(colorId: selectedColorId);
    update();
  }

  Future<void> selectSize(String sizeId) async {
    selectedSizeId = sizeId;
    final previousColorId = selectedColorId;
    final colorExists = variants.any(
      (variant) =>
          variant.colorId == selectedColorId &&
          variant.sizeId == selectedSizeId,
    );
    if (!colorExists) {
      selectedColorId = variants
          .firstWhereOrNull((variant) => variant.sizeId == selectedSizeId)
          ?.colorId;
    }
    if (previousColorId != selectedColorId) {
      await getImages(colorId: selectedColorId);
      return;
    }
    update();
  }

  ProductVariantModel? get selectedVariant {
    if (isFreshFoodProduct) {
      return variants.firstWhereOrNull((variant) => variant.variantId == selectedVariantId) ?? variants.firstOrNull;
    }
    if (hasGenericAttributes && !hasLinkedAttributeVariants) {
      return variants.firstOrNull;
    }
    if (hasGenericAttributes &&
        (selectedColorId == null || selectedSizeId == null)) {
      final requiredAttributes =
          attributes.where((attribute) => attribute.required);
      if (requiredAttributes.any(
          (attribute) => !selectedAttributeValues.containsKey(attribute.id))) {
        return null;
      }
      return variants.firstWhereOrNull((variant) {
        final values = variant.attributeValues.map((value) => value.id).toSet();
        return selectedAttributeValues.values.every(values.contains);
      });
    }
    if (selectedColorId == null || selectedSizeId == null) return null;
    return variants.firstWhereOrNull((variant) =>
        variant.colorId == selectedColorId && variant.sizeId == selectedSizeId);
  }

  List<VariantSizeOption> get selectableSizes {
    if (selectedColorId == null) return availableSizes;
    final allowed = variants
        .where((variant) => variant.colorId == selectedColorId)
        .map((variant) => variant.sizeId)
        .toSet();
    return availableSizes.where((size) => allowed.contains(size.id)).toList();
  }

  List<VariantColorOption> get selectableColors {
    if (selectedSizeId == null) return availableColors;
    final allowed = variants
        .where((variant) => variant.sizeId == selectedSizeId)
        .map((variant) => variant.colorId)
        .toSet();
    return availableColors
        .where((color) => allowed.contains(color.id))
        .toList();
  }

  bool isColorSelectable(String colorId) {
    return variants.any((variant) => variant.colorId == colorId);
  }

  bool isSizeSelectable(String sizeId) {
    return variants.any((variant) => variant.sizeId == sizeId);
  }

  double get fallbackPriceAfterDiscount {
    final discountedPrice =
        double.tryParse(itemsModel.itemsDiscountPrice ?? '') ?? 0;
    if (discountedPrice > 0) {
      return discountedPrice;
    }
    final itemPrice = double.tryParse(itemsModel.itemsPrice ?? '0') ?? 0;
    final itemDiscount = double.tryParse(itemsModel.itemsDiscount ?? '0') ?? 0;
    return itemPrice - (itemPrice * (itemDiscount / 100));
  }

  double get selectedPrice {
    if (isFreshFoodProduct) return fallbackPriceAfterDiscount;
    return selectedVariant?.price ?? fallbackPriceAfterDiscount;
  }

  double get freshAvailableWeight =>
      double.tryParse(itemsModel.itemsCount ?? '0') ?? 0;

  void setFreshWeight(double weight) {
    if (!isFreshFoodProduct) return;
    selectedFreshWeight = weight.clamp(0.25, 1000).toDouble();
    update();
  }

  void changeFreshWeight(double delta) {
    if (!isFreshFoodProduct) return;
    setFreshWeight((selectedFreshWeight + delta).clamp(0.25, 1000).toDouble());
  }

  bool get hasVariants => variants.isNotEmpty;

  bool get hasGenericAttributes => attributes.isNotEmpty;

  bool get hasLinkedAttributeVariants =>
      variants.any((variant) => variant.attributeValues.isNotEmpty);

  void selectAttributeValue(String attributeId, String valueId) {
    selectedAttributeValues[attributeId] = valueId;
    update();
  }

  void selectVariant(String variantId) {
    selectedVariantId = variantId;
    update();
  }

  void selectAdjacentFreshVariant(int delta) {
    if (!isFreshFoodProduct || variants.isEmpty) return;
    final current = selectedVariant;
    final index = current == null ? 0 : variants.indexOf(current);
    final next = (index + delta).clamp(0, variants.length - 1);
    selectVariant(variants[next].variantId);
  }

  String attributeText(List<String> terms, {String fallback = ''}) {
    for (final attribute in attributes) {
      final haystack = '${attribute.nameAr} ${attribute.nameEn}'.toLowerCase();
      if (terms.any((term) => haystack.contains(term.toLowerCase()))) {
        final value = attribute.values
            .map((item) => item.displayName(isArabic))
            .where((item) => item.trim().isNotEmpty)
            .join('، ');
        if (value.isNotEmpty) return value;
      }
    }
    return fallback;
  }

  String attributeValueAt(int index, {String fallback = ''}) {
    if (index < 0 || index >= attributes.length) return fallback;
    final value = attributes[index].values
        .map((item) => item.displayName(isArabic))
        .where((item) => item.trim().isNotEmpty)
        .join('، ');
    return value.isNotEmpty ? value : fallback;
  }

  bool get isSelectedVariantOutOfStock {
    if (isFreshFoodProduct) {
      return selectedFreshWeight > freshAvailableWeight;
    }
    return selectedVariant != null && !selectedVariant!.inStock;
  }

  String get selectedImage {
    if (images.isNotEmpty) {
      final safeIndex = currentImageIndex.clamp(0, images.length - 1);
      return images[safeIndex].imgPath;
    }
    final variantImage = selectedVariant?.imageUrl ?? '';
    if (variantImage.isNotEmpty) {
      return variantImage;
    }
    return itemsModel.itemsImage ?? '';
  }

  bool get hasMultipleImages => images.length > 1;
  bool get hasRatings => ratings.isNotEmpty;
  int get currentUserId => myServices.sharedPreferences.getInt('id') ?? 0;
  bool get hasUserRating => userRatingId != null && userRatingId!.isNotEmpty;

  Future<void> selectImageAt(
    int index, {
    bool animatePage = true,
  }) async {
    if (index < 0 || index >= images.length) {
      return;
    }
    currentImageIndex = index;
    _scrollThumbnailIntoView(index);
    if (animatePage && imagesPageController.hasClients) {
      await imagesPageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
    update();
  }

  void onImagePageChanged(int index) {
    if (index < 0 || index >= images.length) {
      return;
    }
    currentImageIndex = index;
    _scrollThumbnailIntoView(index);
    update();
  }

  Future<void> addSelectedVariantToCart() async {
    if (hasVariants && selectedVariant == null) {
      Get.snackbar(
        isArabic ? 'اختيار غير مكتمل' : 'Incomplete selection',
        isArabic
            ? 'اختر اللون والمقاس قبل إضافة المنتج إلى السلة.'
            : 'Choose both color and size before adding the product to the cart.',
      );
      return;
    }

    if (isSelectedVariantOutOfStock) {
      Get.snackbar(
        isArabic ? 'غير متاح حالياً' : 'Currently unavailable',
        isArabic
            ? 'هذا الاختيار غير متوفر حالياً. اختر لوناً أو مقاساً آخر.'
            : (isFreshFoodProduct
                ? 'The selected quantity is greater than the available stock.'
                : 'This selection is currently unavailable. Please choose another one.'),
      );
      return;
    }

    final variant = selectedVariant;
    final configHash = md5
        .convert(
          utf8.encode(
            '${itemsModel.itemsId}|${variant?.variantId ?? 'default'}|${variant?.colorId ?? ''}|${variant?.sizeId ?? ''}|${isFreshFoodProduct ? selectedFreshWeight : ''}',
          ),
        )
        .toString();

    final payload = <String, dynamic>{
      'config_hash': configHash,
      if (variant != null && !isFreshFoodProduct) 'variantid': variant.variantId,
      if (variant != null && !isFreshFoodProduct) 'item_color': variant.colorName(isArabic),
      if (variant != null && !isFreshFoodProduct) 'item_size': variant.sizeName(isArabic),
      if (isFreshFoodProduct) 'quantity_weight': selectedFreshWeight,
      if (isFreshFoodProduct) 'cart_unit_price': selectedPrice,
      if (selectedAttributeValues.isNotEmpty)
        'cart_variant_attributes_json': jsonEncode(selectedAttributeValues),
    };

    final userId = currentUserId;
    if (userId <= 0) {
      Get.snackbar(
        isArabic ? 'سجّل الدخول أولاً' : 'Login required',
        isArabic
            ? 'يرجى تسجيل الدخول قبل إضافة المنتج إلى السلة.'
            : 'Please sign in before adding the product to your cart.',
      );
      return;
    }

    isAddingSelectedVariant = true;
    update();

    final response = await cartData.addCart(
      userId.toString(),
      itemsModel.itemsId!,
      extraData: payload,
    );

    isAddingSelectedVariant = false;

    if (response is Map) {
      statusRequest = handlingData(response);
      if (statusRequest == StatusRequest.success &&
          response['status'] == 'success') {
        countitems++;
        if (Get.isRegistered<CartController>()) {
          await Get.find<CartController>().view();
        } else {
          await Get.put(CartController()).view();
        }
        update();
        Get.snackbar(
          isArabic ? 'تمت الإضافة' : 'Added to cart',
          isArabic
              ? 'تمت إضافة المنتج إلى السلة بنجاح.'
              : 'The product was added to your cart successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    Get.snackbar(
      isArabic ? 'تعذر الإضافة' : 'Could not add item',
      isArabic
          ? 'حصلت مشكلة أثناء إضافة المنتج إلى السلة.'
          : 'Something went wrong while adding the product to the cart.',
    );
    update();
  }

  Future<void> fetchRatings() async {
    ratingsStatus = StatusRequest.loading;
    canSubmitRating = false;
    update();

    final response = await ratingsData.getRatings(
      itemId: itemsModel.itemsId!,
      userId: currentUserId.toString(),
    );
    ratingsStatus = handlingData(response);

    if (ratingsStatus == StatusRequest.success &&
        response['status'] == 'success') {
      averageRating =
          double.tryParse(response['average_rating'].toString()) ?? 0.0;
      ratingsCount = int.tryParse(response['total_reviews'].toString()) ?? 0;
      ratingPercentage =
          int.tryParse(response['rating_percentage'].toString()) ?? 0;
      canSubmitRating = response['can_rate'] == true ||
          response['can_rate'] == 1 ||
          response['can_rate']?.toString() == '1' ||
          response['can_rate']?.toString().toLowerCase() == 'true';
      ratings = ((response['ratings'] as List?) ?? [])
          .map((e) => RatingModel.fromJson(e))
          .toList();

      final userRating = response['user_rating'];
      if (userRating is Map) {
        userRatingId = userRating['rating_id']?.toString();
        selectedUserRating =
            double.tryParse(userRating['rating'].toString()) ?? 0.0;
        ratingCommentController.text = userRating['comment']?.toString() ?? '';
      } else {
        userRatingId = null;
        selectedUserRating = 0;
        ratingCommentController.clear();
      }

      itemsModel.averageRating = averageRating.toStringAsFixed(1);
      itemsModel.ratingsCount = ratingsCount.toString();
      itemsModel.ratingPercentage = ratingPercentage.toString();
      itemsModel.isTopRated =
          averageRating >= 4 && ratingsCount >= 3 ? '1' : '0';
      _notifyRatingConsumers();
    } else {
      ratings = [];
      averageRating = 0;
      ratingsCount = 0;
      ratingPercentage = 0;
      canSubmitRating = false;
      userRatingId = null;
      selectedUserRating = 0;
      ratingCommentController.clear();

      itemsModel.averageRating = '0.0';
      itemsModel.ratingsCount = '0';
      itemsModel.ratingPercentage = '0';
      itemsModel.isTopRated = '0';
      _notifyRatingConsumers();
    }
    update();
  }

  void setUserRating(double value) {
    selectedUserRating = value;
    update();
  }

  Future<void> submitRating() async {
    if (currentUserId <= 0) {
      Get.snackbar(
        isArabic ? 'سجل الدخول أولاً' : 'Login required',
        isArabic
            ? 'لازم تسجل دخول قبل إضافة تقييم أو تعليق.'
            : 'Please login before adding a rating or review.',
      );
      return;
    }

    if (!canSubmitRating) {
      Get.snackbar(
        isArabic ? 'بعد الاستلام فقط' : 'Delivery required',
        isArabic
            ? 'يمكنك تقييم المنتج والمطعم بعد استلام الطلب فقط.'
            : 'You can only rate this product and restaurant after your order is delivered.',
      );
      return;
    }

    if (selectedUserRating <= 0) {
      Get.snackbar(
        isArabic ? 'اختر التقييم' : 'Choose a rating',
        isArabic
            ? 'حدد عدد النجوم أولاً قبل إرسال رأيك.'
            : 'Pick your star rating before submitting your review.',
      );
      return;
    }

    isSubmittingRating = true;
    update();

    final response = hasUserRating
        ? await ratingsData.updateRating(
            ratingId: userRatingId!,
            userId: currentUserId.toString(),
            rating: selectedUserRating,
            comment: ratingCommentController.text.trim(),
          )
        : await ratingsData.addRating(
            itemId: itemsModel.itemsId!,
            userId: currentUserId.toString(),
            rating: selectedUserRating,
            comment: ratingCommentController.text.trim(),
          );

    isSubmittingRating = false;

    if (response is Map && response['status'] == 'success') {
      await fetchRatings();
      Get.snackbar(
        isArabic ? 'تم حفظ تقييمك' : 'Review saved',
        isArabic
            ? 'تم تحديث التقييم والتعليق بنجاح.'
            : 'Your rating and comment were saved successfully.',
      );
      return;
    }

    Get.snackbar(
      isArabic ? 'تعذر الحفظ' : 'Could not save review',
      isArabic
          ? 'حصلت مشكلة أثناء حفظ التقييم، حاول مرة أخرى.'
          : 'Something went wrong while saving your review.',
    );
    update();
  }

  Future<void> deleteUserRating() async {
    if (currentUserId <= 0 || !hasUserRating) {
      return;
    }

    isSubmittingRating = true;
    update();

    final response = await ratingsData.deleteRating(
      itemId: itemsModel.itemsId!,
      userId: currentUserId.toString(),
    );

    isSubmittingRating = false;

    if (response is Map && response['status'] == 'success') {
      await fetchRatings();
      Get.snackbar(
        isArabic ? 'تم حذف التقييم' : 'Review deleted',
        isArabic
            ? 'تم حذف تقييمك لهذا المنتج والمطعم.'
            : 'Your review for this product and restaurant was deleted.',
      );
      return;
    }

    Get.snackbar(
      isArabic ? 'تعذر الحذف' : 'Could not delete review',
      isArabic
          ? 'لم نتمكن من حذف التقييم الآن.'
          : 'We could not delete your review right now.',
    );
    update();
  }

  void toggleFavorite() {
    isFavorite = !isFavorite;
    update();
  }

  Future<void> share() async {
    final websiteUri = Uri.parse('https://savir-technology.com');
    final opened = await launchUrl(
      websiteUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      Get.snackbar(
        isArabic ? 'تعذر فتح الموقع' : 'Could not open website',
        isArabic ? 'حاول مرة أخرى بعد قليل.' : 'Please try again in a moment.',
      );
    }
  }

  @override
  void onClose() {
    imagesPageController.dispose();
    thumbnailsScrollController.dispose();
    ratingCommentController.dispose();
    super.onClose();
  }

  void _bootstrapSelections() {
    if (variants.isEmpty) return;
    selectedColorId ??= variants.first.colorId;
    selectedSizeId ??= variants
        .firstWhereOrNull((variant) => variant.colorId == selectedColorId)
        ?.sizeId;
  }

  void _scrollThumbnailIntoView(int index) {
    if (!thumbnailsScrollController.hasClients) {
      return;
    }

    const itemExtent = 86.0;
    final targetOffset = (index * itemExtent) - (itemExtent * 0.5);
    final maxOffset = thumbnailsScrollController.position.maxScrollExtent;
    final safeOffset = targetOffset.clamp(0.0, maxOffset);

    thumbnailsScrollController.animateTo(
      safeOffset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _notifyRatingConsumers() {
    if (Get.isRegistered<HomeControllerImp>()) {
      Get.find<HomeControllerImp>().syncProductRating(itemsModel);
    }
    if (Get.isRegistered<ItemsControllerImp>()) {
      Get.find<ItemsControllerImp>().syncProductRating(itemsModel);
    }
  }

  List<ItemImageModel> _fallbackGalleryImages() {
    final paths = isFreshFoodProduct
        ? itemsModel.galleryImagePaths.take(1).toList()
        : itemsModel.galleryImagePaths;
    return paths
        .asMap()
        .entries
        .map(
          (entry) => ItemImageModel(
            imgPath: entry.value,
            imgType: 'normal',
            imgOrder: entry.key,
            colorId: '',
          ),
        )
        .toList();
  }
}
