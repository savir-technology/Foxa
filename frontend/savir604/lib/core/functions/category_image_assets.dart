import 'package:tks/core/constant/imsgesassets.dart';

String categoryFallbackAsset({
  required String? nameAr,
  required String? nameEn,
  String? imageUrl,
}) {
  final haystack = <String?>[nameAr, nameEn, imageUrl]
      .whereType<String>()
      .join(' ')
      .toLowerCase();

  if (haystack.contains('shawarma') ||
      haystack.contains('shawar') ||
      haystack.contains('شاورما') ||
      haystack.contains('shaorma')) {
    return AppImageAsset.shawarmaPromo;
  }

  if (haystack.contains('pizza') || haystack.contains('بيتزا')) {
    return AppImageAsset.pizza;
  }

  if (haystack.contains('grill') ||
      haystack.contains('grills') ||
      haystack.contains('مشاوي') ||
      haystack.contains('جريلات')) {
    return AppImageAsset.grills;
  }

  if (haystack.contains('burger') ||
      haystack.contains('برجر') ||
      haystack.contains('bagar')) {
    return AppImageAsset.burgerPromo;
  }

  if (haystack.contains('dessert') ||
      haystack.contains('sweet') ||
      haystack.contains('حلويات')) {
    return AppImageAsset.saleOne;
  }

  return AppImageAsset.logo1;
}
