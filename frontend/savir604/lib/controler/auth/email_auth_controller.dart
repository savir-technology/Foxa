import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/constant/phone_countries.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/functions/save_token.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/remote/auth/email_auth.dart';

class EmailAuthController extends GetxController {
  final MyServices myServices = Get.find();
  final EmailAuthData authData = EmailAuthData(Get.find());
  final loginFormKey = GlobalKey<FormState>();
  final signupFormKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final otpController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool acceptedTerms = false;
  String pendingEmail = '';
  DateTime? resendAvailableAt;
  PhoneCountry selectedPhoneCountry =
      phoneCountries.firstWhere((country) => country.isoCode == 'SA');

  void selectPhoneCountry(PhoneCountry country) {
    selectedPhoneCountry = country;
    update();
  }

  String? requiredField(String? value, String message) =>
      (value ?? '').trim().isEmpty ? message : null;

  String? validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty || !GetUtils.isEmail(email))
      return 'أدخل بريدًا إلكترونيًا صحيحًا';
    return null;
  }

  String? validatePassword(String? value) {
    if ((value ?? '').length < 6)
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  Future<void> login({GlobalKey<FormState>? formKey}) async {
    if (!((formKey ?? loginFormKey).currentState?.validate() ?? false)) return;
    await _run(() async {
      final response = await authData.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (response is StatusRequest) {
        _error('تعذر الاتصال بالخادم');
        return;
      }
      if ('${response['status']}' != 'success') {
        _error('${response['message'] ?? 'البريد أو كلمة المرور غير صحيحة'}');
        return;
      }
      await _saveSession(response);
      Get.offAllNamed(AppRoutes.homepage);
    });
  }

  Future<void> signup() async {
    if (!(signupFormKey.currentState?.validate() ?? false)) return;
    if (!acceptedTerms) {
      _error('يجب الموافقة على الشروط وسياسة الخصوصية');
      return;
    }
    await _run(() async {
      final response = await authData.signup(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone:
            '${selectedPhoneCountry.dialCode}${phoneController.text.replaceAll(RegExp(r'\D'), '')}',
        password: passwordController.text,
      );
      if (response is StatusRequest) {
        _error('تعذر الاتصال بالخادم');
        return;
      }
      if ('${response['status']}' != 'success') {
        _error('${response['message'] ?? 'البريد أو الهاتف مستخدم بالفعل'}');
        return;
      }
      pendingEmail = emailController.text.trim();
      resendAvailableAt = DateTime.now().add(const Duration(seconds: 105));
      Get.toNamed(AppRoutes.verifyEmail, arguments: pendingEmail);
    });
  }

  Future<void> verify() async {
    if (otpController.text.trim().length != 6) {
      _error('أدخل رمز التحقق كاملًا');
      return;
    }
    await _run(() async {
      final response = await authData.verify(
          email: pendingEmail, code: otpController.text.trim());
      if (response is StatusRequest) {
        _error('تعذر الاتصال بالخادم');
        return;
      }
      if ('${response['status']}' != 'success') {
        _error('${response['message'] ?? 'رمز التحقق غير صحيح'}');
        return;
      }
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar('تم إنشاء الحساب',
          'تم التحقق من بريدك الإلكتروني، يمكنك تسجيل الدخول الآن',
          snackPosition: SnackPosition.BOTTOM);
    });
  }

  Future<void> resend() async {
    if (resendAvailableAt != null &&
        DateTime.now().isBefore(resendAvailableAt!)) return;
    await _run(() async {
      final response = await authData.resend(email: pendingEmail);
      if (response is StatusRequest) {
        _error('تعذر الاتصال بالخادم');
        return;
      }
      if ('${response['status']}' != 'success') {
        _error('تعذر إعادة إرسال الرمز');
        return;
      }
      resendAvailableAt = DateTime.now().add(const Duration(seconds: 105));
      update();
    });
  }

  Future<void> _saveSession(Map response) async {
    final rawUser = response['user'] ?? response['data'] ?? const {};
    final user =
        Map<String, dynamic>.from((rawUser as Map).cast<String, dynamic>());
    await myServices.clearAuthSession();
    await myServices.storeAuthSession(
      user: user,
      accessToken: '${response['token'] ?? ''}',
      refreshToken: '${response['refresh_token'] ?? ''}',
      expiresAt: '${response['expires_at'] ?? ''}',
      refreshExpiresAt: '${response['refresh_expires_at'] ?? ''}',
      profileCompleted: '${user['profile_completed'] ?? 1}' == '1',
      sessionMode: 'email_password',
    );
    final id = int.tryParse('${user['users_id'] ?? 0}') ?? 0;
    if (id > 0) await saveUserToken(id);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (isLoading) return;
    isLoading = true;
    update();
    try {
      await action();
    } finally {
      isLoading = false;
      if (!isClosed) update();
    }
  }

  void _error(String message) =>
      Get.snackbar('تنبيه', message, snackPosition: SnackPosition.BOTTOM);

  // The same controller can survive a GetX route transition. Its text fields
  // must not be disposed while the previous route is still being animated.
  @override
  void onClose() => super.onClose();
}
