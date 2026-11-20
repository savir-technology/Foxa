import 'package:tks/data/datasource/model/itemsmodel.dart';

class AleppoHomeModel {
  AleppoHomeModel({
    required this.marketingHeadlineAr,
    required this.marketingHeadlineEn,
    required this.marketingSubtitleAr,
    required this.marketingSubtitleEn,
    required this.deliveryPromptAr,
    required this.deliveryPromptEn,
    required this.stories,
    required this.banners,
    required this.categories,
    required this.restaurantCategories,
    required this.storeCategories,
    required this.occasions,
    required this.sections,
    required this.productSections,
    this.notificationBanner,
  });

  final String marketingHeadlineAr;
  final String marketingHeadlineEn;
  final String marketingSubtitleAr;
  final String marketingSubtitleEn;
  final String deliveryPromptAr;
  final String deliveryPromptEn;
  final List<AleppoHomeStoryModel> stories;
  final List<AleppoHomeBannerModel> banners;
  final List<AleppoFoodCategoryModel> categories;
  final List<AleppoFoodCategoryModel> restaurantCategories;
  final List<AleppoFoodCategoryModel> storeCategories;
  final List<AleppoOccasionModel> occasions;
  final List<AleppoRestaurantSectionModel> sections;
  final List<AleppoProductSectionModel> productSections;
  final AleppoHomeBannerModel? notificationBanner;

  factory AleppoHomeModel.fromJson(Map<String, dynamic> json) {
    return AleppoHomeModel(
      marketingHeadlineAr: '${json['marketing_headline_ar'] ?? ''}',
      marketingHeadlineEn: '${json['marketing_headline_en'] ?? ''}',
      marketingSubtitleAr: '${json['marketing_subtitle_ar'] ?? ''}',
      marketingSubtitleEn: '${json['marketing_subtitle_en'] ?? ''}',
      deliveryPromptAr: '${json['delivery_prompt_ar'] ?? ''}',
      deliveryPromptEn: '${json['delivery_prompt_en'] ?? ''}',
      stories: _mapList(
        json['stories'],
        (item) => AleppoHomeStoryModel.fromJson(item),
      ),
      banners: _mapList(
        json['banners'],
        (item) => AleppoHomeBannerModel.fromJson(item),
      ),
      categories: _mapList(
        json['categories'],
        (item) => AleppoFoodCategoryModel.fromJson(item),
      ),
      restaurantCategories: _mapList(
        json['restaurant_categories'] ?? json['categories'],
        (item) => AleppoFoodCategoryModel.fromJson(item),
      ),
      storeCategories: _mapList(
        json['store_categories'],
        (item) => AleppoFoodCategoryModel.fromJson(item),
      ),
      occasions: _mapList(
        json['occasions'],
        (item) => AleppoOccasionModel.fromJson(item),
      ),
      sections: _mapList(
        json['sections'],
        (item) => AleppoRestaurantSectionModel.fromJson(item),
      ),
      productSections: _mapList(
        json['product_sections'],
        (item) => AleppoProductSectionModel.fromJson(item),
      ),
      notificationBanner: json['notification_banner'] is Map<String, dynamic>
          ? AleppoHomeBannerModel.fromJson(json['notification_banner'])
          : null,
    );
  }
}

class AleppoHomeStoryModel {
  AleppoHomeStoryModel({
    required this.id,
    required this.restaurantId,
    required this.targetType,
    required this.targetId,
    required this.titleAr,
    required this.titleEn,
    required this.imageUrl,
    required this.videoUrl,
    required this.mediaType,
    required this.ctaLabelAr,
    required this.ctaLabelEn,
  });

  final int id;
  final int restaurantId;
  final String targetType;
  final int targetId;
  final String titleAr;
  final String titleEn;
  final String imageUrl;
  final String videoUrl;
  final String mediaType;
  final String ctaLabelAr;
  final String ctaLabelEn;

  String get normalizedTargetType {
    final raw = targetType.trim().toLowerCase();
    if (raw == 'item') {
      return 'product';
    }
    if (raw == 'restaurant' || raw == 'product') {
      return raw;
    }
    return restaurantId > 0 ? 'restaurant' : '';
  }

  int get resolvedTargetId => targetId > 0 ? targetId : restaurantId;

  bool get hasInternalTarget =>
      normalizedTargetType.isNotEmpty && resolvedTargetId > 0;

  factory AleppoHomeStoryModel.fromJson(Map<String, dynamic> json) {
    return AleppoHomeStoryModel(
      id: _toInt(json['id']),
      restaurantId: _toInt(json['restaurant_id']),
      targetType: '${json['target_type'] ?? ''}',
      targetId: _toInt(json['target_id']),
      titleAr: '${json['title_ar'] ?? ''}',
      titleEn: '${json['title_en'] ?? ''}',
      imageUrl: '${json['image_url'] ?? ''}',
      videoUrl: '${json['video_url'] ?? ''}',
      mediaType: '${json['media_type'] ?? 'image'}',
      ctaLabelAr: '${json['cta_label_ar'] ?? ''}',
      ctaLabelEn: '${json['cta_label_en'] ?? ''}',
    );
  }
}

class AleppoHomeBannerModel {
  AleppoHomeBannerModel({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.imageUrl,
    required this.backgroundColor,
    required this.textColor,
    required this.ctaLabelAr,
    required this.ctaLabelEn,
    required this.ctaTarget,
    required this.placement,
  });

  final int id;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final String imageUrl;
  final String backgroundColor;
  final String textColor;
  final String ctaLabelAr;
  final String ctaLabelEn;
  final String ctaTarget;
  final String placement;

  factory AleppoHomeBannerModel.fromJson(Map<String, dynamic> json) {
    return AleppoHomeBannerModel(
      id: _toInt(json['id']),
      titleAr: '${json['title_ar'] ?? ''}',
      titleEn: '${json['title_en'] ?? ''}',
      subtitleAr: '${json['subtitle_ar'] ?? ''}',
      subtitleEn: '${json['subtitle_en'] ?? ''}',
      imageUrl: '${json['image_url'] ?? ''}',
      backgroundColor: '${json['background_color'] ?? '#21461f'}',
      textColor: '${json['text_color'] ?? '#ffffff'}',
      ctaLabelAr: '${json['cta_label_ar'] ?? ''}',
      ctaLabelEn: '${json['cta_label_en'] ?? ''}',
      ctaTarget: '${json['cta_target'] ?? ''}',
      placement: '${json['placement'] ?? 'home'}',
    );
  }
}

class AleppoFoodCategoryModel {
  AleppoFoodCategoryModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.imageUrl,
    required this.icon,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String imageUrl;
  final String icon;

  factory AleppoFoodCategoryModel.fromJson(Map<String, dynamic> json) {
    return AleppoFoodCategoryModel(
      id: _toInt(json['id']),
      nameAr: '${json['name_ar'] ?? ''}',
      nameEn: '${json['name_en'] ?? ''}',
      imageUrl: '${json['image_url'] ?? ''}',
      icon: '${json['icon'] ?? ''}',
    );
  }
}

class AleppoOccasionModel {
  AleppoOccasionModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.color,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String color;

  factory AleppoOccasionModel.fromJson(Map<String, dynamic> json) {
    return AleppoOccasionModel(
      id: _toInt(json['id']),
      nameAr: '${json['name_ar'] ?? ''}',
      nameEn: '${json['name_en'] ?? ''}',
      color: '${json['color'] ?? '#f5f1e5'}',
    );
  }
}

class AleppoProductSectionModel {
  AleppoProductSectionModel({
    required this.key,
    required this.titleAr,
    required this.titleEn,
    required this.items,
  });

  final String key;
  final String titleAr;
  final String titleEn;
  final List<ItemsModel> items;

  factory AleppoProductSectionModel.fromJson(Map<String, dynamic> json) {
    return AleppoProductSectionModel(
      key: '${json['key'] ?? ''}',
      titleAr: '${json['title_ar'] ?? ''}',
      titleEn: '${json['title_en'] ?? ''}',
      items: _mapList(
        json['items'],
        (item) => ItemsModel.fromJson(item),
      ),
    );
  }
}

class AleppoRestaurantSectionModel {
  AleppoRestaurantSectionModel({
    required this.key,
    required this.titleAr,
    required this.titleEn,
    required this.restaurants,
  });

  final String key;
  final String titleAr;
  final String titleEn;
  final List<AleppoRestaurantModel> restaurants;

  factory AleppoRestaurantSectionModel.fromJson(Map<String, dynamic> json) {
    return AleppoRestaurantSectionModel(
      key: '${json['key'] ?? ''}',
      titleAr: '${json['title_ar'] ?? ''}',
      titleEn: '${json['title_en'] ?? ''}',
      restaurants: _mapList(
        json['restaurants'],
        (item) => AleppoRestaurantModel.fromJson(item),
      ),
    );
  }
}

class AleppoRestaurantModel {
  AleppoRestaurantModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.taglineAr,
    required this.taglineEn,
    required this.logoUrl,
    required this.coverImageUrl,
    required this.rating,
    required this.reviewsCount,
    required this.deliveryFee,
    required this.estimatedMinMinutes,
    required this.estimatedMaxMinutes,
    required this.distanceKm,
    required this.isOpen,
    required this.isNew,
    required this.discountLabelAr,
    required this.discountLabelEn,
    required this.badgesAr,
    required this.badgesEn,
    this.vendorType = 'restaurant',
    this.entityLabelAr = 'مطعم',
    this.entityLabelEn = 'Restaurant',
  });

  final int id;
  final String name;
  final String slug;
  final String taglineAr;
  final String taglineEn;
  final String logoUrl;
  final String coverImageUrl;
  final double rating;
  final int reviewsCount;
  final double deliveryFee;
  final int estimatedMinMinutes;
  final int estimatedMaxMinutes;
  final double? distanceKm;
  final bool isOpen;
  final bool isNew;
  final String discountLabelAr;
  final String discountLabelEn;
  final List<String> badgesAr;
  final List<String> badgesEn;
  final String vendorType;
  final String entityLabelAr;
  final String entityLabelEn;

  String entityLabel(bool isArabic) => isArabic ? entityLabelAr : entityLabelEn;

  factory AleppoRestaurantModel.fromJson(Map<String, dynamic> json) {
    return AleppoRestaurantModel(
      id: _toInt(json['id']),
      name: '${json['name'] ?? ''}',
      slug: '${json['slug'] ?? ''}',
      taglineAr: '${json['tagline_ar'] ?? ''}',
      taglineEn: '${json['tagline_en'] ?? ''}',
      logoUrl: _imageValue(json, const ['vendor_logo', 'logo_url']),
      coverImageUrl: _imageValue(
        json,
        const ['store_banner_url', 'banner_url', 'cover_image_url'],
      ),
      rating: _toDouble(json['rating']),
      reviewsCount: _toInt(json['reviews_count']),
      deliveryFee: _toDouble(json['delivery_fee']),
      estimatedMinMinutes: _toInt(json['estimated_min_minutes']),
      estimatedMaxMinutes: _toInt(json['estimated_max_minutes']),
      distanceKm:
          json['distance_km'] == null ? null : _toDouble(json['distance_km']),
      isOpen: _toBool(json['is_open']),
      isNew: _toBool(json['is_new']),
      discountLabelAr: '${json['discount_label_ar'] ?? ''}',
      discountLabelEn: '${json['discount_label_en'] ?? ''}',
      badgesAr: _toStringList(json['badges_ar']),
      badgesEn: _toStringList(json['badges_en']),
      vendorType: '${json['vendor_type'] ?? 'restaurant'}',
      entityLabelAr: '${json['entity_label_ar'] ?? 'مطعم'}',
      entityLabelEn: '${json['entity_label_en'] ?? 'Restaurant'}',
    );
  }
}

List<T> _mapList<T>(
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

List<String> _toStringList(dynamic raw) {
  if (raw is! List) {
    return [];
  }
  return raw
      .map((item) => '$item')
      .where((item) => item.trim().isNotEmpty)
      .toList();
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse('$value') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse('$value') ?? 0;
}

String _imageValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) {
      return value;
    }
  }
  return '';
}

bool _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  final normalized = '$value'.toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}
