import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/data/datasource/remote/auth/password_reset.dart';

class PasswordResetController extends GetxController {
  final PasswordResetData data = PasswordResetData(Get.find());
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final emailFormKey = GlobalKey<FormState>();
  final passwordFormKey = GlobalKey<FormState>();
  int step = 0;
  bool loading = false;
  bool obscure = true;
  String email = '';

  String? validateEmail(String? value) => GetUtils.isEmail((value ?? '').trim()) ? null : 'أدخل بريدًا إلكترونيًا صحيحًا';
  String? validatePassword(String? value) => (value ?? '').length >= 6 ? null : 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';

  Future<void> sendCode() async {
    if (!(emailFormKey.currentState?.validate() ?? false)) return;
    await _run(() async {
      final response = await data.checkEmail(emailController.text.trim());
      if (response is StatusRequest) { _error('تعذر الاتصال بالخادم'); return; }
      if ('${response['status']}' != 'success') { _error('${response['message'] ?? 'البريد غير موجود'}'); return; }
      email = emailController.text.trim(); step = 1; update();
    });
  }

  Future<void> verifyCode() async {
    if (codeController.text.trim().length != 6) { _error('أدخل رمز التحقق المكون من 6 أرقام'); return; }
    await _run(() async {
      final response = await data.verifyCode(email, codeController.text.trim());
      if (response is StatusRequest) { _error('تعذر الاتصال بالخادم'); return; }
      if ('${response['status']}' != 'success') { _error('${response['message'] ?? 'رمز التحقق غير صحيح'}'); return; }
      step = 2; update();
    });
  }

  Future<void> resetPassword() async {
    if (!(passwordFormKey.currentState?.validate() ?? false)) return;
    if (passwordController.text != confirmController.text) { _error('كلمتا المرور غير متطابقتين'); return; }
    await _run(() async {
      final response = await data.reset(email, codeController.text.trim(), passwordController.text);
      if (response is StatusRequest) { _error('تعذر الاتصال بالخادم'); return; }
      if ('${response['status']}' != 'success') { _error('${response['message'] ?? 'تعذر تغيير كلمة المرور'}'); return; }
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar('تم تغيير كلمة المرور', 'يمكنك تسجيل الدخول الآن', snackPosition: SnackPosition.BOTTOM);
    });
  }

  Future<void> _run(Future<void> Function() action) async { if (loading) return; loading = true; update(); try { await action(); } finally { loading = false; if (!isClosed) update(); } }
  void _error(String message) => Get.snackbar('تنبيه', message, snackPosition: SnackPosition.BOTTOM);
  // Route transitions may still render the previous form for one frame.
  @override void onClose() => super.onClose();
}
