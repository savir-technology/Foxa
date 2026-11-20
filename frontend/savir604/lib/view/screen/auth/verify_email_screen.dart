import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/auth/email_auth_controller.dart';
import 'package:tks/view/widget/auth/auth_shell.dart';
import 'package:tks/view/widget/auth/logoauth.dart';
import 'package:tks/view/widget/common/app_pill_button.dart';
import 'package:tks/view/widget/common/language_selector_sheet.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EmailAuthController());
    controller.pendingEmail =
        (Get.arguments ?? controller.pendingEmail).toString();
    return GetBuilder<EmailAuthController>(
      builder: (_) => AuthShell(
        title: 'رمز التحقق',
        subtitle: 'لقد أرسلنا رمز تحقق إلى بريدك الإلكتروني',
        hero: const Logoauth(),
        headerAction: TextButton.icon(
          onPressed: showLanguageSelectorSheet,
          icon: const Icon(Icons.language),
          label: const Text('العربية'),
        ),
        form: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthSectionTitle(text: 'رمز التحقق'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F8F4),
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: Text(controller.pendingEmail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
            const Text('أدخل رمز التحقق المكون من 6 أرقام',
                textAlign: TextAlign.center),
            const SizedBox(height: 18),
            _SignupOtpBoxes(controller: controller.otpController),
            const SizedBox(height: 18),
            AppPillButton(
                label: controller.isLoading ? 'جار التحقق...' : 'تحقق',
                icon: Icons.verified_outlined,
                height: 52,
                expanded: true,
                onPressed: controller.isLoading ? null : controller.verify),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: controller.isLoading ? null : controller.resend,
                child: const Text('إعادة إرسال الرمز')),
          ],
        ),
      ),
    );
  }
}

class _SignupOtpBoxes extends StatefulWidget {
  const _SignupOtpBoxes({required this.controller});
  final TextEditingController controller;
  @override
  State<_SignupOtpBoxes> createState() => _SignupOtpBoxesState();
}

class _SignupOtpBoxesState extends State<_SignupOtpBoxes> {
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
                        fillColor: const Color(0xFFF4FAF6),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFFD8E7DC))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Color(0xFFFF6500), width: 2)),
                      ),
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
