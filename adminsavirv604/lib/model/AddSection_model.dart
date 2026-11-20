class SectionModel {
  String arabicName;
  String englishName;
  String imageBase64;

  SectionModel({
    required this.arabicName,
    required this.englishName,
    required this.imageBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      "categories_name_ar": arabicName,
      "categories_name_en": englishName,
      "categories_image": imageBase64,
    };
  }
}
