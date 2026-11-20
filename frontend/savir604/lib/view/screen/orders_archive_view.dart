import 'package:flutter/material.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:get/get.dart';
import 'package:tks/core/functions/app_image_urls.dart';
import 'package:tks/controler/archive/orders_archive_controller.dart';
import 'package:tks/data/datasource/model/orders_archive_model.dart';
import 'package:tks/view/widget/common/app_top_banner.dart';
import 'package:tks/view/widget/common/fallback_network_image.dart';

class OrdersArchivePagee extends StatelessWidget {
  const OrdersArchivePagee({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrdersArchiveControllerr());
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isArabic = Get.locale?.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primary.withValues(alpha: 0.08),
                theme.scaffoldBackgroundColor,
                theme.scaffoldBackgroundColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Obx(() {
              final orders = controller.ordersList;

              return RefreshIndicator(
                onRefresh: () => controller.fetchOrdersArchive(controller.userId),
                color: colors.primary,
                backgroundColor: theme.cardColor,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _ArchiveHero(
                      title: isArabic ? 'أرشيف الطلبات' : 'Order archive',
                      subtitle: isArabic
                          ? 'كل طلباتك السابقة في مكان واحد مرتب وواضح.'
                          : 'All of your previous orders in one clean place.',
                      primaryValue: orders.length.toString(),
                      primaryLabel: isArabic ? 'طلب' : 'Orders',
                      secondaryValue: _totalSpent(orders),
                      secondaryLabel: isArabic ? 'إجمالي المصروف' : 'Spent',
                    ),
                    const SizedBox(height: 16),
                    if (controller.isLoading.value)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (orders.isEmpty)
                      _EmptyArchive(theme: theme, colors: colors)
                    else
                      ...orders.map(
                        (order) => _ArchiveCard(
                          order: order,
                          isArabic: isArabic,
                          onOpenDetails: () => controller.openOrderDetails(order),
                          onReorder: () => controller.reorderOrder(order.ordersId),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _totalSpent(List<OrdersArchiveModel> orders) {
    double total = 0;
    for (final order in orders) {
      total += double.tryParse(order.ordersTotalprice) ?? 0;
    }

    return total == 0 ? '0 ${AppCurrency.code}' : '${total.toStringAsFixed(0)} ${AppCurrency.code}';
  }
}

class _ArchiveHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final String primaryValue;
  final String primaryLabel;
  final String secondaryValue;
  final String secondaryLabel;

  const _ArchiveHero({
    required this.title,
    required this.subtitle,
    required this.primaryValue,
    required this.primaryLabel,
    required this.secondaryValue,
    required this.secondaryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppTopBanner(
      title: title,
      subtitle: subtitle,
      leadingIcon: Icons.arrow_back_rounded,
      onLeadingTap: Get.back,
      trailingIcon: Icons.archive_outlined,
      onTrailingTap: () {},
      child: Row(
        children: [
          Expanded(
            child: AppTopBannerMetric(
              value: primaryValue,
              label: primaryLabel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppTopBannerMetric(
              value: secondaryValue,
              label: secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyArchive extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colors;

  const _EmptyArchive({required this.theme, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: colors.primary.withValues(alpha: 0.10),
            child: Icon(
              Icons.inventory_2_outlined,
              color: colors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            theme.platform == TargetPlatform.iOS
                ? 'No archived orders yet'
                : 'لا توجد طلبات مؤرشفة حالياً',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            theme.platform == TargetPlatform.iOS
                ? 'Finished orders will appear here in a tidy archive.'
                : 'عندما تنتهي من طلباتك السابقة ستظهر هنا بشكل منظم.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final OrdersArchiveModel order;
  final bool isArabic;
  final VoidCallback onOpenDetails;
  final VoidCallback onReorder;

  const _ArchiveCard({
    required this.order,
    required this.isArabic,
    required this.onOpenDetails,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final price = double.tryParse(order.itemPrice) ?? 0;
    final discount = double.tryParse(order.itemDiscount) ?? 0;
    final quantity = int.tryParse(order.quantity) ?? 1;
    final frameOnlyTotal = (price - (price * discount / 100)) * quantity;
    final lensTotal = double.tryParse(order.lensTotalPrice) ?? 0;
    final finalPrice = double.tryParse(order.lineTotal) ?? (frameOnlyTotal + lensTotal);
    final hasLenses = order.lensName.trim().isNotEmpty;
    final hasVariantDetails =
        order.itemColor.trim().isNotEmpty || order.itemSize.trim().isNotEmpty;
    final storeName = order.storeName.trim().isNotEmpty
        ? order.storeName
        : (isArabic ? 'المتجر' : 'Store');
    final dateLabel = _archiveDateText(order.ordersDatetime, isArabic);
    final status = _archiveStatusData(order.ordersStatus, isArabic, theme);

    Widget metaChip({
      required IconData icon,
      required String label,
      Color? backgroundColor,
      Color? foregroundColor,
    }) {
      final chipBackground =
          backgroundColor ?? colors.primary.withValues(alpha: 0.08);
      final chipForeground = foregroundColor ?? colors.primary;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: chipBackground,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: chipForeground),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: chipForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FallbackNetworkImage(
                  imageUrls: AppImageUrls.item(order.itemsImage),
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: 88,
                    height: 88,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: colors.primary.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Row(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            order.itemName,
                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: status.backgroundColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                status.icon,
                                size: 14,
                                color: status.foregroundColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status.label,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: status.foregroundColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      storeName,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment:
                          isArabic ? WrapAlignment.end : WrapAlignment.start,
                      children: [
                        metaChip(
                          icon: Icons.confirmation_number_outlined,
                          label: '#${order.ordersId}',
                        ),
                        metaChip(
                          icon: Icons.schedule_rounded,
                          label: dateLabel,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ],
                    ),
                    if (hasVariantDetails || hasLenses) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment:
                            isArabic ? WrapAlignment.end : WrapAlignment.start,
                        children: [
                          if (order.itemColor.trim().isNotEmpty)
                            metaChip(
                              icon: Icons.palette_outlined,
                              label: isArabic
                                  ? 'اللون: ${order.itemColor}'
                                  : 'Color: ${order.itemColor}',
                              backgroundColor: colors.primary.withValues(alpha: 0.12),
                              foregroundColor: colors.primary,
                            ),
                          if (order.itemSize.trim().isNotEmpty)
                            metaChip(
                              icon: Icons.straighten_rounded,
                              label: isArabic
                                  ? 'المقاس: ${order.itemSize}'
                                  : 'Size: ${order.itemSize}',
                              backgroundColor: colors.primary.withValues(alpha: 0.12),
                              foregroundColor: colors.primary,
                            ),
                          if (hasLenses)
                            metaChip(
                              icon: Icons.visibility_outlined,
                              label: isArabic ? 'إضافات' : 'Extras',
                              backgroundColor: colors.primary.withValues(alpha: 0.12),
                              foregroundColor: colors.primary,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      isArabic
                          ? 'تم حفظ هذا الطلب في الأرشيف'
                          : 'This order is saved in the archive',
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PriceRow(
                  label: isArabic ? 'الكمية' : 'Quantity',
                  value: order.quantity,
                ),
                const SizedBox(height: 8),
                _PriceRow(
                  label: isArabic ? 'السعر قبل الخصم' : 'Before discount',
                  value: '${order.itemPrice} ${AppCurrency.code}',
                ),
                const SizedBox(height: 8),
                _PriceRow(
                  label: isArabic ? 'الخصم' : 'Discount',
                  value: '${order.itemDiscount}%',
                ),
                if (hasLenses) ...[
                  const SizedBox(height: 8),
                  _PriceRow(
                    label: isArabic ? 'سعر الإضافة' : 'Add-on price',
                    value:
                        '${double.tryParse(order.lensUnitPrice)?.toStringAsFixed(2) ?? order.lensUnitPrice} ${AppCurrency.code}',
                  ),
                  if (order.lensName.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _PriceRow(
                      label: isArabic ? 'اسم الإضافة' : 'Add-on name',
                      value: order.lensName,
                    ),
                  ],
                  if (order.lensColor.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _PriceRow(
                      label: isArabic ? 'لون الإضافة' : 'Add-on color',
                      value: order.lensColor,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _PriceRow(
                    label: isArabic ? 'إجمالي الإضافات' : 'Extras total',
                        value: '${lensTotal.toStringAsFixed(2)} ${AppCurrency.code}',
                  ),
                ],
                const SizedBox(height: 10),
                _PriceRow(
                  label: isArabic ? 'الإجمالي النهائي' : 'Final total',
                        value: '${finalPrice.toStringAsFixed(2)} ${AppCurrency.code}',
                  highlight: true,
                ),
                if (hasLenses && order.prescriptionSummary.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      isArabic
                          ? 'تفاصيل الإضافة: ${order.prescriptionSummary}'
                          : 'Extras: ${order.prescriptionSummary}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onOpenDetails,
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: Text(isArabic ? 'التفاصيل' : 'Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primary,
                          side: BorderSide(color: theme.dividerColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onReorder,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(isArabic ? 'إعادة الطلب' : 'Reorder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveStatusData {
  const _ArchiveStatusData({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
}

_ArchiveStatusData _archiveStatusData(
  String? rawStatus,
  bool isArabic,
  ThemeData theme,
) {
  final colors = theme.colorScheme;
  final mutedBackground = theme.brightness == Brightness.dark
      ? colors.surfaceContainerHighest
      : const Color(0xFFF5F6F3);
  final successBackground = colors.primary.withValues(alpha: 0.14);
  final mutedForeground = colors.onSurface.withValues(alpha: 0.68);
  final status = (rawStatus ?? '').toLowerCase().trim();
  switch (status) {
    case '4':
    case 'delivered':
    case 'completed':
      return _ArchiveStatusData(
        label: isArabic ? 'مكتمل' : 'Completed',
        backgroundColor: successBackground,
        foregroundColor: colors.primary,
        icon: Icons.check_circle_rounded,
      );
    case 'canceled':
    case 'cancelled':
      return _ArchiveStatusData(
        label: isArabic ? 'ملغي' : 'Cancelled',
        backgroundColor: colors.error.withValues(alpha: 0.14),
        foregroundColor: mutedForeground,
        icon: Icons.cancel_rounded,
      );
    case 'pending':
    case 'new':
    case '0':
      return _ArchiveStatusData(
        label: isArabic ? 'قيد المعالجة' : 'Pending',
        backgroundColor: mutedBackground,
        foregroundColor: colors.error,
        icon: Icons.hourglass_bottom_rounded,
      );
    case 'assigned':
    case 'accepted':
    case 'preparing':
    case 'on_the_way':
      return _ArchiveStatusData(
        label: isArabic ? 'مكتمل' : 'Completed',
        backgroundColor: successBackground,
        foregroundColor: colors.primary,
        icon: Icons.check_circle_rounded,
      );
    default:
      return _ArchiveStatusData(
        label: status.isEmpty
            ? (isArabic ? 'مؤرشف' : 'Archived')
            : status,
        backgroundColor: mutedBackground,
        foregroundColor: mutedForeground,
        icon: Icons.archive_outlined,
      );
  }
}

String _archiveDateText(String rawDate, bool isArabic) {
  final text = rawDate.trim();
  if (text.isEmpty) {
    return isArabic ? 'غير متوفر' : 'N/A';
  }

  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    return text.split(' ').first;
  }

  final local = parsed.toLocal();
  const monthsEn = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  const monthsAr = <String>[
    'ينا',
    'فبر',
    'مار',
    'أبر',
    'ماي',
    'يون',
    'يول',
    'أغس',
    'سبت',
    'أكت',
    'نوف',
    'ديس',
  ];
  final month = isArabic ? monthsAr[local.month - 1] : monthsEn[local.month - 1];
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? (isArabic ? 'م' : 'PM') : (isArabic ? 'ص' : 'AM');

  return isArabic
      ? '${local.day} $month ${local.year} • $hour12:$minute $suffix'
      : '${local.day} $month ${local.year} • $hour12:$minute $suffix';
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _PriceRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: highlight ? colors.primary : colors.onSurface,
            fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
