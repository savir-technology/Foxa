import 'dart:async';
import 'dart:ui' as ui;

import 'package:delvery/controllers/home_controller.dart';
import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle _cairo(
  double size,
  FontWeight weight,
  Color color, {
  double height = 1.0,
  double letterSpacing = 0,
}) {
  return GoogleFonts.cairo(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

String _formatDashboardDate(DateTime date) {
  final isEnglish = Get.locale?.languageCode.trim().toLowerCase() == 'en';
  final arMonths = <String>[
    tx('?????'),
    tx('??????'),
    tx('????'),
    tx('?????'),
    tx('????'),
    tx('?????'),
    tx('?????'),
    tx('?????'),
    tx('??????'),
    tx('??????'),
    tx('??????'),
    tx('??????'),
  ];
  const enMonths = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final month = isEnglish ? enMonths[date.month - 1] : arMonths[date.month - 1];
  return isEnglish
      ? '$month ${date.day}, ${date.year}'
      : '${date.day} $month ${date.year}';
}

Future<void> _pickDashboardDate(
  BuildContext context,
  DriverOrdersService ordersService,
) async {
  final now = DateTime.now();
  final normalizedNow = DateTime(now.year, now.month, now.day);
  final selectedDate = ordersService.dashboardStatsDate.value;
  final initialDate = selectedDate == null
      ? normalizedNow
      : DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  final safeInitialDate = initialDate.isAfter(normalizedNow)
      ? normalizedNow
      : initialDate;

  final isEnglish = Get.locale?.languageCode.trim().toLowerCase() == 'en';
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: safeInitialDate,
    firstDate: DateTime(2020, 1, 1),
    lastDate: normalizedNow,
    locale: Locale(isEnglish ? 'en' : 'ar'),
    builder: (context, child) {
      return Directionality(
        textDirection: isEnglish ? ui.TextDirection.ltr : ui.TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      );
    },
  );

  if (pickedDate != null) {
    ordersService.setDashboardStatsDate(pickedDate);
  }
}

class DashboardTab extends GetView<HomeController> {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersService = Get.find<DriverOrdersService>();
    final sessionService = Get.find<DriverSessionService>();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        children: [
          _HomeHeader(
            onNotificationsTap: () => Get.toNamed(AppRoutes.notifications),
            onSupportTap: () => Get.toNamed(AppRoutes.help),
          ),
          _DriverStatusCard(
            sessionService: sessionService,
            ordersService: ordersService,
            onToggleShift: () {
              if (sessionService.isShiftActive.value) {
                unawaited(sessionService.endShift());
              } else {
                Get.toNamed(AppRoutes.shift);
              }
            },
          ),
          const SizedBox(height: 18),
          Obx(
            () => _TodayStatsCard(
              stats: ordersService.buildStats(),
              selectedDate:
                  ordersService.dashboardStatsDate.value ?? DateTime.now(),
              onCalendarTap: () => _pickDashboardDate(context, ordersService),
            ),
          ),
          Obx(
            () => _CurrentOrderSection(
              activeOrder: ordersService.activeOrder.value,
              onRefresh: ordersService.refreshDashboardNow,
              onOpen: controller.openCurrentOrder,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onNotificationsTap,
    required this.onSupportTap,
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onSupportTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TopActionButton(
            icon: Icons.notifications_none_rounded,
            onTap: onNotificationsTap,
            showDot: true,
          ),
          const Spacer(),
          const _HomeLogo(),
          const Spacer(),
          _TopActionButton(
            icon: Icons.headset_mic_outlined,
            onTap: onSupportTap,
          ),
        ],
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: DriverUi.surfaceAdaptive,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DriverUi.lineAdaptive),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: Icon(icon, size: 22, color: DriverUi.textAdaptive),
                ),
              ),
            ),
          ),
          if (showDot)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: DriverUi.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeLogo extends StatelessWidget {
  const _HomeLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 55,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: DriverUi.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'ROAQ ',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: DriverUi.textAdaptive,
                        ),
                      ),
                      TextSpan(
                        text: '',
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: DriverUi.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          'DRIVER',
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: DriverUi.primary,
            letterSpacing: 3.2,
          ),
        ),
      ],
    );
  }
}

class _DriverStatusCard extends StatelessWidget {
  const _DriverStatusCard({
    required this.sessionService,
    required this.ordersService,
    required this.onToggleShift,
  });

  final DriverSessionService sessionService;
  final DriverOrdersService ordersService;
  final VoidCallback onToggleShift;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = sessionService.dashboardTick.value;
      final activeOrder = ordersService.activeOrder.value;
      final isAvailable = sessionService.isShiftActive.value;
      final canStartShift = sessionService.isWithinOfficialWorkingHours();
      final isBusy = activeOrder != null;
      final statusText = !isAvailable
          ? canStartShift
              ? t('غير متاح', 'Offline')
              : t('خارج الدوام', 'Out of hours')
          : isBusy
          ? t('مشغول', 'Busy')
          : t('متاح', 'Available');
      final description = !isAvailable
          ? canStartShift
              ? t(
                  'ابدأ المناوبة لاستقبال الطلبات',
                  'Start a shift to receive orders',
                )
              : t(
                  'أنت خارج أوقات العمل الرسمية المحددة من داش بورد المستر.',
                  'You are outside the official hours set in the master dashboard.',
                )
          : isBusy
          ? t('يوجد طلب نشط الآن', 'You have an active order now')
          : t('جاهز لاستقبال الطلبات', 'Ready to receive orders');

      return DriverCard(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(18),
        child: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DriverAvatar(sessionService: sessionService),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      t('حالة السائق', 'Driver status'),
                      textAlign: TextAlign.right,
                      style: _cairo(
                        13,
                        FontWeight.w500,
                        DriverUi.textAdaptive,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusText,
                      textAlign: TextAlign.right,
                      style: _cairo(
                        15,
                        FontWeight.w700,
                        DriverUi.primary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      textAlign: TextAlign.right,
                      style: _cairo(
                        11,
                        FontWeight.w400,
                        DriverUi.mutedTextAdaptive,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Transform.scale(
                scale: 0.84,
                child: Switch.adaptive(
                  value: sessionService.isShiftActive.value,
                  onChanged: (_) => onToggleShift(),
                  activeThumbColor: Colors.white,
                  activeTrackColor: DriverUi.primary,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE7E7E7),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.sessionService});

  final DriverSessionService sessionService;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = sessionService.profile.value;
      final photoUrl = sessionService.api.resolveUrl(profile.photoUrl);

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DriverUi.surfaceSoftAdaptive,
              border: Border.all(color: DriverUi.lineAdaptive),
            ),
            clipBehavior: Clip.antiAlias,
            child: photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person_rounded,
                      size: 38,
                      color: DriverUi.primary.withValues(alpha: 0.78),
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    size: 38,
                    color: DriverUi.primary.withValues(alpha: 0.78),
                  ),
          ),
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: DriverUi.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _TodayStatsCard extends StatelessWidget {
  const _TodayStatsCard({
    required this.stats,
    required this.selectedDate,
    required this.onCalendarTap,
  });

  final DriverDashboardStats stats;
  final DateTime selectedDate;
  final VoidCallback onCalendarTap;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    final dateLabel = isToday
        ? t('اليوم', 'Today')
        : _formatDashboardDate(selectedDate);

    final tiles = [
      _StatTile(
        title: t('الطلبات المسلمة', 'Delivered orders'),
        value: stats.deliveredOrders.toString(),
        valueSize: 14,
        label: t('طلب', 'order'),
        icon: Icons.check_circle_outline_rounded,
      ),
      _StatTile(
        title: t('الطلبات الكلية', 'Total orders'),
        value: stats.todayOrders.toString(),
        valueSize: 14,
        label: t('طلب', 'order'),
        icon: Icons.assignment_turned_in_outlined,
      ),
      _StatTile(
        title: t('ساعات العمل', 'Working hours'),
        value: stats.shiftHours,
        valueSize: 13,
        label: t('ساعة', 'hr'),
        icon: Icons.access_time_rounded,
      ),
    ];

    return DriverCard(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: ui.TextDirection.ltr,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      t('إحصائيات اليوم', 'Today stats'),
                      textAlign: TextAlign.right,
                      style: _cairo(
                        15,
                        FontWeight.w600,
                        DriverUi.textAdaptive,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      textAlign: TextAlign.right,
                      style: _cairo(
                        10,
                        FontWeight.w400,
                        DriverUi.mutedTextAdaptive,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCalendarTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.calendar_month_outlined,
                      size: 22,
                      color: DriverUi.textAdaptive,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: tiles,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.valueSize,
    required this.label,
    required this.icon,
  });

  final String title;
  final String value;
  final double valueSize;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95,
      height: 128,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: DriverUi.surfaceSoftAdaptive,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DriverUi.lineAdaptive),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: _cairo(10, FontWeight.w500, DriverUi.mutedTextAdaptive, height: 1.1),
          ),
          const SizedBox(height: 8),
          Icon(icon, size: 22, color: DriverUi.primary),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: _cairo(
              valueSize,
              FontWeight.w700,
              DriverUi.textAdaptive,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: _cairo(9, FontWeight.w400, DriverUi.mutedTextAdaptive, height: 1.0),
          ),
        ],
      ),
    );
  }
}

class _CurrentOrderSection extends StatelessWidget {
  const _CurrentOrderSection({
    required this.activeOrder,
    required this.onRefresh,
    required this.onOpen,
  });

  final DriverOrder? activeOrder;
  final VoidCallback onRefresh;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return DriverCard(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              t('الطلب الحالي', 'Current order'),
              style: _cairo(15, FontWeight.w600, DriverUi.textAdaptive),
            ),
          ),
          const SizedBox(height: 16),
          if (activeOrder == null)
            _EmptyCurrentOrder(onRefresh: onRefresh)
          else
            _ActiveCurrentOrder(order: activeOrder!, onOpen: onOpen),
        ],
      ),
    );
  }
}

class _EmptyCurrentOrder extends StatelessWidget {
  const _EmptyCurrentOrder({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 12,
                      top: 18,
                      child: Icon(
                        Icons.cloud_outlined,
                        size: 28,
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 18,
                      child: Icon(
                        Icons.cloud_outlined,
                        size: 28,
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: DriverUi.primarySoftAdaptive,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 56,
                        color: DriverUi.primary.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t('لا يوجد طلب جديد حالياً', 'No new order right now'),
                textAlign: TextAlign.center,
                style: _cairo(15, FontWeight.w700, DriverUi.primary, height: 1.1),
              ),
              const SizedBox(height: 8),
              Text(
                t(
                  'ستصلك الطلبات الجديدة تلقائياً عند توفرها',
                  'New orders will appear automatically when available',
                ),
                textAlign: TextAlign.center,
                style: _cairo(10, FontWeight.w400, DriverUi.mutedTextAdaptive, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: DriverUi.primarySoftAdaptive,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            textDirection: ui.TextDirection.ltr,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      t('نصيحة', 'Tip'),
                      textAlign: TextAlign.right,
                      style: _cairo(11, FontWeight.w600, DriverUi.primary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t(
                        'ابق متاحاً للحصول على المزيد من الطلبات وزيادة أرباحك',
                        'Stay available to receive more orders and increase earnings',
                      ),
                      textAlign: TextAlign.right,
                      style: _cairo(
                        10,
                        FontWeight.w400,
                        DriverUi.textAdaptive,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: DriverUi.surfaceAdaptive,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: DriverUi.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveCurrentOrder extends StatelessWidget {
  const _ActiveCurrentOrder({required this.order, required this.onOpen});

  final DriverOrder order;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    order.restaurantName,
                    textAlign: TextAlign.right,
                    style: _cairo(13, FontWeight.w600, DriverUi.textAdaptive, height: 1.1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.customerAddress,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _cairo(
                      11,
                      FontWeight.w400,
                      DriverUi.mutedTextAdaptive,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: DriverUi.surfaceSoftAdaptive,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: DriverUi.lineAdaptive),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: DriverUi.primary,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          textDirection: ui.TextDirection.ltr,
          children: [
            Expanded(
              child: _OrderMetric(
                icon: Icons.pin_drop_outlined,
                value: '${order.resolvedDistanceKm().toStringAsFixed(1)} ${t('كم', 'km')}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OrderMetric(
                icon: Icons.timer_outlined,
                value: '${order.etaMinutes} ${t('دقيقة', 'min')}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OrderMetric(
                icon: Icons.shopping_bag_outlined,
                value: '${order.items.length} ${t('أصناف', 'items')}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 46,
          child: FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: DriverUi.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              t('فتح الطلب', 'Open order'),
              style: _cairo(13, FontWeight.w600, Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderMetric extends StatelessWidget {
  const _OrderMetric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: DriverUi.surfaceSoftAdaptive,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DriverUi.lineAdaptive),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: DriverUi.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _cairo(10, FontWeight.w600, DriverUi.textAdaptive),
            ),
          ),
        ],
      ),
    );
  }
}
