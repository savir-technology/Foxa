class ItemsModel {
  String? itemsId;
  String? itemsNameEn;
  String? itemsNameAr;
  String? itemsDescEn;
  String? itemsDescAr;
  String? itemsImage;
  String? itemsCount;
  String? itemsActive;
  String? itemsPrice;
  String? itemsDiscount;
  String? itemsDiscountPrice;
  String? galleryImages;
  String? itemsDate;
  String? itemsCat;
  String? itemsColor;
  String? itemsSize;
  String? categoriesId;
  String? categoriesNameEn;
  String? categoriesNameAr;
  String? categoriesImage;
  String? categoriesDatetime;
  String? favorite;
  String? vendorId;
  String? vendorName;
  String? storeName;
  String? storeSlug;
  String? vendorLogo;
  String? averageRating;
  String? ratingsCount;
  String? ratingPercentage;
  String? isTopRated;
  String? productType;
  String? stockUnit;
  String? stockStep;
  String? vendorType;
  String? storeCategory;

  ItemsModel({
    this.itemsId,
    this.itemsNameEn,
    this.itemsNameAr,
    this.itemsDescEn,
    this.itemsDescAr,
    this.itemsDiscountPrice,
    this.galleryImages,
    this.itemsImage,
    this.itemsCount,
    this.itemsActive,
    this.itemsPrice,
    this.itemsDiscount,
    this.itemsDate,
    this.itemsCat,
    this.itemsColor,
    this.itemsSize,
    this.categoriesId,
    this.categoriesNameEn,
    this.categoriesNameAr,
    this.categoriesImage,
    this.categoriesDatetime,
    this.favorite,
    this.vendorId,
    this.vendorName,
    this.storeName,
    this.storeSlug,
    this.vendorLogo,
    this.averageRating,
    this.ratingsCount,
    this.ratingPercentage,
    this.isTopRated,
    this.productType,
    this.stockUnit,
    this.stockStep,
    this.vendorType,
    this.storeCategory,
  });

  ItemsModel.fromJson(Map<String, dynamic> json) {
    itemsId = json['items_id']?.toString();
    itemsNameEn = json['items_name_en']?.toString();
    itemsNameAr = json['items_name_ar']?.toString();
    itemsDescEn = json['items_desc_en']?.toString();
    itemsDescAr = json['items_desc_ar']?.toString();
    itemsImage = json['items_image']?.toString();
    itemsCount = json['items_count']?.toString();
    itemsActive = json['items_active']?.toString();
    itemsPrice = json['items_price']?.toString();
    itemsDiscount = json['items_discount']?.toString();
    itemsDiscountPrice = json['items_discount_price']?.toString() ??
        json['itemspricedisount']?.toString();
    galleryImages = json['gallery_images']?.toString();
    itemsDate = json['items_date']?.toString();
    itemsCat = json['items_cat']?.toString();
    itemsColor = json['items_color']?.toString();
    itemsSize = json['items_size']?.toString();
    categoriesId = json['categories_id']?.toString();
    categoriesNameEn = json['categories_name_en']?.toString();
    categoriesNameAr = json['categories_name_ar']?.toString();
    categoriesImage = json['categories_image']?.toString();
    categoriesDatetime = json['categories_datetime']?.toString();
    favorite = json['favorite']?.toString();
    vendorId = json['vendor_id']?.toString();
    vendorName = json['vendor_name']?.toString();
    storeName = json['store_name']?.toString();
    storeSlug = json['store_slug']?.toString();
    vendorLogo = json['vendor_logo']?.toString();
    averageRating = json['average_rating']?.toString();
    ratingsCount = json['ratings_count']?.toString();
    ratingPercentage = json['rating_percentage']?.toString();
    isTopRated = json['is_top_rated']?.toString();
    productType = json['product_type']?.toString();
    stockUnit = json['stock_unit']?.toString();
    stockStep = json['stock_step']?.toString();
    vendorType = json['vendor_type']?.toString();
    storeCategory = json['store_category']?.toString();
  }

  double get itemsPriceDiscount {
    double price = double.tryParse(itemsPrice ?? '0') ?? 0;
    double discount = double.tryParse(itemsDiscount ?? '0') ?? 0;
    return price - (price * (discount / 100));
  }

  double get averageRatingValue => double.tryParse(averageRating ?? '0') ?? 0.0;

  int get ratingsCountValue => int.tryParse(ratingsCount ?? '0') ?? 0;

  int get ratingPercentageValue => int.tryParse(ratingPercentage ?? '0') ?? 0;

  bool get isTopRatedValue => isTopRated == '1';

  List<String> get galleryImagePaths {
    final images = (galleryImages ?? '')
        .split('||')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (images.isEmpty && (itemsImage ?? '').trim().isNotEmpty) {
      images.add(itemsImage!.trim());
    }
    return images.toSet().toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['items_id'] = itemsId;
    data['items_name_en'] = itemsNameEn;
    data['items_name_ar'] = itemsNameAr;
    data['items_desc_en'] = itemsDescEn;
    data['items_desc_ar'] = itemsDescAr;
    data['items_image'] = itemsImage;
    data['items_count'] = itemsCount;
    data['items_active'] = itemsActive;
    data['items_price'] = itemsPrice;
    data['items_discount'] = itemsDiscount;
    data['items_discount_price'] = itemsDiscountPrice;
    data['gallery_images'] = galleryImages;
    data['items_date'] = itemsDate;
    data['items_cat'] = itemsCat;
    data['items_color'] = itemsColor;
    data['items_size'] = itemsSize;
    data['categories_id'] = categoriesId;
    data['categories_name_en'] = categoriesNameEn;
    data['categories_name_ar'] = categoriesNameAr;
    data['categories_image'] = categoriesImage;
    data['categories_datetime'] = categoriesDatetime;
    data['favorite'] = favorite;
    data['vendor_id'] = vendorId;
    data['vendor_name'] = vendorName;
    data['store_name'] = storeName;
    data['store_slug'] = storeSlug;
    data['vendor_logo'] = vendorLogo;
    data['average_rating'] = averageRating;
    data['ratings_count'] = ratingsCount;
    data['rating_percentage'] = ratingPercentage;
    data['is_top_rated'] = isTopRated;
    data['product_type'] = productType;
    data['stock_unit'] = stockUnit;
    data['stock_step'] = stockStep;
    data['vendor_type'] = vendorType;
    data['store_category'] = storeCategory;
    return data;
  }
}
