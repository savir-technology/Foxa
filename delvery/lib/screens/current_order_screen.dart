import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/controllers/order_controller.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/screens/order_chat_screen.dart';
import 'package:delvery/widgets/driver_live_mapbox_view.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:delvery/core/services/driver_platform_settings.dart';
import 'package:get/get.dart';

class CurrentOrderScreen extends GetView<OrderController> {
  const CurrentOrderScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.fromLTRB(20, embedInShell ? 16 : 12, 20, 24);

    return Scaffold(
      backgroundColor: DriverUi.background,
      body: SafeArea(
        top: true,
        child: Obx(() {
          final current = Get.find<DriverOrdersService>().activeOrder.value;
          if (current == null) {
            return _EmptyState(
              padding: padding,
              onTracking: () => controller.openTrackingMap(),
            );
          }

          return ListView(
            padding: padding,
            children: [
              DriverHeaderBar(
                leadingIcon: Icons.notifications_none_rounded,
                trailingIcon: Icons.headset_mic_outlined,
                onLeadingTap: () => Get.toNamed(AppRoutes.notifications),
                onTrailingTap: () => Get.toNamed(AppRoutes.help),
              ),
              const SizedBox(height: 14),
              DriverPageHeader(
                title: _titleFor(current.status),
                subtitle: _subtitleFor(current.status),
              ),
              const SizedBox(height: 16),
              _StoreSummaryCard(
                order: current,
                onCallRestaurant: controller.callRestaurant,
                onCallCustomer: controller.callCustomer,
              ),
              const SizedBox(height: 12),
              _CommunicationCard(
                order: current,
                onOpenChat: () => Get.to(() => OrderChatScreen(order: current)),
                onCallCustomer: controller.callCustomer,
                onCallRestaurant: controller.callRestaurant,
              ),
              const SizedBox(height: 12),
              _OrderItemsCard(order: current),
              const SizedBox(height: 12),
              _OrderSummaryCard(order: current),
              const SizedBox(height: 12),
              _MapCard(order: current),
              const SizedBox(height: 12),
              _ActionGuideCard(order: current),
              const SizedBox(height: 12),
              _PrimaryActionCard(
                order: current,
                onRestaurant: controller.goToRestaurant,
                onPickedUp: controller.markPickedUp,
                onCustomer: controller.goToCustomer,
                onDeliver: controller.markDelivered,
                onCodeDeliver: controller.showDeliveryCodeDialog,
              ),
              const SizedBox(height: 12),
              _DeliveryActionsCard(
                order: current,
                onArrivedAtRestaurant: controller.markArrivedAtRestaurant,
                onPickedUp: controller.markPickedUp,
                onArrivedAtCustomer: controller.markArrivedAtCustomer,
                onDeliver: controller.markDelivered,
                onEmergency: controller.showEmergencySheet,
              ),
              const SizedBox(height: 12),
              _QuickReplies(onReply: controller.sendQuickReply),
            ],
          );
        }),
      ),
    );
  }

  String _titleFor(DriverOrderStatus? status) {
    switch (status) {
      case DriverOrderStatus.incoming:
      case DriverOrderStatus.assigned:
      case DriverOrderStatus.headingToRestaurant:
        return tx('التوجه إلى المطعم');
      case DriverOrderStatus.arrivedAtRestaurant:
        return tx('الوصول إلى المطعم');
      case DriverOrderStatus.pickedUp:
        return tx('استلام الطلب');
      case DriverOrderStatus.headingToCustomer:
        return tx('في الطريق إلى العميل');
      case DriverOrderStatus.arrivedAtCustomer:
        return tx('الوصول إلى العميل');
      case DriverOrderStatus.awaitingVerification:
        return tx('إثبات التسليم');
      case DriverOrderStatus.delivered:
        return tx('نجاح التسليم');
      case null:
        return tx('الطلب الحالي');
    }
  }

  String _subtitleFor(DriverOrderStatus? status) {
    switch (status) {
      case DriverOrderStatus.incoming:
      case DriverOrderStatus.assigned:
      case DriverOrderStatus.headingToRestaurant:
        return tx('تحرك إلى المطعم وابدأ تنفيذ الطلب بهدوء وبأقصر وقت.');
      case DriverOrderStatus.arrivedAtRestaurant:
        return tx('تأكد من استلام جميع البنود قبل التحرك للعميل.');
      case DriverOrderStatus.pickedUp:
      case DriverOrderStatus.headingToCustomer:
        return tx('الآن لديك كل البيانات اللازمة للتسليم والمتابعة.');
      case DriverOrderStatus.arrivedAtCustomer:
        return tx('راجع بيانات العميل ثم أكمل التسليم أو التحقق.');
      case DriverOrderStatus.awaitingVerification:
        return tx('أدخل رمز التحقق أو التقط صورة واضحة عند التسليم.');
      case DriverOrderStatus.delivered:
        return tx('تم إغلاق الطلب بنجاح، ويمكنك مراجعة التفاصيل لاحقًا.');
      case null:
        return tx('عرض تفصيلي للطلب الحالي وخيارات التواصل والتنقل.');
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.padding, required this.onTracking});

  final EdgeInsets padding;
  final VoidCallback onTracking;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: [
        const DriverHeaderBar(),
        const SizedBox(height: 16),
        DriverPageHeader(
          title: tx('الطلب الحالي'),
          subtitle: tx('لا يوجد طلب نشط الآن'),
        ),
        const SizedBox(height: 18),
        DriverEmptyStateCard(
          icon: Icons.inbox_rounded,
          title: tx('لا يوجد طلب جديد حالياً'),
          subtitle: tx('ستظهر الطلبات الجديدة هنا فور إرسالها من الإدارة.'),
          actionLabel: tx('فتح التتبع'),
          onAction: onTracking,
        ),
      ],
    );
  }
}

class _StoreSummaryCard extends StatelessWidget {
  const _StoreSummaryCard({
    required this.order,
    required this.onCallRestaurant,
    required this.onCallCustomer,
  });

  final DriverOrder order;
  final VoidCallback onCallRestaurant;
  final VoidCallback onCallCustomer;

  @override
  Widget build(BuildContext context) {
    return DriverCard(
      child: Row(
        children: [
          _RestaurantMedia(order: order),
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
                  order.restaurantAddress.isNotEmpty
                      ? order.restaurantAddress
                      : tx('عنوان المطعم غير متوفر'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DriverUi.mutedText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      icon: Icons.local_phone_outlined,
                      label: order.restaurantPhone.isEmpty
                          ? tx('لا يوجد هاتف')
                          : tx('اتصال بالمطعم'),
                      onTap: order.restaurantPhone.isEmpty
                          ? null
                          : onCallRestaurant,
                    ),
                    _Pill(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: tx('اتصال العميل'),
                      onTap: onCallCustomer,
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

class _CommunicationCard extends StatelessWidget {
  const _CommunicationCard({
    required this.order,
    required this.onOpenChat,
    required this.onCallCustomer,
    required this.onCallRestaurant,
  });

  final DriverOrder order;
  final VoidCallback onOpenChat;
  final VoidCallback onCallCustomer;
  final VoidCallback onCallRestaurant;

  @override
  Widget build(BuildContext context) {
    return DriverCard(
      color: DriverUi.surfaceWarm,
      borderColor: DriverUi.line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tx('التواصل السريع'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: DriverUi.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tx(
              'الدردشة الخاصة بالطلب منفصلة، ويمكنك الاتصال مباشرة بالمطعم أو العميل من هنا.',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DriverUi.mutedText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DriverSecondaryButton(
                  label: tx('محادثة الطلب'),
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: onOpenChat,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DriverSecondaryButton(
                  label: tx('اتصال العميل'),
                  icon: Icons.call_rounded,
                  onPressed: onCallCustomer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DriverPrimaryButton(
            label: tx('اتصال المطعم'),
            icon: Icons.storefront_outlined,
            onPressed: order.restaurantPhone.isEmpty ? null : onCallRestaurant,
          ),
        ],
      ),
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  const _OrderItemsCard({required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    return DriverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tx('تفاصيل البنود'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: DriverUi.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (order.items.isEmpty)
            Text(
              tx('لا توجد بنود مفصلة لهذا الطلب.'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: DriverUi.mutedText),
            )
          else
            Column(
              children: order.items
                  .map(
                    (item) =>
                        _OrderItemRow(item: item, currency: order.currency),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    final currency = order.currency.isNotEmpty
        ? order.currency
        : DriverPlatformSettings.currencySymbol;
    final total = order.resolvedTotalPrice;
    final deliveryFee = order.deliveryFee;

    return DriverCard(
      color: const Color(0xFFF8FBF8),
      borderColor: const Color(0xFFDCEBDD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tx('ملخص الطلب'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: DriverUi.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: tx('عدد الأصناف'), value: '${order.items.length}'),
          _SummaryRow(
            label: tx('قيمة الطلب'),
            value: total > 0
                ? '$currency ${total.toStringAsFixed(2)}'
                : tx('غير متوفر'),
          ),
          _SummaryRow(
            label: tx('رسوم التوصيل'),
            value: deliveryFee > 0
                ? '$currency ${deliveryFee.toStringAsFixed(2)}'
                : tx('مجانية'),
          ),
          _SummaryRow(
            label: tx('المبلغ الكلي'),
            value: (total + deliveryFee) > 0
                ? '$currency ${(total + deliveryFee).toStringAsFixed(2)}'
                : tx('غير متوفر'),
            valueColor: DriverUi.primary,
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    return DriverCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DriverLiveMapboxView(
          order: order,
          sessionService: Get.find<DriverSessionService>(),
          height: 240,
          borderRadius: 18,
        ),
      ),
    );
  }
}

class _ActionGuideCard extends StatelessWidget {
  const _ActionGuideCard({required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    return DriverCard(
      color: const Color(0xFFFFF8F3),
      borderColor: const Color(0xFFF0D8CA),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: DriverUi.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: DriverUi.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _guideText(order.status),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DriverUi.text,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _guideText(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.incoming:
      case DriverOrderStatus.assigned:
      case DriverOrderStatus.headingToRestaurant:
        return tx('توجه إلى المطعم واستلم الطلب بدقة ثم واصل الرحلة.');
      case DriverOrderStatus.arrivedAtRestaurant:
        return tx('راجع البنود جيداً قبل تأكيد الاستلام والتحرك للعميل.');
      case DriverOrderStatus.pickedUp:
      case DriverOrderStatus.headingToCustomer:
        return tx('حافظ على المتابعة وابدأ التواصل مع العميل عند الحاجة.');
      case DriverOrderStatus.arrivedAtCustomer:
        return tx('أكمل التسليم بعد مراجعة رمز التحقق أو الصورة.');
      case DriverOrderStatus.awaitingVerification:
        return tx('أرسل رمز التحقق أو إثبات التسليم من هذه المرحلة.');
      case DriverOrderStatus.delivered:
        return tx('تم التسليم بنجاح، ويمكنك العودة إلى الصفحة الرئيسية.');
    }
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.order,
    required this.onRestaurant,
    required this.onPickedUp,
    required this.onCustomer,
    required this.onDeliver,
    required this.onCodeDeliver,
  });

  final DriverOrder order;
  final VoidCallback onRestaurant;
  final VoidCallback onPickedUp;
  final VoidCallback onCustomer;
  final VoidCallback onDeliver;
  final VoidCallback onCodeDeliver;

  @override
  Widget build(BuildContext context) {
    final action = _primaryActionForStatus();
    if (action == null) {
      return const SizedBox.shrink();
    }

    return DriverPrimaryButton(
      label: action.$1,
      icon: Icons.arrow_forward_rounded,
      onPressed: action.$2,
    );
  }

  (String, VoidCallback)? _primaryActionForStatus() {
    switch (order.status) {
      case DriverOrderStatus.incoming:
      case DriverOrderStatus.assigned:
      case DriverOrderStatus.headingToRestaurant:
        return (tx('اذهب إلى المطعم'), onRestaurant);
      case DriverOrderStatus.arrivedAtRestaurant:
        return (tx('تأكيد الاستلام'), onPickedUp);
      case DriverOrderStatus.pickedUp:
      case DriverOrderStatus.headingToCustomer:
        return (tx('اذهب إلى العميل'), onCustomer);
      case DriverOrderStatus.arrivedAtCustomer:
        return (tx('إثبات التسليم'), onDeliver);
      case DriverOrderStatus.awaitingVerification:
        return (tx('إدخال رمز التحقق'), onCodeDeliver);
      case DriverOrderStatus.delivered:
        return null;
    }
  }
}

class _DeliveryActionsCard extends StatelessWidget {
  const _DeliveryActionsCard({
    required this.order,
    required this.onArrivedAtRestaurant,
    required this.onPickedUp,
    required this.onArrivedAtCustomer,
    required this.onDeliver,
    required this.onEmergency,
  });

  final DriverOrder order;
  final VoidCallback onArrivedAtRestaurant;
  final VoidCallback onPickedUp;
  final VoidCallback onArrivedAtCustomer;
  final VoidCallback onDeliver;
  final VoidCallback onEmergency;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];
    if (order.status == DriverOrderStatus.incoming ||
        order.status == DriverOrderStatus.assigned ||
        order.status == DriverOrderStatus.headingToRestaurant) {
      actions.add(
        _ActionButton(
          label: tx('وصلت للمطعم'),
          icon: Icons.storefront_outlined,
          onPressed: onArrivedAtRestaurant,
        ),
      );
    }
    if (order.status == DriverOrderStatus.arrivedAtRestaurant) {
      actions.add(
        _ActionButton(
          label: tx('تم الاستلام'),
          icon: Icons.inventory_2_outlined,
          onPressed: onPickedUp,
        ),
      );
    }
    if (order.status == DriverOrderStatus.pickedUp ||
        order.status == DriverOrderStatus.headingToCustomer) {
      actions.add(
        _ActionButton(
          label: tx('وصلت للعميل'),
          icon: Icons.person_pin_circle_outlined,
          onPressed: onArrivedAtCustomer,
        ),
      );
    }
    if (order.status == DriverOrderStatus.arrivedAtCustomer) {
      actions.add(
        _ActionButton(
          label: tx('إثبات بالصورة'),
          icon: Icons.photo_camera_outlined,
          onPressed: onDeliver,
        ),
      );
    }
    actions.add(
      _ActionButton(
        label: tx('طوارئ'),
        icon: Icons.warning_amber_rounded,
        onPressed: onEmergency,
        danger: true,
      ),
    );

    return DriverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tx('إجراءات الطلب'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: DriverUi.text,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: actions
                .map(
                  (widget) => SizedBox(
                    width: (MediaQuery.of(context).size.width - 70) / 2,
                    child: widget,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: danger ? DriverUi.dangerSoft : DriverUi.surfaceWarm,
        foregroundColor: danger ? DriverUi.danger : DriverUi.text,
        side: BorderSide(
          color: danger ? const Color(0xFFF0C6C6) : DriverUi.line,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.onReply});

  final void Function(String) onReply;

  @override
  Widget build(BuildContext context) {
    final replies = Get.find<DriverOrdersService>().quickReplies;
    return DriverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tx('الردود السريعة'),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: DriverUi.text,
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: replies
                  .map(
                    (reply) => ActionChip(
                      label: Text(reply),
                      onPressed: () => onReply(reply),
                      backgroundColor: DriverUi.primarySoft,
                      side: BorderSide(color: DriverUi.line),
                      labelStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(
                            color: DriverUi.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantMedia extends StatelessWidget {
  const _RestaurantMedia({required this.order});

  final DriverOrder order;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = order.restaurantMediaUrl;

    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: DriverUi.primarySoft,
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
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 18, color: DriverUi.primary),
      label: Text(label),
      backgroundColor: DriverUi.surface,
      side: BorderSide(color: DriverUi.line),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: DriverUi.text,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item, required this.currency});

  final DriverOrderItem item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final unitPrice = item.resolvedUnitPrice;
    final totalPrice = item.resolvedTotalPrice;
    final moneyPrefix = currency.isNotEmpty
        ? currency
        : DriverPlatformSettings.currencySymbol;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ItemThumb(imageUrl: item.imageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: DriverUi.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trParam('الكمية: {qty}', 'Quantity: {qty}', {
                    'qty': item.quantity,
                  }),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: DriverUi.mutedText),
                ),
                if ((item.note ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DriverUi.mutedText,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                unitPrice > 0
                    ? '$moneyPrefix ${unitPrice.toStringAsFixed(2)}'
                    : '—',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DriverUi.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                totalPrice > 0
                    ? '$moneyPrefix ${totalPrice.toStringAsFixed(2)}'
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
      width: 58,
      height: 58,
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
              size: 24,
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.fastfood_outlined,
                color: DriverUi.primary,
                size: 24,
              ),
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: DriverUi.mutedText),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: valueColor ?? DriverUi.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
