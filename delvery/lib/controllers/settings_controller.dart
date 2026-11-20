import 'package:delvery/controllers/auth_controller.dart';
import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  SettingsController(this.sessionService);

  final DriverSessionService sessionService;
  final RxBool notificationsEnabled = true.obs;
  final RxBool vibrationEnabled = true.obs;
  final RxBool locationSharingEnabled = true.obs;
  final RxString localeLabel = 'العربية'.obs;

  @override
  void onInit() {
    super.onInit();
    localeLabel.value = sessionService.localeCode.value == 'ar'
        ? 'العربية'
        : 'English';
    notificationsEnabled.value = sessionService.notificationsEnabled.value;
    vibrationEnabled.value = sessionService.vibrationEnabled.value;
    locationSharingEnabled.value = sessionService.locationSharingEnabled.value;
  }

  Future<void> toggleTheme(bool dark) async {
    await sessionService.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
    update();
  }

  Future<void> toggleLocale(String code) async {
    localeLabel.value = code == 'ar' ? 'العربية' : 'English';
    await sessionService.setLocale(code);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled.value = value;
    await sessionService.setNotificationsEnabled(value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    vibrationEnabled.value = value;
    await sessionService.setVibrationEnabled(value);
  }

  Future<void> setLocationSharingEnabled(bool value) async {
    locationSharingEnabled.value = value;
    await sessionService.setLocationSharingEnabled(value);
  }

  Future<void> signOut() async {
    await sessionService.signOut();
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().resetAllForms();
    }
    Get.offAllNamed(AppRoutes.login);
  }
}
