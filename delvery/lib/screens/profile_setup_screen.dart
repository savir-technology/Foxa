import 'dart:async';
import 'dart:io';

import 'package:delvery/controllers/auth_controller.dart';
import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final AuthController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
    controller.primeProfileDraft();
    unawaited(controller.loadAvailableRestaurants());
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
              title: tx('إكمال البيانات الأساسية'),
              subtitle: tx('بعدها ستنتقل مباشرة إلى الصفحة الرئيسية'),
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
                      Icons.verified_outlined,
                      color: DriverUi.primary,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      unawaited(controller.pickProfileImage());
                    },
                    child: Obx(() {
                      final path = controller.selectedPhotoPath.value;
                      return Container(
                        width: 162,
                        height: 162,
                        decoration: BoxDecoration(
                          color: DriverUi.surfaceSoft,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: DriverUi.line),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: path == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: DriverUi.primarySoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 34,
                                      color: DriverUi.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    tx('اضغط لإضافة صورة'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: DriverUi.text,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tx('تأكد من وضوح الصورة'),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: DriverUi.mutedText),
                                  ),
                                ],
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(File(path), fit: BoxFit.cover),
                                  Positioned(
                                    right: 10,
                                    top: 10,
                                    child: GestureDetector(
                                      onTap: controller.clearProfileImage,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.45,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tx('الصورة ستظهر للعميل داخل التطبيق'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DriverUi.mutedText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller.fullNameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: tx('اسم السائق'),
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.vehicleTypeController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: tx('نوع المركبة'),
                      prefixIcon: const Icon(Icons.two_wheeler_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.vehicleNumberController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: tx('رقم المركبة'),
                      prefixIcon: const Icon(
                        Icons.confirmation_number_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: tx('رقم الهاتف'),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Obx(
                    () => SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: controller.wantsRestaurantLink.value,
                      onChanged: (value) {
                        controller.wantsRestaurantLink.value = value;
                        if (!value) controller.selectedVendorId.value = 0;
                      },
                      title: Text(tx('أرغب في الربط بمتجر أو مطعم')),
                      subtitle: Text(
                        tx(
                          'اختياري — يمكنك التسجيل كسائق مستقل والعمل مع المنصة مباشرة',
                        ),
                      ),
                    ),
                  ),
                  Obx(() {
                    if (!controller.wantsRestaurantLink.value) {
                      return DriverCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.public_outlined,
                              color: DriverUi.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tx('سائق مستقل — الموافقة النهائية من الماستر'),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return DropdownButtonFormField<int>(
                      value: controller.selectedVendorId.value > 0
                          ? controller.selectedVendorId.value
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: tx('اختر المتجر أو المطعم'),
                        prefixIcon: const Icon(Icons.storefront_outlined),
                      ),
                      items: controller.availableRestaurants
                          .map(
                            (restaurant) => DropdownMenuItem<int>(
                              value: restaurant.id,
                              child: Text(restaurant.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          controller.selectedVendorId.value = value ?? 0,
                    );
                  }),
                  const SizedBox(height: 18),
                  Obx(
                    () => DriverPrimaryButton(
                      label: tx('إكمال التسجيل'),
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: controller.isLoading.value
                          ? null
                          : () {
                              unawaited(controller.completeRegistration());
                            },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tx('بعد الإكمال سيتم توجيهك مباشرة إلى الواجهة الرئيسية.'),
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
