import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/screens/tracking_screen.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:delvery/core/services/driver_platform_settings.dart';
import 'package:get/get.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverUi.background,
      appBar: AppBar(
        title: Text(trParam('الطلب #{id}', 'Order #{id}', {'id': order.id})),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => TrackingScreen(order: order)),
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _HeroCard(order: order),
            const SizedBox(height: 12),
            _SectionCard(
              title: tx('بيانات المطعم'),
              child: Column(
                children: [
                  _InfoRow(label: tx('الاسم'), value: order.restaurantName),
                  _InfoRow(
                    label: tx('العنوان'),
                    value: order.restaurantAddress.isNotEmpty
                        ? order.restaurantAddress
                        : tx('غير متوفر'),
                  ),
                  _InfoRow(
                    label: tx('الهاتف'),
                    value: order.restaurantPhone.isNotEmpty
                        ? order.restaurantPhone
                        : tx('غير متوفر'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: tx('تفاصيل البنود'),
              child: order.items.isEmpty
                  ? Text(
                      tx('لا توجد بنود مفصلة لهذا الطلب.'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DriverUi.mutedText,
                      ),
                    )
                  : Column(
                      children: order.items
                          .map(
                            (item) =>
                                _ItemRow(item: item, currency: order.currency),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: tx('بيانات المستلم'),
              child: Column(
                children: [
                  _InfoRow(label: tx('الاسم'), value: order.customerName),
                  _InfoRow(
                    label: tx('العنوان'),
                    value: order.customerAddress.isNotEmpty
                        ? order.customerAddress
                        : tx('غير متوفر'),
                  ),
                  _InfoRow(
                    label: tx('الهاتف'),
                    value: order.customerPhone.isNotEmpty
                        ? order.customerPhone
                        : tx('غير متوفر'),
                  ),
                  if (order.giftMessage.trim().isNotEmpty)
                    _InfoRow(
                      label: tx('رسالة الإهداء'),
                      value: order.giftMessage,
                    ),
                  if (order.customerNote.trim().isNotEmpty)
                    _InfoRow(label: tx('الملاحظات'), value: order.customerNote),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: tx('ملخص التسليم'),
              child: Column(
                children: [
                  _InfoRow(label: tx('المنطقة'), value: order.zone),
                  _InfoRow(
                    label: tx('المسافة'),
                    value: trParam('{distance} كم', '{distance} km', {
                      'distance': order.resolvedDistanceKm().toStringAsFixed(1),
                    }),
                  ),
                  _InfoRow(
                    label: tx('الوقت المتوقع'),
                    value: trParam('{minutes} دقيقة', '{minutes} min', {
                      'minutes': order.etaMinutes,
                    }),
                  ),
                  _InfoRow(
                    label: tx('تاريخ الإنشاء'),
                    value: _formatDateTime(order.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: tx('الأسعار'),
              child: Column(
                children: [
                  _InfoRow(
                    label: tx('قيمة الطلب'),
                    value: _money(order.resolvedTotalPrice, order.currency),
                  ),
                  _InfoRow(
                    label: tx('رسوم التوصيل'),
                    value: order.deliveryFee > 0
                        ? _money(order.deliveryFee, order.currency)
                        : tx('مجانية'),
                  ),
                  _InfoRow(
                    label: tx('الإجمالي'),
                    value: _money(
                      order.resolvedTotalPrice + order.deliveryFee,
                      order.currency,
                    ),
                    valueColor: DriverUi.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (order.isDelivered)
              DriverPrimaryButton(
                label: tx('العودة إلى الصفحة الرئيسية'),
                icon: Icons.home_rounded,
                onPressed: () {
                  Get.offAllNamed(AppRoutes.home, arguments: {'tab': 0});
                },
              )
            else
              Row(
                children: [
                  Expanded(
                    child: DriverSecondaryButton(
                      label: tx('تتبع'),
                      icon: Icons.navigation_rounded,
                      onPressed: () =>
                          Get.to(() => TrackingScreen(order: order)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DriverPrimaryButton(
                      label: tx('فتح الطلب'),
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => Get.toNamed(AppRoutes.currentOrder),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = order.restaurantMediaUrl;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8F3), Color(0xFFFFF0E6)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DriverUi.line),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: DriverUi.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DriverUi.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: mediaUrl.isEmpty
                ? const Icon(
                    Icons.storefront_outlined,
                    color: DriverUi.primary,
                    size: 34,
                  )
                : Image.network(
                    mediaUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.storefront_outlined,
                      color: DriverUi.primary,
                      size: 34,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: DriverUi.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusLabel(order.status),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DriverUi.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.zone} · ${_formatDateTime(order.createdAt)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: DriverUi.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DriverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: DriverUi.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: DriverUi.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor ?? DriverUi.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.currency});

  final DriverOrderItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final prefix = currency.isNotEmpty
        ? currency
        : DriverPlatformSettings.currencySymbol;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ItemThumb(imageUrl: item.imageUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: DriverUi.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  trParam('الكمية: {qty}', 'Quantity: {qty}', {
                    'qty': item.quantity,
                  }),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: DriverUi.mutedText),
                ),
                if ((item.note ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.note!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: DriverUi.mutedText),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.resolvedUnitPrice > 0
                    ? '$prefix ${item.resolvedUnitPrice.toStringAsFixed(2)}'
                    : '—',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DriverUi.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.resolvedTotalPrice > 0
                    ? '$prefix ${item.resolvedTotalPrice.toStringAsFixed(2)}'
                    : '—',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DriverUi.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemThumb extends StatelessWidget {
  const _ItemThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: DriverUi.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DriverUi.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.trim().isEmpty
          ? const Icon(
              Icons.fastfood_outlined,
              color: DriverUi.primary,
              size: 22,
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.fastfood_outlined,
                color: DriverUi.primary,
                size: 22,
              ),
            ),
    );
  }
}

String _money(double value, String currency) {
  final prefix = currency.isNotEmpty
      ? currency
      : DriverPlatformSettings.currencySymbol;
  return value > 0 ? '$prefix ${value.toStringAsFixed(2)}' : tx('غير متوفر');
}

String _statusLabel(DriverOrderStatus status) {
  switch (status) {
    case DriverOrderStatus.incoming:
      return tx('طلب جديد');
    case DriverOrderStatus.assigned:
      return tx('مكلف');
    case DriverOrderStatus.headingToRestaurant:
      return tx('في الطريق إلى المطعم');
    case DriverOrderStatus.arrivedAtRestaurant:
      return tx('في المطعم');
    case DriverOrderStatus.pickedUp:
      return tx('تم الاستلام');
    case DriverOrderStatus.headingToCustomer:
      return tx('في الطريق إلى العميل');
    case DriverOrderStatus.arrivedAtCustomer:
      return tx('وصل إلى العميل');
    case DriverOrderStatus.awaitingVerification:
      return tx('بانتظار رمز التحقق');
    case DriverOrderStatus.delivered:
      return tx('تم التسليم');
  }
}

String _formatDateTime(DateTime dateTime) {
  final months = <String>[
    tx('يناير', 'January'),
    tx('فبراير', 'February'),
    tx('مارس', 'March'),
    tx('أبريل', 'April'),
    tx('مايو', 'May'),
    tx('يونيو', 'June'),
    tx('يوليو', 'July'),
    tx('أغسطس', 'August'),
    tx('سبتمبر', 'September'),
    tx('أكتوبر', 'October'),
    tx('نوفمبر', 'November'),
    tx('ديسمبر', 'December'),
  ];
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? tx('م', 'PM') : tx('ص', 'AM');
  return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} - $hour:$minute $period';
}
