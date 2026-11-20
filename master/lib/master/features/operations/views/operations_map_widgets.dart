// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class _LiveOperationsMap extends StatefulWidget {
  const _LiveOperationsMap({
    required this.markers,
    required this.showWeatherBadge,
    required this.showLayerPanel,
    this.routes = const [],
    this.onMarkerTap,
  });

  static const LatLng _middleEastCenter = LatLng(30.0444, 31.2357);
  static final LatLngBounds _middleEastBounds = LatLngBounds(
    const LatLng(29.45, 30.45),
    const LatLng(30.75, 32.05),
  );
  static const bool _hasMapboxToken = _kMapboxAccessToken != '';

  final List<_OperationsMapMarkerData> markers;
  final bool showWeatherBadge;
  final bool showLayerPanel;
  final List<_OperationsRouteData> routes;
  final ValueChanged<_OperationsMapMarkerData>? onMarkerTap;

  @override
  State<_LiveOperationsMap> createState() => _LiveOperationsMapState();
}

class _LiveOperationsMapState extends State<_LiveOperationsMap> {
  final MapController _mapController = MapController();
  late bool _layerPanelVisible;
  late List<_OperationsRouteData> _displayRoutes;
  int _routeRequestId = 0;

  @override
  void initState() {
    super.initState();
    _layerPanelVisible = widget.showLayerPanel;
    _displayRoutes = widget.routes;
    _loadRoadRoutes();
  }

  @override
  void didUpdateWidget(covariant _LiveOperationsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showLayerPanel != widget.showLayerPanel) {
      _layerPanelVisible = widget.showLayerPanel;
    }
    if (oldWidget.markers.length != widget.markers.length ||
        oldWidget.routes.length != widget.routes.length) {
      _displayRoutes = widget.routes;
      _loadRoadRoutes();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitToWorkingArea();
      });
    }
  }

  Future<void> _loadRoadRoutes() async {
    if (widget.routes.isEmpty) return;
    final requestId = ++_routeRequestId;
    final resolved = <_OperationsRouteData>[];
    for (final route in widget.routes.take(40)) {
      if (route.points.length < 2) {
        resolved.add(route);
        continue;
      }
      final start = route.points.first;
      final end = route.points.last;
      final mapbox = _kMapboxAccessToken.trim().isNotEmpty;
      final uri = mapbox
          ? Uri.parse(
              'https://api.mapbox.com/directions/v5/mapbox/driving/'
              '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
              '?alternatives=false&overview=full&geometries=geojson'
              '&access_token=${Uri.encodeComponent(_kMapboxAccessToken)}',
            )
          : Uri.parse(
              'https://router.project-osrm.org/route/v1/driving/'
              '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
              '?overview=full&geometries=geojson',
            );
      try {
        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: 8));
        final payload = response.statusCode == 200
            ? jsonDecode(response.body)
            : null;
        final routeRows = payload is Map ? payload['routes'] : null;
        final geometry = routeRows is List && routeRows.isNotEmpty
            ? routeRows.first['geometry']
            : null;
        final coordinates = geometry is Map ? geometry['coordinates'] : null;
        final roadPoints = coordinates is List
            ? coordinates
                  .whereType<List>()
                  .where((point) => point.length >= 2)
                  .map(
                    (point) => LatLng(
                      (point[1] as num).toDouble(),
                      (point[0] as num).toDouble(),
                    ),
                  )
                  .toList()
            : <LatLng>[];
        resolved.add(
          roadPoints.length > 1 ? route.withPoints(roadPoints) : route,
        );
      } catch (_) {
        resolved.add(route);
      }
    }
    if (!mounted || requestId != _routeRequestId) return;
    setState(() => _displayRoutes = resolved);
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final zoom = (camera.zoom + delta).clamp(3.0, 18.0).toDouble();
    _mapController.move(camera.center, zoom);
  }

  void _resetToMiddleEast() {
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: _LiveOperationsMap._middleEastBounds,
        padding: const EdgeInsets.fromLTRB(44, 34, 44, 58),
        minZoom: 3.2,
        maxZoom: 5.2,
      ),
    );
  }

  void _fitToWorkingArea() {
    final points =
        <LatLng>[
              ...widget.markers.map((marker) => marker.point),
              ..._displayRoutes.expand((route) => route.points),
            ]
            .where(
              (point) =>
                  point.latitude.abs() > 0.000001 &&
                  point.longitude.abs() > 0.000001,
            )
            .toList();
    if (points.length < 2) {
      if (points.length == 1) {
        _mapController.move(points.first, 12.0);
      }
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(70, 70, 70, 90),
        maxZoom: 15,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitToWorkingArea();
    });
  }

  @override
  Widget build(BuildContext context) {
    final validMarkers = widget.markers
        .where(
          (marker) =>
              marker.point.latitude.abs() > 0.000001 &&
              marker.point.longitude.abs() > 0.000001,
        )
        .toList();
    final workingPoints = <LatLng>[
      ...validMarkers.map((marker) => marker.point),
      ..._displayRoutes.expand((route) => route.points),
    ];
    final hasWorkingBounds = workingPoints.length > 1;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: workingPoints.isNotEmpty
                    ? workingPoints.first
                    : _LiveOperationsMap._middleEastCenter,
                initialZoom: hasWorkingBounds ? 10.5 : 4.2,
                initialCameraFit: hasWorkingBounds
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(workingPoints),
                        padding: const EdgeInsets.fromLTRB(70, 70, 70, 90),
                        maxZoom: 15,
                      )
                    : CameraFit.bounds(
                        bounds: _LiveOperationsMap._middleEastBounds,
                        padding: const EdgeInsets.fromLTRB(44, 34, 44, 58),
                        minZoom: 3.2,
                        maxZoom: 5.2,
                      ),
                minZoom: 3,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.scrollWheelZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _LiveOperationsMap._hasMapboxToken
                      ? _kMapboxTileUrl
                      : _kEsriTileUrl,
                  fallbackUrl: _kOsmTileUrl,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  additionalOptions: const {'accessToken': _kMapboxAccessToken},
                  userAgentPackageName: 'com.aleppoeats.master',
                  maxNativeZoom: 18,
                  keepBuffer: 1,
                  panBuffer: 0,
                  tileDisplay: const TileDisplay.fadeIn(
                    duration: Duration(milliseconds: 90),
                  ),
                ),
                if (_displayRoutes.any((route) => route.points.length > 1))
                  PolylineLayer(
                    polylines: [
                      for (final route in _displayRoutes)
                        if (route.points.length > 1)
                          Polyline(
                            points: route.points,
                            color: route.color.withValues(alpha: 0.82),
                            strokeWidth: 4,
                            borderColor: Colors.white.withValues(alpha: 0.75),
                            borderStrokeWidth: 1.5,
                          ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (final marker in validMarkers)
                      Marker(
                        point: marker.point,
                        width: 92,
                        height: 58,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: widget.onMarkerTap == null
                              ? null
                              : () => widget.onMarkerTap!(marker),
                          child: _MapMarkerBubble(marker: marker),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (widget.showWeatherBadge)
              const Positioned(
                left: 14,
                top: 14,
                child: _TrackingWeatherBadge(),
              ),
            if (_layerPanelVisible)
              Positioned(top: 14, left: 12, child: _OperationsMapLayerPanel()),
            Positioned(
              right: 12,
              top: 12,
              child: Column(
                children: [
                  _TrackingMapControlButton(
                    icon: Icons.layers_rounded,
                    tooltip: 'الطبقات',
                    onPressed: () {
                      setState(() => _layerPanelVisible = !_layerPanelVisible);
                    },
                  ),
                  const SizedBox(height: 8),
                  _TrackingMapControlButton(
                    icon: Icons.add_rounded,
                    tooltip: 'تكبير',
                    onPressed: () => _zoomBy(1),
                  ),
                  const SizedBox(height: 8),
                  _TrackingMapControlButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'تصغير',
                    onPressed: () => _zoomBy(-1),
                  ),
                  const SizedBox(height: 8),
                  _TrackingMapControlButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'عرض الشرق الأوسط',
                    onPressed: _resetToMiddleEast,
                  ),
                ],
              ),
            ),
            if (validMarkers.isEmpty)
              const Positioned.fill(child: Center(child: _MapEmptyOverlay())),
            const Positioned(left: 12, bottom: 52, child: _MapProviderBadge()),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(child: _OperationsLegendBar()),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationsMapLayerPanel extends StatelessWidget {
  const _OperationsMapLayerPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الطبقات',
            style: TextStyle(
              fontSize: 11.8,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E232A),
              height: 1.0,
            ),
          ),
          SizedBox(height: 8),
          _OpsLayerItem(
            label: 'السائقون',
            icon: Icons.electric_scooter_rounded,
            color: Color(0xFF1E7D3F),
          ),
          _OpsLayerItem(
            label: 'المطاعم',
            icon: Icons.storefront_outlined,
            color: Color(0xFFF59E0B),
          ),
          _OpsLayerItem(
            label: 'الطلبات النشطة',
            icon: Icons.receipt_long_outlined,
            color: Color(0xFF2563EB),
          ),
          _OpsLayerItem(
            label: 'تنبيهات',
            icon: Icons.warning_amber_rounded,
            color: Color(0xFFD92C2C),
          ),
        ],
      ),
    );
  }
}

class _MapMarkerBubble extends StatelessWidget {
  const _MapMarkerBubble({required this.marker});

  final _OperationsMapMarkerData marker;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: marker.color, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(marker.icon, size: 15, color: marker.color),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxWidth: 90),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: marker.color.withValues(alpha: 0.24)),
          ),
          child: Text(
            marker.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.2,
              fontWeight: FontWeight.w800,
              color: marker.color,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapEmptyOverlay extends StatelessWidget {
  const _MapEmptyOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: const Text(
        'لا توجد إحداثيات مباشرة متاحة الآن',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4E5660),
        ),
      ),
    );
  }
}

class _OperationsMapPanel extends StatelessWidget {
  const _OperationsMapPanel({required this.markers});

  final List<_OperationsMapMarkerData> markers;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 274,
      child: _LiveOperationsMap(
        markers: markers,
        showWeatherBadge: false,
        showLayerPanel: true,
      ),
    );
    /*
    return Container(
      height: 274,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _OpsMapBackdropPainter()),
            ),
            Positioned(
              top: 14,
              left: 12,
              child: Container(
                width: 128,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7ECE8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الطبقات',
                      style: TextStyle(
                        fontSize: 11.8,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E232A),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _OpsLayerItem(
                      label: 'السائقون',
                      icon: Icons.electric_scooter_rounded,
                      color: Color(0xFF1E7D3F),
                    ),
                    _OpsLayerItem(
                      label: 'المطاعم',
                      icon: Icons.storefront_outlined,
                      color: Color(0xFFF59E0B),
                    ),
                    _OpsLayerItem(
                      label: 'الطلبات النشطة',
                      icon: Icons.receipt_long_outlined,
                      color: Color(0xFF2563EB),
                    ),
                    _OpsLayerItem(
                      label: 'مناطق الضغط',
                      icon: Icons.local_fire_department_outlined,
                      color: Color(0xFFD92C2C),
                    ),
                    _OpsLayerItem(
                      label: 'نقص في السائقين',
                      icon: Icons.warning_amber_rounded,
                      color: Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7ECE8)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fullscreen_rounded,
                      size: 16,
                      color: Color(0xFF4E5660),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'عرض في الخريطة الكاملة',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4E5660),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 12,
              bottom: 12,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: Color(0xFF4E5660),
                ),
              ),
            ),
            Positioned(
              left: 160,
              top: 82,
              child: _OpsMapMarker(
                label: 'الزبداني',
                icon: Icons.storefront_outlined,
                color: Color(0xFFF59E0B),
              ),
            ),
            Positioned(
              left: 260,
              top: 120,
              child: _OpsMapMarker(
                label: 'جامعة حلب',
                icon: Icons.electric_scooter_rounded,
                color: Color(0xFF1E7D3F),
              ),
            ),
            Positioned(
              left: 480,
              top: 68,
              child: _OpsMapMarker(
                label: 'الزهراء',
                icon: Icons.local_fire_department_outlined,
                color: Color(0xFFD92C2C),
              ),
            ),
            Positioned(
              left: 548,
              top: 150,
              child: _OpsMapMarker(
                label: 'المحطة',
                icon: Icons.delivery_dining_rounded,
                color: Color(0xFF2563EB),
              ),
            ),
            Positioned(
              left: 382,
              top: 214,
              child: _OpsMapMarker(
                label: 'الزرزور',
                icon: Icons.storefront_outlined,
                color: Color(0xFFF59E0B),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(child: _OperationsLegendBar()),
            ),
          ],
        ),
      ),
    );
    */
  }
}

class _MapProviderBadge extends StatelessWidget {
  const _MapProviderBadge();

  @override
  Widget build(BuildContext context) {
    final isMapbox = _kMapboxAccessToken.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        isMapbox ? 'Mapbox | Esri / OpenStreetMap' : 'Esri / OpenStreetMap',
        style: const TextStyle(
          fontSize: 10,
          height: 1,
          color: Color(0xFF4B5563),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OpsLayerItem extends StatelessWidget {
  const _OpsLayerItem({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 10, color: color),
          const SizedBox(width: 6),
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF505862),
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpsMapMarker extends StatelessWidget {
  const _OpsMapMarker({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.2,
            fontWeight: FontWeight.w600,
            color: color,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _OperationsLegendBar extends StatelessWidget {
  const _OperationsLegendBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: const [
          _OpsLegendItem(label: 'سائق متاح', color: Color(0xFF1E7D3F)),
          _OpsLegendItem(label: 'طلب نشط', color: Color(0xFF2563EB)),
          _OpsLegendItem(label: 'مطعم مفتوح', color: Color(0xFFF59E0B)),
          _OpsLegendItem(label: 'منطقة ضغط', color: Color(0xFFD92C2C)),
          _OpsLegendItem(label: 'نقص في السائقين', color: Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}

class _OpsLegendItem extends StatelessWidget {
  const _OpsLegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.1,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4E5660),
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _OpsMapBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF8F8F6), Color(0xFFF1F2EE), Color(0xFFEDEDE9)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, basePaint);

    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFE2E5DE)
      ..strokeWidth = 8;
    final roadThinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFD7DBD3)
      ..strokeWidth = 2;
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFF4F5F1)
      ..strokeWidth = 1;

    for (var i = 0; i < 10; i++) {
      final dx = size.width * (0.08 + i * 0.09);
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (var i = 0; i < 7; i++) {
      final dy = size.height * (0.08 + i * 0.12);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final roads = <Path>[
      Path()
        ..moveTo(size.width * 0.05, size.height * 0.34)
        ..quadraticBezierTo(
          size.width * 0.18,
          size.height * 0.26,
          size.width * 0.30,
          size.height * 0.33,
        )
        ..quadraticBezierTo(
          size.width * 0.44,
          size.height * 0.40,
          size.width * 0.56,
          size.height * 0.34,
        )
        ..quadraticBezierTo(
          size.width * 0.70,
          size.height * 0.28,
          size.width * 0.92,
          size.height * 0.32,
        ),
      Path()
        ..moveTo(size.width * 0.02, size.height * 0.66)
        ..quadraticBezierTo(
          size.width * 0.21,
          size.height * 0.58,
          size.width * 0.38,
          size.height * 0.64,
        )
        ..quadraticBezierTo(
          size.width * 0.54,
          size.height * 0.69,
          size.width * 0.76,
          size.height * 0.61,
        )
        ..quadraticBezierTo(
          size.width * 0.88,
          size.height * 0.56,
          size.width * 0.98,
          size.height * 0.62,
        ),
      Path()
        ..moveTo(size.width * 0.16, size.height * 0.05)
        ..quadraticBezierTo(
          size.width * 0.18,
          size.height * 0.22,
          size.width * 0.22,
          size.height * 0.38,
        )
        ..quadraticBezierTo(
          size.width * 0.27,
          size.height * 0.54,
          size.width * 0.25,
          size.height * 0.92,
        ),
      Path()
        ..moveTo(size.width * 0.48, size.height * 0.05)
        ..quadraticBezierTo(
          size.width * 0.50,
          size.height * 0.25,
          size.width * 0.54,
          size.height * 0.40,
        )
        ..quadraticBezierTo(
          size.width * 0.58,
          size.height * 0.57,
          size.width * 0.57,
          size.height * 0.95,
        ),
      Path()
        ..moveTo(size.width * 0.79, size.height * 0.10)
        ..quadraticBezierTo(
          size.width * 0.76,
          size.height * 0.28,
          size.width * 0.78,
          size.height * 0.46,
        )
        ..quadraticBezierTo(
          size.width * 0.81,
          size.height * 0.70,
          size.width * 0.87,
          size.height * 0.94,
        ),
    ];

    for (final road in roads) {
      canvas.drawPath(road, roadPaint);
      canvas.drawPath(road, roadThinPaint);
    }

    final routeGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF2D6BFF).withValues(alpha: 0.12)
      ..strokeWidth = 8;
    final routePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF2D6BFF)
      ..strokeWidth = 2.6;
    final route = Path()
      ..moveTo(size.width * 0.68, size.height * 0.56)
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.45,
        size.width * 0.81,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.29,
        size.width * 0.90,
        size.height * 0.22,
      );
    canvas.drawPath(route, routeGlowPaint);
    canvas.drawPath(route, routePaint);
    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.22),
      6,
      Paint()..color = const Color(0xFF2D6BFF),
    );
    canvas.drawCircle(
      Offset(size.width * 0.90, size.height * 0.22),
      2.5,
      Paint()..color = Colors.white,
    );

    final spotPaint = Paint()..style = PaintingStyle.fill;
    final spots = <Offset>[
      Offset(size.width * 0.22, size.height * 0.58),
      Offset(size.width * 0.48, size.height * 0.33),
      Offset(size.width * 0.68, size.height * 0.61),
      Offset(size.width * 0.82, size.height * 0.43),
    ];
    final colors = <Color>[
      const Color(0xFFD92C2C).withValues(alpha: 0.10),
      const Color(0xFFF59E0B).withValues(alpha: 0.12),
      const Color(0xFF1E7D3F).withValues(alpha: 0.12),
      const Color(0xFF2563EB).withValues(alpha: 0.10),
    ];
    for (var i = 0; i < spots.length; i++) {
      spotPaint.color = colors[i];
      canvas.drawCircle(spots[i], 28 + (i % 2) * 6, spotPaint);
      spotPaint.color = colors[i].withValues(alpha: 0.18);
      canvas.drawCircle(spots[i], 14, spotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MasterAuthShell extends StatelessWidget {
  const MasterAuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF031F18), Color(0xFF073A2C), Color(0xFF05281F)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _kAuthBackdropAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                opacity: const AlwaysStoppedAnimation(1.0),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.05),
                    radius: 1.25,
                    colors: [Colors.transparent, Colors.transparent],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1240;
                  final maxWidth = constraints.maxWidth > 1600
                      ? 1520.0
                      : constraints.maxWidth;

                  final hero = isWide
                      ? const Expanded(flex: 6, child: _AuthHeroPanelV2())
                      : const SizedBox.shrink();

                  final card = ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(38),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 36,
                            offset: const Offset(0, 24),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(38),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(42, 28, 42, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  _LanguagePill(
                                    label: 'العربية',
                                    icon: Icons.language_rounded,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 27,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF141922),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _AuthSubtitle(text: subtitle),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              child,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );

                  if (isWide) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 46,
                            vertical: 22,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              hero,
                              const SizedBox(width: 24),
                              SizedBox(width: 560, child: card),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _CompactAuthHero(),
                          const SizedBox(height: 16),
                          card,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
