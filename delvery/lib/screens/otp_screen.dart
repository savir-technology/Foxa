import 'dart:async';

import 'package:delvery/controllers/auth_controller.dart';
import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final AuthController controller;
  final FocusNode _focusNode = FocusNode();

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

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
              title: t('التحقق من OTP', 'Verify OTP'),
              subtitle: t(
                'لقد أرسلنا رمز التحقق إلى بريدك الإلكتروني',
                'We sent the verification code to your email',
              ),
            ),
            const SizedBox(height: 22),
            DriverCard(
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: DriverUi.primarySoftAdaptive,
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
                      email.isEmpty
                          ? t('البريد غير متاح', 'Email unavailable')
                          : email,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: DriverUi.textAdaptive,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(t('تعديل', 'Edit')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            DriverCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    t('أدخل رمز التحقق المكوّن من 6 أرقام', 'Enter the 6-digit code'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: DriverUi.textAdaptive,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () =>
                        FocusScope.of(context).requestFocus(_focusNode),
                    child: Row(
                      children: List.generate(6, (index) {
                        final text = controller.otpController.text;
                        final hasChar = index < text.length;
                        final isFocused =
                            _focusNode.hasFocus && index == text.length;
                        return Expanded(
                          child: Container(
                            height: 64,
                            margin: EdgeInsets.only(
                              left: index == 0 ? 0 : 8,
                              right: index == 5 ? 0 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: DriverUi.surfaceAdaptive,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isFocused
                                    ? DriverUi.primary
                                    : DriverUi.line,
                                width: isFocused ? 1.4 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              hasChar ? text[index] : (isFocused ? '|' : ''),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: hasChar
                                        ? DriverUi.textAdaptive
                                        : DriverUi.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: 0.01,
                    child: SizedBox(
                      height: 1,
                      child: TextField(
                        focusNode: _focusNode,
                        controller: controller.otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Obx(
                    () => DriverPrimaryButton(
                      label: t('تحقق', 'Verify'),
                      icon: Icons.verified_rounded,
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                              unawaited(controller.verifyEmailCode());
                            },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Obx(
                    () => TextButton(
                      onPressed: controller.resendSeconds.value == 0
                          ? controller.resendCode
                          : null,
                      child: Text(
                        controller.resendSeconds.value == 0
                            ? t('إعادة إرسال الرمز', 'Resend code')
                            : t(
                                'إعادة الإرسال خلال ${controller.resendSeconds.value} ث',
                                'Resend in ${controller.resendSeconds.value} s',
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      controller.resendSeconds.value == 0
                          ? t('لم يصلك الرمز؟ يمكنك إعادة الإرسال الآن.', 'Did not receive the code? You can resend now.')
                          : t('انتظر قليلاً ثم أعد المحاولة.', 'Please wait a little and try again.'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DriverUi.mutedTextAdaptive,
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

