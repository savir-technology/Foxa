import 'package:delvery/controllers/navigation_guide_controller.dart';
import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/core/services/driver_mapbox_service.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/data/models/navigation_models.dart';
import 'package:delvery/widgets/driver_live_mapbox_view.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, this.order});

  final DriverOrder? order;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late final String _controllerTag;

  DriverNavigationGuideController get _controller =>
      Get.find<DriverNavigationGuideController>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();

    final sessionService = Get.find<DriverSessionService>();
    final ordersService = Get.find<DriverOrdersService>();
    final currentOrder = widget.order ?? ordersService.activeOrder.value;

    _controllerTag =
        'tracking-${currentOrder?.id ?? 'none'}-${DateTime.now().microsecondsSinceEpoch}';
    Get.put(
      DriverNavigationGuideController(
        order: currentOrder,
        sessionService: sessionService,
        directionsService: DriverMapboxService(),
      ),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<DriverNavigationGuideController>(
      tag: _controllerTag,
    )) {
      Get.delete<DriverNavigationGuideController>(
        tag: _controllerTag,
        force: true,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionService = Get.find<DriverSessionService>();
    final ordersService = Get.find<DriverOrdersService>();
    final screenSize = MediaQuery.of(context).size;

    return Obx(() {
      final liveOrder = ordersService.activeOrder.value;
      final currentOrder = widget.order?.id == liveOrder?.id
          ? liveOrder
          : widget.order ?? liveOrder;

      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F3),
        body: Stack(
          children: [
            Positioned.fill(
              child: DriverLiveMapboxView(
                order: currentOrder,
                sessionService: sessionService,
                height: screenSize.height,
                borderRadius: 0,
                navigationMode: true,
                showStatusChips: false,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.10),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                child: Column(
                  children: [
                    _NavigationTopBar(
                      controller: _controller,
                      onBack: () => Get.back(),
                    ),
                    const Spacer(),
                    _NavigationBottomDock(controller: _controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _NavigationTopBar extends StatelessWidget {
  const _NavigationTopBar({required this.controller, required this.onBack});

  final DriverNavigationGuideController controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassButton(icon: Icons.arrow_back_rounded, onPressed: onBack),
          const SizedBox(width: 10),
          Expanded(child: _InstructionBanner(controller: controller)),
          const SizedBox(width: 10),
          _GlassButton(
            icon: controller.muted.value
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            onPressed: controller.toggleMute,
          ),
        ],
      ),
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  const _InstructionBanner({required this.controller});

  final DriverNavigationGuideController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = controller.upcomingStep.value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2F80FF),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80FF).withValues(alpha: 0.26),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(_maneuverIcon(step), color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.headline.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.subheadline.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (controller.loading.value) ...[
            const SizedBox(width: 10),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _maneuverIcon(DriverNavigationStep? step) {
    final modifier = step?.modifier?.trim().toLowerCase();
    if (step?.isArrival == true) {
      return Icons.flag_rounded;
    }
    if (modifier?.contains('left') == true) {
      return Icons.turn_left_rounded;
    }
    if (modifier?.contains('right') == true) {
      return Icons.turn_right_rounded;
    }
    if (step?.maneuverType == 'roundabout') {
      return Icons.roundabout_right_rounded;
    }
    return Icons.straight_rounded;
  }
}

class _NavigationBottomDock extends StatelessWidget {
  const _NavigationBottomDock({required this.controller});

  final DriverNavigationGuideController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: tx('الوصول'),
                    value: controller.routeDurationText.value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: tx('المتبقي'),
                    value: controller.destinationDistanceText.value,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    label: tx('المسار'),
                    value: controller.routeDistanceText.value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DockButton(
                    icon: Icons.campaign_rounded,
                    label: tx('إعادة التوجيه'),
                    onPressed: controller.repeatCurrentInstruction,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DockButton(
                    icon: controller.muted.value
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    label: controller.muted.value
                        ? tx('تشغيل الصوت', 'Unmute')
                        : tx('كتم الصوت'),
                    filled: true,
                    onPressed: controller.toggleMute,
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF66756C),
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: const Color(0xFF101827),
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final background = filled ? DriverUi.primary : Colors.white;
    final foreground = filled ? Colors.white : DriverUi.primary;

    return SizedBox(
      height: 44,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: background,
          foregroundColor: foreground,
          side: BorderSide(
            color: filled ? Colors.transparent : const Color(0xFFD9E7DD),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF101827), size: 22),
        ),
      ),
    );
  }
}
