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
  String? itemsDate;
  String? itemsCat;
  String? vendorId;
  String? vendorName;
  String? storeName;
  String? storeSlug;
  String? productType;
  String? stockUnit;

  ItemsModel({
    this.itemsId,
    this.itemsNameEn,
    this.itemsNameAr,
    this.itemsDescEn,
    this.itemsDescAr,
    this.itemsImage,
    this.itemsCount,
    this.itemsActive,
    this.itemsPrice,
    this.itemsDiscount,
    this.itemsDate,
    this.itemsCat,
    this.vendorId,
    this.vendorName,
    this.storeName,
    this.storeSlug,
    this.productType,
    this.stockUnit,
  });

  // 🔹 تحويل من JSON إلى كائن Dart
  ItemsModel.fromJson(Map<String, dynamic> json) {
    itemsId = json['items_id']?.toString();
    itemsNameEn = json['items_name_en'];
    itemsNameAr = json['items_name_ar'];
    itemsDescEn = json['items_desc_en'];
    itemsDescAr = json['items_desc_ar'];
    itemsImage = json['items_image'];
    itemsCount = json['items_count']?.toString();
    itemsActive = json['items_active']?.toString();
    itemsPrice = json['items_price']?.toString();
    itemsDiscount = json['items_discount']?.toString();
    itemsDate = json['items_date'];
    itemsCat = json['items_cat']?.toString();
    vendorId = json['vendor_id']?.toString();
    vendorName = json['vendor_name']?.toString();
    storeName = json['store_name']?.toString();
    storeSlug = json['store_slug']?.toString();
    productType = json['product_type']?.toString();
    stockUnit = json['stock_unit']?.toString();
  }

  // 🔹 تحويل من كائن Dart إلى JSON لإرساله للسيرفر
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['items_id'] = itemsId;
    data['items_name_en'] = itemsNameEn;
    data['items_name_ar'] = itemsNameAr;
    data['items_desc_en'] = itemsDescEn;
    data['items_desc_ar'] = itemsDescAr;
    data['items_price'] = itemsPrice;
    data['items_count'] = itemsCount;
    data['items_discount'] = itemsDiscount;
    data['items_cat'] = itemsCat;
    data['items_active'] = itemsActive;
    data['vendor_id'] = vendorId;
    data['vendor_name'] = vendorName;
    data['store_name'] = storeName;
    data['store_slug'] = storeSlug;
    data['product_type'] = productType;
    data['stock_unit'] = stockUnit;

    // ✅ إرسال الصورة فقط إذا كانت موجودة فعلاً (Base64 أو اسم ملف)
    if (itemsImage != null && itemsImage!.isNotEmpty) {
      data['items_image'] = itemsImage;
    }

    return data;
  }
}
