import 'package:flutter/material.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:get/get.dart';
import 'package:tks/controler/cart/cart_controller.dart';

class BottomNavgationBarCart extends GetView<CartController> {
  final String totalprice;
  final int restaurantCount;

  const BottomNavgationBarCart({
    super.key,
    required this.totalprice,
    this.restaurantCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isArabic = Get.locale?.languageCode == 'ar';

    final note = restaurantCount > 1
        ? (isArabic
            ? 'سيتم تقسيم الطلب تلقائيًا بين $restaurantCount مطاعم عند الدفع.'
            : 'This order will be split automatically across $restaurantCount restaurants at checkout.')
        : (isArabic
            ? 'الطلب جاهز من مطعم واحد.'
            : 'This order is ready from a single restaurant.');

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isArabic ? 'الإجمالي' : 'Total',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.72,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalprice ${AppCurrency.code}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.75,
                      ),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: controller.goToPageCheckout,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                isArabic ? 'إتمام الطلب' : 'Checkout',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
