class LensModel {
  String? lensId;
  String? lensCode;
  String? lensNameAr;
  String? lensNameEn;
  String? lensType;
  String? lensColor;
  String? lensPrice;
  String? lensFeaturesAr;
  String? lensFeaturesEn;
  String? priorityLight;
  String? priorityMedium;
  String? priorityHigh;
  String? isActive;

  LensModel({
    this.lensId,
    this.lensCode,
    this.lensNameAr,
    this.lensNameEn,
    this.lensType,
    this.lensColor,
    this.lensPrice,
    this.lensFeaturesAr,
    this.lensFeaturesEn,
    this.priorityLight,
    this.priorityMedium,
    this.priorityHigh,
    this.isActive,
  });

  factory LensModel.fromJson(Map<String, dynamic> json) {
    return LensModel(
      lensId: json['lens_id']?.toString(),
      lensCode: json['lens_code']?.toString(),
      lensNameAr: json['lens_name_ar']?.toString(),
      lensNameEn: json['lens_name_en']?.toString(),
      lensType: json['lens_type']?.toString(),
      lensColor: json['lens_color']?.toString(),
      lensPrice: json['lens_price']?.toString(),
      lensFeaturesAr: json['lens_features_ar']?.toString(),
      lensFeaturesEn: json['lens_features_en']?.toString(),
      priorityLight: json['priority_light']?.toString(),
      priorityMedium: json['priority_medium']?.toString(),
      priorityHigh: json['priority_high']?.toString(),
      isActive: json['is_active']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lens_id': lensId,
      'lens_code': lensCode,
      'lens_name_ar': lensNameAr,
      'lens_name_en': lensNameEn,
      'lens_type': lensType,
      'lens_color': lensColor,
      'lens_price': lensPrice,
      'lens_features_ar': lensFeaturesAr,
      'lens_features_en': lensFeaturesEn,
      'priority_light': priorityLight,
      'priority_medium': priorityMedium,
      'priority_high': priorityHigh,
      'is_active': isActive ?? '1',
    };
  }
}
