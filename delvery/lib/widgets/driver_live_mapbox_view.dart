import 'dart:async';

import 'package:delvery/core/services/driver_mapbox_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/core/services/mapbox_runtime_config.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/data/models/navigation_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/widgets/driver_ui.dart';

class DriverLiveMapboxView extends StatefulWidget {
  const DriverLiveMapboxView({
    super.key,
    required this.order,
    required this.sessionService,
    this.height = 280,
    this.borderRadius = 30,
    this.navigationMode = false,
    this.showStatusChips = true,
  });

  final DriverOrder? order;
  final DriverSessionService sessionService;
  final double height;
  final double borderRadius;
  final bool navigationMode;
  final bool showStatusChips;

  @override
  State<DriverLiveMapboxView> createState() => _DriverLiveMapboxViewState();
}

class _DriverLiveMapboxViewState extends State<DriverLiveMapboxView> {
  final DriverMapboxService _mapService = DriverMapboxService();
  Worker? _driverWorker;
  MapboxMap? _mapboxMap;
  late ViewportState _viewport;
  bool _styleLoaded = false;
  bool _syncQueued = false;
  bool _syncRequestedWhileBusy = false;
  bool _forceRouteRefresh = true;
  bool _followLiveScene = true;
  bool _hasRenderedScene = false;
  String _routeKey = '';
  DriverRouteBundle? _cachedRouteBundle;

  @override
  void initState() {
    super.initState();
    _viewport = _buildViewport(widget.order);
    _driverWorker = ever<DriverCoordinate?>(
      widget.sessionService.liveCoordinate,
      (_) => _scheduleSync(forceRouteRefresh: false),
    );
  }

  @override
  void didUpdateWidget(covariant DriverLiveMapboxView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldOrder = oldWidget.order;
    final newOrder = widget.order;
    if (oldOrder?.id != newOrder?.id || oldOrder?.status != newOrder?.status) {
      _viewport = _buildViewport(newOrder);
      _followLiveScene = true;
      _forceRouteRefresh = true;
      _routeKey = '';
      _cachedRouteBundle = null;
      _hasRenderedScene = false;
      _scheduleSync(forceRouteRefresh: true);
    }
  }

  @override
  void dispose() {
    _driverWorker?.dispose();
    _mapService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (MapboxRuntimeConfig.isConfigured)
              MapWidget(
                key: ValueKey('driver-live-mapbox-${order?.id ?? 'empty'}'),
                styleUri: MapboxRuntimeConfig.styleUri,
                viewport: _viewport,
                onMapCreated: _onMapCreated,
                onStyleLoadedListener: _onStyleLoaded,
                onScrollListener: _handleMapGesture,
                onZoomListener: _handleMapGesture,
                onCameraChangeListener: _onCameraChanged,
                onMapIdleListener: _onMapIdle,
              )
            else
              const _FallbackMap(),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.navigationMode && MapboxRuntimeConfig.isConfigured)
              const Positioned.fill(
                child: IgnorePointer(child: _NavigationArrowOverlay()),
              ),
            if (widget.showStatusChips)
              Positioned(
                left: 14,
                top: 14,
                child: Obx(
                  () => _StatusChip(
                    text: widget.sessionService.liveCoordinate.value == null
                        ? tx('بانتظار GPS')
                        : tx('GPS يعمل'),
                  ),
                ),
              ),
            if (widget.showStatusChips)
              Positioned(
                right: 14,
                bottom: 14,
                child: _StatusChip(
                  text: order == null
                      ? tx('بانتظار طلب')
                      : _targetLabelFor(order.status),
                ),
              ),
            if (widget.navigationMode)
              Positioned(
                right: 14,
                top: widget.showStatusChips ? 14 : 92,
                child: _FollowRouteChip(
                  followLiveScene: _followLiveScene,
                  onPressed: _toggleFollowMode,
                ),
              ),
            if (!MapboxRuntimeConfig.isConfigured)
              const Positioned(
                left: 14,
                right: 14,
                bottom: 58,
                child: _ConfigWarning(),
              ),
          ],
        ),
      ),
    );
  }

  Point _initialCenter(
    DriverCoordinate? driverLocation,
    DriverCoordinate? targetLocation,
  ) {
    final target = _targetLocationFor(widget.order);
    final center = driverLocation ?? target ?? targetLocation;
    if (center == null) {
      return Point(coordinates: Position(37.1343, 36.2021));
    }
    return Point(coordinates: Position(center.longitude, center.latitude));
  }

  double _initialZoom(
    DriverCoordinate? driverLocation,
    DriverCoordinate? targetLocation,
  ) {
    if (widget.navigationMode && driverLocation != null) {
      return 17.2;
    }
    if (driverLocation != null && targetLocation != null) {
      return 12.8;
    }
    if (driverLocation != null || targetLocation != null) {
      return 14.8;
    }
    return 11.2;
  }

  ViewportState _buildViewport(DriverOrder? order) {
    final driverLocation = widget.sessionService.liveCoordinate.value;
    final targetLocation = _targetLocationFor(order);
    return CameraViewportState(
      center: _initialCenter(driverLocation, targetLocation),
      zoom: _initialZoom(driverLocation, targetLocation),
      pitch: widget.navigationMode ? 54 : 0,
    );
  }

  DriverCoordinate? _targetLocationFor(DriverOrder? order) {
    final current = order;
    if (current == null) {
      return null;
    }
    bool isValid(DriverCoordinate coordinate) {
      return coordinate.latitude != 0 && coordinate.longitude != 0;
    }

    switch (current.status) {
      case DriverOrderStatus.incoming:
      case DriverOrderStatus.assigned:
      case DriverOrderStatus.headingToRestaurant:
      case DriverOrderStatus.arrivedAtRestaurant:
        return isValid(current.restaurantLocation)
            ? current.restaurantLocation
            : null;
      case DriverOrderStatus.pickedUp:
      case DriverOrderStatus.headingToCustomer:
      case DriverOrderStatus.arrivedAtCustomer:
      case DriverOrderStatus.awaitingVerification:
      case DriverOrderStatus.delivered:
        return isValid(current.customerLocation)
            ? current.customerLocation
            : null;
    }
  }

  String _targetLabelFor(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.incoming:
      case DriverOrderStatus.assigned:
      case DriverOrderStatus.headingToRestaurant:
        return tx('إلى المطعم');
      case DriverOrderStatus.arrivedAtRestaurant:
        return tx('في المطعم');
      case DriverOrderStatus.pickedUp:
      case DriverOrderStatus.headingToCustomer:
        return tx('إلى المستلم');
      case DriverOrderStatus.arrivedAtCustomer:
        return tx('عند المستلم');
      case DriverOrderStatus.awaitingVerification:
        return tx('بانتظار الرمز');
      case DriverOrderStatus.delivered:
        return tx('تم التسليم');
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _mapService.attachMap(mapboxMap);
    unawaited(
      mapboxMap.gestures.updateSettings(
        GesturesSettings(
          scrollEnabled: true,
          pinchPanEnabled: true,
          pinchToZoomEnabled: true,
          rotateEnabled: true,
          pitchEnabled: true,
          quickZoomEnabled: true,
        ),
      ),
    );
    if (_styleLoaded) {
      _scheduleSync(forceRouteRefresh: true);
    }
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    _styleLoaded = true;
    await _mapService.prepareMapStyle();
    await _mapService.enableLocationPuck();
    try {
      await _mapboxMap?.style.setStyleImportConfigProperty(
        'basemap',
        'lightPreset',
        'day',
      );
    } catch (_) {}
    _scheduleSync(forceRouteRefresh: true);
  }

  void _scheduleSync({required bool forceRouteRefresh}) {
    _forceRouteRefresh = _forceRouteRefresh || forceRouteRefresh;
    if (_syncQueued) {
      _syncRequestedWhileBusy = true;
      return;
    }

    _syncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _syncQueued = false;
        return;
      }

      try {
        do {
          _syncRequestedWhileBusy = false;
          await _syncMap();
        } while (_syncRequestedWhileBusy && mounted);
      } finally {
        _syncQueued = false;
        _forceRouteRefresh = false;
        _syncRequestedWhileBusy = false;
      }
    });
  }

  Future<void> _syncMap() async {
    if (!mounted || _mapboxMap == null || !_styleLoaded) {
      return;
    }

    final driverLocation = widget.sessionService.liveCoordinate.value;
    final order = widget.order;
    final targetLocation = _targetLocationFor(order);

    final routeKey = [
      order?.id.toString() ?? 'none',
      order?.status.name ?? 'none',
      _pointKey(driverLocation, fractionDigits: 4),
      _pointKey(targetLocation),
    ].join('|');

    if (_forceRouteRefresh || routeKey != _routeKey) {
      _routeKey = routeKey;
      try {
        if (driverLocation != null && targetLocation != null) {
          _cachedRouteBundle = await _mapService.fetchRouteBundle(
            origin: driverLocation,
            destination: targetLocation,
          );
        } else {
          _cachedRouteBundle = null;
        }
      } catch (_) {
        _cachedRouteBundle = null;
      }
    }

    try {
      await _mapService.renderScene(
        driverLocation: driverLocation,
        targetLocation: targetLocation,
        routes: _routesForRender(),
        immediate: !_hasRenderedScene,
        autoFocus: widget.navigationMode ? _followLiveScene : true,
        navigationCamera: widget.navigationMode && _followLiveScene,
        cameraPadding: widget.navigationMode
            ? MbxEdgeInsets(top: 118, left: 0, bottom: 260, right: 0)
            : MbxEdgeInsets(top: 72, left: 28, bottom: 92, right: 28),
      );
      _hasRenderedScene = true;
    } catch (_) {}
  }

  List<DriverRouteVariant>? _routesForRender() {
    final routes = _cachedRouteBundle?.routes
        .where((route) => route.hasRoute)
        .toList(growable: false);
    if (routes == null || routes.isEmpty) {
      return null;
    }

    if (!widget.navigationMode) {
      return [routes.first];
    }

    var bestRoute = routes.first;
    for (final route in routes.skip(1)) {
      if (route.distanceMeters > 0 &&
          (bestRoute.distanceMeters <= 0 ||
              route.distanceMeters < bestRoute.distanceMeters)) {
        bestRoute = route;
      }
    }
    return [bestRoute];
  }

  void _handleMapGesture(MapContentGestureContext context) {
    if (!widget.navigationMode) {
      return;
    }

    if (context.gestureState == GestureState.started ||
        context.gestureState == GestureState.changed) {
      if (_followLiveScene) {
        setState(() {
          _followLiveScene = false;
        });
      }
    }
  }

  void _onCameraChanged(CameraChangedEventData _) {
    if (!mounted) {
      return;
    }
  }

  void _onMapIdle(MapIdleEventData _) {
    if (!mounted || !widget.navigationMode) {
      return;
    }
  }

  void _toggleFollowMode() {
    if (!widget.navigationMode) {
      return;
    }

    setState(() {
      _followLiveScene = !_followLiveScene;
    });

    if (_followLiveScene) {
      _forceRouteRefresh = true;
      _scheduleSync(forceRouteRefresh: true);
    }
  }

  String _pointKey(DriverCoordinate? point, {int fractionDigits = 5}) {
    if (point == null) {
      return 'null';
    }
    return '${point.latitude.toStringAsFixed(fractionDigits)},${point.longitude.toStringAsFixed(fractionDigits)}';
  }
}

class _NavigationArrowOverlay extends StatelessWidget {
  const _NavigationArrowOverlay();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.28),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2F80FF).withValues(alpha: 0.16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2F80FF).withValues(alpha: 0.22),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(48, 56),
            painter: _NavigationArrowPainter(),
          ),
        ],
      ),
    );
  }
}

class _NavigationArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final bodyPaint = Paint()
      ..color = const Color(0xFF2F80FF)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width / 2, 4)
      ..lineTo(size.width - 7, size.height - 7)
      ..lineTo(size.width / 2, size.height - 21)
      ..lineTo(7, size.height - 7)
      ..close();

    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();
    canvas.drawPath(path, bodyPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FallbackMap extends StatelessWidget {
  const _FallbackMap();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6F8F4), Color(0xFFF1F5EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: -48,
            top: 18,
            child: _SoftOrb(size: 170, color: Color(0x14FF6500)),
          ),
          const Positioned(
            right: -54,
            top: 86,
            child: _SoftOrb(size: 220, color: Color(0x12FFFFFF)),
          ),
          const Positioned(
            right: -34,
            bottom: -26,
            child: _SoftOrb(size: 210, color: Color(0x0F8DBB98)),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: _LabelChip(
              text: tx('الخريطة غير مفعلة بعد'),
              color: DriverUi.primary,
            ),
          ),
          Positioned(
            right: 20,
            top: 38,
            child: _LabelChip(text: tx('المطعم'), color: DriverUi.primary),
          ),
          Positioned(
            right: 34,
            bottom: 38,
            child: _LabelChip(text: tx('العميل'), color: DriverUi.primary),
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF1A3322),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FollowRouteChip extends StatelessWidget {
  const _FollowRouteChip({
    required this.followLiveScene,
    required this.onPressed,
  });

  final bool followLiveScene;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = followLiveScene ? const Color(0xFF2F80FF) : DriverUi.primary;
    final label = followLiveScene ? tx('متابعة مباشرة') : tx('إعادة التمركز');
    final icon = followLiveScene ? Icons.navigation_rounded : Icons.my_location;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF4A2412),
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

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.08), Colors.transparent],
          stops: const [0.0, 0.48, 1.0],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF4A2412),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ConfigWarning extends StatelessWidget {
  const _ConfigWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Text(
        tx('ضع MAPBOX_ACCESS_TOKEN لتفعيل الخريطة الحية.'),
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: const Color(0xFF466050)),
      ),
    );
  }
}
