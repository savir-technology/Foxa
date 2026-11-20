import 'package:delvery/screens/help_screen.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/widgets/driver_order_chat_card.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:delvery/core/localization/driver_text.dart';

class OrderChatScreen extends StatelessWidget {
  const OrderChatScreen({super.key, required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverUi.background,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          children: [
            DriverHeaderBar(
              leadingIcon: Icons.arrow_back_rounded,
              trailingIcon: Icons.headset_mic_outlined,
              onLeadingTap: () => Navigator.of(context).maybePop(),
              onTrailingTap: () =>
                  Get.to(() => const HelpScreen(embedInShell: true)),
            ),
            const SizedBox(height: 16),
            DriverPageHeader(
              title: tx('دردشة الطلب'),
              subtitle:
                  tx('هذه الصفحة مخصصة لمحادثة الطلب الحالي فقط. صفحة الدعم الفني منفصلة ويمكن فتحها من الأيقونة العلوية.'),
            ),
            const SizedBox(height: 18),
            DriverCard(
              color: DriverUi.surfaceWarm,
              borderColor: DriverUi.line,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: DriverUi.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: DriverUi.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.restaurantName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: DriverUi.text,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tx('طلبات هذا الفرع فقط تظهر هنا، أما الدعم الفني فله شاشة مستقلة.'),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: DriverUi.mutedText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniInfoChip(
                          label: tx('رقم الطلب'),
                          value: '#${order.id}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniInfoChip(
                          label: tx('المنطقة'),
                          value: order.zone,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DriverOrderChatCard(order: order),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  const _MiniInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DriverUi.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DriverUi.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DriverUi.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DriverUi.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
