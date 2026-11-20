import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/functions/save_token.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/remote/auth/phone_complete_profile.dart';

class UserProfileSetupController extends GetxController {
  final MyServices myServices = Get.find();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final PhoneCompleteProfileData completeProfileData =
      PhoneCompleteProfileData();
  late final TextEditingController fullNameController;
  final ImagePicker _imagePicker = ImagePicker();

  bool isSaving = false;
  bool isPickingImage = false;
  File? profileImageFile;
  StatusRequest statusRequest = StatusRequest.none;

  @override
  void onInit() {
    super.onInit();
    fullNameController = TextEditingController(
      text: myServices.sharedPreferences.getString('username') ?? '',
    );
  }

  String? validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) {
      return 'Enter your full name'.tr;
    }
    if (name.length < 3) {
      return 'Name is too short'.tr;
    }
    return null;
  }

  Future<void> finishSetup() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!myServices.hasAccessToken) {
      Get.snackbar(
        'Session expired'.tr,
        'Please sign in again with Google to continue'.tr,
      );
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    isSaving = true;
    statusRequest = StatusRequest.loading;
    update();

    final response = await completeProfileData.postData(
      fullName: fullNameController.text.trim(),
      locale: Get.locale?.languageCode ?? 'ar',
      accessToken: myServices.accessToken,
      imagePath: profileImageFile?.path,
    );

    if (response is StatusRequest) {
      statusRequest = response;
      isSaving = false;
      update();
      Get.snackbar(
        'Unable to save'.tr,
        'Check your connection and try again'.tr,
      );
      return;
    }

    if ('${response['status'] ?? ''}' != 'success') {
      statusRequest = StatusRequest.failure;
      isSaving = false;
      update();
      Get.snackbar(
        'Unable to save'.tr,
        '${response['message'] ?? 'Unexpected error'}',
      );
      return;
    }

    final user = Map<String, dynamic>.from(
      (response['user'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    await myServices.updateStoredUser(user);

    final userId = int.tryParse('${user['users_id'] ?? 0}') ?? 0;
    if (userId > 0) {
      await saveUserToken(userId);
    }

    isSaving = false;
    statusRequest = StatusRequest.success;
    update();
    Get.offAllNamed(AppRoutes.homepage);
  }

  Future<void> pickProfileImage() async {
    if (isPickingImage) {
      return;
    }

    isPickingImage = true;
    update();

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (picked != null) {
        profileImageFile = File(picked.path);
      }
    } catch (e) {
      Get.snackbar(
        'Unable to pick image'.tr,
        e.toString(),
      );
    } finally {
      isPickingImage = false;
      update();
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    super.onClose();
  }
}
