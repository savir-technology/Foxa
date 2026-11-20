import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tks/controler/archive/orders_archive_controller.dart';
import 'package:tks/controler/orders/pending.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/functions/app_image_urls.dart';
import 'package:tks/data/datasource/model/orders_archive_model.dart';
import 'package:tks/data/datasource/model/ordersmodel.dart';
import 'package:tks/linkapi/linkapi.dart';
import 'package:tks/view/notification/notification_page.dart';
import 'package:tks/view/widget/common/fallback_network_image.dart';

const Color _ordersPageBg = Color(0xFFFFFFFF);
const Color _ordersGreen = Color(0xFFFF6500);
const Color _ordersGreenSoft = Color(0xFFFFE8DC);
const Color _ordersBorder = Color(0xFFF0D8CA);
const Color _ordersMuted = Color(0xFF767D78);
const Color _ordersLine = Color(0xFFF1E2DA);
const Color _ordersShadow = Color(0x12000000);

Color _ordersBorderColor(BuildContext context) {
  final theme = Theme.of(context);
  return theme.brightness == Brightness.dark
      ? theme.dividerColor.withValues(alpha: 0.42)
      : _ordersBorder;
}

class OrdersPending extends StatelessWidget {
  const OrdersPending({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrdersPendingController());
    final archiveController = Get.put(OrdersArchiveControllerr());
    final isArabic = Get.locale?.languageCode == 'ar';
    final textDirection =
        isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: GetBuilder<OrdersPendingController>(
            builder: (_) {
              return Obx(() {
                final archiveOrders = archiveController.ordersList;
                final isArchiveLoading = archiveController.isLoading.value;

                return RefreshIndicator(
                  color: _ordersGreen,
                  backgroundColor: theme.cardColor,
                  onRefresh: () async {
                    await Future.wait([
                      controller.getOrders(),
                      archiveController.fetchOrdersArchive(
                        archiveController.userId,
                      ),
                    ]);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                    children: [
                      _OrdersHeader(
                        isArabic: isArabic,
                        onNotificationsTap: () =>
                            Get.to(() => const NotificationPage()),
                      ),
                      const SizedBox(height: 16),
                      _OrdersTabsBar(
                        isArabic: isArabic,
                        currentCount: controller.data.length,
                        previousCount: archiveOrders.length,
                        onPreviousTap: () =>
                            Get.toNamed(AppRoutes.ordersarchive_page),
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(
                        title: isArabic ? 'الطلبات الحالية' : 'Current orders',
                        dotColor: _ordersGreen,
                      ),
                      const SizedBox(height: 12),
                      if (controller.statusRequest == StatusRequest.loading &&
                          controller.data.isEmpty)
                        const _LoadingSectionCard()
                      else if (controller.data.isEmpty)
                        _EmptySectionCard(
                          title: isArabic
                              ? 'لا توجد طلبات حالية'
                              : 'No active orders right now',
                          message: isArabic
                              ? 'ستظهر الطلبات الجديدة هنا مع التتبع المباشر والدردشة والدعم.'
                              : 'New orders will appear here with live tracking, chat, and support actions.',
                        )
                      else
                        ...controller.data.map(
                          (order) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _CurrentOrderCard(
                              order: order,
                              isArabic: isArabic,
                              controller: controller,
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      _SectionTitle(
                        title: isArabic ? 'الطلبات السابقة' : 'Previous orders',
                        dotColor: const Color(0xFF9CA29E),
                      ),
                      const SizedBox(height: 12),
                      if (isArchiveLoading && archiveOrders.isEmpty)
                        const _LoadingSectionCard()
                      else if (archiveOrders.isEmpty)
                        _EmptySectionCard(
                          title: isArabic
                              ? 'لا توجد طلبات سابقة'
                              : 'No previous orders yet',
                          message: isArabic
                              ? 'عندما تكتمل طلباتك ستظهر هنا بشكل مرتب وسهل التصفح.'
                              : 'Completed orders will appear here in a tidy archive.',
                        )
                      else
                        ...archiveOrders.map(
                          (order) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ArchiveOrderCard(
                              order: order,
                              isArabic: isArabic,
                              controller: archiveController,
                            ),
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.isArabic,
    required this.onNotificationsTap,
  });

  final bool isArabic;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = isArabic ? 'طلباتي' : 'My orders';
    final subtitle =
        isArabic ? 'جميع طلباتك في مكان واحد' : 'All your orders in one place';

    return SizedBox(
      height: 74,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _ordersMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: _HeaderIconButton(onTap: onNotificationsTap),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      elevation: 0,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: _ordersShadow,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _OrdersTabsBar extends StatelessWidget {
  const _OrdersTabsBar({
    required this.isArabic,
    required this.currentCount,
    required this.previousCount,
    this.onPreviousTap,
  });

  final bool isArabic;
  final int currentCount;
  final int previousCount;
  final VoidCallback? onPreviousTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ordersBorderColor(context)),
        boxShadow: const [
          BoxShadow(
            color: _ordersShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _OrdersTab(
              isActive: true,
              title: isArabic ? 'الطلبات الحالية' : 'Current orders',
              count: currentCount,
              theme: theme,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _OrdersTab(
              isActive: false,
              title: isArabic ? 'الطلبات السابقة' : 'Previous orders',
              count: previousCount,
              theme: theme,
              onTap: onPreviousTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({
    required this.isActive,
    required this.title,
    required this.count,
    required this.theme,
    this.onTap,
  });

  final bool isActive;
  final String title;
  final int count;
  final ThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive ? theme.cardColor : Colors.transparent;
    final textColor = isActive ? theme.colorScheme.onSurface : theme.hintColor;
    final badgeBg = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final badgeText = isActive ? theme.colorScheme.onPrimary : theme.hintColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isActive
                ? const [
                    BoxShadow(
                      color: _ordersShadow,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TabBadge(
                value: count.toString(),
                backgroundColor: badgeBg,
                textColor: badgeText,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
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

class _TabBadge extends StatelessWidget {
  const _TabBadge({
    required this.value,
    required this.backgroundColor,
    required this.textColor,
  });

  final String value;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.dotColor,
  });

  final String title;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _LoadingSectionCard extends StatelessWidget {
  const _LoadingSectionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ordersBorderColor(context)),
        boxShadow: const [
          BoxShadow(
            color: _ordersShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ordersBorderColor(context)),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: _ordersGreenSoft,
            child: Icon(
              Icons.inventory_2_outlined,
              color: _ordersGreen,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _ordersMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentOrderCard extends StatelessWidget {
  const _CurrentOrderCard({
    required this.order,
    required this.isArabic,
    required this.controller,
  });

  final OrdersModel order;
  final bool isArabic;
  final OrdersPendingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _normalizedOrderStatus(order);
    final statusConfig = _statusVisual(status, isArabic);
    final timeText = _formatOrderTime(order.ordersDatetime, isArabic);
    final storeName = _cleanDisplayText(order.restaurantDisplayName);
    final bannerUrl = _cleanDisplayText(order.storeBannerUrl);
    final logoUrl = _cleanDisplayText(order.vendorLogo);
    final storeImageUrls = <String>[
      if (bannerUrl.isNotEmpty) AppLink.resolveUrl(bannerUrl),
      if (logoUrl.isNotEmpty) AppLink.resolveUrl(logoUrl),
    ];
    final etaText = _etaText(order, isArabic);
    final currentIndex = _statusIndex(status);
    final totalText = _money(order.ordersTotalprice, isArabic);
    final addressText = order.deliveryDisplayAddress.trim().isNotEmpty
        ? order.deliveryDisplayAddress.trim()
        : (isArabic ? 'العنوان غير متوفر' : 'Address not available');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _ordersBorderColor(context)),
        boxShadow: const [
          BoxShadow(
            color: _ordersShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusPill(
                label: statusConfig.label,
                backgroundColor: statusConfig.backgroundColor,
                textColor: statusConfig.textColor,
                icon: statusConfig.icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.ordersId ?? ''}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _ordersMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _RestaurantLogo(imageUrls: storeImageUrls, label: storeName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName.isEmpty
                          ? (isArabic ? 'المتجر' : 'Store')
                          : storeName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _OrderTimeline(
            statusIndex: currentIndex,
            isArabic: isArabic,
          ),
          const SizedBox(height: 12),
          _OrderBanner(
            isArabic: isArabic,
            title: _orderBannerTitle(order, isArabic),
            subtitle: _orderBannerSubtitle(order, isArabic, etaText),
            onTap: () => controller.openTracking(order),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _ordersBorderColor(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _InfoColumn(
                    isArabic: isArabic,
                    title: isArabic ? 'العنوان' : 'Address',
                    value: addressText,
                    alignStart: true,
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _InfoColumn(
                    isArabic: isArabic,
                    title: isArabic ? 'طريقة الطلب' : 'Order type',
                    value: _orderTypeText(order, isArabic),
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _InfoColumn(
                    isArabic: isArabic,
                    title: isArabic ? 'المبلغ' : 'Amount',
                    value: totalText,
                    valueColor: _ordersGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: isArabic ? 'المساعدة' : 'Help',
                  icon: Icons.headset_mic_outlined,
                  outlineColor: _ordersBorderColor(context),
                  textColor: Theme.of(context).colorScheme.onSurface,
                  onTap: () => controller.openSupportForOrder(order),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: isArabic ? 'دردشة الطلب' : 'Order chat',
                  icon: Icons.chat_bubble_outline_rounded,
                  outlineColor: _ordersGreen,
                  textColor: _ordersGreen,
                  onTap: () => controller.openOrderChat(order),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArchiveOrderCard extends StatelessWidget {
  const _ArchiveOrderCard({
    required this.order,
    required this.isArabic,
    required this.controller,
  });

  final OrdersArchiveModel order;
  final bool isArabic;
  final OrdersArchiveControllerr controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _normalizedArchiveStatus(order.ordersStatus);
    final statusConfig = _statusVisual(status, isArabic, archived: true);
    final timeText = _formatOrderTime(order.ordersDatetime, isArabic);
    final amountText = _money(order.ordersTotalprice, isArabic);
    final subtitle = _archiveSubtitle(order, isArabic);
    final imageUrls = AppImageUrls.item(order.itemsImage);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ordersBorderColor(context)),
        boxShadow: const [
          BoxShadow(
            color: _ordersShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusPill(
                label: statusConfig.label,
                backgroundColor: statusConfig.backgroundColor,
                textColor: statusConfig.textColor,
                icon: statusConfig.icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.ordersId}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _ordersMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ArchiveThumb(imageUrls: imageUrls, label: order.itemName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.itemName.isEmpty
                          ? (isArabic ? 'طلب سابق' : 'Previous order')
                          : order.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _ordersMuted,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _ordersBorderColor(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _InfoColumn(
                    isArabic: isArabic,
                    title: isArabic ? 'المبلغ' : 'Amount',
                    value: amountText,
                    valueColor: _ordersGreen,
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _InfoColumn(
                    isArabic: isArabic,
                    title: isArabic ? 'طريقة الطلب' : 'Order type',
                    value: isArabic ? 'توصيل سريع' : 'Quick delivery',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () => controller.openOrderDetails(
                OrdersArchiveModel(
                  ordersId: order.ordersId,
                  ordersDatetime: order.ordersDatetime,
                  ordersTotalprice: order.ordersTotalprice,
                  ordersStatus: order.ordersStatus,
                  ordersType: order.ordersType ?? '0',
                  storeName: order.storeName,
                  vendorLogo: order.vendorLogo,
                  storeBannerUrl: order.storeBannerUrl,
                  itemName: order.itemName,
                  itemColor: order.itemColor,
                  itemSize: order.itemSize,
                  itemPrice: order.itemPrice,
                  itemDiscount: order.itemDiscount,
                  quantity: order.quantity,
                  lineTotal: order.lineTotal,
                  itemsImage: order.itemsImage,
                  lensName: order.lensName,
                  lensColor: order.lensColor,
                  lensFeatures: order.lensFeatures,
                  lensUnitPrice: order.lensUnitPrice,
                  lensTotalPrice: order.lensTotalPrice,
                  prescriptionSummary: order.prescriptionSummary,
                ),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              label: Text(isArabic ? 'عرض التفاصيل' : 'View details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(color: Theme.of(context).dividerColor),
                backgroundColor: Theme.of(context).cardColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantLogo extends StatelessWidget {
  const _RestaurantLogo({
    required this.imageUrls,
    required this.label,
  });

  final List<String> imageUrls;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: FallbackNetworkImage(
        imageUrls: imageUrls,
        label: label,
        fit: BoxFit.cover,
        placeholder: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.storefront_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
        ),
        errorWidget: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.storefront_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ArchiveThumb extends StatelessWidget {
  const _ArchiveThumb({
    required this.imageUrls,
    required this.label,
  });

  final List<String> imageUrls;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: FallbackNetworkImage(
        imageUrls: imageUrls,
        label: label,
        fit: BoxFit.cover,
        placeholder: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(Icons.fastfood_outlined,
              color: Theme.of(context).colorScheme.primary),
        ),
        errorWidget: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(Icons.fastfood_outlined,
              color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({
    required this.statusIndex,
    required this.isArabic,
  });

  final int statusIndex;
  final bool isArabic;

  static const _labelsAr = <String>[
    'تم إنشاء الطلب',
    'قبله المطعم',
    'قيد التحضير',
    'في الطريق',
    'تم التوصيل',
  ];

  static const _labelsEn = <String>[
    'Order created',
    'Accepted',
    'Preparing',
    'On the way',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    final labels = isArabic ? _labelsAr : _labelsEn;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.56);

    return SizedBox(
      height: 82,
      child: Stack(
        children: [
          PositionedDirectional(
            start: 22,
            end: 22,
            top: 18,
            child: Container(
              height: 1,
              color: theme.dividerColor,
            ),
          ),
          Row(
            children: List.generate(labels.length, (index) {
              final isActive = index == statusIndex;
              final isDone = index < statusIndex;
              final color = isActive || isDone ? accent : muted;
              final bgColor = isActive
                  ? theme.cardColor
                  : isDone
                      ? accent.withValues(alpha: 0.14)
                      : theme.colorScheme.surfaceContainerHighest;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive
                              ? accent
                              : isDone
                                  ? accent.withValues(alpha: 0.30)
                                  : theme.dividerColor,
                          width: isActive ? 1.8 : 1.0,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _stepIcon(index),
                        size: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[index],
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isActive ? accent : muted,
                            fontWeight:
                                isActive ? FontWeight.w800 : FontWeight.w500,
                            height: 1.25,
                            fontSize: 10.5,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _stepIcon(int index) {
    switch (index) {
      case 0:
        return Icons.receipt_long_outlined;
      case 1:
        return Icons.storefront_outlined;
      case 2:
        return Icons.kitchen_outlined;
      case 3:
        return Icons.delivery_dining_outlined;
      case 4:
        return Icons.check_rounded;
      default:
        return Icons.circle_outlined;
    }
  }
}

class _OrderBanner extends StatelessWidget {
  const _OrderBanner({
    required this.isArabic,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool isArabic;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return Material(
      color: accent.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              _BannerTrackLabel(isArabic: isArabic),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: _ordersGreen,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerTrackLabel extends StatelessWidget {
  const _BannerTrackLabel({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.location_on_outlined,
          color: _ordersGreen,
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          isArabic ? 'تبع الطلب' : 'Track order',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _ordersGreen,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
        ),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.isArabic,
    required this.title,
    required this.value,
    this.valueColor,
    this.alignStart = false,
  });

  final bool isArabic;
  final String title;
  final String value;
  final Color? valueColor;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        crossAxisAlignment:
            alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignStart ? TextAlign.start : TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _ordersMuted,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignStart ? TextAlign.start : TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: valueColor ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1.2,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 52,
      color: _ordersBorderColor(context),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.outlineColor,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color outlineColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: outlineColor),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

String _cleanDisplayText(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) {
    return '';
  }
  if (text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

class _CurrentStatusVisual {
  const _CurrentStatusVisual({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
}

_CurrentStatusVisual _statusVisual(
  String status,
  bool isArabic, {
  bool archived = false,
}) {
  switch (status) {
    case '4':
    case 'delivered':
    case 'completed':
      return _CurrentStatusVisual(
        label: isArabic ? 'تم التوصيل' : 'Delivered',
        backgroundColor:
            archived ? const Color(0xFFF0F1EF) : const Color(0xFFEAF2EA),
        textColor: archived ? _ordersMuted : _ordersGreen,
        icon: Icons.check_rounded,
      );
    case '3':
    case 'on_the_way':
    case 'on the way':
    case 'delivering':
    case 'arrived_at_customer':
      return _CurrentStatusVisual(
        label: isArabic ? 'في الطريق' : 'On the way',
        backgroundColor: const Color(0xFFEAF5EE),
        textColor: _ordersGreen,
        icon: Icons.delivery_dining_outlined,
      );
    case '2':
    case 'preparing':
    case 'driver_at_restaurant':
    case 'heading_to_restaurant':
      return _CurrentStatusVisual(
        label: isArabic ? 'قيد التحضير' : 'Preparing',
        backgroundColor: const Color(0xFFFDF3E8),
        textColor: const Color(0xFFCB7D14),
        icon: Icons.soup_kitchen_outlined,
      );
    case '1':
    case 'accepted':
    case 'approved':
      return _CurrentStatusVisual(
        label: isArabic ? 'في المطعم' : 'At restaurant',
        backgroundColor: const Color(0xFFEAF5EE),
        textColor: _ordersGreen,
        icon: Icons.storefront_outlined,
      );
    case '0':
    case 'pending':
    default:
      return _CurrentStatusVisual(
        label: isArabic ? 'قيد الانتظار' : 'Pending',
        backgroundColor: const Color(0xFFF0F1EF),
        textColor: _ordersMuted,
        icon: Icons.hourglass_bottom_rounded,
      );
  }
}

String _normalizedOrderStatus(OrdersModel order) {
  return (order.status ?? order.ordersStatus ?? 'pending').toLowerCase().trim();
}

String _normalizedArchiveStatus(String value) {
  return value.toLowerCase().trim();
}

int _statusIndex(String status) {
  switch (status) {
    case '0':
    case 'pending':
      return 0;
    case '1':
    case 'accepted':
    case 'approved':
      return 1;
    case '2':
    case 'preparing':
    case 'driver_at_restaurant':
    case 'heading_to_restaurant':
      return 2;
    case '3':
    case 'on_the_way':
    case 'on the way':
    case 'delivering':
    case 'arrived_at_customer':
      return 3;
    case '4':
    case 'delivered':
    case 'completed':
      return 4;
    default:
      return 0;
  }
}

String _orderTypeText(OrdersModel order, bool isArabic) {
  final raw = (order.ordersType ?? '').trim();
  if (raw == '1') {
    return isArabic ? 'استلام سريع' : 'Pickup';
  }
  return isArabic ? 'توصيل سريع' : 'Delivery';
}

String _formatOrderTime(String? value, bool isArabic) {
  final dateTime = DateTime.tryParse((value ?? '').trim());
  if (dateTime == null) {
    return isArabic ? 'اليوم' : 'Today';
  }

  final locale = isArabic ? 'ar' : 'en';
  final now = DateTime.now();
  final sameDay = dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day;
  final timeText = DateFormat('h:mm a', locale).format(dateTime);

  if (sameDay) {
    return isArabic ? 'اليوم، $timeText' : 'Today, $timeText';
  }

  final dayText = DateFormat('EEE', locale).format(dateTime);
  return '$dayText، $timeText';
}

String _money(String? value, bool isArabic) {
  final amount = double.tryParse((value ?? '').trim()) ?? 0;
  final formatted = amount.toStringAsFixed(1);
  return isArabic ? '$formatted ${AppCurrency.symbol}' : '${AppCurrency.code} $formatted';
}

String _etaText(OrdersModel order, bool isArabic) {
  final raw = (order.ordersEstimatedMinutes ?? '').trim();
  final minutes = int.tryParse(raw) ?? 45;
  return isArabic ? '$minutes دقيقة' : '$minutes min';
}

String _orderBannerTitle(OrdersModel order, bool isArabic) {
  final status = _normalizedOrderStatus(order);
  switch (status) {
    case '4':
    case 'delivered':
    case 'completed':
      return isArabic ? 'تم تسليم الطلب' : 'Order delivered';
    case '2':
    case 'preparing':
    case 'driver_at_restaurant':
    case 'heading_to_restaurant':
      return isArabic ? 'طلبك قيد التحضير' : 'Your order is being prepared';
    case '1':
    case 'accepted':
    case 'approved':
      return isArabic ? 'تم قبول الطلب' : 'Order accepted';
    case '0':
    case 'pending':
    default:
      return isArabic ? 'جاري تجهيز طلبك' : 'Preparing your order';
  }
}

String _orderBannerSubtitle(
  OrdersModel order,
  bool isArabic,
  String etaText,
) {
  final status = _normalizedOrderStatus(order);
  switch (status) {
    case '4':
    case 'delivered':
    case 'completed':
      return isArabic
          ? 'يمكنك مراجعة تفاصيل الطلب أو التقييم بعد قليل.'
          : 'You can review the order details or rate it shortly.';
    default:
      return isArabic
          ? 'سيصل خلال $etaText تقريبًا'
          : 'Arriving in about $etaText';
  }
}

String _archiveSubtitle(OrdersArchiveModel order, bool isArabic) {
  final details = <String>[
    order.itemColor.trim(),
    order.itemSize.trim(),
    order.lensFeatures.trim(),
  ].where((value) => value.isNotEmpty).toList();

  if (details.isNotEmpty) {
    return details.join(' • ');
  }

  return isArabic ? 'طلب سابق' : 'Previous order';
}
