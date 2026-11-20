// ignore_for_file: unused_element

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/auth/user_profile_setup_controller.dart';
import 'package:tks/view/widget/auth/auth_shell.dart';
import 'package:tks/view/widget/auth/logoauth.dart';
import 'package:tks/view/widget/common/app_pill_button.dart';

class UserProfileSetupScreen extends StatelessWidget {
  const UserProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(UserProfileSetupController());
    final pendingPhone =
        Get.find<UserProfileSetupController>().myServices.pendingPhone ?? '';

    return GetBuilder<UserProfileSetupController>(
      builder: (controller) {
        return AuthShell(
          title: 'Complete your account',
          subtitle:
              'Add your full name now and optionally choose a profile photo.',
          hero: const Logoauth(),
          form: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pendingPhone.isNotEmpty) ...[
                  Text(
                    'Connected number'.tr,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      pendingPhone,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                TextFormField(
                  controller: controller.fullNameController,
                  validator: controller.validateName,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Full name'.tr,
                    hintText: 'Example: Ahmad Khaled'.tr,
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Profile photo'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: controller.pickProfileImage,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: controller.isPickingImage
                              ? const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : controller.profileImageFile != null
                                  ? ClipOval(
                                      child: Image.file(
                                        File(controller.profileImageFile!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.photo_camera_back_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.profileImageFile != null
                                    ? 'Photo selected'.tr
                                    : 'Tap to choose a profile photo'.tr,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You can skip this and continue if you want.'.tr,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Theme.of(context).hintColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppPillButton(
                  label: controller.isSaving ? 'Saving' : 'Start now',
                  icon: Icons.check_rounded,
                  expanded: true,
                  onPressed: controller.isSaving ? null : controller.finishSetup,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileSetupHero extends StatelessWidget {
  const _ProfileSetupHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 18,
            top: 24,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  const Icon(Icons.person_outline_rounded, color: Colors.white),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 18,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 46,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
