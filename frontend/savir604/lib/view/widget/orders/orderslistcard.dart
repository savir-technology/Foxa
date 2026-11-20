// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tks/controler/orders/pending.dart';
import 'package:tks/data/datasource/model/ordersmodel.dart';

class CardOrdersList extends GetView<OrdersPendingController> {
  const CardOrdersList({Key? key, required this.listdata}) : super(key: key);

  final OrdersModel listdata;

  bool get _isPendingDeleteState {
    final status = (listdata.ordersStatus ?? '').toLowerCase();
    return status == '0' || status == 'pending';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipient = listdata.ordersRecipientName?.trim() ?? '';
    final status = controller.printOrderStatus(listdata.ordersStatus ?? 'pending');
    final total = listdata.ordersTotalprice ?? '0';
    final eta = listdata.ordersEstimatedMinutes?.trim().isNotEmpty == true
        ? '${listdata.ordersEstimatedMinutes} min'
        : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${listdata.ordersId}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111111),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  listdata.ordersDatetime != null
                      ? DateFormat('yyyy-MM-dd')
                          .format(DateTime.parse(listdata.ordersDatetime!))
                      : '-',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF222222),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipLabel(label: status),
              _ChipLabel(
                label: controller.printOrderType(listdata.ordersType ?? '0'),
              ),
              _ChipLabel(
                label: controller.printPaymentMethod(
                  listdata.ordersPaymentmethod ?? '0',
                ),
              ),
              _ChipLabel(label: 'ETA $eta'),
            ],
          ),
          const SizedBox(height: 14),
          _InfoText(
            label: 'Subtotal',
            value: '${listdata.ordersPrice ?? '0'} ${AppCurrency.code}',
          ),
          const SizedBox(height: 8),
          _InfoText(
            label: 'Delivery',
            value: '${listdata.ordersPricedelivery ?? '0'} ${AppCurrency.code}',
          ),
          if (recipient.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoText(
              label: 'Recipient',
              value: recipient,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'الإجمالي: $total ${AppCurrency.code}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111111),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => controller.openTracking(listdata),
                child: const Text('Track'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => controller.openDetails(listdata),
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.openSupportForOrder(listdata),
                  child: const Text('Help'),
                ),
              ),
              if (_isPendingDeleteState) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.deleteOrder(listdata.ordersId!),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF222222),
            ),
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
