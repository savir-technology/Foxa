import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/auth/password_reset_controller.dart';
import 'package:tks/view/widget/auth/auth_shell.dart';
import 'package:tks/view/widget/auth/logoauth.dart';
import 'package:tks/view/widget/common/app_pill_button.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PasswordResetController());
    return GetBuilder<PasswordResetController>(
      builder: (_) => AuthShell(
        title: 'استعادة كلمة المرور',
        subtitle: 'أعد ضبط كلمة المرور بأمان',
        hero: const Logoauth(),
        form: _content(controller),
      ),
    );
  }

  Widget _content(PasswordResetController c) {
    if (c.step == 1) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const AuthSectionTitle(text: 'فحص البريد الإلكتروني'),
        Text('أدخل الرمز المرسل إلى ${c.email}', textAlign: TextAlign.center),
        const SizedBox(height: 18),
        _ResetOtpBoxes(controller: c.codeController),
        const SizedBox(height: 18),
        AppPillButton(
            label: c.loading ? 'جار الفحص...' : 'تأكيد الرمز',
            height: 52,
            expanded: true,
            onPressed: c.loading ? null : c.verifyCode),
        TextButton(
            onPressed: c.loading ? null : c.sendCode,
            child: const Text('إعادة إرسال الرمز')),
      ]);
    }
    if (c.step == 2) {
      return Form(
          key: c.passwordFormKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const AuthSectionTitle(text: 'تعيين كلمة مرور جديدة'),
            AuthField(
                controller: c.passwordController,
                hint: 'كلمة المرور الجديدة',
                icon: Icons.lock_outline,
                obscureText: c.obscure,
                onToggle: () {
                  c.obscure = !c.obscure;
                  c.update();
                },
                validator: c.validatePassword),
            AuthField(
                controller: c.confirmController,
                hint: 'تأكيد كلمة المرور',
                icon: Icons.lock_reset_outlined,
                obscureText: c.obscure,
                validator: c.validatePassword),
            AppPillButton(
                label: c.loading ? 'جار الحفظ...' : 'حفظ كلمة المرور',
                icon: Icons.check_rounded,
                height: 52,
                expanded: true,
                onPressed: c.loading ? null : c.resetPassword),
          ]));
    }
    return Form(
        key: c.emailFormKey,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const AuthSectionTitle(text: 'نسيت كلمة المرور؟'),
          const Text('أدخل بريدك الإلكتروني لنرسل لك رمز التحقق',
              textAlign: TextAlign.center),
          const SizedBox(height: 18),
          AuthField(
              controller: c.emailController,
              hint: 'البريد الإلكتروني',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: c.validateEmail),
          AppPillButton(
              label: c.loading ? 'جار الإرسال...' : 'إرسال رمز التحقق',
              icon: Icons.send_outlined,
              height: 52,
              expanded: true,
              onPressed: c.loading ? null : c.sendCode),
        ]));
  }
}

class _ResetOtpBoxes extends StatefulWidget {
  const _ResetOtpBoxes({required this.controller});
  final TextEditingController controller;
  @override
  State<_ResetOtpBoxes> createState() => _ResetOtpBoxesState();
}

class _ResetOtpBoxesState extends State<_ResetOtpBoxes> {
  late final List<TextEditingController> boxes =
      List.generate(6, (_) => TextEditingController());
  late final List<FocusNode> nodes = List.generate(6, (_) => FocusNode());

  void sync() {
    widget.controller.text = boxes.map((box) => box.text).join();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
              6,
              (index) => SizedBox(
                    width: 42,
                    height: 56,
                    child: TextField(
                      controller: boxes[index],
                      focusNode: nodes[index],
                      maxLength: 1,
                      obscureText: false,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      cursorColor: const Color(0xFFFF6500),
                      style: const TextStyle(
                          color: Color(0xFFFF6500),
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5)
                          nodes[index + 1].requestFocus();
                        sync();
                      },
                      decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFFFF3EC),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: Color(0xFFF0D8CA))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFFFF6500), width: 2))),
                    ),
                  )),
        ),
      );

  @override
  void dispose() {
    for (final box in boxes) box.dispose();
    for (final node in nodes) node.dispose();
    super.dispose();
  }
}
