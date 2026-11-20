import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:tks/controler/orders/order_tracking_controller.dart';
import 'package:tks/core/services/mapbox_runtime_config.dart';
import 'package:tks/core/services/order_tracking_realtime_service.dart';
import 'package:tks/data/datasource/model/ordersmodel.dart';
import 'package:tks/linkapi/linkapi.dart';
import 'package:tks/view/notification/notification_page.dart';
import 'package:tks/view/widget/common/fallback_network_image.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shareToken = (Get.parameters['token'] ?? '').trim();

    return GetBuilder<OrderTrackingController>(
      init: OrderTrackingController(
        shareToken: shareToken.isEmpty ? null : shareToken,
      ),
      builder: (controller) {
        final theme = Theme.of(context);
        final snapshot = controller.snapshot;
        final driver = snapshot?.driver;
        final isArabic = controller.isArabic;
        final mapStyleUri =
            MapboxRuntimeConfig.styleUriForBrightness(theme.brightness);
        final size = MediaQuery.sizeOf(context);
        final mapHeight = (size.height * 0.54).clamp(390.0, 470.0);

        controller.setMapBrightness(theme.brightness);

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TrackingHeader(
                            isArabic: isArabic,
                            onBack: Get.back,
                            onNotificationsTap: () =>
                                Get.to(() => const NotificationPage()),
                          ),
                          const SizedBox(height: 14),
                          _TrackingMapHero(
                            controller: controller,
                            mapHeight: mapHeight,
                            mapStyleUri: mapStyleUri,
                          ),
                          const SizedBox(height: 14),
                          _TrackingStatusCard(controller: controller),
                          const SizedBox(height: 14),
                          _DriverContactCard(
                            controller: controller,
                            driver: driver,
                          ),
                          const SizedBox(height: 14),
                          _OrderDetailsCard(controller: controller),
                          const SizedBox(height: 14),
                          _ShareTrackingCard(controller: controller),
                          const SizedBox(height: 14),
                          _NeedHelpCard(controller: controller),
                          if (controller.canRateDriver) ...[
                            const SizedBox(height: 14),
                            _DriverRatingCard(controller: controller),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (controller.isLoading)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrackingHeader extends StatelessWidget {
  const _TrackingHeader({
    required this.isArabic,
    required this.onBack,
    required this.onNotificationsTap,
  });

  final bool isArabic;
  final VoidCallback onBack;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
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
                  isArabic ? 'تتبع طلبك' : 'Track order',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'تتبع مباشر لحالة طلبك'
                      : 'Live tracking for your order',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.66),
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _HeaderActionButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _HeaderActionButton(
              icon: Icons.notifications_none_rounded,
              onTap: onNotificationsTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingMapHero extends StatelessWidget {
  const _TrackingMapHero({
    required this.controller,
    required this.mapHeight,
    required this.mapStyleUri,
  });

  final OrderTrackingController controller;
  final double mapHeight;
  final String mapStyleUri;

  @override
  Widget build(BuildContext context) {
    final isArabic = controller.isArabic;
    final restaurantName = controller.restaurantName;
    final destinationName = controller.destinationSummaryLabel;
    final distanceLabel = controller.liveDistanceLabel;
    final etaLabel = controller.etaText;
    final statusLabel = _trackingSummaryTitle(controller);
    final statusSubtitle = _trackingSummarySubtitle(controller);

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: mapHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 24,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: controller.isMapboxReady
                  ? MapWidget(
                      key: ValueKey(
                        'orderTrackingMap-${Theme.of(context).brightness.name}-$mapStyleUri',
                      ),
                      styleUri: mapStyleUri,
                      viewport: CameraViewportState(
                        center: controller.initialCameraCenter,
                        zoom: 13.6,
                        pitch: 0,
                      ),
                      gestureRecognizers: <Factory<
                          OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                      onMapCreated: controller.onMapCreated,
                      onStyleLoadedListener: controller.onStyleLoaded,
                      onScrollListener: controller.onUserMapGesture,
                      onZoomListener: controller.onUserMapGesture,
                    )
                  : _TrackingMapFallback(isArabic: isArabic),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.16),
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.18),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.58, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: _MapInfoBubble(
                icon: Icons.location_on_outlined,
                title: destinationName,
                subtitle: isArabic
                    ? 'يبعد $distanceLabel • حوالي $etaLabel'
                    : 'About $distanceLabel • $etaLabel away',
                accentColor: const Color(0xFFFF6500),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _MapInfoBubble(
                icon: Icons.storefront_rounded,
                title: restaurantName.isNotEmpty
                    ? restaurantName
                    : (isArabic ? 'المطعم' : 'Restaurant'),
                subtitle: statusLabel,
                accentColor: const Color(0xFFFF6500),
                compactSubtitle: statusSubtitle,
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: _MapFloatingButton(
                icon: Icons.my_location_rounded,
                onTap: controller.recenter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingStatusCard extends StatelessWidget {
  const _TrackingStatusCard({required this.controller});

  final OrderTrackingController controller;

  @override
  Widget build(BuildContext context) {
    final isArabic = controller.isArabic;
    final title = _trackingSummaryTitle(controller);
    final subtitle = _trackingSummarySubtitle(controller);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.72)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isArabic ? 'حالة الطلب' : 'Order status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 14),
          _TrackingStageTimeline(controller: controller),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              textDirection: TextDirection.ltr,
              children: [
                const Icon(
                  Icons.delivery_dining_rounded,
                  color: Color(0xFFFF6500),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: controller.isArabic
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textAlign: controller.isArabic
                            ? TextAlign.right
                            : TextAlign.left,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFFFF6500),
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        textAlign: controller.isArabic
                            ? TextAlign.right
                            : TextAlign.left,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.68),
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingStageTimeline extends StatelessWidget {
  const _TrackingStageTimeline({required this.controller});

  final OrderTrackingController controller;

  @override
  Widget build(BuildContext context) {
    final stages = _trackingStages(controller);
    final currentIndex =
        _trackingStageIndex(_normalizedTrackingStatus(controller));
    const completedColor = Color(0xFFFF6500);
    const mutedColor = Color(0xFFE1E6E1);
    final progress = stages.length <= 1
        ? 0.0
        : (currentIndex / (stages.length - 1)).clamp(0.0, 1.0);

    return SizedBox(
      height: 112,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 20,
            right: 20,
            top: 21,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: mutedColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: 21,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: completedColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          Row(
            textDirection: TextDirection.rtl,
            children: List.generate(stages.length, (index) {
              final stage = stages[index];
              final active = index <= currentIndex;
              final current = index == currentIndex;
              return Expanded(
                child: _TrackingStageStep(
                  stage: stage,
                  active: active,
                  current: current,
                  activeColor: completedColor,
                  mutedColor: mutedColor,
                  isArabic: controller.isArabic,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DriverContactCard extends StatelessWidget {
  const _DriverContactCard({
    required this.controller,
    required this.driver,
  });

  final OrderTrackingController controller;
  final TrackingDriverInfo? driver;

  @override
  Widget build(BuildContext context) {
    final isArabic = controller.isArabic;
    final theme = Theme.of(context);
    final hasDriver = controller.canContactDriver || (driver?.hasId ?? false);
    final driverName = controller.driverDisplayName;
    final driverVehicle = driver?.vehicle.trim() ?? '';
    final driverPhone = driver?.phone.trim() ?? '';
    final photoUrl = driver?.photoUrl.trim() ?? '';
    final driverRole =
        driverVehicle.isNotEmpty ? driverVehicle : controller.driverSubtitle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.72)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 68,
              height: 68,
              color: theme.colorScheme.surfaceContainerHighest,
              child: photoUrl.isNotEmpty
                  ? FallbackNetworkImage(
                      imageUrls: [AppLink.resolveUrl(photoUrl)],
                      fit: BoxFit.cover,
                      label: driverName,
                    )
                  : Icon(
                      Icons.delivery_dining_rounded,
                      color: const Color(0xFFFF6500).withValues(alpha: 0.85),
                      size: 34,
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Expanded(
                      child: Text(
                        driverName,
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    if (hasDriver) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isArabic ? 'مُعيَّن' : 'Assigned',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFFFF6500),
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  driverRole,
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.68),
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (driverPhone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: Color(0xFFFF6500),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          driverPhone,
                          textAlign:
                              isArabic ? TextAlign.right : TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFFFF6500),
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OutlineActionButton(
                  icon: Icons.call_rounded,
                  label: isArabic ? 'اتصال' : 'Call',
                  onTap: hasDriver ? controller.callDriver : null,
                ),
                const SizedBox(height: 8),
                _OutlineActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: isArabic ? 'رسالة' : 'Chat',
                  onTap: hasDriver ? controller.openOrderChat : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailsCard extends StatefulWidget {
  const _OrderDetailsCard({required this.controller});

  final OrderTrackingController controller;

  @override
  State<_OrderDetailsCard> createState() => _OrderDetailsCardState();
}

class _OrderDetailsCardState extends State<_OrderDetailsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isArabic = controller.isArabic;
    final order = controller.order;
    final restaurantName = controller.restaurantName;
    final logoUrl = (order.vendorLogo ?? '').trim();
    final bannerUrl = (order.storeBannerUrl ?? '').trim();
    final restaurantImageUrls = <String>[
      if (bannerUrl.isNotEmpty) AppLink.resolveUrl(bannerUrl),
      if (logoUrl.isNotEmpty && logoUrl != bannerUrl)
        AppLink.resolveUrl(logoUrl),
    ];
    final orderNumber = (order.ordersId ?? '').trim();
    final addressParts = controller.deliveryAddressParts;
    final addressLines = <String>[
      for (final part in addressParts.take(4))
        ...part
            .split(RegExp(r'\s*[,،]\s*'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty),
    ];
    final seenAddressLines = <String>{};
    addressLines.removeWhere(
      (line) => !seenAddressLines.add(line.toLowerCase()),
    );
    if (addressLines.isEmpty) {
      addressLines.add(controller.deliveryAddressText);
    }
    final orderTime = _formatOrderTime(order.ordersDatetime, isArabic);
    final orderType = _orderTypeText(order, isArabic);
    final total = _money(order.ordersTotalprice, isArabic);
    final recipientName = (order.ordersRecipientName ?? '').trim();
    final deliveryNote = (order.ordersDeliveryNote ?? '').trim();
    final giftMessage = (order.ordersGiftMessage ?? '').trim();
    final deliveryCode = (order.deliveryCode ?? '').trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final theme = Theme.of(context);

        Widget summaryTile({
          required String label,
          required String value,
          Color? valueColor,
        }) {
          return _DetailLabelValue(
            label: label,
            value: value,
            valueColor: valueColor,
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
          );
        }

        Widget buildSummary() {
          final tiles = <Widget>[
            summaryTile(
              label: isArabic ? 'وقت الطلب' : 'Order time',
              value: orderTime,
            ),
            summaryTile(
              label: isArabic ? 'طريقة الطلب' : 'Order type',
              value: orderType,
            ),
            summaryTile(
              label: isArabic ? 'الإجمالي' : 'Total',
              value: total,
              valueColor: const Color(0xFFFF6500),
            ),
          ];

          if (compact) {
            return Column(
              crossAxisAlignment:
                  isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                tiles[0],
                const SizedBox(height: 12),
                tiles[1],
                const SizedBox(height: 12),
                tiles[2],
              ],
            );
          }

          return Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tiles[0]),
              const SizedBox(width: 12),
              Expanded(child: tiles[1]),
              const SizedBox(width: 12),
              Expanded(child: tiles[2]),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            border:
                Border.all(color: theme.dividerColor.withValues(alpha: 0.72)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isArabic ? 'تفاصيل الطلب' : 'Order details',
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 14),
              buildSummary(),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(22),
                ),
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
                          child: Column(
                            crossAxisAlignment: isArabic
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurantName,
                                textAlign:
                                    isArabic ? TextAlign.right : TextAlign.left,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w900,
                                      height: 1.15,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isArabic ? 'رقم الطلب' : 'Order number',
                                textAlign:
                                    isArabic ? TextAlign.right : TextAlign.left,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.66),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                orderNumber.isNotEmpty
                                    ? '#$orderNumber'
                                    : (isArabic ? 'غير متوفر' : 'N/A'),
                                textAlign:
                                    isArabic ? TextAlign.right : TextAlign.left,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 84,
                            height: 58,
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            padding: const EdgeInsets.all(4),
                            child: restaurantImageUrls.isNotEmpty
                                ? FallbackNetworkImage(
                                    imageUrls: restaurantImageUrls,
                                    fit: BoxFit.cover,
                                    label: restaurantName,
                                  )
                                : Icon(
                                    Icons.storefront_rounded,
                                    color: const Color(0xFFFF6500)
                                        .withValues(alpha: 0.82),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.72),
                        ),
                      ),
                      child: Row(
                        textDirection: TextDirection.ltr,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFFFF6500),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: isArabic
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic ? 'العنوان' : 'Address',
                                  textAlign: isArabic
                                      ? TextAlign.right
                                      : TextAlign.left,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.66),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  addressLines.first,
                                  textAlign: isArabic
                                      ? TextAlign.right
                                      : TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        fontWeight: FontWeight.w800,
                                        height: 1.25,
                                      ),
                                ),
                                if (addressLines.length > 1) ...[
                                  const SizedBox(height: 6),
                                  ...addressLines.skip(1).map(
                                        (line) => Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            line,
                                            textAlign: isArabic
                                                ? TextAlign.right
                                                : TextAlign.left,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme.onSurface,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.25,
                                                ),
                                          ),
                                        ),
                                      ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 12),
                      if (recipientName.isNotEmpty)
                        _DetailLabelValue(
                          label: isArabic ? 'المستلم' : 'Recipient',
                          value: recipientName,
                          maxLines: 4,
                          textAlign:
                              isArabic ? TextAlign.right : TextAlign.left,
                        ),
                      if (deliveryNote.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _DetailLabelValue(
                          label: isArabic ? 'ملاحظات التوصيل' : 'Delivery note',
                          value: deliveryNote,
                          maxLines: 4,
                          textAlign:
                              isArabic ? TextAlign.right : TextAlign.left,
                        ),
                      ],
                      if (giftMessage.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _DetailLabelValue(
                          label: isArabic ? 'رسالة الإهداء' : 'Gift message',
                          value: giftMessage,
                          maxLines: 4,
                          textAlign:
                              isArabic ? TextAlign.right : TextAlign.left,
                        ),
                      ],
                      if (deliveryCode.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _DetailLabelValue(
                          label: isArabic ? 'رمز التحقق' : 'Delivery code',
                          value: deliveryCode,
                          textAlign:
                              isArabic ? TextAlign.right : TextAlign.left,
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _CollapseButton(
                        label: _expanded
                            ? (isArabic ? 'إخفاء التفاصيل' : 'Hide details')
                            : (isArabic ? 'عرض التفاصيل' : 'Show details'),
                        expanded: _expanded,
                        onTap: () => setState(() => _expanded = !_expanded),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShareTrackingCard extends StatelessWidget {
  const _ShareTrackingCard({required this.controller});

  final OrderTrackingController controller;

  @override
  Widget build(BuildContext context) {
    final isArabic = controller.isArabic;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.14 : 0.07,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          SizedBox(
            width: 132,
            child: _OutlineActionButton(
              icon: Icons.copy_rounded,
              label: isArabic ? 'نسخ الرابط' : 'Copy link',
              onTap: controller.copyShareLink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'مشاركة رابط التتبع' : 'Share tracking link',
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFFF6500),
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'شارك رابط طلبك مع الآخرين ليتابعوا وصوله'
                      : 'Share the order link with others so they can follow the delivery',
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.68),
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _SquareActionButton(
            icon: Icons.share_rounded,
            onTap: controller.copyShareLink,
          ),
        ],
      ),
    );
  }
}

class _NeedHelpCard extends StatelessWidget {
  const _NeedHelpCard({required this.controller});

  final OrderTrackingController controller;

  @override
  Widget build(BuildContext context) {
    final isArabic = controller.isArabic;
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: controller.callSupport,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: theme.dividerColor.withValues(alpha: 0.72)),
          ),
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              _CircleArrowButton(
                isArabic: isArabic,
                onTap: controller.callSupport,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'تحتاج مساعدة؟' : 'Need help?',
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArabic
                          ? 'تواصل معنا وسنساعدك فورًا'
                          : 'Talk to us and we will help right away',
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.68),
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.headset_mic_outlined,
                  color: Color(0xFFFF6500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverRatingCard extends StatelessWidget {
  const _DriverRatingCard({required this.controller});

  final OrderTrackingController controller;

  @override
  Widget build(BuildContext context) {
    final isArabic = controller.isArabic;
    final hasSubmitted = controller.hasSubmittedDriverRating;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.72)),
      ),
      child: Column(
        crossAxisAlignment:
            isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'قيّم السائق' : 'Rate driver',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (hasSubmitted) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.24),
                ),
              ),
              child: Text(
                isArabic
                    ? 'تم حفظ تقييمك للسائق. يمكنك تعديله في أي وقت.'
                    : 'Your driver rating was saved. You can update it anytime.',
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFFF6500),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'سيتم حفظ تقييمك للسائق مباشرة.'
                : 'Your rating will be saved for the driver.',
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.68),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) {
                final starValue = index + 1;
                final isActive = controller.driverRating >= starValue;
                return GestureDetector(
                  onTap: () => controller.setDriverRating(starValue.toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isActive ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFFF6500),
                      size: 30,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.isSubmittingDriverRating
                  ? null
                  : controller.submitDriverRating,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6500),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFFFF6500).withValues(alpha: 0.55),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: controller.isSubmittingDriverRating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      hasSubmitted
                          ? (isArabic ? 'تحديث التقييم' : 'Update rating')
                          : (isArabic ? 'إرسال التقييم' : 'Submit rating'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingStageStep extends StatelessWidget {
  const _TrackingStageStep({
    required this.stage,
    required this.active,
    required this.current,
    required this.activeColor,
    required this.mutedColor,
    required this.isArabic,
  });

  final _TrackingStageData stage;
  final bool active;
  final bool current;
  final Color activeColor;
  final Color mutedColor;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final circleColor = active ? activeColor : Colors.white;
    final borderColor = active ? activeColor : mutedColor;
    final iconColor = active ? Colors.white : const Color(0xFF9BA3A0);
    final theme = Theme.of(context);
    final textColor = active
        ? const Color(0xFFFF6500)
        : theme.colorScheme.onSurface.withValues(alpha: 0.68);

    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: current ? 2.5 : 1.6),
          ),
          child: Icon(stage.icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          isArabic ? stage.labelAr : stage.labelEn,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
        ),
      ],
    );
  }
}

class _TrackingStageData {
  const _TrackingStageData({
    required this.icon,
    required this.labelAr,
    required this.labelEn,
  });

  final IconData icon;
  final String labelAr;
  final String labelEn;
}

class _TrackingMapFallback extends StatelessWidget {
  const _TrackingMapFallback({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF3EC),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6500).withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.map_outlined,
              color: Color(0xFFFF6500),
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isArabic ? 'الخريطة غير مفعلة بعد' : 'Map is not configured yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF171717),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'أضف MAPBOX_ACCESS_TOKEN لعرض التتبع الحي'
                : 'Add MAPBOX_ACCESS_TOKEN to enable live tracking',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.68),
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _MapInfoBubble extends StatelessWidget {
  const _MapInfoBubble({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.compactSubtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String? compactSubtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 136),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.ltr,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF171717),
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: compactSubtitle == null ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: compactSubtitle == null
                            ? const Color(0xFF5C675D)
                            : accentColor,
                        height: 1.2,
                        fontWeight: compactSubtitle == null
                            ? FontWeight.w600
                            : FontWeight.w800,
                      ),
                ),
                if (compactSubtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    compactSubtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5C675D),
                          height: 1.2,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: const Color(0x15000000),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(icon, color: const Color(0xFF171717)),
        ),
      ),
    );
  }
}

class _MapFloatingButton extends StatelessWidget {
  const _MapFloatingButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 10,
      shadowColor: const Color(0x18000000),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: const Color(0xFF171717)),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? Colors.white : const Color(0xFFF4F7F4),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  enabled ? const Color(0xFFFFE3D4) : const Color(0xFFE8E8E8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    enabled ? const Color(0xFFFF6500) : const Color(0xFFB2B8B4),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: enabled
                            ? const Color(0xFFFF6500)
                            : const Color(0xFF9BA3A0),
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

class _SquareActionButton extends StatelessWidget {
  const _SquareActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFF6500),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _CircleArrowButton extends StatelessWidget {
  const _CircleArrowButton({
    required this.isArabic,
    required this.onTap,
  });

  final bool isArabic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F7F4),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            isArabic
                ? Icons.arrow_back_ios_new_rounded
                : Icons.arrow_forward_ios_rounded,
            color: const Color(0xFF171717),
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _DetailLabelValue extends StatelessWidget {
  const _DetailLabelValue({
    required this.label,
    required this.value,
    required this.textAlign,
    this.valueColor,
    this.maxLines = 3,
  });

  final String label;
  final String value;
  final TextAlign textAlign;
  final Color? valueColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.66),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
        ),
      ],
    );
  }
}

class _CollapseButton extends StatelessWidget {
  const _CollapseButton({
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        expanded
            ? Icons.keyboard_arrow_up_rounded
            : Icons.keyboard_arrow_down_rounded,
        size: 20,
      ),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface,
        side: BorderSide(color: theme.dividerColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

List<_TrackingStageData> _trackingStages(OrderTrackingController controller) {
  return const [
    _TrackingStageData(
      icon: Icons.storefront_rounded,
      labelAr: 'تم استلام الطلب',
      labelEn: 'Order received',
    ),
    _TrackingStageData(
      icon: Icons.kitchen_rounded,
      labelAr: 'جاري التحضير',
      labelEn: 'Preparing',
    ),
    _TrackingStageData(
      icon: Icons.shopping_bag_rounded,
      labelAr: 'جاري التجهيز',
      labelEn: 'Packing',
    ),
    _TrackingStageData(
      icon: Icons.delivery_dining_rounded,
      labelAr: 'في الطريق',
      labelEn: 'On the way',
    ),
    _TrackingStageData(
      icon: Icons.flag_rounded,
      labelAr: 'تم التوصيل',
      labelEn: 'Delivered',
    ),
  ];
}

String _normalizedTrackingStatus(OrderTrackingController controller) {
  return controller.trackingStatus;
}

int _trackingStageIndex(String status) {
  switch (status) {
    case '4':
    case 'delivered':
    case 'completed':
      return 4;
    case '3':
    case 'on_the_way':
    case 'on the way':
    case 'delivering':
    case 'arrived_at_customer':
      return 3;
    case 'picked_up':
    case 'driver_at_restaurant':
    case 'heading_to_customer':
    case 'heading_to_restaurant':
      return 2;
    case '2':
    case 'preparing':
      return 1;
    case '1':
    case 'accepted':
    case 'approved':
    case 'assigned':
    case '0':
    case 'pending':
    default:
      return 0;
  }
}

String _trackingSummaryTitle(OrderTrackingController controller) {
  final isArabic = controller.isArabic;
  final status = _normalizedTrackingStatus(controller);

  switch (status) {
    case '4':
    case 'delivered':
    case 'completed':
      return isArabic ? 'تم توصيل طلبك' : 'Your order has been delivered';
    case 'arrived_at_customer':
      return isArabic ? 'السائق عندك' : 'Driver arrived';
    case '3':
    case 'on_the_way':
    case 'on the way':
    case 'delivering':
    case 'picked_up':
      return isArabic ? 'طلبك في الطريق إليك' : 'Your order is on the way';
    case 'driver_at_restaurant':
    case 'heading_to_restaurant':
    case '2':
    case 'preparing':
      return isArabic ? 'طلبك قيد التحضير' : 'Your order is being prepared';
    case '1':
    case 'accepted':
    case 'approved':
    case 'assigned':
    case '0':
    case 'pending':
    default:
      return isArabic ? 'تم استلام الطلب' : 'Order received';
  }
}

String _trackingSummarySubtitle(OrderTrackingController controller) {
  final isArabic = controller.isArabic;
  final status = _normalizedTrackingStatus(controller);
  final eta = controller.etaText;

  switch (status) {
    case '4':
    case 'delivered':
    case 'completed':
      return isArabic
          ? 'يمكنك تقييم السائق الآن بعد التسليم.'
          : 'You can rate the driver now.';
    case 'arrived_at_customer':
      return isArabic
          ? 'السائق وصل إلى عنوانك وينتظر خطوة التسليم النهائية.'
          : 'The driver has reached your address and is waiting for the final handoff.';
    case '3':
    case 'on_the_way':
    case 'on the way':
    case 'delivering':
    case 'picked_up':
      return isArabic
          ? 'سيصل إليك خلال $eta تقريبًا.'
          : 'Arriving in about $eta.';
    case 'driver_at_restaurant':
    case 'heading_to_restaurant':
    case '2':
    case 'preparing':
      return isArabic
          ? 'طلبك قيد التحضير وسيغادر قريبًا.'
          : 'Your order is being prepared and will leave shortly.';
    default:
      return isArabic
          ? 'سيصل إليك خلال $eta تقريبًا.'
          : 'Arriving in about $eta.';
  }
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
  final timeText = intl.DateFormat('h:mm a', locale).format(dateTime);

  if (sameDay) {
    return isArabic ? 'اليوم، $timeText' : 'Today, $timeText';
  }

  final dayText = intl.DateFormat('EEE', locale).format(dateTime);
  return isArabic ? '$dayText، $timeText' : '$dayText, $timeText';
}

String _orderTypeText(OrdersModel order, bool isArabic) {
  final raw = (order.ordersType ?? '').trim();
  if (raw == '1') {
    return isArabic ? 'استلام سريع' : 'Pickup';
  }
  return isArabic ? 'توصيل سريع' : 'Delivery';
}

String _money(String? value, bool isArabic) {
  final amount = double.tryParse((value ?? '').trim()) ?? 0;
  final formatted = amount.toStringAsFixed(1);
  return isArabic ? '$formatted ${AppCurrency.symbol}' : '${AppCurrency.code} $formatted';
}

class _CompactTrackingHeader extends StatelessWidget {
  const _CompactTrackingHeader({required this.controller});

  final OrderTrackingController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoundIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: Get.back,
                backgroundColor: Colors.white,
                iconColor: const Color(0xFF101010),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: controller.isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.orderId == '-'
                          ? (controller.isArabic
                              ? 'جارٍ تحضير التتبع'
                              : 'Preparing live tracking')
                          : (controller.isArabic
                              ? 'تتبع الطلب #${controller.orderId}'
                              : 'Track order #${controller.orderId}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.deliveryAddressText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            height: 1.3,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6500),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.liveStatusLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.etaText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveTrackingDock extends StatelessWidget {
  const _LiveTrackingDock({
    required this.controller,
    required this.snapshot,
    required this.driver,
    required this.onOpenDetails,
  });

  final OrderTrackingController controller;
  final OrderTrackingLiveSnapshot? snapshot;
  final TrackingDriverInfo? driver;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final driverName = driver?.name.trim() ?? '';
    final driverLine = driverName.isNotEmpty
        ? driverName
        : (controller.isArabic
            ? 'السائق سيظهر بعد التعيين'
            : 'Driver will appear once assigned');

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.66),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: controller.isArabic
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.liveStatusLabel,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.liveStatusSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                    height: 1.35,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          driverLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _MiniStat(
                    value: controller.etaText,
                    label: controller.isArabic ? 'الوصول' : 'ETA',
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    value: controller.liveDistanceLabel,
                    label: controller.isArabic ? 'المسافة' : 'Distance',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionPill(
                      icon: controller.isFollowingDriver
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_not_fixed_rounded,
                      label: controller.isArabic ? 'تتبع مباشر' : 'Follow',
                      onTap: controller.recenter,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionPill(
                      icon: Icons.route_outlined,
                      label: controller.isArabic ? 'نظرة عامة' : 'Overview',
                      onTap: controller.showOverview,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionPill(
                      icon: Icons.keyboard_arrow_up_rounded,
                      label: controller.isArabic ? 'التفاصيل' : 'Details',
                      onTap: onOpenDetails,
                    ),
                  ),
                ],
              ),
              if (!controller.isFollowingDriver) ...[
                const SizedBox(height: 12),
                Text(
                  controller.isArabic
                      ? 'الخريطة مفتوحة الآن. اسحبها بحرية ثم اضغط تتبع مباشر للرجوع.'
                      : 'Map unlocked. Drag freely, then tap Follow to lock back on the driver.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                        height: 1.35,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _TopTrackingCard extends StatelessWidget {
  const _TopTrackingCard({required this.controller});

  final OrderTrackingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoundIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: Get.back,
                backgroundColor: Colors.white,
                iconColor: const Color(0xFF101010),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: controller.isArabic
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.isArabic
                          ? 'تتبع الطلب #${controller.orderId}'
                          : 'Track order #${controller.orderId}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.deliveryAddressText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(
                title: controller.liveStatusLabel,
                subtitle: controller.etaText,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.liveStatusSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _TopInfoChip(
                      icon: Icons.schedule_rounded,
                      label: controller.etaText,
                    ),
                    _TopInfoChip(
                      icon: Icons.social_distance_rounded,
                      label: controller.liveDistanceLabel,
                    ),
                    _TopInfoChip(
                      icon: Icons.person_pin_circle_outlined,
                      label: controller.destinationSummaryLabel,
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

class _BottomTrackingPanel extends StatelessWidget {
  const _BottomTrackingPanel({
    required this.controller,
    required this.snapshot,
    required this.driver,
    required this.scrollController,
  });

  final OrderTrackingController controller;
  final OrderTrackingLiveSnapshot? snapshot;
  final TrackingDriverInfo? driver;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final proofImage = snapshot?.deliveryProofImageUrl.trim() ?? '';
    final awaitingDeliveryCode = controller.isAwaitingDeliveryCode;
    final hasDriver = driver?.name.trim().isNotEmpty ?? false;
    final hasDriverPhone = driver?.hasPhone ?? false;
    final canRateDriver = controller.canRateDriver;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.36),
            blurRadius: 34,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  controller.liveStatusLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              _MiniStat(
                value: controller.etaText,
                label: controller.isArabic ? 'الوصول' : 'ETA',
              ),
              const SizedBox(width: 10),
              _MiniStat(
                value: controller.liveDistanceLabel,
                label: controller.isArabic ? 'المسافة' : 'Distance',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            controller.liveStatusSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.45,
                ),
          ),
          if (awaitingDeliveryCode) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC857).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFFFC857).withValues(alpha: 0.32),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFFFFC857),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.isArabic
                          ? 'تمت صورة التسليم، والآن بانتظار إدخال رمز التحقق من 4 أرقام.'
                          : 'The delivery photo is saved. We are now waiting for the 4-digit verification code.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canRateDriver) ...[
            const SizedBox(height: 16),
            _SectionTitle(
              title: controller.isArabic ? 'قيّم السائق' : 'Rate driver',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2A160D),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFFF6500).withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    controller.isArabic
                        ? 'سيتم حفظ تقييمك للسائق مباشرة.'
                        : 'Your rating will be saved for the driver.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) {
                        final starValue = index + 1;
                        final isActive = controller.driverRating >= starValue;
                        return GestureDetector(
                          onTap: () => controller.setDriverRating(
                            starValue.toDouble(),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              isActive
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: const Color(0xFFFF6500),
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isSubmittingDriverRating
                          ? null
                          : controller.submitDriverRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6500),
                        foregroundColor: Colors.black,
                        disabledBackgroundColor:
                            const Color(0xFFFF6500).withValues(alpha: 0.55),
                        disabledForegroundColor: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: controller.isSubmittingDriverRating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black,
                                ),
                              ),
                            )
                          : Text(
                              controller.isArabic
                                  ? 'إرسال التقييم'
                                  : 'Submit rating',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionTitle(
            title: controller.isArabic ? 'تفاصيل السائق' : 'Driver details',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF1A1A1A),
                  backgroundImage: (driver?.hasPhoto ?? false)
                      ? NetworkImage(driver!.photoUrl)
                      : null,
                  child: (driver?.hasPhoto ?? false)
                      ? null
                      : const Icon(
                          Icons.delivery_dining_rounded,
                          color: Colors.white,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: controller.isArabic
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasDriver
                            ? driver!.name
                            : (controller.isArabic
                                ? 'سيظهر اسم السائق بعد التعيين'
                                : 'Driver will appear once assigned'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasDriverPhone
                            ? '${driver!.vehicle.isEmpty ? '' : '${driver!.vehicle} • '}${driver!.phone}'
                            : (controller.isArabic
                                ? 'بيانات التواصل ستظهر عندما يصبح السائق متاحًا'
                                : 'Contact details appear after assignment'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    _RoundIconButton(
                      icon: Icons.call_rounded,
                      onTap: controller.callDriver,
                      backgroundColor: Colors.white,
                      iconColor: const Color(0xFF101010),
                    ),
                    const SizedBox(height: 8),
                    _RoundIconButton(
                      icon: Icons.headset_mic_outlined,
                      onTap: controller.callSupport,
                      backgroundColor: const Color(0xFF202020),
                      iconColor: Colors.white,
                      borderColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  icon: Icons.ios_share_rounded,
                  label: controller.isArabic ? 'مشاركة' : 'Share',
                  onTap: controller.copyShareLink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.route_outlined,
                  label: controller.isArabic ? 'نظرة عامة' : 'Overview',
                  onTap: controller.showOverview,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  icon: Icons.gps_fixed_rounded,
                  label: controller.isArabic ? 'تحديث' : 'Follow',
                  onTap: controller.recenter,
                ),
              ),
            ],
          ),
          if (proofImage.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionTitle(
              title: controller.isArabic ? 'إثبات التسليم' : 'Delivery proof',
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 1.65,
                child: Image.network(
                  proofImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF1A1A1A),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white.withValues(alpha: 0.45),
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    this.borderColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: CircleBorder(
        side: BorderSide(
          color: borderColor ?? Colors.transparent,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 8,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 54,
          height: 54,
          child: Icon(
            icon,
            color: const Color(0xFF101010),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6500),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _TopInfoChip extends StatelessWidget {
  const _TopInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111214),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.map_outlined,
            color: Colors.white24,
            size: 70,
          ),
          const SizedBox(height: 18),
          Text(
            isArabic ? 'الخريطة غير مفعلة بعد' : 'Mapbox is not configured yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'أضف MAPBOX_ACCESS_TOKEN في android/local.properties أو عبر dart-define لعرض التتبع الحي.'
                : 'Add MAPBOX_ACCESS_TOKEN in android/local.properties or pass it with dart-define to enable live tracking.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
