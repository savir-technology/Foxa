import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  @override
  Widget build(BuildContext context) {
    final ordersService = Get.find<DriverOrdersService>();
    return Scaffold(
      appBar: null,
      body: SafeArea(
        top: !embedInShell,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            const DriverHeaderBar(),
            const SizedBox(height: 16),
            DriverPageHeader(
              title: t('سجل الطلبات', 'Orders history'),
              subtitle: t(
                'جميع الطلبات السابقة وتفاصيلها',
                'All past orders and their details',
              ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => ordersService.history.isEmpty
                  ? DriverEmptyStateCard(
                      icon: Icons.receipt_long_rounded,
                      title: t('لا توجد طلبات مكتملة', 'No completed orders'),
                      subtitle: t(
                        'ستظهر الطلبات المنتهية هنا بعد إتمامها.',
                        'Finished orders will appear here after completion.',
                      ),
                    )
                  : Column(
                      children: [
                        for (final order in ordersService.history)
                          _HistoryCard(order: order),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DriverCard(
        child: InkWell(
          onTap: () => Get.toNamed(AppRoutes.orderDetails, arguments: order),
          borderRadius: BorderRadius.circular(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: DriverUi.primarySoftAdaptive,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: DriverUi.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t('الطلب', 'Order')} #${order.id}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: DriverUi.textAdaptive,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.restaurantName,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: DriverUi.mutedTextAdaptive),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: DriverUi.primarySoftAdaptive,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      t('مكتمل', 'Completed'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: DriverUi.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: DriverUi.lineAdaptive.withValues(alpha: 0.9)),
              const SizedBox(height: 12),
              Text(
                order.customerName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DriverUi.textAdaptive,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.customerAddress,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: DriverUi.mutedTextAdaptive),
              ),
              const SizedBox(height: 10),
              Text(
                DateFormat('EEE, MMM d - hh:mm a').format(order.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: DriverUi.mutedTextAdaptive),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

