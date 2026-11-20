import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:tks/core/services/mapbox_runtime_config.dart';
import 'package:tks/features/navigation/presentation/controllers/driver_navigation_controller.dart';
import 'package:tks/features/navigation/presentation/widgets/navigation_top_card.dart';
import 'package:tks/features/navigation/presentation/widgets/trip_bottom_panel.dart';

class DriverNavigationScreen extends StatelessWidget {
  const DriverNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DriverNavigationController>(
      init: DriverNavigationController(),
      builder: (controller) {
        final theme = Theme.of(context);
        final progress = controller.progress;
        controller.setMapBrightness(theme.brightness);
        final mapStyleUri =
            MapboxRuntimeConfig.styleUriForBrightness(theme.brightness);
        return Directionality(
          textDirection:
              controller.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xFF101010),
            body: Stack(
              children: [
                Positioned.fill(
                  child: controller.isMapboxReady
                      ? MapWidget(
                          key: ValueKey(
                            'driverNavigationMap-${theme.brightness.name}-$mapStyleUri',
                          ),
                          styleUri: mapStyleUri,
                          viewport: controller.isFollowingDriver
                              ? FollowPuckViewportState(
                                  zoom: 17,
                                  pitch: 45,
                                  bearing:
                                      const FollowPuckViewportStateBearingCourse(),
                                  padding: MbxEdgeInsets(
                                    top: 170,
                                    left: 24,
                                    bottom: 270,
                                    right: 24,
                                  ),
                                )
                              : const IdleViewportState(),
                          onMapCreated: controller.onMapCreated,
                          onStyleLoadedListener: controller.onStyleLoaded,
                        )
                      : Container(
                          color: const Color(0xFF1B1B1B),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.map_rounded,
                            color: Colors.white24,
                            size: 72,
                          ),
                        ),
                ),
                Positioned(
                  top: 18,
                  left: 16,
                  right: 16,
                  child: SafeArea(
                    bottom: false,
                    child: progress == null
                        ? _NavigationStateBanner(
                            title: controller.isArabic
                                ? 'يتم تجهيز الرحلة'
                                : 'Preparing trip',
                            subtitle: controller.errorMessage ??
                                (controller.isRerouting
                                    ? (controller.isArabic
                                        ? 'جارٍ إعادة حساب المسار...'
                                        : 'Recalculating route...')
                                    : (controller.isArabic
                                        ? 'جارٍ تحميل موقع السائق والمسار'
                                        : 'Loading driver location and route')),
                            isError: controller.errorMessage != null,
                          )
                        : NavigationTopCard(
                            progress: progress,
                            isArabic: controller.isArabic,
                          ),
                  ),
                ),
                if (controller.errorMessage != null)
                  Positioned(
                    top: 160,
                    left: 16,
                    right: 16,
                    child: _PermissionHelperCard(controller: controller),
                  ),
                Positioned(
                  right: 16,
                  bottom: 220,
                  child: Column(
                    children: [
                      _MapActionButton(
                        icon: Icons.gps_fixed_rounded,
                        onTap: controller.recenterCamera,
                      ),
                      const SizedBox(height: 12),
                      _MapActionButton(
                        icon: Icons.route_outlined,
                        onTap: controller.showOverview,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: TripBottomPanel(
                      eta: progress?.eta ?? Duration.zero,
                      remainingDistanceMeters:
                          progress?.remainingDistanceMeters ?? 0,
                      passengerName: controller.tripDestination.passengerName,
                      tripStatus: controller.isRerouting
                          ? (controller.isArabic
                              ? 'إعادة حساب المسار'
                              : 'Rerouting')
                          : controller.tripDestination.tripStatus,
                      destinationLabel:
                          controller.tripDestination.destinationLabel,
                      isArabic: controller.isArabic,
                      isFollowingDriver: controller.isFollowingDriver,
                      onOverviewTap: controller.showOverview,
                      onRecenterTap: controller.recenterCamera,
                    ),
                  ),
                ),
                if (controller.isBootstrapping)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x22000000),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(icon, color: const Color(0xFF161616)),
          ),
        ),
      ),
    );
  }
}

class _NavigationStateBanner extends StatelessWidget {
  const _NavigationStateBanner({
    required this.title,
    required this.subtitle,
    this.isError = false,
  });

  final String title;
  final String subtitle;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isError ? const Color(0xFFE8E8E8) : const Color(0xFFF2F2F2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isError
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFF1A1A1A),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6D6D6D),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _PermissionHelperCard extends StatelessWidget {
  const _PermissionHelperCard({required this.controller});

  final DriverNavigationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.errorMessage ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: const Color(0xFF6D6D6D),
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.openLocationSettings,
                  child: Text(
                    controller.isArabic ? 'خدمات الموقع' : 'Location Services',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: controller.openSystemSettings,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF161616),
                  ),
                  child: Text(
                    controller.isArabic ? 'إعدادات التطبيق' : 'App Settings',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
