class FoodItemDetailsModel {
  FoodItemDetailsModel({
    required this.item,
    required this.galleryImages,
    required this.rating,
    required this.reviewsCount,
    required this.tags,
    required this.modifierGroups,
    required this.suggestedItems,
  });

  final FoodItemModel item;
  final List<String> galleryImages;
  final double rating;
  final int reviewsCount;
  final List<FoodDetailTagModel> tags;
  final List<FoodModifierGroupModel> modifierGroups;
  final List<FoodSuggestedItemModel> suggestedItems;

  factory FoodItemDetailsModel.fromJson(Map<String, dynamic> json) {
    return FoodItemDetailsModel(
      item: FoodItemModel.fromJson(
        Map<String, dynamic>.from(json['item'] ?? const {}),
      ),
      galleryImages: _foodStringList(
        json['gallery_images'] ?? json['images'] ?? json['gallery'],
      ),
      rating: _foodDouble(json['rating']),
      reviewsCount: _foodInt(json['reviews_count']),
      tags: _mapFoodList(
        json['tags'],
        (item) => FoodDetailTagModel.fromJson(item),
      ),
      modifierGroups: _mapFoodList(
        json['modifier_groups'],
        (item) => FoodModifierGroupModel.fromJson(item),
      ),
      suggestedItems: _mapFoodList(
        json['suggested_items'],
        (item) => FoodSuggestedItemModel.fromJson(item),
      ),
    );
  }
}

class FoodItemModel {
  FoodItemModel({
    required this.id,
    required this.vendorId,
    required this.categoryId,
    required this.categoryNameAr,
    required this.categoryNameEn,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.imageUrl,
    required this.price,
    required this.comparePrice,
    required this.isAvailable,
  });

  final String id;
  final String vendorId;
  final String categoryId;
  final String categoryNameAr;
  final String categoryNameEn;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String imageUrl;
  final double price;
  final double? comparePrice;
  final bool isAvailable;

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    return FoodItemModel(
      id: '${json['id'] ?? ''}',
      vendorId: '${json['vendor_id'] ?? ''}',
      categoryId: '${json['category_id'] ?? ''}',
      categoryNameAr: '${json['category_name_ar'] ?? ''}',
      categoryNameEn: '${json['category_name_en'] ?? ''}',
      nameAr: '${json['name_ar'] ?? ''}',
      nameEn: '${json['name_en'] ?? ''}',
      descriptionAr: '${json['description_ar'] ?? ''}',
      descriptionEn: '${json['description_en'] ?? ''}',
      imageUrl: '${json['image_url'] ?? ''}',
      price: _foodDouble(json['price']),
      comparePrice: json['compare_price'] == null
          ? null
          : _foodDouble(json['compare_price']),
      isAvailable: _foodBool(json['is_available']),
    );
  }
}

class FoodDetailTagModel {
  FoodDetailTagModel({
    required this.labelAr,
    required this.labelEn,
    required this.iconKey,
  });

  final String labelAr;
  final String labelEn;
  final String iconKey;

  factory FoodDetailTagModel.fromJson(Map<String, dynamic> json) {
    return FoodDetailTagModel(
      labelAr: '${json['label_ar'] ?? json['label'] ?? ''}',
      labelEn: '${json['label_en'] ?? json['label'] ?? ''}',
      iconKey: '${json['icon'] ?? json['icon_key'] ?? 'tag'}',
    );
  }
}

class FoodModifierGroupModel {
  FoodModifierGroupModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.groupType,
    required this.minSelect,
    required this.maxSelect,
    required this.isRequired,
    required this.options,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String groupType;
  final int minSelect;
  final int maxSelect;
  final bool isRequired;
  final List<FoodModifierOptionModel> options;

  factory FoodModifierGroupModel.fromJson(Map<String, dynamic> json) {
    return FoodModifierGroupModel(
      id: '${json['id'] ?? ''}',
      nameAr: '${json['name_ar'] ?? ''}',
      nameEn: '${json['name_en'] ?? ''}',
      groupType: '${json['group_type'] ?? 'modifier'}',
      minSelect: _foodInt(json['min_select']),
      maxSelect: _foodInt(json['max_select']),
      isRequired: _foodBool(json['is_required']),
      options: _mapFoodList(
        json['options'],
        (item) => FoodModifierOptionModel.fromJson(item),
      ),
    );
  }
}

class FoodModifierOptionModel {
  FoodModifierOptionModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.imageUrl,
    required this.priceDelta,
    required this.isDefaultSelected,
    required this.isRemovable,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String imageUrl;
  final double priceDelta;
  final bool isDefaultSelected;
  final bool isRemovable;

  factory FoodModifierOptionModel.fromJson(Map<String, dynamic> json) {
    return FoodModifierOptionModel(
      id: '${json['id'] ?? ''}',
      nameAr: '${json['name_ar'] ?? ''}',
      nameEn: '${json['name_en'] ?? ''}',
      imageUrl: '${json['image_url'] ?? ''}',
      priceDelta: _foodDouble(json['price_delta']),
      isDefaultSelected: _foodBool(json['is_default_selected']),
      isRemovable:
          _foodBool(json['is_removable']) || json['is_removable'] == null,
    );
  }
}

class FoodSuggestedItemModel {
  FoodSuggestedItemModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.imageUrl,
    required this.price,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String imageUrl;
  final double price;

  factory FoodSuggestedItemModel.fromJson(Map<String, dynamic> json) {
    return FoodSuggestedItemModel(
      id: '${json['id'] ?? ''}',
      nameAr: '${json['name_ar'] ?? ''}',
      nameEn: '${json['name_en'] ?? ''}',
      imageUrl: '${json['image_url'] ?? ''}',
      price: _foodDouble(json['price']),
    );
  }
}

List<T> _mapFoodList<T>(
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

List<String> _foodStringList(dynamic raw) {
  if (raw is! List) {
    return [];
  }
  return raw
      .map(_foodStringFromValue)
      .where((item) => item.trim().isNotEmpty)
      .toList();
}

String _foodStringFromValue(dynamic value) {
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    return '${map['url'] ?? map['image_url'] ?? map['path'] ?? map['img_path'] ?? ''}';
  }
  return '$value';
}

int _foodInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse('$value') ?? 0;
}

double _foodDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse('$value') ?? 0;
}

bool _foodBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  final normalized = '$value'.toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}
