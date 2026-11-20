class RestaurantDetailsModel {
  RestaurantDetailsModel({
    required this.restaurant,
    required this.orderModes,
    required this.menuCategories,
    required this.menuItems,
  });

  final RestaurantHeaderModel restaurant;
  final RestaurantOrderModesModel orderModes;
  final List<RestaurantMenuCategoryModel> menuCategories;
  final List<RestaurantMenuItemModel> menuItems;

  factory RestaurantDetailsModel.fromJson(Map<String, dynamic> json) {
    return RestaurantDetailsModel(
      restaurant: RestaurantHeaderModel.fromJson(
        Map<String, dynamic>.from(json['restaurant'] ?? const {}),
      ),
      orderModes: RestaurantOrderModesModel.fromJson(
        Map<String, dynamic>.from(json['order_modes'] ?? const {}),
      ),
      menuCategories: _mapRestaurantList(
        json['menu_categories'],
        (item) => RestaurantMenuCategoryModel.fromJson(item),
      ),
      menuItems: _mapRestaurantList(
        json['menu_items'],
        (item) => RestaurantMenuItemModel.fromJson(item),
      ),
    );
  }
}

class RestaurantHeaderModel {
  RestaurantHeaderModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.vendorDescription,
    required this.taglineAr,
    required this.taglineEn,
    required this.logoUrl,
    required this.coverImageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.deliveryFee,
    required this.estimatedMinMinutes,
    required this.estimatedMaxMinutes,
    required this.isOpen,
    required this.supportsScheduledOrders,
    required this.supportsPickup,
    required this.distanceKm,
    required this.badgesAr,
    required this.badgesEn,
    this.vendorType = 'restaurant',
    this.entityLabelAr = 'مطعم',
    this.entityLabelEn = 'Restaurant',
  });

  final int id;
  final String name;
  final String slug;
  final String vendorDescription;
  final String taglineAr;
  final String taglineEn;
  final String logoUrl;
  final String coverImageUrl;
  final double rating;
  final int reviewsCount;
  final double deliveryFee;
  final int estimatedMinMinutes;
  final int estimatedMaxMinutes;
  final bool isOpen;
  final bool supportsScheduledOrders;
  final bool supportsPickup;
  final double? distanceKm;
  final List<String> badgesAr;
  final List<String> badgesEn;
  final String vendorType;
  final String entityLabelAr;
  final String entityLabelEn;

  factory RestaurantHeaderModel.fromJson(Map<String, dynamic> json) {
    return RestaurantHeaderModel(
      id: _restaurantInt(json['id']),
      name: '${json['name'] ?? ''}',
      slug: '${json['slug'] ?? ''}',
      vendorDescription: '${json['vendor_description'] ?? ''}',
      taglineAr: '${json['tagline_ar'] ?? ''}',
      taglineEn: '${json['tagline_en'] ?? ''}',
      logoUrl: _restaurantImageValue(json, const ['vendor_logo', 'logo_url']),
      coverImageUrl: _restaurantImageValue(
        json,
        const ['store_banner_url', 'banner_url', 'cover_image_url'],
      ),
      rating: _restaurantDouble(json['rating']),
      reviewsCount: _restaurantInt(json['reviews_count']),
      deliveryFee: _restaurantDouble(json['delivery_fee']),
      estimatedMinMinutes: _restaurantInt(json['estimated_min_minutes']),
      estimatedMaxMinutes: _restaurantInt(json['estimated_max_minutes']),
      isOpen: _restaurantBool(json['is_open']),
      supportsScheduledOrders:
          _restaurantBool(json['supports_scheduled_orders']),
      supportsPickup: _restaurantBool(json['supports_pickup']),
      distanceKm: json['distance_km'] == null
          ? null
          : _restaurantDouble(json['distance_km']),
      badgesAr: _restaurantStringList(json['badges_ar']),
      badgesEn: _restaurantStringList(json['badges_en']),
      vendorType: '${json['vendor_type'] ?? 'restaurant'}',
      entityLabelAr: '${json['entity_label_ar'] ?? 'مطعم'}',
      entityLabelEn: '${json['entity_label_en'] ?? 'Restaurant'}',
    );
  }
}

class RestaurantOrderModesModel {
  RestaurantOrderModesModel({
    required this.asapEnabled,
    required this.asapLabelAr,
    required this.asapLabelEn,
    required this.scheduledSlots,
    required this.preorderSlots,
  });

  final bool asapEnabled;
  final String asapLabelAr;
  final String asapLabelEn;
  final List<RestaurantOrderSlotModel> scheduledSlots;
  final List<RestaurantOrderSlotModel> preorderSlots;

  factory RestaurantOrderModesModel.fromJson(Map<String, dynamic> json) {
    return RestaurantOrderModesModel(
      asapEnabled: _restaurantBool(json['asap_enabled']),
      asapLabelAr: '${json['asap_label_ar'] ?? ''}',
      asapLabelEn: '${json['asap_label_en'] ?? ''}',
      scheduledSlots: _mapRestaurantList(
        json['scheduled_slots'],
        (item) => RestaurantOrderSlotModel.fromJson(item),
      ),
      preorderSlots: _mapRestaurantList(
        json['preorder_slots'],
        (item) => RestaurantOrderSlotModel.fromJson(item),
      ),
    );
  }
}

class RestaurantOrderSlotModel {
  RestaurantOrderSlotModel({
    required this.labelAr,
    required this.labelEn,
    required this.value,
  });

  final String labelAr;
  final String labelEn;
  final String value;

  factory RestaurantOrderSlotModel.fromJson(Map<String, dynamic> json) {
    return RestaurantOrderSlotModel(
      labelAr: '${json['label_ar'] ?? ''}',
      labelEn: '${json['label_en'] ?? ''}',
      value: '${json['value'] ?? ''}',
    );
  }
}

class RestaurantMenuCategoryModel {
  RestaurantMenuCategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  final String id;
  final String nameAr;
  final String nameEn;

  factory RestaurantMenuCategoryModel.fromJson(Map<String, dynamic> json) {
    return RestaurantMenuCategoryModel(
      id: '${json['id'] ?? ''}',
      nameAr: '${json['name_ar'] ?? ''}',
      nameEn: '${json['name_en'] ?? ''}',
    );
  }
}

class RestaurantMenuItemModel {
  RestaurantMenuItemModel({
    required this.id,
    required this.vendorId,
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.imageUrl,
    required this.price,
    required this.comparePrice,
    required this.hasDiscount,
    required this.isAvailable,
    required this.hasModifiers,
    this.productType = 'food',
    this.stockUnit = 'piece',
    this.stockStep = '1',
    this.storeCategory,
    this.itemsCount = '0',
  });

  final String id;
  final String vendorId;
  final String categoryId;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String imageUrl;
  final double price;
  final double? comparePrice;
  final bool hasDiscount;
  final bool isAvailable;
  final bool hasModifiers;
  final String productType;
  final String stockUnit;
  final String stockStep;
  final String? storeCategory;
  final String itemsCount;

  factory RestaurantMenuItemModel.fromJson(Map<String, dynamic> json) {
    return RestaurantMenuItemModel(
      id: '${json['id'] ?? ''}',
      vendorId: '${json['vendor_id'] ?? ''}',
      categoryId: '${json['category_id'] ?? ''}',
      nameAr: '${json['name_ar'] ?? ''}',
      nameEn: '${json['name_en'] ?? ''}',
      descriptionAr: '${json['description_ar'] ?? ''}',
      descriptionEn: '${json['description_en'] ?? ''}',
      imageUrl: '${json['image_url'] ?? ''}',
      price: _restaurantDouble(json['price']),
      comparePrice: json['compare_price'] == null
          ? null
          : _restaurantDouble(json['compare_price']),
      hasDiscount: _restaurantBool(json['has_discount']),
      isAvailable: _restaurantBool(json['is_available']),
      hasModifiers: _restaurantBool(json['has_modifiers']),
      productType: '${json['product_type'] ?? 'food'}',
      stockUnit: '${json['stock_unit'] ?? 'piece'}',
      stockStep: '${json['stock_step'] ?? '1'}',
      storeCategory: json['store_category']?.toString(),
      itemsCount: '${json['items_count'] ?? '0'}',
    );
  }
}

List<T> _mapRestaurantList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> item) mapper,
) {
  if (raw is! List) {
    return [];
  }
  return raw
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList();
}

List<String> _restaurantStringList(dynamic raw) {
  if (raw is! List) {
    return [];
  }
  return raw
      .map((item) => '$item')
      .where((item) => item.trim().isNotEmpty)
      .toList();
}

int _restaurantInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse('$value') ?? 0;
}

double _restaurantDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse('$value') ?? 0;
}

String _restaurantImageValue(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

bool _restaurantBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  final normalized = '$value'.toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}
