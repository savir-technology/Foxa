import 'dart:async';

import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeliverySuccessScreen extends StatefulWidget {
  const DeliverySuccessScreen({
    super.key,
    required this.orderId,
    required this.elapsedText,
  });

  final int orderId;
  final String elapsedText;

  @override
  State<DeliverySuccessScreen> createState() => _DeliverySuccessScreenState();
}

class _DeliverySuccessScreenState extends State<DeliverySuccessScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Get.offAllNamed(AppRoutes.home, arguments: {'tab': 0});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              const Center(child: DriverBrandMark()),
              const SizedBox(height: 28),
              DriverCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: DriverUi.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: DriverUi.primary,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tx('تم التسليم بنجاح'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: DriverUi.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Order #${widget.orderId}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: DriverUi.mutedText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      trParam('الوقت: {time}', 'Time: {time}', {
                        'time': widget.elapsedText,
                      }),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: DriverUi.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DriverCard(
                      color: const Color(0xFFFFF8F3),
                      borderColor: const Color(0xFFF0D8CA),
                      child: Text(
                        tx(
                          'سيتم الرجوع إلى الصفحة الرئيسية خلال ثوانٍ قليلة...',
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DriverUi.mutedText,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    DriverPrimaryButton(
                      label: tx('العودة للصفحة الرئيسية'),
                      icon: Icons.home_rounded,
                      onPressed: () {
                        Get.offAllNamed(AppRoutes.home, arguments: {'tab': 0});
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
