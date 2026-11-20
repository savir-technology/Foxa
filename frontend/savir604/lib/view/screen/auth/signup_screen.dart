import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:tks/controler/auth/email_auth_controller.dart';
import 'package:tks/controler/auth/login_controler.dart';
import 'package:tks/core/constant/phone_countries.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/view/widget/auth/auth_shell.dart';
import 'package:tks/view/widget/auth/logoauth.dart';
import 'package:tks/view/widget/common/app_pill_button.dart';
import 'package:tks/view/widget/common/language_selector_sheet.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EmailAuthController());
    final social = Get.put(LoginControllerImp());
    return GetBuilder<EmailAuthController>(
      builder: (_) => AuthShell(
        title: 'إنشاء حساب جديد',
        subtitle: 'أنشئ حسابك بسهولة وابدأ التسوق الآن',
        hero: const Logoauth(),
        headerAction: TextButton.icon(
          onPressed: showLanguageSelectorSheet,
          icon: const Icon(Icons.language),
          label: const Text('العربية'),
        ),
        form: Form(
          key: controller.signupFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthSectionTitle(text: 'إنشاء حساب جديد'),
              AuthField(
                controller: controller.nameController,
                hint: 'الاسم الكامل',
                icon: Icons.person_outline,
                validator: (value) =>
                    controller.requiredField(value, 'أدخل الاسم الكامل'),
              ),
              AuthField(
                controller: controller.emailController,
                hint: 'البريد الإلكتروني',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                validator: controller.validateEmail,
              ),
              _PhoneField(controller: controller),
              AuthField(
                controller: controller.passwordController,
                hint: 'كلمة المرور',
                icon: Icons.lock_outline,
                obscureText: controller.obscurePassword,
                onToggle: () {
                  controller.obscurePassword = !controller.obscurePassword;
                  controller.update();
                },
                validator: controller.validatePassword,
              ),
              AuthField(
                controller: controller.confirmPasswordController,
                hint: 'تأكيد كلمة المرور',
                icon: Icons.lock_reset_outlined,
                obscureText: controller.obscureConfirmPassword,
                onToggle: () {
                  controller.obscureConfirmPassword =
                      !controller.obscureConfirmPassword;
                  controller.update();
                },
                validator: (value) =>
                    value != controller.passwordController.text
                        ? 'كلمتا المرور غير متطابقتين'
                        : null,
              ),
              CheckboxListTile(
                value: controller.acceptedTerms,
                onChanged: (value) {
                  controller.acceptedTerms = value ?? false;
                  controller.update();
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'أوافق على الشروط والأحكام وسياسة الخصوصية',
                  style: TextStyle(fontSize: 12, color: Color(0xFF344054)),
                ),
              ),
              AppPillButton(
                label: controller.isLoading
                    ? 'جارٍ إنشاء الحساب...'
                    : 'إنشاء حساب',
                icon: Icons.person_add_alt_1,
                height: 48,
                expanded: true,
                foregroundColor: Colors.white,
                onPressed: controller.isLoading ? null : controller.signup,
              ),
              const SizedBox(height: 10),
              const _SignupDivider(),
              OutlinedButton.icon(
                onPressed: social.isLoading ? null : social.loginWithGoogle,
                icon: const FaIcon(FontAwesomeIcons.google, size: 17),
                label: const Text('إنشاء حساب باستخدام Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF344054),
                  side: const BorderSide(color: Color(0xFFB8C2CC)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('لديك حساب بالفعل؟',
                      style: TextStyle(color: Color(0xFF344054))),
                  TextButton(
                    onPressed: () => Get.offNamed(AppRoutes.login),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6500),
                    ),
                    child: const Text('تسجيل الدخول'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller});
  final EmailAuthController controller;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: controller.phoneController,
          keyboardType: TextInputType.phone,
          validator: (value) =>
              controller.requiredField(value, 'أدخل رقم الهاتف'),
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 14, color: Color(0xFF344054)),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            hintText: 'رقم الهاتف',
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF697586)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFDCE1E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  const BorderSide(color: Color(0xFFFF6500), width: 1.5),
            ),
            prefixIcon: const Icon(Icons.phone_outlined,
                size: 20, color: Color(0xFF667085)),
            suffixIcon: _CountrySelector(controller: controller),
          ),
        ),
      );
}

class _CountrySelector extends StatelessWidget {
  const _CountrySelector({required this.controller});
  final EmailAuthController controller;

  @override
  Widget build(BuildContext context) {
    final country = controller.selectedPhoneCountry;
    return InkWell(
      onTap: () => _chooseCountry(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_flag(country.isoCode), style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 5),
          Text(country.dialCode,
              style: const TextStyle(
                  color: Color(0xFF344054),
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          const Icon(Icons.keyboard_arrow_down,
              size: 18, color: Color(0xFF667085)),
        ]),
      ),
    );
  }

  Future<void> _chooseCountry(BuildContext context) async {
    final selected = await showModalBottomSheet<PhoneCountry>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * .72,
          child: Column(children: [
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text('اختر الدولة',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            Expanded(
              child: ListView.builder(
                itemCount: phoneCountries.length,
                itemBuilder: (_, index) {
                  final item = phoneCountries[index];
                  return ListTile(
                    leading: Text(_flag(item.isoCode),
                        style: const TextStyle(fontSize: 22)),
                    title: Text(item.name),
                    trailing: Text(item.dialCode),
                    onTap: () => Navigator.pop(sheetContext, item),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
    if (selected != null) controller.selectPhoneCountry(selected);
  }

  static String _flag(String iso) => iso.toUpperCase().replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397));
}

class _SignupDivider extends StatelessWidget {
  const _SignupDivider();

  @override
  Widget build(BuildContext context) => const Row(children: [
        Expanded(child: Divider(color: Color(0xFFD1D8DE))),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('أو', style: TextStyle(color: Color(0xFF667085)))),
        Expanded(child: Divider(color: Color(0xFFD1D8DE))),
      ]);
}
