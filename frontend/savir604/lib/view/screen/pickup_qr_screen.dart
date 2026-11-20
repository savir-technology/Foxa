import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PickupQrScreen extends StatelessWidget {
  const PickupQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        Get.arguments is Map ? Get.arguments as Map : <String, dynamic>{};
    final orderId = '${args['order_id'] ?? args['orders_id'] ?? '-'}';
    final shareToken =
        '${args['share_token'] ?? args['orders_share_token'] ?? ''}';
    final eta =
        '${args['estimated_minutes'] ?? args['orders_estimated_minutes'] ?? '20'}';
    final qrValue = 'ALEPPO_EATS_PICKUP|$orderId|$shareToken';
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pickup QR',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: qrValue,
                      version: QrVersions.auto,
                      size: 220,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Show this code at the restaurant counter.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Order #$orderId',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Estimated ready time: $eta min',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
