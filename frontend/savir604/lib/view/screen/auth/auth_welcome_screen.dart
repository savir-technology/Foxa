import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:tks/controler/auth/email_auth_controller.dart';
import 'package:tks/controler/auth/login_controler.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/functions/alertexitapp.dart';
import 'package:tks/view/widget/auth/auth_shell.dart';
import 'package:tks/view/widget/auth/logoauth.dart';
import 'package:tks/view/widget/common/app_pill_button.dart';
import 'package:tks/view/widget/common/language_selector_sheet.dart';

class AuthWelcomeScreen extends StatefulWidget {
  const AuthWelcomeScreen({super.key});

  @override
  State<AuthWelcomeScreen> createState() => _AuthWelcomeScreenState();
}

class _AuthWelcomeScreenState extends State<AuthWelcomeScreen> {
  final _loginFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final email = Get.put(EmailAuthController());
    final social = Get.put(LoginControllerImp());
    const secondaryText = Color(0xFF344054);
    const outline = Color(0xFFB8C2CC);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) alertExitApp();
      },
      child: GetBuilder<EmailAuthController>(
        builder: (_) => AuthShell(
          title: 'مرحبًا بك',
          subtitle: 'أهلًا بك مجددًا، سجّل دخولك للمتابعة مع FOXA',
          hero: const Logoauth(),
          headerAction: TextButton.icon(
            onPressed: showLanguageSelectorSheet,
            icon: const Icon(Icons.language),
            label: const Text('العربية'),
          ),
          footer: const _Benefits(),
          form: Form(
            key: _loginFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthSectionTitle(text: 'تسجيل الدخول'),
                AuthField(
                  controller: email.emailController,
                  hint: 'أدخل البريد الإلكتروني',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: email.validateEmail,
                ),
                AuthField(
                  controller: email.passwordController,
                  hint: 'أدخل كلمة المرور',
                  icon: Icons.lock_outline_rounded,
                  obscureText: email.obscurePassword,
                  onToggle: () {
                    email.obscurePassword = !email.obscurePassword;
                    email.update();
                  },
                  validator: email.validatePassword,
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                    child: const Text('نسيت كلمة المرور؟'),
                  ),
                ),
                AppPillButton(
                  label:
                      email.isLoading ? 'جارٍ تسجيل الدخول...' : 'تسجيل الدخول',
                  icon: Icons.login_rounded,
                  height: 48,
                  expanded: true,
                  foregroundColor: Colors.white,
                  onPressed: email.isLoading
                      ? null
                      : () => email.login(formKey: _loginFormKey),
                ),
                const _AuthDivider(),
                OutlinedButton.icon(
                  onPressed: social.isLoading ? null : social.loginWithGoogle,
                  icon: const FaIcon(FontAwesomeIcons.google, size: 18),
                  label: const Text('تسجيل الدخول باستخدام Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: secondaryText,
                    side: const BorderSide(color: outline),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: social.isLoading ? null : social.continueAsGuest,
                  icon: const Icon(Icons.person_outline),
                  label: const Text('الدخول كضيف'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: secondaryText,
                    side: const BorderSide(color: outline),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ليس لديك حساب؟',
                        style: TextStyle(color: secondaryText)),
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.signup),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFF6500),
                      ),
                      child: const Text('إنشاء حساب جديد'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFD1D8DE))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('أو', style: TextStyle(color: Color(0xFF667085))),
            ),
            const Expanded(child: Divider(color: Color(0xFFD1D8DE))),
          ],
        ),
      );
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) => const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Benefit(icon: Icons.local_offer_outlined, text: 'عروض حصرية'),
          _Benefit(icon: Icons.local_shipping_outlined, text: 'توصيل سريع'),
          _Benefit(icon: Icons.verified_user_outlined, text: 'آمن وموثوق'),
        ],
      );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: const Color(0xFFFF6500), size: 28),
          const SizedBox(height: 5),
          Text(text,
              style: const TextStyle(
                  color: Color(0xFF344054),
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      );
}
