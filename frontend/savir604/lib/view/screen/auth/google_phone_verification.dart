import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/auth/google_phone_verification_controller.dart';
import 'package:tks/view/widget/auth/auth_shell.dart';
import 'package:tks/view/widget/auth/logoauth.dart';
import 'package:tks/view/widget/common/app_pill_button.dart';

class GooglePhoneVerificationScreen extends StatelessWidget {
  const GooglePhoneVerificationScreen({super.key});

  static const Color _green = Color(0xFFFF6500);

  @override
  Widget build(BuildContext context) {
    Get.put(GooglePhoneVerificationController());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          final controller = Get.find<GooglePhoneVerificationController>();
          controller.signOutAndChangeAccount();
        }
      },
      child: GetBuilder<GooglePhoneVerificationController>(
        builder: (controller) {
          return AuthShell(
            title: 'Link WhatsApp number',
            subtitle:
                'Enter the WhatsApp number you want to attach to this Google account.',
            hero: const Logoauth(),
            form: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppPillIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: controller.signOutAndChangeAccount,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: controller.signOutAndChangeAccount,
                        child: Text('Change account'.tr),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AccountCard(
                    name: controller.googleName.isEmpty
                        ? 'Google account'.tr
                        : controller.googleName,
                    email: controller.googleEmail,
                    photoUrl: controller.googlePhoto,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'WhatsApp number'.tr,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.phoneController,
                    validator: controller.validatePhone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => controller.verifyPhone(),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: 'Enter your WhatsApp number'.tr,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We will attach this number to your account and continue.'
                        .tr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6E6E6E),
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 18),
                  AppPillButton(
                    label:
                        controller.isSubmitting ? 'Linking...' : 'Link number',
                    icon: Icons.arrow_forward_rounded,
                    expanded: true,
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    onPressed:
                        controller.isSubmitting ? null : controller.verifyPhone,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  final String name;
  final String email;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFEAF5EE),
            child: ClipOval(
              child: SizedBox.expand(
                child: photoUrl.trim().isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        color: GooglePhoneVerificationScreen._green,
                      )
                    : CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          color: GooglePhoneVerificationScreen._green,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6A6A6A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
