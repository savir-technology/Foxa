class Category {
  final int id;
  final String nameEn;
  final String nameAr;
  final String image;

  Category(
      {required this.id,
      required this.nameEn,
      required this.nameAr,
      required this.image});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['categories_id'],
      nameEn: json['categories_name_en'],
      nameAr: json['categories_name_ar'],
      image: json['categories_image'],
    );
  }
}
