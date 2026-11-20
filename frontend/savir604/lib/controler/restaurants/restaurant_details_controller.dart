import 'dart:async';

import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/functions/commerce_access_guard.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/core/services/local_json_cache.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/restaurant_details_model.dart';
import 'package:tks/data/datasource/model/itemsmodel.dart';
import 'package:tks/data/datasource/remote/restaurants/restaurant_details_data.dart';

class RestaurantDetailsController extends GetxController {
  RestaurantDetailsController()
      : remote = RestaurantDetailsData(Get.find()),
        myServices = Get.find();

  final RestaurantDetailsData remote;
  final MyServices myServices;
  late final LocalJsonCache _cache;
  static const String _lastRestaurantIdKey = 'last_restaurant_id';
  static const int _detailsCacheVersion = 2;
  static String _orderModeKey(String restaurantId) =>
      'restaurant_order_mode_$restaurantId';
  static String _orderSlotKey(String restaurantId) =>
      'restaurant_order_slot_$restaurantId';
  static const Duration _detailsCacheTtl = Duration(minutes: 15);

  StatusRequest statusRequest = StatusRequest.loading;
  RestaurantDetailsModel? details;
  String? loadedRestaurantId;
  String selectedOrderMode = 'asap';
  String? selectedSlotValue;
  String selectedCategoryId = 'all';

  bool get isArabic => Get.locale?.languageCode == 'ar';

  bool get requestedStore {
    final arguments = Get.arguments;
    return arguments is Map &&
        arguments['vendor_type']?.toString().toLowerCase() == 'store';
  }

  @override
  void onInit() {
    super.onInit();
    _cache = LocalJsonCache(myServices.sharedPreferences);
  }

  RestaurantOrderModesModel? get orderModes => details?.orderModes;

  bool get hasOrderModeOptions {
    final modes = orderModes;
    if (modes == null) {
      return false;
    }
    return modes.asapEnabled ||
        modes.scheduledSlots.isNotEmpty ||
        modes.preorderSlots.isNotEmpty;
  }

  List<RestaurantMenuCategoryModel> get menuCategories =>
      details?.menuCategories ?? const [];

  List<RestaurantOrderSlotModel> slotsForMode(String mode) {
    final modes = orderModes;
    if (modes == null) {
      return const [];
    }

    switch (mode) {
      case 'scheduled':
        return modes.scheduledSlots;
      case 'preorder':
        return modes.preorderSlots;
      default:
        return const [];
    }
  }

  bool canSelectMode(String mode) {
    final modes = orderModes;
    if (modes == null) {
      return false;
    }

    switch (mode) {
      case 'asap':
        return modes.asapEnabled;
      case 'scheduled':
        return modes.scheduledSlots.isNotEmpty;
      case 'preorder':
        return modes.preorderSlots.isNotEmpty;
      default:
        return false;
    }
  }

  List<RestaurantMenuItemModel> get visibleItems {
    final items = details?.menuItems ?? const <RestaurantMenuItemModel>[];
    if (selectedCategoryId == 'all') {
      return items;
    }
    return items
        .where((item) => item.categoryId == selectedCategoryId)
        .toList();
  }

  String get restaurantName => details?.restaurant.name ?? '';

  Future<void> retryFetch() =>
      fetchDetails(restaurantId: loadedRestaurantId, forceRefresh: true);

  bool _slotExists(List<RestaurantOrderSlotModel> slots, String value) {
    return slots.any((slot) => slot.value == value);
  }

  void _persistOrderSelection() {
    final restaurantId = loadedRestaurantId?.trim() ?? '';
    if (restaurantId.isEmpty) {
      return;
    }

    unawaited(
      myServices.sharedPreferences.setString(
        _orderModeKey(restaurantId),
        selectedOrderMode,
      ),
    );
    unawaited(
      myServices.sharedPreferences.setString(
        _orderSlotKey(restaurantId),
        selectedSlotValue ?? '',
      ),
    );
  }

  Future<void> fetchDetails({
    String? restaurantId,
    bool forceRefresh = false,
  }) async {
    final resolvedRestaurantId = _resolveRestaurantId(restaurantId);
    final previousRestaurantId = loadedRestaurantId?.trim() ?? '';
    final restaurantChanged = previousRestaurantId.isNotEmpty &&
        previousRestaurantId != resolvedRestaurantId;

    if (resolvedRestaurantId.isEmpty) {
      if (details != null) {
        statusRequest = StatusRequest.success;
        update();
        return;
      }

      statusRequest = StatusRequest.failure;
      details = null;
      update();
      Get.snackbar(
        isArabic ? 'تعذر فتح المطعم' : 'Unable to open restaurant',
        isArabic
            ? 'لم يتم تمرير رقم المطعم إلى صفحة التفاصيل.'
            : 'The restaurant id was not passed to the details page.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    loadedRestaurantId = resolvedRestaurantId;
    myServices.sharedPreferences
        .setString(_lastRestaurantIdKey, resolvedRestaurantId);

    final selectedLocation = _loadSelectedHomeLocation();
    final cacheKey = _detailsCacheKey(
      restaurantId: resolvedRestaurantId,
      location: selectedLocation,
    );
    final cachedPayload = _cache.readPayload(cacheKey);
    final cachedMap =
        cachedPayload is Map ? Map<String, dynamic>.from(cachedPayload) : null;

    selectedCategoryId = 'all';

    if (cachedMap != null) {
      details = RestaurantDetailsModel.fromJson(cachedMap);
      statusRequest = StatusRequest.success;
      _bootstrapSelections();
      update();
    } else {
      statusRequest = StatusRequest.loading;
      if (restaurantChanged) {
        details = null;
      }
      update();
    }

    try {
      final shouldRefresh = forceRefresh ||
          cachedMap == null ||
          !_cache.isFresh(cacheKey, _detailsCacheTtl);
      if (shouldRefresh) {
        final response = await remote.getData(
          resolvedRestaurantId,
          lat: selectedLocation?.latitude,
          lng: selectedLocation?.longitude,
        );
        if (isClosed) {
          return;
        }
        final remoteStatus = handlingData(response);

        if (remoteStatus == StatusRequest.success &&
            response is Map &&
            response['status'] == 'success' &&
            response['data'] is Map) {
          final payload = Map<String, dynamic>.from(response['data']);
          details = RestaurantDetailsModel.fromJson(payload);
          myServices.sharedPreferences
              .setString(_lastRestaurantIdKey, resolvedRestaurantId);
          _bootstrapSelections();
          await _cache.writePayload(cacheKey, payload);
          statusRequest = StatusRequest.success;
        } else if (cachedMap == null) {
          statusRequest = StatusRequest.failure;
          details = null;
        }
      }
    } catch (_) {
      statusRequest =
          details == null ? StatusRequest.failure : StatusRequest.success;
    }

    if (isClosed) {
      return;
    }
    update();
  }

  _SelectedLocation? _loadSelectedHomeLocation() {
    final latitude = DeliverySelectionStore.readLatitude(
      myServices.sharedPreferences,
    );
    final longitude = DeliverySelectionStore.readLongitude(
      myServices.sharedPreferences,
    );
    if (latitude == null || longitude == null) {
      return null;
    }
    return _SelectedLocation(latitude: latitude, longitude: longitude);
  }

  String _detailsCacheKey({
    required String restaurantId,
    required _SelectedLocation? location,
  }) {
    final userId =
        myServices.sharedPreferences.getInt('id')?.toString() ?? 'guest';
    final lang = Get.locale?.languageCode ?? 'ar';
    final locationPart = location == null
        ? 'no_location'
        : '${location.latitude.toStringAsFixed(4)}_${location.longitude.toStringAsFixed(4)}';
    return 'restaurant_details_v${_detailsCacheVersion}_${userId.trim()}_${lang.trim()}_${restaurantId.trim()}_$locationPart';
  }

  String _resolveRestaurantId([String? restaurantId]) {
    final direct = restaurantId?.trim() ?? '';
    if (direct.isNotEmpty && direct != 'null') {
      return direct;
    }

    for (final key in const ['restaurant_id', 'restaurantId', 'id']) {
      final parameter = Get.parameters[key]?.trim() ?? '';
      if (parameter.isNotEmpty && parameter != 'null') {
        return parameter;
      }
    }

    final arguments = Get.arguments;
    if (arguments is Map) {
      final value = arguments['restaurant_id'] ??
          arguments['restaurantId'] ??
          arguments['id'];
      final resolved = '$value'.trim();
      if (resolved.isNotEmpty && resolved != 'null') {
        return resolved;
      }
    } else if (arguments is String || arguments is int) {
      final resolved = '$arguments'.trim();
      if (resolved.isNotEmpty && resolved != 'null') {
        return resolved;
      }
    }

    final cached =
        myServices.sharedPreferences.getString(_lastRestaurantIdKey)?.trim() ??
            '';
    if (cached.isNotEmpty && cached != 'null') {
      return cached;
    }

    return '';
  }

  void _bootstrapSelections() {
    selectedOrderMode = 'asap';
    selectedSlotValue = null;

    final modes = details?.orderModes;
    if (modes == null) {
      _persistOrderSelection();
      return;
    }

    final restaurantId = loadedRestaurantId?.trim() ?? '';
    final storedMode = restaurantId.isEmpty
        ? ''
        : (myServices.sharedPreferences
                .getString(_orderModeKey(restaurantId))
                ?.trim() ??
            '');
    final storedSlot = restaurantId.isEmpty
        ? ''
        : (myServices.sharedPreferences
                .getString(_orderSlotKey(restaurantId))
                ?.trim() ??
            '');

    if (storedMode == 'asap' && modes.asapEnabled) {
      selectedOrderMode = 'asap';
      selectedSlotValue = null;
      _persistOrderSelection();
      return;
    }

    if (storedMode == 'scheduled' && modes.scheduledSlots.isNotEmpty) {
      selectedOrderMode = 'scheduled';
      selectedSlotValue = _slotExists(modes.scheduledSlots, storedSlot)
          ? storedSlot
          : modes.scheduledSlots.first.value;
      _persistOrderSelection();
      return;
    }

    if (storedMode == 'preorder' && modes.preorderSlots.isNotEmpty) {
      selectedOrderMode = 'preorder';
      selectedSlotValue = _slotExists(modes.preorderSlots, storedSlot)
          ? storedSlot
          : modes.preorderSlots.first.value;
      _persistOrderSelection();
      return;
    }

    if (modes.asapEnabled) {
      selectedOrderMode = 'asap';
      selectedSlotValue = null;
    } else if (modes.scheduledSlots.isNotEmpty) {
      selectedOrderMode = 'scheduled';
      selectedSlotValue = modes.scheduledSlots.first.value;
    } else if (modes.preorderSlots.isNotEmpty) {
      selectedOrderMode = 'preorder';
      selectedSlotValue = modes.preorderSlots.first.value;
    }
    _persistOrderSelection();
  }

  void selectOrderMode(String mode) {
    if (!canSelectMode(mode)) {
      return;
    }

    selectedOrderMode = mode;
    if (mode == 'asap') {
      selectedSlotValue = null;
    } else {
      final slots = slotsForMode(mode);
      if (slots.isNotEmpty) {
        selectedSlotValue = slots.first.value;
      }
    }
    _persistOrderSelection();
    update();
  }

  void selectSlot(String value) {
    final slots = slotsForMode(selectedOrderMode);
    if (slots.isEmpty || !slots.any((slot) => slot.value == value)) {
      return;
    }

    selectedSlotValue = value;
    _persistOrderSelection();
    update();
  }

  void selectCategory(String categoryId) {
    selectedCategoryId = categoryId;
    update();
  }

  void openFoodItem(RestaurantMenuItemModel item) {
    unawaited(
      CommerceAccessGuard.openProduct(
        itemId: item.id,
        arguments: {
          'item_id': item.id,
          'vendor_type': details?.restaurant.vendorType ?? 'restaurant',
          'itemsmodel': ItemsModel(
            itemsId: item.id,
            itemsNameAr: item.nameAr,
            itemsNameEn: item.nameEn,
            itemsDescAr: item.descriptionAr,
            itemsDescEn: item.descriptionEn,
            itemsImage: item.imageUrl,
            itemsPrice: item.price.toString(),
            itemsCount: item.itemsCount,
            vendorId: item.vendorId,
            vendorType: details?.restaurant.vendorType ?? 'restaurant',
            productType: item.productType,
            stockUnit: item.stockUnit,
            stockStep: item.stockStep,
            storeCategory: item.storeCategory,
          ),
          'restaurant_name': details?.restaurant.name ?? '',
          'restaurant_id':
              loadedRestaurantId ?? details?.restaurant.id.toString(),
        },
        parameters: {
          'item_id': item.id,
          'restaurant_id':
              loadedRestaurantId ?? details?.restaurant.id.toString() ?? '',
        },
      ),
    );
  }
}

class _SelectedLocation {
  const _SelectedLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}
