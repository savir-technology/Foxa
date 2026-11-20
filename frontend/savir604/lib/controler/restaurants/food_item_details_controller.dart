import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tks/controler/favorite/favorite_controler.dart';
import 'package:tks/controler/cart/cart_controller.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/food_item_details_model.dart';
import 'package:tks/data/datasource/model/itemsmodel.dart';
import 'package:tks/data/datasource/remote/cart/cart_data.dart';
import 'package:tks/data/datasource/remote/favorite/favorite_data.dart';
import 'package:tks/data/datasource/remote/restaurants/food_item_details_data.dart';

class FoodItemDetailsController extends GetxController {
  final FoodItemDetailsData remote = FoodItemDetailsData(Get.find());
  final CartData cartData = CartData(Get.find());
  final FavoriteData favoriteData = FavoriteData(Get.find());
  final MyServices myServices = Get.find();
  static const String _lastItemIdKey = 'last_food_item_id';

  late final FavoriteController favoriteController;

  StatusRequest statusRequest = StatusRequest.loading;
  FoodItemDetailsModel? details;
  final TextEditingController noteController = TextEditingController();
  final Map<String, Set<String>> selections = {};
  int quantity = 1;
  int currentImageIndex = 0;
  bool isAdding = false;
  bool isFavorite = false;

  bool get isArabic => Get.locale?.languageCode == 'ar';
  FoodItemModel? get item => details?.item;
  List<FoodModifierGroupModel> get groups =>
      details?.modifierGroups ?? const [];
  List<FoodModifierGroupModel> get ingredientGroups => groups
      .where((group) => group.groupType.toLowerCase() == 'ingredient')
      .toList();
  List<FoodModifierGroupModel> get extraGroups => groups
      .where((group) => group.groupType.toLowerCase() != 'ingredient')
      .toList();
  List<FoodSuggestedItemModel> get suggestedItems =>
      details?.suggestedItems ?? const [];
  List<String> get galleryImages {
    final detailsImages = details?.galleryImages
            .where((image) => image.trim().isNotEmpty)
            .toList() ??
        const <String>[];
    if (detailsImages.isNotEmpty) {
      return detailsImages;
    }
    final fallback = item?.imageUrl.trim() ?? '';
    return fallback.isNotEmpty ? [fallback] : const [];
  }

  double get rating => details?.rating ?? 0;
  int get reviewsCount => details?.reviewsCount ?? 0;

  List<FoodDetailTagModel> get displayTags {
    final backendTags = details?.tags
            .where((tag) =>
                tag.labelAr.trim().isNotEmpty || tag.labelEn.trim().isNotEmpty)
            .toList() ??
        const <FoodDetailTagModel>[];
    if (backendTags.isNotEmpty) {
      return backendTags.take(2).toList();
    }

    final fallback = <FoodDetailTagModel>[];
    final currentItem = item;
    final categoryAr = currentItem?.categoryNameAr.trim() ?? '';
    final categoryEn = currentItem?.categoryNameEn.trim() ?? '';
    if (categoryAr.isNotEmpty || categoryEn.isNotEmpty) {
      fallback.add(
        FoodDetailTagModel(
          labelAr: categoryAr.isNotEmpty ? categoryAr : categoryEn,
          labelEn: categoryEn.isNotEmpty ? categoryEn : categoryAr,
          iconKey: 'category',
        ),
      );
    }

    final modifierSource = extraGroups.isNotEmpty
        ? extraGroups.first
        : ingredientGroups.isNotEmpty
            ? ingredientGroups.first
            : (groups.isNotEmpty ? groups.first : null);
    if (modifierSource != null) {
      fallback.add(
        FoodDetailTagModel(
          labelAr: modifierSource.nameAr.trim().isNotEmpty
              ? modifierSource.nameAr
              : (isArabic ? 'إضافات' : 'Toppings'),
          labelEn: modifierSource.nameEn.trim().isNotEmpty
              ? modifierSource.nameEn
              : (isArabic ? 'إضافات' : 'Toppings'),
          iconKey: modifierSource.groupType.toLowerCase() == 'ingredient'
              ? 'ingredient'
              : 'toppings',
        ),
      );
    }

    if (fallback.length < 2 && currentItem != null) {
      fallback.add(
        FoodDetailTagModel(
          labelAr: currentItem.isAvailable ? 'متوفر الآن' : 'غير متوفر',
          labelEn: currentItem.isAvailable ? 'Available now' : 'Unavailable',
          iconKey: currentItem.isAvailable ? 'available' : 'unavailable',
        ),
      );
    }

    if (fallback.length < 2) {
      fallback.add(
        FoodDetailTagModel(
          labelAr: 'جاهز للطلب',
          labelEn: 'Ready to order',
          iconKey: 'ready',
        ),
      );
    }

    return fallback.take(2).toList();
  }

  @override
  void onInit() {
    favoriteController = Get.isRegistered<FavoriteController>()
        ? Get.find<FavoriteController>()
        : Get.put(FavoriteController());
    fetchDetails();
    super.onInit();
  }

  Future<void> fetchDetails() async {
    final itemId = _resolveItemId();
    if (itemId.isEmpty) {
      if (details != null) {
        statusRequest = StatusRequest.success;
        update();
        return;
      }

      statusRequest = StatusRequest.failure;
      update();
      Get.snackbar(
        isArabic ? 'تعذر فتح الصنف' : 'Unable to open item',
        isArabic
            ? 'لم يتم تمرير رقم الصنف إلى صفحة التفاصيل.'
            : 'The item id was not passed to the details page.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    myServices.sharedPreferences.setString(_lastItemIdKey, itemId);
    statusRequest = StatusRequest.loading;
    update();

    final response = await remote.getData(itemId);
    if (isClosed) {
      return;
    }
    statusRequest = handlingData(response);

    if (statusRequest == StatusRequest.success &&
        response['status'] == 'success' &&
        response['data'] is Map) {
      details = FoodItemDetailsModel.fromJson(
        Map<String, dynamic>.from(response['data']),
      );
      myServices.sharedPreferences.setString(_lastItemIdKey, itemId);
      currentImageIndex = 0;
      _bootstrapSelections();
      _syncFavoriteState();
    } else {
      statusRequest =
          details == null ? StatusRequest.failure : StatusRequest.success;
    }
    update();
  }

  void _syncFavoriteState() {
    final currentItem = item;
    if (currentItem == null) {
      isFavorite = false;
      return;
    }

    final raw = favoriteController.isFavorite[currentItem.id];
    isFavorite = '$raw' == '1';
  }

  String _resolveItemId() {
    final parameter = Get.parameters['item_id']?.trim() ?? '';
    if (parameter.isNotEmpty && parameter != 'null') {
      return parameter;
    }

    final arguments = Get.arguments;
    if (arguments is Map) {
      final rawItem = arguments['itemsmodel'];
      if (rawItem is ItemsModel && (rawItem.itemsId ?? '').trim().isNotEmpty) {
        return rawItem.itemsId!.trim();
      }

      final value = arguments['item_id'] ??
          arguments['id'] ??
          arguments['itemId'] ??
          arguments['menu_item_id'] ??
          arguments['menuItemId'];
      final resolved = '$value'.trim();
      if (resolved.isNotEmpty && resolved != 'null') {
        return resolved;
      }
    }

    final cached = myServices.sharedPreferences
            .getString(_lastItemIdKey)
            ?.trim() ??
        '';
    if (cached.isNotEmpty && cached != 'null') {
      return cached;
    }

    return '';
  }

  void _bootstrapSelections() {
    selections.clear();
    for (final group in groups) {
      final defaults = group.options
          .where((option) => option.isDefaultSelected)
          .map((option) => option.id)
          .toSet();
      if (defaults.isEmpty &&
          group.groupType.toLowerCase() == 'ingredient') {
        defaults.addAll(group.options.map((option) => option.id));
      }
      selections[group.id] = defaults;
    }
  }

  void setCurrentImageIndex(int index) {
    currentImageIndex = index;
    update();
  }

  bool isSelected(String groupId, String optionId) {
    return selections[groupId]?.contains(optionId) ?? false;
  }

  void toggleOption(
      FoodModifierGroupModel group, FoodModifierOptionModel option) {
    final selected = selections[group.id] ?? <String>{};
    if (!option.isRemovable) {
      selected.add(option.id);
      selections[group.id] = selected;
      update();
      return;
    }

    if (selected.contains(option.id)) {
      selected.remove(option.id);
    } else {
      if (group.maxSelect <= 1) {
        selected.clear();
      } else if (selected.length >= group.maxSelect) {
        return;
      }
      selected.add(option.id);
    }
    selections[group.id] = selected;
    update();
  }

  void incrementQuantity() {
    quantity += 1;
    update();
  }

  void decrementQuantity() {
    if (quantity <= 1) {
      return;
    }
    quantity -= 1;
    update();
  }

  void appendNote(String text) {
    final current = noteController.text.trim();
    if (current.isEmpty) {
      noteController.text = text;
    } else if (!current.contains(text)) {
      noteController.text = '$current، $text';
    }
    noteController.selection = TextSelection.collapsed(
      offset: noteController.text.length,
    );
    update();
  }

  double get modifiersTotal {
    double total = 0;
    for (final group in groups) {
      final selectedIds = selections[group.id] ?? const <String>{};
      for (final option in group.options) {
        if (selectedIds.contains(option.id)) {
          total += option.priceDelta;
        }
      }
    }
    return total;
  }

  double get unitPrice => (item?.price ?? 0) + modifiersTotal;
  double get totalPrice => unitPrice * quantity;

  bool validateSelection() {
    for (final group in groups) {
      final selectedCount = selections[group.id]?.length ?? 0;
      if (group.isRequired && selectedCount < group.minSelect) {
        Get.snackbar(
          isArabic ? 'اختيار ناقص' : 'Selection required',
          isArabic
              ? 'يرجى اختيار ${group.nameAr} قبل المتابعة.'
              : 'Please choose ${group.nameEn} before continuing.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    }
    return true;
  }

  Future<void> toggleFavorite() async {
    final currentItem = item;
    final userId = myServices.sharedPreferences.getInt('id');
    if (currentItem == null) {
      return;
    }
    if (userId == null) {
      Get.snackbar(
        isArabic ? 'تسجيل الدخول مطلوب' : 'Login required',
        isArabic
            ? 'سجّل الدخول أولاً حتى تتمكن من حفظ العناصر المفضلة.'
            : 'Please sign in first to save favorites.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final response = isFavorite
        ? await favoriteData.removeFavorite(userId.toString(), currentItem.id)
        : await favoriteData.addFavorite(userId.toString(), currentItem.id);

    if (response is Map && response['status'] == 'success') {
      isFavorite = !isFavorite;
      favoriteController.setFavorite(currentItem.id, isFavorite ? '1' : '0');
      update();
      return;
    }

    Get.snackbar(
      isArabic ? 'تعذر التحديث' : 'Unable to update',
      isArabic
          ? 'تعذر تحديث المفضلة الآن، حاول مرة أخرى.'
          : 'Could not update favorites right now. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> shareItem() async {
    final currentItem = item;
    if (currentItem == null) {
      return;
    }

    final shareText = [
      isArabic ? 'جرب هذا الصنف' : 'Check out this item',
      isArabic ? currentItem.nameAr : currentItem.nameEn,
      if (currentItem.categoryNameAr.trim().isNotEmpty ||
          currentItem.categoryNameEn.trim().isNotEmpty)
        isArabic
            ? 'القسم: ${currentItem.categoryNameAr}'
            : 'Category: ${currentItem.categoryNameEn}',
      if (galleryImages.isNotEmpty) galleryImages.first,
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: shareText));
    Get.snackbar(
      isArabic ? 'تم النسخ' : 'Copied',
      isArabic
          ? 'تم نسخ رابط المشاركة إلى الحافظة.'
          : 'Share text copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> addToCart() async {
    final currentItem = item;
    if (currentItem == null || isAdding) {
      return;
    }
    if (!validateSelection()) {
      return;
    }

    final userId = myServices.sharedPreferences.getInt('id');
    if (userId == null) {
      Get.snackbar(
        isArabic ? 'تسجيل الدخول مطلوب' : 'Login required',
        isArabic
            ? 'سجّل الدخول أولاً حتى تتمكن من الإضافة إلى السلة.'
            : 'Please sign in first to add items to your cart.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final selectedGroups = groups
        .map((group) {
          final ids = selections[group.id] ?? const <String>{};
          final options = group.options
              .where((option) => ids.contains(option.id))
              .map(
                (option) => {
                  'id': option.id,
                  'name_ar': option.nameAr,
                  'name_en': option.nameEn,
                  'price_delta': option.priceDelta,
                },
              )
              .toList();
          return {
            'group_id': group.id,
            'group_name_ar': group.nameAr,
            'group_name_en': group.nameEn,
            'group_type': group.groupType,
            'is_required': group.isRequired,
            'options': options,
          };
        })
        .where((entry) => (entry['options'] as List).isNotEmpty)
        .toList();

    final note = noteController.text.trim();
    final optionsSummary = selectedGroups
        .map((entry) {
          final groupName = isArabic
              ? '${entry['group_name_ar'] ?? ''}'
              : '${entry['group_name_en'] ?? ''}';
          final optionNames = (entry['options'] as List)
              .map(
                (option) =>
                    isArabic ? option['name_ar'] : option['name_en'],
              )
              .whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .join(isArabic ? '، ' : ', ');
          if (optionNames.trim().isEmpty) {
            return '';
          }
          return '${groupName.trim().isNotEmpty ? groupName.trim() : (isArabic ? 'التخصيص' : 'Customization')}: $optionNames';
        })
        .where((entry) => entry.trim().isNotEmpty)
        .join(isArabic ? ' | ' : ' | ');

    final configSource = jsonEncode({
      'item_id': currentItem.id,
      'selected_groups': selectedGroups,
      'note': note,
    });

    final configHash = md5.convert(utf8.encode(configSource)).toString();

    isAdding = true;
    update();

    final response = await cartData.addCart(
      userId.toString(),
      currentItem.id,
      extraData: {
        'config_hash': configHash,
        'cart_context_type': 'food',
        'cart_vendor_id': currentItem.vendorId,
        'cart_unit_price': unitPrice.toStringAsFixed(2),
        'cart_item_note': note,
        'cart_menu_options_json': jsonEncode(selectedGroups),
        'cart_menu_options_summary': optionsSummary,
      },
    );

    isAdding = false;
    if (isClosed) {
      return;
    }

    if (response is Map && response['status'] == 'success') {
      final quantityToAdd = quantity;
      if (quantityToAdd > 1) {
        for (var i = 1; i < quantityToAdd; i++) {
          await cartData.addCart(
            userId.toString(),
            currentItem.id,
            extraData: {
              'config_hash': configHash,
              'cart_context_type': 'food',
              'cart_vendor_id': currentItem.vendorId,
              'cart_unit_price': unitPrice.toStringAsFixed(2),
              'cart_item_note': note,
              'cart_menu_options_json': jsonEncode(selectedGroups),
              'cart_menu_options_summary': optionsSummary,
            },
          );
        }
      }
      if (isClosed) {
        return;
      }
      if (Get.isRegistered<CartController>()) {
        await Get.find<CartController>().view();
      } else {
        await Get.put(CartController()).view();
      }
      if (isClosed) {
        return;
      }
      update();
      Get.snackbar(
        isArabic ? 'تمت الإضافة' : 'Added to cart',
        isArabic
            ? 'تمت إضافة الوجبة إلى السلة بنجاح.'
            : 'The meal was added to your cart successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.snackbar(
      isArabic ? 'تعذر الإضافة' : 'Unable to add item',
      isArabic
          ? 'حصلت مشكلة أثناء إضافة الوجبة إلى السلة.'
          : 'Something went wrong while adding the meal to your cart.',
      snackPosition: SnackPosition.BOTTOM,
    );
    update();
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}
