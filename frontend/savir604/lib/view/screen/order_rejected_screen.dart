import 'package:flutter/material.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:get/get.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/view/widget/common/app_pill_button.dart';

class OrderRejectedScreen extends StatelessWidget {
  const OrderRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};
    final isArabic = Get.locale?.languageCode == 'ar';
    final orderId = '${args['order_id'] ?? '-'}'.trim();
    final total = '${args['total'] ?? '0.00'}'.trim();
    final paymentStatus =
        '${args['payment_status'] ?? args['status'] ?? 'failed'}'
            .toLowerCase()
            .trim();
    final failureReason = '${args['failure_reason'] ?? ''}'.trim();
    final statusLabel = paymentStatus == 'pending'
        ? (isArabic ? 'بانتظار التأكيد' : 'Pending confirmation')
        : (isArabic ? 'فشل الدفع' : 'Payment failed');

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F4),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFFE8ECE8)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFECEB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cancel_rounded,
                              size: 64,
                              color: Color(0xFFB3261E),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            isArabic ? 'تم رفض الطلب' : 'Order rejected',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF171717),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isArabic
                                ? 'تعذر إكمال عملية الدفع. يمكنك العودة إلى إتمام الطلب والمحاولة مرة أخرى.'
                                : 'Payment could not be completed. You can return to checkout and try again.',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      height: 1.45,
                                      color: const Color(0xFF6D736E),
                                    ),
                          ),
                          const SizedBox(height: 22),
                          _InfoTile(
                            label: isArabic ? 'حالة الطلب' : 'Order status',
                            value: statusLabel,
                            valueColor: const Color(0xFFB3261E),
                          ),
                          const SizedBox(height: 12),
                          _InfoTile(
                            label: isArabic ? 'رقم الطلب' : 'Order ID',
                            value: orderId.isNotEmpty ? '#$orderId' : '-',
                          ),
                          const SizedBox(height: 12),
                          _InfoTile(
                            label: isArabic ? 'الإجمالي' : 'Total',
                            value: '$total ${AppCurrency.code}',
                          ),
                          if (failureReason.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5F4),
                                borderRadius: BorderRadius.circular(22),
                                border:
                                    Border.all(color: const Color(0xFFF2C4C0)),
                              ),
                              child: Text(
                                failureReason,
                                textAlign:
                                    isArabic ? TextAlign.right : TextAlign.left,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF7A2A23),
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                AppPillButton(
                  label:
                      isArabic ? 'العودة إلى إتمام الطلب' : 'Back to checkout',
                  icon: Icons.refresh_rounded,
                  expanded: true,
                  backgroundColor: const Color(0xFFFF6500),
                  foregroundColor: Colors.white,
                  onPressed: () => Get.offNamed(AppRoutes.checkout),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.homepage),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    isArabic ? 'العودة للرئيسية' : 'Go home',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8E3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF78807B),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: valueColor ?? const Color(0xFF171717),
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
