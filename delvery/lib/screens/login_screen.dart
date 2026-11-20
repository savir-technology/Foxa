import 'dart:async';

import 'package:delvery/controllers/auth_controller.dart';
import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            const SizedBox(height: 4),
            const Center(child: DriverBrandMark()),
            const SizedBox(height: 28),
            DriverPageHeader(
              title: t('دخول السائق', 'Driver login'),
              subtitle: t(
                'للسائقين المسجلين مسبقاً، أدخل البريد الإلكتروني وكلمة السر للمتابعة.',
                'For registered drivers, enter your email and password to continue.',
              ),
            ),
            const SizedBox(height: 22),
            Obx(() {
              final isLogin = controller.mode.value == AuthEntryMode.login;
              return Column(
                children: [
                  DriverCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isLogin
                                    ? t('تسجيل الدخول للمسجلين', 'Sign in')
                                    : t('تسجيل سائق جديد', 'Register driver'),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: DriverUi.textAdaptive,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                controller.setMode(
                                  isLogin
                                      ? AuthEntryMode.register
                                      : AuthEntryMode.login,
                                );
                              },
                              child: Text(
                                isLogin
                                    ? t('سائق جديد؟', 'New driver?')
                                    : t('لديك حساب؟', 'Have an account?'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _FieldLabel(
                          label: t('البريد الإلكتروني', 'Email'),
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: isLogin
                              ? TextInputAction.next
                              : TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'driver@example.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        if (isLogin) ...[
                          const SizedBox(height: 16),
                          _FieldLabel(
                            label: t('كلمة السر', 'Password'),
                            icon: Icons.lock_outline_rounded,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: controller.passwordController,
                            textInputAction: TextInputAction.done,
                            obscureText: _obscurePassword,
                            onSubmitted: (_) {
                              if (!controller.isLoading.value) {
                                unawaited(controller.loginWithEmail());
                              }
                            },
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Obx(
                          () => DriverPrimaryButton(
                            label: isLogin
                                ? t('تسجيل الدخول', 'Sign in')
                                : t('إرسال رمز التحقق', 'Send verification code'),
                            icon: isLogin
                                ? Icons.login_rounded
                                : Icons.send_rounded,
                            onPressed: controller.isLoading.value
                                ? null
                                : () {
                                    if (isLogin) {
                                      unawaited(controller.loginWithEmail());
                                    } else {
                                      unawaited(controller.requestRegistrationCode());
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isLogin
                              ? t(
                                  'لن تتمكن من الوصول إلى التطبيق إلا بحساب سائق فعّال وبريد مسجل في النظام.',
                                  'You can only access the app with an active driver account and a registered email.',
                                )
                              : t(
                                  'التسجيل الجديد يمر عبر رمز تحقق بالبريد ثم كلمة سر قوية ثم البيانات الأساسية والصورة الشخصية.',
                                  'New registration uses email verification, then a strong password, then basic profile details.',
                                ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DriverUi.mutedTextAdaptive,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLogin) ...[
                    const SizedBox(height: 8),
                    Text(
                      t(
                        'أدخل بريدك الإلكتروني لإرسال رمز التحقق، ثم أكمل كلمة السر والبيانات الأساسية بعد التحقق.',
                        'Enter your email to send the verification code, then complete the password and basic details after verification.',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DriverUi.mutedTextAdaptive,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              );
            }),
            const SizedBox(height: 18),
            DriverCard(
              color: DriverUi.surfaceWarmAdaptive,
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: DriverUi.primarySoftAdaptive,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_outlined,
                      color: DriverUi.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      t(
                        'إعدادات الثيم واللغة والإشعارات مرتبطة مباشرة بالجلسة الحالية، وستبقى كما اخترتها بعد إعادة فتح التطبيق.',
                        'Theme, language and notification settings are tied to the current session and will stay as you chose them after relaunch.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DriverUi.textAdaptive,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DriverUi.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: DriverUi.mutedTextAdaptive,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

