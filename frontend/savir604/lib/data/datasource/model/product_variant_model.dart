class VariantColorOption {
  final String id;
  final String nameAr;
  final String nameEn;
  final String hex;

  const VariantColorOption({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.hex,
  });

  factory VariantColorOption.fromJson(Map<String, dynamic> json) {
    final fallbackName = json['color_name']?.toString() ?? '';
    return VariantColorOption(
      id: json['color_id']?.toString() ?? '',
      nameAr: json['color_name_ar']?.toString() ?? fallbackName,
      nameEn: json['color_name_en']?.toString() ?? fallbackName,
      hex:
          json['color_hex']?.toString() ?? json['hex']?.toString() ?? '#D1D5DB',
    );
  }

  String displayName(bool isArabic) => isArabic ? nameAr : nameEn;
}

class VariantSizeOption {
  final String id;
  final String nameAr;
  final String nameEn;
  final int order;

  const VariantSizeOption({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.order,
  });

  factory VariantSizeOption.fromJson(Map<String, dynamic> json) {
    final fallbackName = json['size_name']?.toString() ?? '';
    return VariantSizeOption(
      id: json['size_id']?.toString() ?? '',
      nameAr: json['size_name_ar']?.toString() ?? fallbackName,
      nameEn: json['size_name_en']?.toString() ?? fallbackName,
      order: int.tryParse(
            json['size_order']?.toString() ?? json['order']?.toString() ?? '0',
          ) ??
          0,
    );
  }

  String displayName(bool isArabic) => isArabic ? nameAr : nameEn;
}

class ProductVariantModel {
  final String variantId;
  final String itemId;
  final String colorId;
  final String sizeId;
  final int stock;
  final double price;
  final String imageUrl;
  final String colorNameAr;
  final String colorNameEn;
  final String colorHex;
  final String sizeNameAr;
  final String sizeNameEn;
  final int sizeOrder;
  final String sku;
  final String unit;
  final double stockQuantity;
  final double unitQuantity;
  final List<ProductVariantValue> attributeValues;

  const ProductVariantModel({
    required this.variantId,
    required this.itemId,
    required this.colorId,
    required this.sizeId,
    required this.stock,
    required this.price,
    required this.imageUrl,
    required this.colorNameAr,
    required this.colorNameEn,
    required this.colorHex,
    required this.sizeNameAr,
    required this.sizeNameEn,
    required this.sizeOrder,
    this.sku = '',
    this.unit = 'piece',
    this.stockQuantity = 0,
    this.unitQuantity = 1,
    this.attributeValues = const [],
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    final fallbackColor = json['color_name']?.toString() ?? '';
    final fallbackSize = json['size_name']?.toString() ?? '';
    return ProductVariantModel(
      variantId: json['variant_id']?.toString() ?? '',
      itemId: json['item_id']?.toString() ?? '',
      colorId: json['color_id']?.toString() ?? '',
      sizeId: json['size_id']?.toString() ?? '',
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      imageUrl: json['image_url']?.toString() ?? '',
      colorNameAr: json['color_name_ar']?.toString() ?? fallbackColor,
      colorNameEn: json['color_name_en']?.toString() ?? fallbackColor,
      colorHex: json['color_hex']?.toString() ?? '#D1D5DB',
      sizeNameAr: json['size_name_ar']?.toString() ?? fallbackSize,
      sizeNameEn: json['size_name_en']?.toString() ?? fallbackSize,
      sizeOrder: int.tryParse(json['size_order']?.toString() ?? '0') ?? 0,
      sku: json['sku']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'piece',
      stockQuantity:
          double.tryParse(json['stock_quantity']?.toString() ?? '') ??
              (double.tryParse(json['stock']?.toString() ?? '0') ?? 0),
      unitQuantity: double.tryParse(json['unit_quantity']?.toString() ?? '') ?? 1,
      attributeValues: (json['attribute_values'] as List? ?? const [])
          .whereType<Map>()
          .map((value) =>
              ProductVariantValue.fromJson(Map<String, dynamic>.from(value)))
          .toList(),
    );
  }

  bool get inStock => stockQuantity >= unitQuantity && stock > 0;

  String colorName(bool isArabic) => isArabic ? colorNameAr : colorNameEn;

  String sizeName(bool isArabic) => isArabic ? sizeNameAr : sizeNameEn;
}

class ProductAttributeValue {
  final String id;
  final String valueAr;
  final String valueEn;

  const ProductAttributeValue(
      {required this.id, required this.valueAr, required this.valueEn});

  factory ProductAttributeValue.fromJson(Map<String, dynamic> json) =>
      ProductAttributeValue(
        id: json['id']?.toString() ?? json['value_id']?.toString() ?? '',
        valueAr: json['value_ar']?.toString() ?? '',
        valueEn: json['value_en']?.toString() ?? '',
      );

  String displayName(bool isArabic) => isArabic ? valueAr : valueEn;
}

class ProductVariantValue extends ProductAttributeValue {
  const ProductVariantValue(
      {required super.id, required super.valueAr, required super.valueEn});

  factory ProductVariantValue.fromJson(Map<String, dynamic> json) =>
      ProductVariantValue(
        id: json['id']?.toString() ?? json['value_id']?.toString() ?? '',
        valueAr: json['value_ar']?.toString() ?? '',
        valueEn: json['value_en']?.toString() ?? '',
      );
}

class ProductAttribute {
  final String id;
  final String nameAr;
  final String nameEn;
  final bool required;
  final List<ProductAttributeValue> values;

  const ProductAttribute(
      {required this.id,
      required this.nameAr,
      required this.nameEn,
      required this.required,
      required this.values});

  factory ProductAttribute.fromJson(Map<String, dynamic> json) =>
      ProductAttribute(
        id: json['id']?.toString() ?? json['attribute_id']?.toString() ?? '',
        nameAr: json['name_ar']?.toString() ?? '',
        nameEn: json['name_en']?.toString() ?? '',
        required: json['is_required'] == true ||
            json['is_required']?.toString() == '1',
        values: (json['values'] as List? ?? const [])
            .whereType<Map>()
            .map((v) =>
                ProductAttributeValue.fromJson(Map<String, dynamic>.from(v)))
            .toList(),
      );

  String displayName(bool isArabic) => isArabic ? nameAr : nameEn;
}
