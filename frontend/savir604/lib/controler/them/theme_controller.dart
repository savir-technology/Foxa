import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/services/services.dart';

class ThemeController extends GetxController {
  ThemeController(this._services);

  final MyServices _services;
  final RxBool isDarkMode = false.obs;

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value =
        _services.sharedPreferences.getBool('isDarkMode') ?? false;
  }

  void toggleTheme() {
    setTheme(!isDarkMode.value);
  }

  void setTheme(bool isDark) {
    isDarkMode.value = isDark;
    _services.sharedPreferences.setBool('isDarkMode', isDarkMode.value);
    Get.changeThemeMode(themeMode);
    update();
  }
}
