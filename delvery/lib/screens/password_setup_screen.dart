import 'dart:async';

import 'package:delvery/controllers/auth_controller.dart';
import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PasswordSetupScreen extends GetView<AuthController> {
  const PasswordSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email =
        controller.sessionService.pendingRegistrationEmail.value ??
        controller.emailController.text.trim();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            const SizedBox(height: 4),
            const Center(child: DriverBrandMark()),
            const SizedBox(height: 26),
            DriverPageHeader(
              title: tx('إنشاء كلمة مرور قوية'),
              subtitle: tx('هذه الكلمة ستُستخدم لاحقًا لتسجيل الدخول'),
            ),
            const SizedBox(height: 18),
            DriverCard(
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: DriverUi.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      color: DriverUi.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      email.isEmpty ? tx('البريد غير متاح') : email,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: DriverUi.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            DriverCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx('شروط كلمة المرور'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: DriverUi.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Rule(text: tx('8 أحرف على الأقل')),
                  _Rule(text: tx('حرف كبير وحرف صغير')),
                  _Rule(text: tx('رقم واحد على الأقل')),
                  _Rule(text: tx('رمز خاص مثل ! @ # \$ %')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: tx('كلمة المرور الجديدة'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DriverPrimaryButton(
                    label: tx('متابعة'),
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      unawaited(controller.submitPassword());
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tx('لن نُكمل التسجيل إلا بعد إدخال كلمة مرور قوية وواضحة.'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DriverUi.mutedText,
                      height: 1.45,
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

class _Rule extends StatelessWidget {
  const _Rule({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: DriverUi.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DriverUi.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
