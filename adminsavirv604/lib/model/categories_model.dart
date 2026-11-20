class cat {
  String? categoriesId;
  String? categoriesNameEn;
  String? categoriesNameAr;
  String? categoriesImage;

  cat(
      {this.categoriesId,
      this.categoriesNameEn,
      this.categoriesNameAr,
      this.categoriesImage});

  cat.fromJson(Map<String, dynamic> json) {
    categoriesId = json['categories_id'].toString();
    categoriesNameEn = json['categories_name_en'].toString();
    categoriesNameAr = json['categories_name_ar'].toString();
    categoriesImage = json['categories_image'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['categories_id'] = categoriesId.toString();
    data['categories_name_en'] = categoriesNameEn.toString();
    data['categories_name_ar'] = categoriesNameAr.toString();
    data['categories_image'] = categoriesImage.toString();
    return data;
  }
}
