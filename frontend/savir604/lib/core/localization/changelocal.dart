import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/services/services.dart';

class LocaleController extends GetxController {
  late Locale language;
  final MyServices myServices = Get.find();

  void changeLang(String codelang) {
    language = Locale(codelang);
    Get.updateLocale(language);
    myServices.sharedPreferences.setString("lang", codelang);
    update();
  }

  @override
  void onInit() {
    final String? savedLang = myServices.sharedPreferences.getString("lang");
    final String? deviceLang = Get.deviceLocale?.languageCode.toLowerCase();

    if (savedLang == "ar") {
      language = const Locale("ar");
    } else if (savedLang == "en") {
      language = const Locale("en");
    } else if (deviceLang == "en") {
      language = const Locale("en");
    } else {
      language = const Locale("ar");
    }

    Get.updateLocale(language);
    super.onInit();
  }
}
