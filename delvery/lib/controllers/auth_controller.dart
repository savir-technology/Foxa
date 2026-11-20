import 'dart:async';

import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/data/models/driver_models.dart';

enum AuthEntryMode { register, login }

class AuthController extends GetxController {
  AuthController(this.sessionService);

  final DriverSessionService sessionService;

  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final vehicleTypeController = TextEditingController();
  final vehicleNumberController = TextEditingController();

  final Rx<AuthEntryMode> mode = AuthEntryMode.login.obs;
  final RxBool isLoading = false.obs;
  final RxInt resendSeconds = 0.obs;
  final RxString debugOtp = ''.obs;
  final RxnString selectedPhotoPath = RxnString();
  final RxList<DriverRestaurantChoice> availableRestaurants =
      <DriverRestaurantChoice>[].obs;
  final RxInt selectedVendorId = 0.obs;
  final RxBool wantsRestaurantLink = false.obs;

  Timer? _resendTimer;
  bool _profileDraftPrimed = false;

  @override
  void onInit() {
    super.onInit();
    final pendingEmail = sessionService.pendingRegistrationEmail.value;
    if ((pendingEmail ?? '').isNotEmpty) {
      emailController.text = pendingEmail!;
    } else if (sessionService.profile.value.email.isNotEmpty) {
      emailController.text = sessionService.profile.value.email;
    }

    if (sessionService.profile.value.phone.isNotEmpty) {
      phoneController.text = sessionService.profile.value.phone;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    vehicleTypeController.dispose();
    vehicleNumberController.dispose();
    _resendTimer?.cancel();
    super.onClose();
  }

  void setMode(AuthEntryMode nextMode) {
    mode.value = nextMode;
  }

  Future<void> loadAvailableRestaurants() async {
    try {
      final rows = await sessionService.api.fetchDriverRestaurants();
      if ((rows['status'] ?? '').toString().toLowerCase() != 'success') return;
      final raw = rows['data'];
      if (raw is! List) return;
      availableRestaurants.assignAll(
        raw
            .whereType<Map>()
            .map((row) {
              final item = row.map((key, value) => MapEntry('$key', value));
              return DriverRestaurantChoice(
                id: int.tryParse('${item['vendor_id'] ?? 0}') ?? 0,
                vendorName: '${item['vendor_name'] ?? ''}',
                storeName: '${item['store_name'] ?? ''}',
                description: '${item['vendor_description'] ?? ''}',
              );
            })
            .where((item) => item.id > 0),
      );
    } catch (_) {
      // Registration can continue as an independent driver if stores fail to load.
    }
  }

  Future<void> requestRegistrationCode() async {
    final email = emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar(tx('البريد غير صحيح'), tx('أدخل بريدًا إلكترونيًا صالحًا.'));
      return;
    }

    mode.value = AuthEntryMode.register;
    isLoading.value = true;
    try {
      await sessionService.requestEmailRegistrationCode(email);
      debugOtp.value = sessionService.otpCode.value;
      otpController.clear();
      resendSeconds.value = 60;
      _startResendTimer();
      Get.toNamed(AppRoutes.otp);
    } catch (error) {
      Get.snackbar(tx('تعذر إرسال الرمز'), error.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyEmailCode() async {
    final code = otpController.text.trim();
    if (code.length < 4) {
      Get.snackbar(
        tx('الرمز غير مكتمل'),
        tx('أدخل رمز التحقق المرسل إلى بريدك.'),
      );
      return;
    }

    isLoading.value = true;
    try {
      final ok = await sessionService.verifyEmailRegistrationCode(code);
      if (!ok) {
        Get.snackbar(tx('رمز غير صحيح'), tx('تحقق من الرمز وأعد المحاولة.'));
        return;
      }

      passwordController.clear();
      Get.toNamed(AppRoutes.passwordSetup);
    } catch (error) {
      Get.snackbar(tx('تعذر التحقق'), error.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitPassword() async {
    final password = passwordController.text;
    if (!_isStrongPassword(password)) {
      Get.snackbar(
        tx('كلمة المرور ضعيفة'),
        tx(
          'يجب أن تحتوي على 8 أحرف على الأقل، وحرف كبير، وحرف صغير، ورقم، ورمز.',
        ),
      );
      return;
    }

    primeProfileDraft();
    Get.toNamed(AppRoutes.profileSetup);
  }

  Future<void> loginWithEmail() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar(tx('البريد غير صحيح'), tx('أدخل بريدًا إلكترونيًا صالحًا.'));
      return;
    }
    if (password.isEmpty) {
      Get.snackbar(tx('كلمة المرور مطلوبة'), tx('أدخل كلمة المرور.'));
      return;
    }

    mode.value = AuthEntryMode.login;
    isLoading.value = true;
    try {
      final ok = await sessionService.loginWithEmail(
        email: email,
        password: password,
      );
      if (!ok) {
        Get.snackbar(
          tx('فشل الدخول'),
          tx('البريد الإلكتروني أو كلمة المرور غير صحيحة.'),
        );
        return;
      }

      if (!sessionService.profile.value.profileCompleted) {
        primeProfileDraft();
        Get.offAllNamed(AppRoutes.profileSetup);
        return;
      }

      Get.offAllNamed(AppRoutes.home, arguments: {'tab': 0});
    } catch (error) {
      Get.snackbar(tx('فشل الدخول'), error.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> completeRegistration() async {
    final email =
        sessionService.pendingRegistrationEmail.value?.trim() ??
        emailController.text.trim();
    final password = passwordController.text;
    final name = fullNameController.text.trim();
    final phone = phoneController.text.trim();
    final vehicleType = vehicleTypeController.text.trim();
    final vehicleNumber = vehicleNumberController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar(
        tx('البريد غير صحيح'),
        tx('أدخل البريد الإلكتروني من جديد.'),
      );
      return;
    }
    if (!_isStrongPassword(password)) {
      Get.snackbar(
        tx('كلمة المرور ضعيفة'),
        tx(
          'يجب أن تحتوي على 8 أحرف على الأقل، وحرف كبير، وحرف صغير، ورقم، ورمز.',
        ),
      );
      return;
    }
    if (name.isEmpty) {
      Get.snackbar(tx('الاسم مطلوب'), tx('أدخل اسم السائق.'));
      return;
    }
    if (!_isValidPhone(phone)) {
      Get.snackbar(tx('رقم الهاتف غير صحيح'), tx('أدخل رقم هاتف صالحًا.'));
      return;
    }
    if (vehicleType.isEmpty) {
      Get.snackbar(tx('نوع المركبة مطلوب'), tx('أدخل نوع المركبة.'));
      return;
    }
    if (vehicleNumber.isEmpty) {
      Get.snackbar(tx('رقم المركبة مطلوب'), tx('أدخل رقم المركبة.'));
      return;
    }
    if (wantsRestaurantLink.value && selectedVendorId.value <= 0) {
      Get.snackbar(
        tx('اختيار المتجر مطلوب'),
        tx('اختر المتجر أو المطعم المرتبط بك.'),
      );
      return;
    }

    isLoading.value = true;
    try {
      final ok = await sessionService.completeEmailRegistration(
        password: password,
        name: name,
        phone: phone,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        vendorId: wantsRestaurantLink.value ? selectedVendorId.value : 0,
        imagePath: selectedPhotoPath.value,
      );
      if (!ok) {
        Get.snackbar(
          tx('فشل التسجيل'),
          tx('تعذر إنشاء الحساب، حاول مرة أخرى.'),
        );
        return;
      }

      _resetRegistrationForm();
      Get.offAllNamed(AppRoutes.home, arguments: {'tab': 0});
    } catch (error) {
      Get.snackbar(tx('فشل التسجيل'), error.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
      );
      if (image == null) {
        return;
      }
      selectedPhotoPath.value = image.path;
    } catch (error) {
      Get.snackbar(tx('تعذر اختيار الصورة'), error.toString());
    }
  }

  void clearProfileImage() {
    selectedPhotoPath.value = null;
  }

  void resetAllForms() {
    _resendTimer?.cancel();
    _resendTimer = null;
    emailController.clear();
    _resetRegistrationForm();
    resendSeconds.value = 0;
    debugOtp.value = '';
    mode.value = AuthEntryMode.login;
    _profileDraftPrimed = false;
  }

  void primeProfileDraft() {
    if (_profileDraftPrimed) {
      return;
    }

    final profile = sessionService.profile.value;
    final pendingEmail = sessionService.pendingRegistrationEmail.value;

    if (emailController.text.trim().isEmpty &&
        (pendingEmail ?? '').isNotEmpty) {
      emailController.text = pendingEmail!;
    }

    if (fullNameController.text.trim().isEmpty &&
        profile.name.trim().isNotEmpty &&
        profile.name.trim() != 'السائق' &&
        profile.name.trim().toLowerCase() != 'driver') {
      fullNameController.text = profile.name;
    }
    if (phoneController.text.trim().isEmpty &&
        profile.phone.trim().isNotEmpty) {
      phoneController.text = profile.phone;
    }
    if (vehicleTypeController.text.trim().isEmpty &&
        profile.vehicleType.trim().isNotEmpty) {
      vehicleTypeController.text = profile.vehicleType;
    }
    if (vehicleNumberController.text.trim().isEmpty &&
        profile.vehicleNumber.trim().isNotEmpty) {
      vehicleNumberController.text = profile.vehicleNumber;
    }

    _profileDraftPrimed = true;
  }

  void resendCode() {
    if (resendSeconds.value > 0) {
      return;
    }
    unawaited(requestRegistrationCode());
  }

  bool _isValidPhone(String phone) {
    final normalized = phone.replaceAll(RegExp(r'\s+'), '');
    return normalized.length >= 8;
  }

  bool _isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  }

  void _resetRegistrationForm() {
    otpController.clear();
    passwordController.clear();
    fullNameController.clear();
    phoneController.clear();
    vehicleTypeController.clear();
    vehicleNumberController.clear();
    selectedPhotoPath.value = null;
    debugOtp.value = '';
    _profileDraftPrimed = false;
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds.value <= 1) {
        resendSeconds.value = 0;
        timer.cancel();
      } else {
        resendSeconds.value--;
      }
    });
  }
}
