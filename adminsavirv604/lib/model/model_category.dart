class CategoryModel {
  String categoryId;
  String categoryNameAr;
  String categoryNameEn;
  String categoryActive; // '1' أو '0'
  String? categoryImage; // base64 string للصورة (اختياري)

  CategoryModel({
    required this.categoryId,
    required this.categoryNameAr,
    required this.categoryNameEn,
    required this.categoryActive,
    this.categoryImage,
  });

  // لتحويل الموديل إلى Map لإرسالها في API
  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId.toString(),
      'category_name_ar': categoryNameAr,
      'category_name_en': categoryNameEn,
      'category_active': categoryActive,
      'category_image': categoryImage,
    };
  }

  // لتحويل Map إلى موديل (لو احتجت)
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId: map['category_id'] ?? '',
      categoryNameAr: map['category_name_ar'] ?? '',
      categoryNameEn: map['category_name_en'] ?? '',
      categoryActive: map['category_active'] ?? '1',
      categoryImage: map['category_image'],
    );
  }
}
