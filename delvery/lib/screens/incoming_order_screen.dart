import 'package:delvery/controllers/incoming_order_controller.dart';
import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IncomingOrderScreen extends GetView<IncomingOrderController> {
  const IncomingOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersService = Get.find<DriverOrdersService>();
    final sessionService = Get.find<DriverSessionService>();
    final order = ordersService.incomingOrder.value;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              const SizedBox(height: 8),
              const Center(child: DriverBrandMark()),
              const SizedBox(height: 24),
              DriverPageHeader(
                title: tx('وصل طلب جديد'),
                subtitle: tx('سيتم القبول تلقائيًا خلال الوقت المحدد'),
              ),
              const SizedBox(height: 20),
              DriverCard(
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 84,
                                height: 84,
                                child: CircularProgressIndicator(
                                  value: controller.countdown.value / 10,
                                  strokeWidth: 7,
                                  backgroundColor: DriverUi.primarySoft,
                                  color: DriverUi.primary,
                                ),
                              ),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: DriverUi.primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
                                  color: DriverUi.primary,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx('سيتم قبول الطلب تلقائيًا خلال'),
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: DriverUi.mutedText,
                                        height: 1.35,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  trParam('{seconds} ث', '{seconds}s', {
                                    'seconds': controller.countdown.value
                                        .toString()
                                        .padLeft(2, '0'),
                                  }),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: DriverUi.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DetailRow(
                        label: tx('الطلب'),
                        value: '#${order?.id ?? '-'}',
                      ),
                      _DetailRow(
                        label: tx('المطعم'),
                        value: order?.restaurantName ?? '-',
                      ),
                      _DetailRow(
                        label: tx('المستلم'),
                        value: order?.customerName ?? '-',
                      ),
                      _DetailRow(
                        label: tx('المنطقة'),
                        value: order?.zone ?? '-',
                      ),
                      _DetailRow(
                        label: tx('المسافة'),
                        value: trParam('{distance} كم', '{distance} km', {
                          'distance':
                              order
                                  ?.resolvedDistanceKm(
                                    origin: sessionService.liveCoordinate.value,
                                  )
                                  .toStringAsFixed(1) ??
                              '-',
                        }),
                      ),
                      const SizedBox(height: 12),
                      DriverCard(
                        color: const Color(0xFFFFF8F3),
                        borderColor: const Color(0xFFF0D8CA),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: DriverUi.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tx(
                                  'لا يمكن رفض الطلبات في هذا التطبيق المخصص لسائقي الشركة.',
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: DriverUi.text,
                                      height: 1.45,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DriverPrimaryButton(
                        label: tx('قبول الآن'),
                        icon: Icons.check_rounded,
                        onPressed: controller.acceptNow,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DriverUi.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: DriverUi.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
