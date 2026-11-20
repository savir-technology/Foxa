import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/functions/save_token.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/remote/auth/google_phone_login.dart';

class GooglePhoneVerificationController extends GetxController {
  final MyServices myServices = Get.find();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GooglePhoneLoginData loginData = GooglePhoneLoginData(Get.find());
  late final TextEditingController phoneController;

  bool isSubmitting = false;
  StatusRequest statusRequest = StatusRequest.none;

  String googleEmail = '';
  String googleName = '';
  String googlePhoto = '';
  String googleUid = '';

  @override
  void onInit() {
    super.onInit();
    googleEmail = myServices.pendingGoogleEmail;
    googleName = myServices.pendingGoogleName;
    googlePhoto = myServices.pendingGooglePhoto;
    googleUid = myServices.pendingGoogleUid;
    phoneController = TextEditingController(
      text: myServices.pendingPhone ?? '',
    );

    if (googleEmail.trim().isEmpty || googleUid.trim().isEmpty) {
      Future.microtask(() {
        Get.snackbar(
          'Sign in required'.tr,
          'Please sign in with Google first.'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.offAllNamed(AppRoutes.login);
      });
    }
  }

  String? validatePhone(String? value) {
    final phone = (value ?? '').trim();
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (phone.isEmpty) {
      return 'Enter your WhatsApp number'.tr;
    }

    if (digits.length < 7) {
      return 'Enter a valid phone number'.tr;
    }

    return null;
  }

  Future<void> verifyPhone() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      return;
    }

    isSubmitting = true;
    statusRequest = StatusRequest.loading;
    update();

    final response = await loginData.postData(
      phone: phone,
      email: googleEmail,
      name: googleName.isEmpty ? googleEmail : googleName,
      uid: googleUid,
      photoUrl: googlePhoto,
      locale: Get.locale?.languageCode ?? 'en',
    );

    if (response is StatusRequest) {
      statusRequest = response;
      isSubmitting = false;
      update();
      Get.snackbar(
        'Connection issue'.tr,
        'Check your connection and try again.'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if ('${response['status'] ?? ''}' != 'success') {
      statusRequest = StatusRequest.failure;
      isSubmitting = false;
      update();

      final status = '${response['status'] ?? ''}';
      final message = status == 'phone_in_use'
          ? 'This WhatsApp number is already linked to another account.'.tr
          : '${response['message'] ?? 'Unable to link the number'.tr}';

      Get.snackbar('Unable to continue'.tr, message,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final user = Map<String, dynamic>.from(
      (response['user'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final profileCompleted = '${user['profile_completed'] ?? 1}' == '1';

    await myServices.storeAuthSession(
      user: user,
      accessToken: '${response['token'] ?? ''}',
      refreshToken: '${response['refresh_token'] ?? ''}',
      expiresAt: '${response['expires_at'] ?? ''}',
      refreshExpiresAt: '${response['refresh_expires_at'] ?? ''}',
      profileCompleted: profileCompleted,
      pendingPhone: phone,
      sessionMode: 'google_whatsapp',
    );

    await myServices.clearGooglePhoneVerification();

    final userId = int.tryParse('${user['users_id'] ?? 0}') ?? 0;
    if (userId > 0) {
      await saveUserToken(userId);
    }

    isSubmitting = false;
    statusRequest = StatusRequest.success;
    update();

    Get.offAllNamed(AppRoutes.homepage);
  }

  Future<void> signOutAndChangeAccount() async {
    await myServices.clearAuthSession();
    await FirebaseAuth.instance.signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }
}
