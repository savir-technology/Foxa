import 'package:admin_tks/core/services/mapbox_runtime_config.dart';
import 'package:admin_tks/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

String dashboardMapTileUrlTemplate() {
  final token = MapboxRuntimeConfig.accessToken.trim();
  if (token.isNotEmpty) {
    return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=${Uri.encodeQueryComponent(token)}';
  }

  return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}

bool dashboardHasMapCoordinates(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) {
    return false;
  }
  return !(latitude == 0 && longitude == 0);
}

class DashboardMapBox extends StatelessWidget {
  const DashboardMapBox({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title = 'الخريطة',
    this.subtitle,
    this.height = 190,
    this.zoom = 15.2,
    this.interactive = false,
    this.onMapTap,
    this.onOpenExternal,
  });

  final double? latitude;
  final double? longitude;
  final String title;
  final String? subtitle;
  final double height;
  final double zoom;
  final bool interactive;
  final void Function(double latitude, double longitude)? onMapTap;
  final VoidCallback? onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final hasCoordinates = dashboardHasMapCoordinates(latitude, longitude);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: hasCoordinates
                  ? FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(latitude!, longitude!),
                        initialZoom: zoom,
                        interactionOptions: InteractionOptions(
                          flags: interactive
                              ? InteractiveFlag.all
                              : InteractiveFlag.none,
                        ),
                        onTap: onMapTap == null
                            ? null
                            : (tapPosition, point) =>
                                onMapTap!(point.latitude, point.longitude),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: dashboardMapTileUrlTemplate(),
                          userAgentPackageName:
                              'com.aleppoeats.admin.dashboard',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(latitude!, longitude!),
                              width: 46,
                              height: 46,
                              child: const _DashboardMapPin(),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const _DashboardMapEmptyState(),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: _DashboardMapLabel(title: title, subtitle: subtitle),
            ),
            if (hasCoordinates && onOpenExternal != null)
              Positioned(
                left: 12,
                bottom: 12,
                child: _MapOpenButton(onPressed: onOpenExternal!),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMapLabel extends StatelessWidget {
  const _DashboardMapLabel({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topEnd,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            const Icon(Icons.map_rounded, color: kPrimary, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((subtitle ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapOpenButton extends StatelessWidget {
  const _MapOpenButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new_rounded, size: 15, color: kPrimary),
              SizedBox(width: 6),
              Text(
                'فتح الخريطة',
                style: TextStyle(
                  color: kPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardMapPin extends StatelessWidget {
  const _DashboardMapPin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: kPrimary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 13,
          ),
        ),
      ],
    );
  }
}

class _DashboardMapEmptyState extends StatelessWidget {
  const _DashboardMapEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6FAF7), Color(0xFFEFF7F1)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, color: kPrimary, size: 38),
            SizedBox(height: 10),
            Text(
              'الموقع غير متوفر حالياً',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
