// ignore_for_file: avoid_print

import 'dart:async';

import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/functions/commerce_access_guard.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/core/services/local_json_cache.dart';
import 'package:tks/core/services/location_service.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/addressmodel.dart';
import 'package:tks/data/datasource/model/aleppo_home_model.dart';
import 'package:tks/data/datasource/model/itemsmodel.dart';
import 'package:tks/data/datasource/model/video_model.dart';
import 'package:tks/data/datasource/remote/address/address_data.dart';
import 'package:tks/data/datasource/remote/home/homedata.dart';
import 'package:tks/data/datasource/remote/video/video_remote.dart';
import 'package:tks/view/screen/story_viewer_page.dart';

abstract class HomeController extends GetxController {
  void initialData();
  Future<void> getdata({bool showLoader = true, bool forceRefresh = false});
  void goToItems(List categories, int selectedCat, String categoryid);
}

class HomeControllerImp extends HomeController {
  final MyServices myServices = Get.find();
  final HomeData homedata = HomeData(Get.find());
  final AddressData addressData = AddressData(Get.find());
  final VideoRemote videoRemote = VideoRemote(Get.find());
  late final LocalJsonCache _cache;

  StatusRequest statusRequest = StatusRequest.none;
  String? username;
  String? id;
  String? lang;

  AleppoHomeModel? homeModel;
  AleppoHomeBannerModel? notificationBanner;
  List<AleppoHomeStoryModel> stories = [];
  List<AleppoHomeBannerModel> banners = [];
  List<AleppoFoodCategoryModel> foodCategories = [];
  List<AleppoFoodCategoryModel> restaurantCategories = [];
  List<AleppoFoodCategoryModel> storeCategories = [];
  List<AleppoOccasionModel> occasions = [];
  List<AleppoRestaurantSectionModel> restaurantSections = [];
  List<AleppoProductSectionModel> productSections = [];
  List<VideoModel> homeVideos = [];

  List categories = [];
  List items = [];
  List<ItemsModel> searchResults = [];
  bool isSearch = false;

  final LocationService _locationService = const LocationService();
  bool _locationPromptShown = false;

  static const Duration _homeCacheTtl = Duration(minutes: 15);
  static const Duration _videoCacheTtl = Duration(minutes: 15);

  // Get.locale is the source of truth after an in-app language switch. The
  // persisted value is only a startup fallback; keeping it first here made
  // the home screen stay in the previous language until a full restart.
  bool get isArabic => (Get.locale?.languageCode ?? lang ?? 'ar') == 'ar';

  @override
  void onInit() {
    super.onInit();
    _cache = LocalJsonCache(myServices.sharedPreferences);
    initialData();
    getdata();
  }

  @override
  void initialData() {
    lang = myServices.sharedPreferences.getString('lang');
    username = myServices.sharedPreferences.getString('username');
    id = myServices.sharedPreferences.getInt('id')?.toString();
  }

  @override
  Future<void> getdata({
    bool showLoader = true,
    bool forceRefresh = false,
  }) async {
    final homeLocation = await _resolveHomeLocation();
    final homeCacheKey = _homeCacheKey(homeLocation);
    final videoCacheKey = _videoCacheKey();
    final cachedHomePayload = _extractMap(_cache.readPayload(homeCacheKey));
    final cachedVideos = _readCachedVideos(videoCacheKey);
    final hasCachedHome = cachedHomePayload != null;
    final hasCachedVideos = cachedVideos.isNotEmpty;

    if (hasCachedHome) {
      _applyHomePayload(cachedHomePayload);
      statusRequest = StatusRequest.success;
      if (hasCachedVideos && homeVideos.isEmpty) {
        homeVideos = cachedVideos;
      }
      update();
    } else if (showLoader) {
      _resetHomeContent();
      statusRequest = StatusRequest.loading;
      update();
    }

    final shouldRefreshHome = forceRefresh ||
        !hasCachedHome ||
        !_cache.isFresh(homeCacheKey, _homeCacheTtl);
    final shouldRefreshVideos = forceRefresh ||
        !hasCachedVideos ||
        !_cache.isFresh(videoCacheKey, _videoCacheTtl);

    if (!shouldRefreshHome && !shouldRefreshVideos) {
      return;
    }

    try {
      if (shouldRefreshHome) {
        final response = await homedata.getData(
          lat: homeLocation?.latitude,
          lng: homeLocation?.longitude,
          userId: id,
        );
        print('Aleppo Home response: $response');
        final remoteStatus = handlingData(response);
        if (remoteStatus == StatusRequest.success &&
            response is Map &&
            response['status'] == 'success' &&
            response['data'] is Map) {
          final payload = Map<String, dynamic>.from(response['data']);
          _applyHomePayload(payload);
          statusRequest = StatusRequest.success;
          await _cache.writePayload(homeCacheKey, payload);
        } else if (!hasCachedHome) {
          statusRequest = StatusRequest.failure;
          if (showLoader) {
            _resetHomeContent();
          }
        }
      }

      if (shouldRefreshVideos) {
        final videos = await videoRemote.fetchVideos();
        homeVideos = videos;
        await _cache.writePayload(
          videoCacheKey,
          videos.map((video) => video.toJson()).toList(),
        );
      }
    } catch (error) {
      print('Home refresh failed: $error');
      if (!hasCachedHome) {
        statusRequest = StatusRequest.failure;
      }
    }

    update();
  }

  void _resetHomeContent() {
    homeModel = null;
    notificationBanner = null;
    stories = [];
    banners = [];
    foodCategories = [];
    restaurantCategories = [];
    storeCategories = [];
    occasions = [];
    restaurantSections = [];
    productSections = [];
    homeVideos = [];
    categories = [];
  }

  void _applyHomePayload(Map<String, dynamic> payload) {
    homeModel = AleppoHomeModel.fromJson(payload);
    notificationBanner = homeModel!.notificationBanner;
    stories = homeModel!.stories;
    banners = homeModel!.banners;
    foodCategories = homeModel!.categories;
    restaurantCategories = homeModel!.restaurantCategories;
    storeCategories = homeModel!.storeCategories;
    occasions = homeModel!.occasions;
    restaurantSections = homeModel!.sections;
    productSections = homeModel!.productSections;
    categories = foodCategories.map(_categoryToMap).toList();
  }

  String _cacheUserTag() {
    final userId = id ?? myServices.sharedPreferences.getInt('id')?.toString();
    final tag = (userId ?? '').trim();
    return tag.isEmpty ? 'guest' : tag;
  }

  String _cacheLanguageTag() {
    return (Get.locale?.languageCode ?? lang ?? 'ar').trim();
  }

  String _homeCacheKey(_HomeLocation? homeLocation) {
    final locationPart = homeLocation == null
        ? 'no_location'
        : '${homeLocation.latitude.toStringAsFixed(4)}_${homeLocation.longitude.toStringAsFixed(4)}';
    return 'aleppo_home_${_cacheUserTag()}_${_cacheLanguageTag()}_$locationPart';
  }

  String _videoCacheKey() {
    return 'aleppo_home_videos_${_cacheUserTag()}_${_cacheLanguageTag()}';
  }

  List<VideoModel> _readCachedVideos(String cacheKey) {
    final payload = _extractList(_cache.readPayload(cacheKey));
    if (payload == null) {
      return [];
    }
    return payload
        .whereType<Map>()
        .map((item) => VideoModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic>? _extractMap(dynamic payload) {
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    return null;
  }

  List<dynamic>? _extractList(dynamic payload) {
    if (payload is List) {
      return payload;
    }
    return null;
  }

  Future<void> _storeSelectedHomeLocation(
    AddressModel address, {
    String? locationLabel,
  }) async {
    final latitude = address.resolvedLatitude;
    final longitude = address.resolvedLongitude;
    if (latitude == null || longitude == null) {
      return;
    }

    await DeliverySelectionStore.saveAddress(
      myServices.sharedPreferences,
      addressId: address.addressId,
      addressName: address.addressName,
      addressCity: address.addressCity,
      addressStreet: address.addressStreet,
      addressPhone: address.addressphone,
      latitude: latitude,
      longitude: longitude,
      locationLabel: locationLabel ??
          _firstNonEmpty([
            address.addressName ?? '',
            address.addressStreet ?? '',
            address.addressCity ?? '',
          ]),
    );
  }

  _HomeLocation? _loadSelectedHomeLocation() {
    final latitude = DeliverySelectionStore.readLatitude(
      myServices.sharedPreferences,
    );
    final longitude = DeliverySelectionStore.readLongitude(
      myServices.sharedPreferences,
    );
    if (latitude == null || longitude == null) {
      return null;
    }
    final location = _HomeLocation(
      latitude: latitude,
      longitude: longitude,
    );
    return _isWithinEgypt(location) ? location : null;
  }

  bool _isWithinEgypt(_HomeLocation location) {
    return location.latitude >= 21.5 &&
        location.latitude <= 31.9 &&
        location.longitude >= 24.5 &&
        location.longitude <= 37.2;
  }

  Future<_HomeLocation?> _resolveHomeLocation() async {
    // The home feed must be based on where the user is now, not only on the
    // delivery address saved in the account. This is what keeps nearby
    // restaurants and stores local when the user moves to another city.
    try {
      final currentLocation = await _locationService.getCurrentLocation();
      if (currentLocation != null) {
        final deviceLocation = _HomeLocation(
          latitude: currentLocation.latitude,
          longitude: currentLocation.longitude,
        );
        if (_isWithinEgypt(deviceLocation)) {
          return deviceLocation;
        }
      }
    } catch (error) {
      print('Could not read device location: $error');
    }

    _showLocationFallbackMessage();

    final cachedLocation = _loadSelectedHomeLocation();
    if (cachedLocation != null) {
      return cachedLocation;
    }

    final userId = myServices.sharedPreferences.getInt('id') ?? 0;
    if (userId <= 0) {
      return null;
    }

    final response = await addressData.getData(userId.toString());
    if (response is! Map || response['status'] != 'success') {
      return null;
    }

    final rawAddresses = response['data'];
    if (rawAddresses is! List) {
      return null;
    }

    final addresses = rawAddresses
        .whereType<Map>()
        .map((item) => AddressModel.fromJson(Map<String, dynamic>.from(item)))
        .where(
          (address) =>
              address.resolvedLatitude != null &&
              address.resolvedLongitude != null,
        )
        .toList()
      ..sort((a, b) {
        final aId = int.tryParse(a.addressId ?? '') ?? 0;
        final bId = int.tryParse(b.addressId ?? '') ?? 0;
        return bId.compareTo(aId);
      });

    if (addresses.isEmpty) {
      return null;
    }

    final selected = addresses.first;
    final resolvedLocation = _HomeLocation(
      latitude: selected.resolvedLatitude!,
      longitude: selected.resolvedLongitude!,
    );
    if (!_isWithinEgypt(resolvedLocation)) {
      return null;
    }
    await _storeSelectedHomeLocation(selected);
    return resolvedLocation;
  }

  void _showLocationFallbackMessage() {
    if (_locationPromptShown) {
      return;
    }
    _locationPromptShown = true;

    final isArabicLanguage = isArabic;
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (Get.isSnackbarOpen) {
        return;
      }
      Get.snackbar(
        isArabicLanguage ? 'الموقع' : 'Location',
        isArabicLanguage
            ? 'فعّل صلاحية الموقع لعرض المطاعم والمتاجر القريبة منك.'
            : 'Enable location permission to see restaurants and stores near you.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    });
  }

  String get deliveryPrompt {
    if (homeModel == null) {
      return isArabic ? 'اختر عنوان التوصيل' : 'Choose delivery address';
    }
    final localized = isArabic
        ? homeModel!.deliveryPromptAr.trim()
        : homeModel!.deliveryPromptEn.trim();
    return localized.isEmpty
        ? (isArabic ? 'اختر عنوان التوصيل' : 'Choose delivery address')
        : localized;
  }

  String get marketingHeadline {
    if (homeModel == null) {
      return isArabic
          ? 'اطلب لأحبابك في مصر من أي مكان في العالم'
          : 'Order for your loved ones in Egypt from anywhere in the world';
    }
    final localized = isArabic
        ? homeModel!.marketingHeadlineAr.trim()
        : homeModel!.marketingHeadlineEn.trim();
    return localized.isEmpty
        ? (isArabic
            ? 'اطلب لأحبابك في مصر من أي مكان في العالم'
            : 'Order for your loved ones in Egypt from anywhere in the world')
        : localized;
  }

  String get marketingSubtitle {
    if (homeModel == null) {
      return isArabic
          ? 'مطاعم وعروض وتتبع مباشر للطلب في مكان واحد.'
          : 'Restaurants, offers, and live order tracking in one flow.';
    }
    final localized = isArabic
        ? homeModel!.marketingSubtitleAr.trim()
        : homeModel!.marketingSubtitleEn.trim();
    return localized.isEmpty
        ? (isArabic
            ? 'مطاعم وعروض وتتبع مباشر للطلب في مكان واحد.'
            : 'Restaurants, offers, and live order tracking in one flow.')
        : localized;
  }

  Future<void> refreshHome() async {
    await getdata(showLoader: true, forceRefresh: true);
  }

  Future<void> openAddressView() async {
    final homeLocation = await _resolveHomeLocation();
    final result = await Get.toNamed(
      AppRoutes.selectAddressMap,
      arguments: {
        'mode': 'address',
        'country': 'EG',
        'title': isArabic ? 'تحديد العنوان' : 'Choose delivery address',
        'hint_title':
            isArabic ? 'حدد موقع التوصيل' : 'Choose the delivery location',
        'hint_body': isArabic
            ? 'اضغط على الخريطة لتحديد موقع التوصيل بدقة.'
            : 'Tap the map to pinpoint the delivery location.',
        'confirm_label': isArabic ? 'اعتماد العنوان' : 'Use location',
        if (homeLocation != null) 'initial_latitude': homeLocation.latitude,
        if (homeLocation != null) 'initial_longitude': homeLocation.longitude,
      },
    );

    if (result is Map) {
      await _saveSelectedAddress(Map<String, dynamic>.from(result));
    }
  }

  Future<void> _saveSelectedAddress(Map<String, dynamic> selection) async {
    final userId = myServices.sharedPreferences.getInt('id')?.toString() ?? '';
    if (userId.isEmpty) {
      return;
    }

    final latitude = _parseSelectionDouble(selection, 'latitude');
    final longitude = _parseSelectionDouble(selection, 'longitude');
    if (latitude == null || longitude == null) {
      Get.snackbar(
        isArabic ? 'العنوان' : 'Address',
        isArabic
            ? 'لم نتمكن من حفظ الموقع المحدد.'
            : 'We could not save the selected location.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final addressName = _firstNonEmpty([
      _selectionText(selection, 'place_name'),
      _selectionText(selection, 'address_line'),
      _selectionText(selection, 'street'),
      isArabic ? 'المنزل' : 'Home',
    ]);
    final city = _firstNonEmpty([
      _selectionText(selection, 'city'),
      _extractLeadingSegment(_selectionText(selection, 'place_name')),
      _extractLeadingSegment(_selectionText(selection, 'address_line')),
      isArabic ? 'المدينة' : 'City',
    ]);
    final street = _firstNonEmpty([
      _selectionText(selection, 'address_line'),
      _selectionText(selection, 'street'),
      _selectionText(selection, 'place_name'),
      isArabic ? 'العنوان' : 'Address',
    ]);
    final phone =
        (myServices.sharedPreferences.getString('phone') ?? '').trim();
    final locationLabel = _firstNonEmpty([
      _selectionText(selection, 'place_name'),
      _selectionText(selection, 'address_line'),
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
    ]);

    final response = await addressData.addData(
      userId,
      addressName,
      city,
      street,
      phone,
      latitude: latitude.toString(),
      longitude: longitude.toString(),
      locationLabel: locationLabel,
    );

    if (response is Map && response['status'] == 'success') {
      await DeliverySelectionStore.saveAddress(
        myServices.sharedPreferences,
        addressName: addressName,
        addressCity: city,
        addressStreet: street,
        addressPhone: phone,
        latitude: latitude,
        longitude: longitude,
        locationLabel: locationLabel,
      );
      await getdata(showLoader: false, forceRefresh: true);
      Get.snackbar(
        isArabic ? 'تم الحفظ' : 'Saved',
        isArabic
            ? 'تم حفظ العنوان بنجاح وسيظهر في صفحة إتمام الطلب.'
            : 'The address was saved and will appear in checkout.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        isArabic ? 'العنوان' : 'Address',
        isArabic
            ? 'تعذر حفظ العنوان، حاول مرة أخرى.'
            : 'Failed to save the address. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _selectionText(Map<String, dynamic> selection, String key) {
    return '${selection[key] ?? ''}'.trim();
  }

  double? _parseSelectionDouble(
    Map<String, dynamic> selection,
    String key,
  ) {
    final value = selection[key];
    if (value is num) {
      return value.toDouble();
    }
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return double.tryParse(text);
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  String _extractLeadingSegment(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final commaSegments = trimmed
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (commaSegments.isNotEmpty) {
      return commaSegments.first;
    }
    final dashSegments = trimmed
        .split(' - ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (dashSegments.isNotEmpty) {
      return dashSegments.first;
    }
    return trimmed;
  }

  void openSearchPage() {
    if (foodCategories.isEmpty) {
      Get.snackbar(
        isArabic ? 'بحث' : 'Search',
        isArabic
            ? 'لا توجد أقسام متاحة الآن.'
            : 'No categories are available right now.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    goToItems(
      categories,
      0,
      foodCategories.first.id.toString(),
    );
  }

  void openRestaurant(AleppoRestaurantModel restaurant) {
    unawaited(
      CommerceAccessGuard.openRestaurant(
        restaurantId: restaurant.id.toString(),
        arguments: {
          'restaurant_id': restaurant.id.toString(),
          'vendor_type': restaurant.vendorType,
        },
        parameters: {'restaurant_id': restaurant.id.toString()},
      ),
    );
  }

  void openCategory(AleppoFoodCategoryModel category) {
    if (foodCategories.isEmpty) {
      Get.snackbar(
        isArabic ? 'الأقسام' : 'Categories',
        isArabic
            ? 'لا توجد أقسام متاحة الآن.'
            : 'No categories are available right now.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final index = foodCategories.indexWhere((item) => item.id == category.id);
    goToItems(
      categories,
      index >= 0 ? index : 0,
      category.id.toString(),
    );
  }

  void openBanner(AleppoHomeBannerModel banner) {
    final title = isArabic ? banner.titleAr : banner.titleEn;
    Get.snackbar(
      title.isEmpty ? 'Offer' : title,
      'Smart offer navigation is next after the restaurant page.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void openStory(AleppoHomeStoryModel story) {
    Get.to(() => StoryViewerPage(story: story));
  }

  void syncProductRating(ItemsModel updatedItem) {
    var changed = false;
    for (var i = 0; i < items.length; i++) {
      final item = ItemsModel.fromJson(Map<String, dynamic>.from(items[i]));
      if (item.itemsId == updatedItem.itemsId) {
        final updatedMap = Map<String, dynamic>.from(items[i]);
        updatedMap['average_rating'] = updatedItem.averageRating;
        updatedMap['ratings_count'] = updatedItem.ratingsCount;
        updatedMap['rating_percentage'] = updatedItem.ratingPercentage;
        updatedMap['is_top_rated'] = updatedItem.isTopRated;
        items[i] = updatedMap;
        changed = true;
        break;
      }
    }
    for (final section in productSections) {
      for (var i = 0; i < section.items.length; i++) {
        final item = section.items[i];
        if (item.itemsId == updatedItem.itemsId) {
          section.items[i] = updatedItem;
          changed = true;
        }
      }
    }
    if (!changed) {
      return;
    }
    update();
  }

  @override
  void goToItems(List categories, int selectedCat, String categoryid) {
    Get.toNamed(
      AppRoutes.items,
      arguments: {
        'categories': categories,
        'selectedcat': selectedCat,
        'catid': categoryid,
      },
    );
  }

  void goToPageProductDetails(ItemsModel itemsModel) {
    unawaited(
      CommerceAccessGuard.openProduct(
        itemId: itemsModel.itemsId ?? '',
        arguments: {
          'item_id': itemsModel.itemsId,
          'itemsmodel': itemsModel,
        },
        parameters: {
          'item_id': itemsModel.itemsId ?? '',
        },
      ),
    );
  }
}

Map<String, dynamic> _categoryToMap(AleppoFoodCategoryModel category) {
  return <String, dynamic>{
    'categories_id': category.id.toString(),
    'categories_name_en': category.nameEn,
    'categories_name_ar': category.nameAr,
    'categories_image': category.imageUrl,
    'categories_datetime': '',
  };
}

class _HomeLocation {
  const _HomeLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}
