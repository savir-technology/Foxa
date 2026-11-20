import 'package:delvery/controllers/splash_controller.dart';
import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Obx(
              () => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const DriverBrandMark(),
                  const SizedBox(height: 28),
                  if (!controller.ready.value)
                    const CircularProgressIndicator(
                      color: DriverUi.primary,
                      strokeWidth: 2.6,
                    )
                  else ...[
                    Text(
                      controller.statusText.value,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: DriverUi.mutedTextAdaptive,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: controller.retry,
                      child: Text(t('إعادة المحاولة', 'Retry')),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

