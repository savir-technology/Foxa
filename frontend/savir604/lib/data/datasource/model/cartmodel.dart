class CartModel {
  String? totalItemsPrice;
  String? countitems;
  String? cartId;
  String? cartUsersid;
  String? cartItemsid;
  String? cartVariantId;
  String? cartItemColor;
  String? cartItemSize;
  String? cartLensCode;
  String? cartLensName;
  String? cartLensColor;
  String? cartLensFeatures;
  String? cartLensPrice;
  String? cartPrescriptionJson;
  String? cartPrescriptionSummary;
  String? cartConfigHash;
  String? cartContextType;
  String? cartVendorId;
  String? vendorId;
  String? vendorName;
  String? storeName;
  String? vendorLogo;
  String? cartUnitPrice;
  String? cartItemNote;
  String? cartMenuOptionsJson;
  String? cartMenuOptionsSummary;
  String? cartVariantAttributesJson;
  String? stockUnit;
  String? weightQuantity;
  String? lineTotal;
  String? lineSubtotal;
  String? lineDiscount;
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

  CartModel({
    this.totalItemsPrice,
    this.countitems,
    this.cartId,
    this.cartUsersid,
    this.cartItemsid,
    this.cartVariantId,
    this.cartItemColor,
    this.cartItemSize,
    this.cartLensCode,
    this.cartLensName,
    this.cartLensColor,
    this.cartLensFeatures,
    this.cartLensPrice,
    this.cartPrescriptionJson,
    this.cartPrescriptionSummary,
    this.cartConfigHash,
    this.cartContextType,
    this.cartVendorId,
    this.vendorId,
    this.vendorName,
    this.storeName,
    this.vendorLogo,
    this.cartUnitPrice,
    this.cartItemNote,
    this.cartMenuOptionsJson,
    this.cartMenuOptionsSummary,
    this.cartVariantAttributesJson,
    this.stockUnit,
    this.lineTotal,
    this.lineSubtotal,
    this.lineDiscount,
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
  });

  CartModel.fromJson(Map<String, dynamic> json) {
    totalItemsPrice = json['total_items_price']?.toString() ?? "0.0";
    countitems = json['countitems']?.toString() ?? "0";
    cartId = json['cart_id']?.toString() ?? "";
    cartUsersid = json['cart_usersid']?.toString() ?? "";
    cartItemsid = json['cart_itemsid']?.toString() ?? "";
    cartVariantId = json['cart_variantid']?.toString() ?? "";
    cartItemColor = json['item_color']?.toString() ??
        json['cart_item_color']?.toString() ??
        "";
    cartItemSize = json['item_size']?.toString() ??
        json['cart_item_size']?.toString() ??
        "";
    cartLensCode = json['cart_lens_code']?.toString() ?? "";
    cartLensName = json['cart_lens_name']?.toString() ?? "";
    cartLensColor = json['cart_lens_color']?.toString() ?? "";
    cartLensFeatures = json['cart_lens_features']?.toString() ?? "";
    cartLensPrice = json['cart_lens_price']?.toString() ?? "0.0";
    cartPrescriptionJson = json['cart_prescription_json']?.toString() ?? "";
    cartPrescriptionSummary =
        json['cart_prescription_summary']?.toString() ?? "";
    cartConfigHash = json['cart_config_hash']?.toString() ?? "";
    cartContextType = json['cart_context_type']?.toString() ?? "product";
    cartVendorId = json['cart_vendor_id']?.toString() ??
        json['vendor_id']?.toString() ??
        "";
    vendorId = json['vendor_id']?.toString() ?? "";
    vendorName = json['vendor_name']?.toString() ?? "";
    storeName = json['store_name']?.toString() ?? "";
    vendorLogo = json['vendor_logo']?.toString() ?? "";
    cartUnitPrice = json['cart_unit_price']?.toString() ?? "";
    cartItemNote = json['cart_item_note']?.toString() ?? "";
    cartMenuOptionsJson = json['cart_menu_options_json']?.toString() ?? "";
    cartMenuOptionsSummary =
        json['cart_menu_options_summary']?.toString() ?? "";
    cartVariantAttributesJson =
        json['cart_variant_attributes_json']?.toString() ?? "";
    stockUnit = json['stock_unit']?.toString() ?? "piece";
    weightQuantity = json['weight_quantity']?.toString();
    lineTotal = json['line_total']?.toString() ?? "0.0";
    lineSubtotal = json['line_subtotal']?.toString() ?? "0.0";
    lineDiscount = json['line_discount']?.toString() ?? "0.0";
    itemsId = json['items_id']?.toString() ?? "";
    itemsNameEn = json['items_name_en']?.toString() ?? "";
    itemsNameAr = json['items_name_ar']?.toString() ?? "";
    itemsDescEn = json['items_desc_en']?.toString() ?? "";
    itemsDescAr = json['items_desc_ar']?.toString() ?? "";
    itemsImage = json['items_image_effective']?.toString() ??
        json['items_image']?.toString() ??
        "";
    itemsCount = json['items_count']?.toString() ?? "0";
    itemsActive = json['items_active']?.toString() ?? "";
    itemsPrice = json['items_price']?.toString() ?? "0.0";
    itemsDiscount = json['items_discount']?.toString() ?? "0";
    itemsDate = json['items_date']?.toString() ?? "";
    itemsCat = json['items_cat']?.toString() ?? "";
  }

  get itemsDiscountPrice => null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_items_price'] = totalItemsPrice;
    data['countitems'] = countitems;
    data['cart_id'] = cartId;
    data['cart_usersid'] = cartUsersid;
    data['cart_itemsid'] = cartItemsid;
    data['cart_variantid'] = cartVariantId;
    data['cart_item_color'] = cartItemColor;
    data['cart_item_size'] = cartItemSize;
    data['cart_lens_code'] = cartLensCode;
    data['cart_lens_name'] = cartLensName;
    data['cart_lens_color'] = cartLensColor;
    data['cart_lens_features'] = cartLensFeatures;
    data['cart_lens_price'] = cartLensPrice;
    data['cart_prescription_json'] = cartPrescriptionJson;
    data['cart_prescription_summary'] = cartPrescriptionSummary;
    data['cart_config_hash'] = cartConfigHash;
    data['cart_context_type'] = cartContextType;
    data['cart_vendor_id'] = cartVendorId;
    data['vendor_id'] = vendorId;
    data['vendor_name'] = vendorName;
    data['store_name'] = storeName;
    data['vendor_logo'] = vendorLogo;
    data['cart_unit_price'] = cartUnitPrice;
    data['cart_item_note'] = cartItemNote;
    data['cart_menu_options_json'] = cartMenuOptionsJson;
    data['cart_menu_options_summary'] = cartMenuOptionsSummary;
    data['cart_variant_attributes_json'] = cartVariantAttributesJson;
    data['stock_unit'] = stockUnit;
    data['weight_quantity'] = weightQuantity;
    data['line_total'] = lineTotal;
    data['line_subtotal'] = lineSubtotal;
    data['line_discount'] = lineDiscount;
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
    data['items_date'] = itemsDate;
    data['items_cat'] = itemsCat;
    return data;
  }

  bool get hasLensSelection => (cartLensCode ?? '').isNotEmpty;

  bool get hasVariantSelection =>
      (cartItemColor ?? '').isNotEmpty || (cartItemSize ?? '').isNotEmpty;

  String get resolvedVendorId => (cartVendorId ?? vendorId ?? '').trim();

  String get displayVendorName {
    final store = (storeName ?? '').trim();
    if (store.isNotEmpty) return store;
    final vendor = (vendorName ?? '').trim();
    if (vendor.isNotEmpty) return vendor;
    return '';
  }

  String get displayVendorLogo => (vendorLogo ?? '').trim();
}
