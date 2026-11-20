import 'package:flutter/material.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/view/widget/common/app_pill_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        Get.arguments is Map ? Get.arguments as Map : <String, dynamic>{};
    final orderId = '${args['order_id'] ?? '-'}';
    final total = '${args['total'] ?? '0.00'}';
    final etaMinutes = int.tryParse('${args['estimated_minutes'] ?? 45}') ?? 45;
    final shareToken = '${args['share_token'] ?? ''}';
    final deliveryCode = '${args['delivery_code'] ?? ''}';
    final orderMode = '${args['order_mode'] ?? 'asap'}'.toLowerCase().trim();
    final scheduledFor = '${args['scheduled_for'] ?? ''}'.trim();
    final paymentStatus =
        '${args['payment_status'] ?? args['status'] ?? 'pending'}'
            .toLowerCase()
            .trim();
    final orderType =
        '${args['order_type'] ?? args['orderstype'] ?? args['orders_type'] ?? '0'}';
    final isPickup = orderType == '1';
    final isPaid = paymentStatus == 'paid' ||
        paymentStatus == 'success' ||
        paymentStatus == 'completed' ||
        paymentStatus == 'confirmed';
    final theme = Theme.of(context);
    final isArabic = Get.locale?.languageCode == 'ar';

    String formatScheduledFor(String raw) {
      final parsed = DateTime.tryParse(raw.replaceFirst('T', ' '));
      if (parsed == null) {
        return raw;
      }
      return DateFormat('yyyy/MM/dd h:mm a', isArabic ? 'ar' : 'en')
          .format(parsed);
    }

    String orderModeLabel() {
      switch (orderMode) {
        case 'scheduled':
          return isArabic ? 'طلب مجدول' : 'Scheduled order';
        case 'preorder':
          return isArabic ? 'طلب مسبق' : 'Preorder';
        default:
          return isArabic ? 'طلب فوري' : 'ASAP';
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 152,
                      height: 152,
                      child: Lottie.asset(
                        'assets/lottie/Order completed.json',
                        repeat: false,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'تم إنشاء الطلب بنجاح',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'يمكنك الآن تتبع الطلب ومشاركة حالته المباشرة مع المستلم.',
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? const Color(0xFFEAF6EE)
                            : const Color(0xFFFFF6E8),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isPaid
                              ? const Color(0xFFD6EAD9)
                              : const Color(0xFFF4D8A2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaid
                                ? Icons.verified_rounded
                                : Icons.hourglass_top_rounded,
                            size: 18,
                            color: isPaid
                                ? const Color(0xFF1C7C3E)
                                : const Color(0xFFAD6B00),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPaid
                                ? (Get.locale?.languageCode == 'ar'
                                    ? 'تم تأكيد الدفع'
                                    : 'Payment confirmed')
                                : (Get.locale?.languageCode == 'ar'
                                    ? 'جاري تأكيد الدفع'
                                    : 'Payment pending'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isPaid
                                  ? const Color(0xFF1C7C3E)
                                  : const Color(0xFFAD6B00),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          _MetricRow(label: 'رقم الطلب', value: '#$orderId'),
                          const SizedBox(height: 12),
                          _MetricRow(label: 'الإجمالي', value: '$total ${AppCurrency.code}'),
                          const SizedBox(height: 12),
                          _MetricRow(
                            label: isArabic ? 'نوع الطلب' : 'Order mode',
                            value: orderModeLabel(),
                          ),
                          if (scheduledFor.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _MetricRow(
                              label: isArabic ? 'موعد الطلب' : 'Scheduled time',
                              value: formatScheduledFor(scheduledFor),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _MetricRow(
                            label: 'الوقت المتوقع',
                            value: '$etaMinutes د',
                          ),
                          if (shareToken.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _MetricRow(
                              label: 'رمز المشاركة',
                              value: shareToken,
                            ),
                          ],
                          if (deliveryCode.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _MetricRow(
                              label: 'رمز التوصيل',
                              value: deliveryCode,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppPillButton(
                label: isPickup ? 'عرض رمز الاستلام' : 'تتبع الطلب',
                icon: isPickup
                    ? Icons.qr_code_2_rounded
                    : Icons.location_searching_rounded,
                expanded: true,
                onPressed: () {
                  Get.offNamed(
                    isPickup ? AppRoutes.pickupQr : AppRoutes.orderTracking,
                    arguments: args,
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Get.offAllNamed(AppRoutes.homepage),
                child: const Text('العودة للرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
