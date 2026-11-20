import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:tks/controler/delivery_controller.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:tks/core/services/mapbox_runtime_config.dart';
import 'package:tks/linkapi/linkapi.dart';

class SelectAddressMap extends StatefulWidget {
  const SelectAddressMap({super.key});

  @override
  State<SelectAddressMap> createState() => _SelectAddressMapState();
}

class _SelectAddressMapState extends State<SelectAddressMap> {
  static const double _initialZoom = 14;
  static const LatLng _cairoCenter = LatLng(30.0444, 31.2357);
  static const String _egyptSearchBbox = '24.5,21.5,37.2,31.9';
  static const String _egyptOsmViewbox = '24.5,31.9,37.2,21.5';
  static const String _nominatimHost = 'nominatim.openstreetmap.org';
  static const String _nominatimUserAgent =
      'FOXA/6.0.4 address-picker (https://savir-technology.online/roaqv2)';

  final Distance _distance = const Distance();
  final http.Client _client = http.Client();
  final fm.MapController _osmMapController = fm.MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late final Future<Uint8List> _selectedMarkerIconFuture;

  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _startMarkerManager;
  PointAnnotationManager? _selectedMarkerManager;
  Cancelable? _selectedMarkerDragSubscription;
  PointAnnotation? _selectedMarkerAnnotation;
  bool _startMarkerDrawn = false;

  LatLng? selectedPoint;
  double? distanceKm;
  int? deliveryPrice;
  String selectedPlaceName = '';
  String selectedAddressLine = '';
  String selectedCity = '';
  String selectedStreet = '';
  bool isResolvingAddress = false;
  bool isSearching = false;
  double _osmZoom = _initialZoom;

  bool get _isMapboxReady => MapboxRuntimeConfig.isConfigured;

  bool get _isArabic => Get.locale?.languageCode == 'ar';

  // The consumer app is restricted to Egypt.
  String get _countryCode => 'EG';

  Map<String, dynamic> get _args {
    final arguments = Get.arguments;
    if (arguments is Map) {
      return Map<String, dynamic>.from(arguments);
    }
    return <String, dynamic>{};
  }

  LatLng get _defaultMapCenter {
    switch (_countryCode) {
      case 'EG':
        return _cairoCenter;
      case 'SA':
        return const LatLng(24.7136, 46.6753);
      case 'JO':
        return const LatLng(31.9539, 35.9106);
      case 'LB':
        return const LatLng(33.8938, 35.5018);
      case 'IQ':
        return const LatLng(33.3152, 44.3661);
      case 'AE':
        return const LatLng(24.4539, 54.3773);
      case 'QA':
        return const LatLng(25.2854, 51.5310);
      case 'KW':
        return const LatLng(29.3759, 47.9774);
      case 'TR':
        return const LatLng(39.9334, 32.8597);
      case 'US':
        return const LatLng(38.9072, -77.0369);
      default:
        return _cairoCenter;
    }
  }

  String get _mode => _args['mode']?.toString() ?? 'address';

  String get _screenTitle => (_args['title']?.toString() ??
          (_mode == 'recipient' ? 'Recipient location' : 'Delivery location'))
      .tr;

  String get _searchHint => _isArabic
      ? '\u0627\u0628\u062d\u062b \u0628\u0627\u0644\u0634\u0627\u0631\u0639 \u0623\u0648 \u0627\u0644\u0645\u0643\u0627\u0646'
      : 'Search by street or place';

  String get _locationSummaryTitle => _isArabic
      ? '\u0645\u0644\u062e\u0635 \u0627\u0644\u0645\u0648\u0642\u0639'
      : 'Location summary';

  String get _addressLabelText =>
      _isArabic ? '\u0627\u0644\u0639\u0646\u0648\u0627\u0646' : 'Address';

  String get _coordinatesLabelText => _isArabic
      ? '\u0627\u0644\u0625\u062d\u062f\u0627\u062b\u064a\u0627\u062a'
      : 'Coordinates';

  String get _distanceLabelText =>
      _isArabic ? '\u0627\u0644\u0645\u0633\u0627\u0641\u0629' : 'Distance';

  String get _deliveryFeeLabelText => _isArabic
      ? '\u0631\u0633\u0648\u0645 \u0627\u0644\u062a\u0648\u0635\u064a\u0644'
      : 'Delivery fee';

  String get _emptySelectionText => _isArabic
      ? '\u0644\u0645 \u064a\u062a\u0645 \u0627\u062e\u062a\u064a\u0627\u0631 \u0645\u0648\u0642\u0639 \u0628\u0639\u062f. \u0627\u0628\u062d\u062b \u0623\u0648 \u0627\u0636\u063a\u0637 \u0639\u0644\u0649 \u0627\u0644\u062e\u0631\u064a\u0637\u0629 \u0644\u062a\u062d\u062f\u064a\u062f \u0627\u0644\u0645\u0643\u0627\u0646.'
      : 'No point selected yet. Search or tap the map to choose the delivery location.';

  String get _resultsTitle => _isArabic
      ? '\u0646\u062a\u0627\u0626\u062c \u0627\u0644\u0628\u062d\u062b'
      : 'Search results';

  String get _dragHint => _isArabic
      ? '\u0627\u0633\u062d\u0628 \u0627\u0644\u062f\u0628\u0648\u0633 \u0644\u062a\u0639\u062f\u064a\u0644 \u0627\u0644\u0645\u0643\u0627\u0646'
      : 'Drag the pin to fine-tune the location';

  String get _confirmLabel =>
      (_args['confirm_label']?.toString() ?? 'Use location').tr;

  bool get _returnOnly => _args['return_only'] == true;

  double? get _referenceLatitudeArg =>
      _parseArgumentDouble('reference_latitude');

  double? get _referenceLongitudeArg =>
      _parseArgumentDouble('reference_longitude');

  bool get _hasExplicitReferencePoint =>
      _referenceLatitudeArg != null && _referenceLongitudeArg != null;

  LatLng get _referencePoint {
    final fallbackPoint = _defaultMapCenter;
    final latitude = _referenceLatitudeArg ??
        _parseArgumentDouble('initial_latitude') ??
        _parseArgumentDouble('latitude') ??
        fallbackPoint.latitude;
    final longitude = _referenceLongitudeArg ??
        _parseArgumentDouble('initial_longitude') ??
        _parseArgumentDouble('longitude') ??
        fallbackPoint.longitude;
    final point = LatLng(latitude, longitude);
    if (_countryCode == 'EG' && !_isWithinEgypt(point)) {
      return _cairoCenter;
    }
    return point;
  }

  bool _isWithinEgypt(LatLng point) {
    return point.latitude >= 21.5 &&
        point.latitude <= 31.9 &&
        point.longitude >= 24.5 &&
        point.longitude <= 37.2;
  }

  @override
  void initState() {
    super.initState();
    _selectedMarkerIconFuture = _buildSelectedMarkerIcon();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _selectedMarkerDragSubscription?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _client.close();
    super.dispose();
  }

  void _onSearchTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapStyleUri =
        MapboxRuntimeConfig.styleUriForBrightness(theme.brightness);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        toolbarHeight: 54,
        title: Text(_screenTitle),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _isMapboxReady
                ? MapWidget(
                    key: ValueKey(
                      'selectAddressMap-${theme.brightness.name}-$mapStyleUri',
                    ),
                    styleUri: mapStyleUri,
                    cameraOptions: CameraOptions(
                      center: Point(
                        coordinates: Position(
                          _referencePoint.longitude,
                          _referencePoint.latitude,
                        ),
                      ),
                      zoom: _initialZoom,
                    ),
                    onMapCreated: _onMapCreated,
                    onStyleLoadedListener: _onStyleLoaded,
                    onTapListener: _onMapTapped,
                  )
                : _OsmMapFallback(
                    controller: _osmMapController,
                    initialCenter: _referencePoint,
                    initialZoom: _osmZoom,
                    selectedPoint: selectedPoint,
                    onTap: (latlng) => _selectMapLocation(
                      latlng,
                      animateCamera: false,
                      resolveAddress: true,
                    ),
                  ),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: _MapSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: _searchHint,
                isSearching: isSearching,
                onSearch: _searchPlaces,
                onClear: () {
                  _searchController.clear();
                  _searchFocusNode.requestFocus();
                },
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 280,
            child: Column(
              children: [
                _FloatingMapButton(
                  icon: Icons.add_rounded,
                  onTap: () => _changeZoom(0.8),
                ),
                const SizedBox(height: 12),
                _FloatingMapButton(
                  icon: Icons.remove_rounded,
                  onTap: () => _changeZoom(-0.8),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: _BottomLocationPanel(
                selectedPoint: selectedPoint,
                distanceKm: distanceKm,
                deliveryPrice: deliveryPrice,
                addressLabel: _selectedAddressLabel,
                coordinates: _selectedCoordinates,
                isResolvingAddress: isResolvingAddress,
                confirmLabel: _confirmLabel,
                locationSummaryTitle: _locationSummaryTitle,
                addressLabelText: _addressLabelText,
                coordinatesLabelText: _coordinatesLabelText,
                distanceLabelText: _distanceLabelText,
                deliveryFeeLabelText: _deliveryFeeLabelText,
                emptySelectionText: _emptySelectionText,
                dragHint: _dragHint,
                showDistanceMetrics: _hasExplicitReferencePoint,
                onConfirm: selectedPoint == null || isResolvingAddress
                    ? null
                    : _confirmAddress,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
  }

  Future<void> _onStyleLoaded(StyleLoadedEventData _) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    await MapboxRuntimeConfig.configureDetailedBasemapStyle(
      mapboxMap.style,
      Theme.of(context).brightness,
    );

    _selectedMarkerDragSubscription?.cancel();
    _selectedMarkerDragSubscription = null;
    _selectedMarkerAnnotation = null;
    _startMarkerDrawn = false;

    _startMarkerManager =
        await mapboxMap.annotations.createCircleAnnotationManager();
    _selectedMarkerManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    _selectedMarkerDragSubscription = _selectedMarkerManager?.dragEvents(
      onEnd: _handleSelectedMarkerDragEnd,
    );

    await _ensureMarkers();
  }

  Future<void> _ensureMarkers() async {
    await _ensureStartMarker();
    await _syncSelectedMarker();
  }

  Future<void> _ensureStartMarker() async {
    final manager = _startMarkerManager;
    if (manager == null || _startMarkerDrawn) {
      return;
    }

    await manager.deleteAll();
    if (!_hasExplicitReferencePoint) {
      _startMarkerDrawn = true;
      return;
    }
    await manager.create(
      CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            _referencePoint.longitude,
            _referencePoint.latitude,
          ),
        ),
        circleColor: const Color(0xFF171717).toARGB32(),
        circleRadius: 9,
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 3,
      ),
    );
    _startMarkerDrawn = true;
  }

  Future<void> _syncSelectedMarker() async {
    final manager = _selectedMarkerManager;
    if (manager == null) {
      return;
    }

    if (selectedPoint == null) {
      if (_selectedMarkerAnnotation != null) {
        try {
          await manager.delete(_selectedMarkerAnnotation!);
        } catch (_) {}
        _selectedMarkerAnnotation = null;
      }
      return;
    }

    final geometry = Point(
      coordinates: Position(selectedPoint!.longitude, selectedPoint!.latitude),
    );

    if (_selectedMarkerAnnotation == null) {
      final options = await _buildSelectedMarkerOptions(geometry);
      _selectedMarkerAnnotation = await manager.create(options);
      return;
    }

    _selectedMarkerAnnotation!.geometry = geometry;
    _selectedMarkerAnnotation!.isDraggable = true;
    await manager.update(_selectedMarkerAnnotation!);
  }

  Future<PointAnnotationOptions> _buildSelectedMarkerOptions(
    Point geometry,
  ) async {
    final image = await _selectedMarkerIconFuture;
    return PointAnnotationOptions(
      geometry: geometry,
      image: image,
      iconAnchor: IconAnchor.BOTTOM,
      iconSize: 0.85,
      isDraggable: true,
    );
  }

  Future<Uint8List> _buildSelectedMarkerIcon() async {
    const double canvasSize = 128;
    const Color brandOrange = Color(0xFFFF6500);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(
      const Offset(canvasSize / 2, canvasSize * 0.72),
      24,
      shadowPaint,
    );

    final iconPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(Icons.location_on_rounded.codePoint),
        style: TextStyle(
          fontSize: 92,
          fontFamily: Icons.location_on_rounded.fontFamily,
          package: Icons.location_on_rounded.fontPackage,
          foreground: Paint()..color = brandOrange,
        ),
      ),
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(
        (canvasSize - iconPainter.width) / 2,
        2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _onMapTapped(MapContentGestureContext context) async {
    final position = context.point.coordinates;
    final latlng = LatLng(position.lat.toDouble(), position.lng.toDouble());
    await _selectMapLocation(
      latlng,
      animateCamera: true,
      resolveAddress: true,
    );
  }

  Future<void> _handleSelectedMarkerDragEnd(PointAnnotation annotation) async {
    final coordinates = annotation.geometry.coordinates;
    final latlng =
        LatLng(coordinates.lat.toDouble(), coordinates.lng.toDouble());
    await _selectMapLocation(
      latlng,
      animateCamera: false,
      resolveAddress: true,
    );
  }

  Future<void> _changeZoom(double delta) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      if (!_isMapboxReady) {
        final nextZoom = (_osmZoom + delta).clamp(3.0, 19.0).toDouble();
        setState(() {
          _osmZoom = nextZoom;
        });
        try {
          _osmMapController.move(_osmMapController.camera.center, nextZoom);
        } catch (_) {}
      }
      return;
    }

    final cameraState = await mapboxMap.getCameraState();
    await mapboxMap.easeTo(
      CameraOptions(
        center: cameraState.center,
        zoom: (cameraState.zoom + delta).clamp(3, 19),
        bearing: cameraState.bearing,
        pitch: cameraState.pitch,
        padding: cameraState.padding,
      ),
      MapAnimationOptions(duration: 250),
    );
  }

  Future<void> _moveCameraTo(
    LatLng latlng, {
    double zoom = 15.5,
  }) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      if (!_isMapboxReady) {
        setState(() {
          _osmZoom = zoom;
        });
        try {
          _osmMapController.move(latlng, zoom);
        } catch (_) {}
      }
      return;
    }

    await mapboxMap.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(latlng.longitude, latlng.latitude),
        ),
        zoom: zoom,
        padding: MbxEdgeInsets(
          top: 120,
          left: 24,
          bottom: 260,
          right: 24,
        ),
      ),
      MapAnimationOptions(duration: 700),
    );
  }

  Future<void> _searchPlaces() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || isSearching) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      isSearching = true;
    });

    final results = await _searchHybridPlaces(query);
    if (!mounted) {
      return;
    }

    setState(() {
      isSearching = false;
    });

    if (results.isEmpty) {
      Get.snackbar(
        _isArabic
            ? '\u0644\u0627 \u062a\u0648\u062c\u062f \u0646\u062a\u0627\u0626\u062c'
            : 'No results found',
        _isArabic
            ? '\u062c\u0631\u0628 \u0627\u0633\u0645 \u0634\u0627\u0631\u0639 \u0623\u0648 \u062d\u064a \u0623\u0648 \u0645\u062f\u064a\u0646\u0629 \u0623\u062e\u0631\u0649.'
            : 'Try another street, area, or city name.',
      );
      return;
    }

    if (results.length == 1 &&
        _shouldAutoSelectSingleResult(query, results.first)) {
      await _selectSearchResult(results.first);
      return;
    }

    final selected = await _showSearchResults(results);
    if (selected != null) {
      await _selectSearchResult(selected);
    }
  }

  Future<void> _selectSearchResult(_MapSearchResult result) async {
    await _selectMapLocation(
      result.point,
      animateCamera: true,
      resolveAddress: false,
      resolvedLocation: result.toResolvedLocation(),
    );
  }

  Future<void> _selectMapLocation(
    LatLng latlng, {
    required bool animateCamera,
    required bool resolveAddress,
    _ResolvedMapLocation? resolvedLocation,
  }) async {
    final distance =
        _distance.as(LengthUnit.Kilometer, _referencePoint, latlng);

    final fallbackPrice = _calculateDeliveryPrice(distance);
    setState(() {
      selectedPoint = latlng;
      distanceKm = distance;
      deliveryPrice = fallbackPrice;

      if (resolvedLocation != null) {
        selectedPlaceName = resolvedLocation.placeName;
        selectedAddressLine = resolvedLocation.addressLine;
        selectedCity = resolvedLocation.city;
        selectedStreet = resolvedLocation.street;
        isResolvingAddress = false;
      } else {
        selectedPlaceName = '';
        selectedAddressLine = '';
        selectedCity = '';
        selectedStreet = '';
        isResolvingAddress = resolveAddress;
      }
    });

    final serverPrice = await _fetchDeliveryPrice(distance);
    if (mounted && selectedPoint == latlng) {
      setState(() => deliveryPrice = serverPrice ?? fallbackPrice);
    }

    await _syncSelectedMarker();

    if (animateCamera) {
      await _moveCameraTo(latlng);
    }

    if (!resolveAddress || resolvedLocation != null) {
      return;
    }

    final resolved = await _reverseGeocode(latlng);
    if (!mounted || !_isSamePoint(selectedPoint, latlng)) {
      return;
    }

    setState(() {
      selectedPlaceName = resolved.placeName;
      selectedAddressLine = resolved.addressLine;
      selectedCity = resolved.city;
      selectedStreet = resolved.street;
      isResolvingAddress = false;
    });
  }

  Future<List<_MapSearchResult>> _searchHybridPlaces(String query) async {
    final biasPoint = selectedPoint ?? _referencePoint;
    final mapboxResults = await _searchMapboxPlaces(query);
    final shouldUseOsm = mapboxResults.length < 4 || !_isMapboxReady;

    if (!shouldUseOsm) {
      return mapboxResults;
    }

    final osmResults = await _searchOsmPlaces(query);
    final merged = <_MapSearchResult>[];

    void addCandidate(_MapSearchResult candidate) {
      final isDuplicate = merged.any((existing) {
        final distanceMeters = _distance.as(
          LengthUnit.Meter,
          existing.point,
          candidate.point,
        );
        if (distanceMeters <= 80) {
          return true;
        }

        final existingText = _normalizeResultText(
          '${existing.title} ${existing.subtitle}',
        );
        final candidateText = _normalizeResultText(
          '${candidate.title} ${candidate.subtitle}',
        );
        return existingText.isNotEmpty && existingText == candidateText;
      });

      if (!isDuplicate && _isRelevantEgyptSearchResult(candidate, biasPoint)) {
        merged.add(candidate);
      }
    }

    for (final result in mapboxResults) {
      addCandidate(result);
    }
    for (final result in osmResults) {
      addCandidate(result);
    }

    _prioritizeSearchResults(merged, query);
    return merged.take(18).toList();
  }

  Future<List<_MapSearchResult>> _searchMapboxPlaces(String query) async {
    final token = MapboxRuntimeConfig.accessToken;
    if (token.isEmpty) {
      return [];
    }

    final biasPoint = selectedPoint ?? _referencePoint;
    final results = <_MapSearchResult>[];
    final seenKeys = <String>{};

    for (final searchQuery in _buildSearchQueries(query)) {
      await _collectSearchResults(
        query: searchQuery,
        token: token,
        biasPoint: biasPoint,
        seenKeys: seenKeys,
        results: results,
        useEgyptBbox: false,
      );
    }

    _prioritizeSearchResults(results, query);
    return results;
  }

  Future<List<_MapSearchResult>> _searchOsmPlaces(String query) async {
    final biasPoint = selectedPoint ?? _referencePoint;
    final results = <_MapSearchResult>[];
    final seenKeys = <String>{};

    for (final searchQuery in _buildSearchQueries(query)) {
      await _collectOsmSearchResults(
        query: searchQuery,
        seenKeys: seenKeys,
        results: results,
        useEgyptBbox: false,
      );
    }

    final filtered = results
        .where((result) => _isRelevantEgyptSearchResult(result, biasPoint))
        .toList();
    _prioritizeSearchResults(filtered, query);
    return filtered;
  }

  Future<void> _collectOsmSearchResults({
    required String query,
    required Set<String> seenKeys,
    required List<_MapSearchResult> results,
    required bool useEgyptBbox,
  }) async {
    final parameters = <String, String>{
      'format': 'jsonv2',
      'q': query,
      'limit': '10',
      'addressdetails': '1',
      'namedetails': '1',
      'accept-language': _osmLanguage,
      if (_countryCode.isNotEmpty) 'countrycodes': _countryCode.toLowerCase(),
      if (useEgyptBbox && _countryCode == 'EG') ...{
        'viewbox': _egyptOsmViewbox,
        'bounded': '1',
      },
    };

    try {
      final response = await _client.get(
        Uri.https(_nominatimHost, '/search', parameters),
        headers: _osmHeaders,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return;
      }

      for (final place in decoded.whereType<Map>()) {
        final result = _osmSearchResultFromPlace(
          Map<String, dynamic>.from(place),
        );
        if (result == null) {
          continue;
        }

        final key =
            '${result.point.latitude.toStringAsFixed(6)},${result.point.longitude.toStringAsFixed(6)}|${_normalizeResultText(result.title)}';
        if (seenKeys.add(key)) {
          results.add(result);
        }
      }
    } catch (_) {
      return;
    }
  }

  _MapSearchResult? _osmSearchResultFromPlace(Map<String, dynamic> place) {
    final lat = _parseOsmDouble(place['lat']);
    final lon = _parseOsmDouble(place['lon']);
    if (lat == null || lon == null) {
      return null;
    }

    final point = LatLng(lat, lon);
    final resolved = _resolveOsmLocation(place, point);
    return _MapSearchResult(
      point: point,
      placeName: resolved.placeName,
      addressLine: resolved.addressLine,
      city: resolved.city,
      street: resolved.street,
    );
  }

  Future<_ResolvedMapLocation?> _reverseGeocodeOsm(LatLng latlng) async {
    final uri = Uri.https(
      _nominatimHost,
      '/reverse',
      <String, String>{
        'format': 'jsonv2',
        'lat': latlng.latitude.toString(),
        'lon': latlng.longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
        'namedetails': '1',
        'accept-language': _osmLanguage,
      },
    );

    try {
      final response = await _client.get(uri, headers: _osmHeaders);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return _resolveOsmLocation(decoded, latlng);
    } catch (_) {
      return null;
    }
  }

  _ResolvedMapLocation _resolveOsmLocation(
    Map<String, dynamic> place,
    LatLng fallbackPoint,
  ) {
    final coordinatesLabel =
        '${fallbackPoint.latitude.toStringAsFixed(5)}, ${fallbackPoint.longitude.toStringAsFixed(5)}';
    final address = place['address'] is Map
        ? Map<String, dynamic>.from(place['address'] as Map)
        : <String, dynamic>{};
    final namedetails = place['namedetails'] is Map
        ? Map<String, dynamic>.from(place['namedetails'] as Map)
        : <String, dynamic>{};

    final displayName = _osmString(place, 'display_name');
    final displayParts = displayName
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final fallbackName =
        displayParts.isNotEmpty ? displayParts.first : coordinatesLabel;

    final street = _firstNonEmpty([
      _osmString(address, 'road'),
      _osmString(address, 'pedestrian'),
      _osmString(address, 'residential'),
      _osmString(address, 'footway'),
      _osmString(address, 'neighbourhood'),
      _osmString(address, 'suburb'),
      _osmString(address, 'quarter'),
      _osmString(address, 'city_district'),
    ]);

    final city = _firstNonEmpty([
      _osmString(address, 'city'),
      _osmString(address, 'town'),
      _osmString(address, 'village'),
      _osmString(address, 'municipality'),
      _osmString(address, 'county'),
      _osmString(address, 'state'),
    ]);

    final placeName = _firstNonEmpty([
      _osmString(place, 'name'),
      _osmString(namedetails, 'name:ar'),
      _osmString(namedetails, 'name:en'),
      _osmString(address, 'neighbourhood'),
      _osmString(address, 'suburb'),
      _osmString(address, 'quarter'),
      _osmString(address, 'city_district'),
      street,
      fallbackName,
    ]);

    final addressLine = _firstNonEmpty([
      _joinUniqueAddressParts([
        street,
        _osmString(address, 'neighbourhood'),
        _osmString(address, 'suburb'),
        city,
      ]),
      displayName,
      placeName,
    ]);

    return _ResolvedMapLocation(
      placeName: placeName.isNotEmpty ? placeName : coordinatesLabel,
      addressLine: addressLine,
      city: city,
      street: street,
    );
  }

  String _joinUniqueAddressParts(List<String> parts) {
    final seen = <String>{};
    final filtered = <String>[];
    for (final part in parts) {
      final trimmed = part.trim();
      final normalized = _normalizeResultText(trimmed);
      if (trimmed.isNotEmpty && seen.add(normalized)) {
        filtered.add(trimmed);
      }
    }
    return filtered.join(' - ');
  }

  Map<String, String> get _osmHeaders => const {
        'User-Agent': _nominatimUserAgent,
        'Accept': 'application/json',
      };

  String get _osmLanguage => _isArabic ? 'ar,en' : 'en,ar';

  String _osmString(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  double? _parseOsmDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('${value ?? ''}'.trim());
  }

  String _normalizeResultText(String value) {
    var text = value.toLowerCase().trim();
    text = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    const replacements = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ٱ': 'ا',
      'ى': 'ي',
      'ة': 'ه',
      'ؤ': 'و',
      'ئ': 'ي',
    };
    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text.replaceAll(RegExp(r'[\s,\-،]+'), ' ').trim();
  }

  Future<void> _collectSearchResults({
    required String query,
    required String token,
    required LatLng biasPoint,
    required Set<String> seenKeys,
    required List<_MapSearchResult> results,
    required bool useEgyptBbox,
  }) async {
    final uri = Uri.https(
      'api.mapbox.com',
      '/search/geocode/v6/forward',
      <String, String>{
        'q': query,
        'limit': '10',
        'autocomplete': 'true',
        'types':
            'address,street,place,locality,neighborhood,district,region,postcode',
        'country': _countryCode,
        'language': _searchLanguageForQuery(query),
        'worldview': _searchWorldviewForQuery(query),
        'proximity': '${biasPoint.longitude},${biasPoint.latitude}',
        if (useEgyptBbox && _countryCode == 'EG') 'bbox': _egyptSearchBbox,
        'access_token': token,
      },
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final features = (decoded['features'] as List?) ?? const [];
      for (final feature in features.whereType<Map>()) {
        final result = _mapSearchResultFromFeature(
          Map<String, dynamic>.from(feature),
        );
        if (result == null) {
          continue;
        }

        final key =
            '${result.point.latitude.toStringAsFixed(6)},${result.point.longitude.toStringAsFixed(6)}|${result.placeName}';
        if (seenKeys.add(key)) {
          results.add(result);
        }
      }
    } catch (_) {
      return;
    }
  }

  String _searchLanguageForQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return _isArabic ? 'ar,en' : 'en,ar';
    }

    final containsArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed);
    final containsLatin = RegExp(r'[A-Za-z]').hasMatch(trimmed);

    if (containsArabic && !containsLatin) {
      return 'ar,en';
    }

    if (containsLatin && !containsArabic) {
      return 'en,ar';
    }

    return _isArabic ? 'ar,en' : 'en,ar';
  }

  String _searchWorldviewForQuery(String query) {
    return 'us';
  }

  List<String> _buildSearchQueries(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final normalized = _normalizeStreetQuery(trimmed);
    final queries = <String>[];

    void addQuery(String value) {
      final candidate = value.trim();
      if (candidate.isEmpty || queries.contains(candidate)) {
        return;
      }
      queries.add(candidate);
    }

    addQuery(trimmed);
    if (normalized.isNotEmpty) {
      addQuery(normalized);
    }

    return queries;
  }

  bool _shouldAutoSelectSingleResult(String query, _MapSearchResult result) {
    return true;
  }

  bool _isRelevantEgyptSearchResult(
    _MapSearchResult result,
    LatLng biasPoint,
  ) {
    final distanceKm =
        _distance.as(LengthUnit.Kilometer, biasPoint, result.point);
    return _countryCode != 'EG' || distanceKm <= 250;
  }

  void _prioritizeSearchResults(List<_MapSearchResult> results, String query) {
    if (results.length < 2) {
      return;
    }

    final queryTokens = _normalizeResultText(query)
        .split(RegExp(r'[\s,،-]+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toSet();

    int scoreResult(_MapSearchResult result) {
      final haystack = _normalizeResultText(
          '${result.placeName} ${result.addressLine} ${result.city} ${result.street}');
      var score = 0;

      for (final token in queryTokens) {
        if (token.length < 2) {
          continue;
        }
        if (haystack.contains(token)) {
          score += 5;
        }
      }

      return score;
    }

    results.sort((a, b) => scoreResult(b).compareTo(scoreResult(a)));
  }

  String _normalizeStreetQuery(String query) {
    final normalized = query
        .replaceFirst(
          RegExp(
            r'^(?:شارع|ش\.?|street|st\.?|road|rd\.?|avenue|ave\.?|lane|ln\.?|roadway|boulevard|blvd\.?|way|district|area|neighborhood|حي|منطقة|ميدان)\s+',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return normalized;
  }

  _MapSearchResult? _mapSearchResultFromFeature(Map<String, dynamic> feature) {
    final coordinates = _extractFeatureCoordinates(feature);
    if (coordinates == null) {
      return null;
    }

    final point = coordinates;
    final resolved = _resolveFeatureLocation(feature, point);
    return _MapSearchResult(
      point: point,
      placeName: resolved.placeName,
      addressLine: resolved.addressLine,
      city: resolved.city,
      street: resolved.street,
    );
  }

  Future<_ResolvedMapLocation> _reverseGeocode(LatLng latlng) async {
    final mapboxResolved = await _reverseGeocodeMapbox(latlng);

    if (_hasResolvedAddress(mapboxResolved, latlng)) {
      return mapboxResolved;
    }

    final osmResolved = await _reverseGeocodeOsm(latlng);
    if (osmResolved != null && _hasResolvedAddress(osmResolved, latlng)) {
      return _mergeResolvedLocations(osmResolved, mapboxResolved);
    }

    return mapboxResolved;
  }

  Future<_ResolvedMapLocation> _reverseGeocodeMapbox(LatLng latlng) async {
    final token = MapboxRuntimeConfig.accessToken;
    if (token.isEmpty) {
      return _coordinateResolvedLocation(latlng);
    }

    final uri = Uri.parse(
      'https://api.mapbox.com/search/geocode/v6/reverse'
      '?longitude=${latlng.longitude}'
      '&latitude=${latlng.latitude}'
      '&limit=1'
      '&country=$_countryCode'
      '&types=address,street,place,locality,neighborhood,district,region,postcode'
      '&language=${_isArabic ? 'ar,en' : 'en,ar'}'
      '&worldview=${_isArabic ? 'ar' : 'us'}'
      '&access_token=$token',
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _coordinateResolvedLocation(latlng);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return _coordinateResolvedLocation(latlng);
      }

      final features = (decoded['features'] as List?) ?? const [];
      if (features.isEmpty || features.first is! Map) {
        return _coordinateResolvedLocation(latlng);
      }

      return _resolveFeatureLocation(
        Map<String, dynamic>.from(features.first as Map),
        latlng,
      );
    } catch (_) {
      return _coordinateResolvedLocation(latlng);
    }
  }

  _ResolvedMapLocation _coordinateResolvedLocation(LatLng latlng) {
    return _ResolvedMapLocation(
      placeName:
          '${latlng.latitude.toStringAsFixed(5)}, ${latlng.longitude.toStringAsFixed(5)}',
      addressLine: '',
      city: '',
      street: '',
    );
  }

  bool _hasResolvedAddress(_ResolvedMapLocation location, LatLng point) {
    if (location.addressLine.trim().isNotEmpty ||
        location.city.trim().isNotEmpty ||
        location.street.trim().isNotEmpty) {
      return true;
    }

    final coordinateLabel =
        '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    final placeName = location.placeName.trim();
    return placeName.isNotEmpty &&
        placeName != coordinateLabel &&
        !RegExp(r'^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$').hasMatch(placeName);
  }

  _ResolvedMapLocation _mergeResolvedLocations(
    _ResolvedMapLocation primary,
    _ResolvedMapLocation fallback,
  ) {
    return _ResolvedMapLocation(
      placeName: _firstNonEmpty([primary.placeName, fallback.placeName]),
      addressLine: _firstNonEmpty([primary.addressLine, fallback.addressLine]),
      city: _firstNonEmpty([primary.city, fallback.city]),
      street: _firstNonEmpty([primary.street, fallback.street]),
    );
  }

  _ResolvedMapLocation _resolveFeatureLocation(
    Map<String, dynamic> feature,
    LatLng fallbackPoint,
  ) {
    final coordinatesLabel =
        '${fallbackPoint.latitude.toStringAsFixed(5)}, ${fallbackPoint.longitude.toStringAsFixed(5)}';
    final properties = _featureProperties(feature);
    final placeName = _firstNonEmpty([
      _featureString(properties, 'name'),
      _featureString(properties, 'full_address'),
      _featureString(properties, 'place_formatted'),
      _featureString(feature, 'place_name'),
      _featureString(feature, 'text'),
    ]);
    final street = _extractStreet(feature);
    final city = _extractCity(feature);
    final addressLine =
        _extractAddressLine(feature, properties, street, placeName);

    return _ResolvedMapLocation(
      placeName: placeName.isNotEmpty ? placeName : coordinatesLabel,
      addressLine: addressLine,
      city: city,
      street: street,
    );
  }

  String _extractStreet(Map<String, dynamic> feature) {
    final properties = _featureProperties(feature);
    final context = _featureContext(feature);

    final addressNumber = _firstNonEmpty([
      _featureString(properties, 'address'),
      _featureString(feature, 'address'),
      _nestedFeatureString(context, 'address', 'address_number'),
    ]);
    final primaryText = _firstNonEmpty([
      _featureString(properties, 'text'),
      _featureString(feature, 'text'),
      _nestedFeatureString(context, 'street', 'name'),
      _nestedFeatureString(context, 'address', 'street_name'),
    ]);

    if (addressNumber.isNotEmpty && primaryText.isNotEmpty) {
      return '$addressNumber $primaryText';
    }
    if (primaryText.isNotEmpty) {
      return primaryText;
    }
    if (addressNumber.isNotEmpty) {
      return addressNumber;
    }
    return '';
  }

  String _extractCity(Map<String, dynamic> feature) {
    final context = _featureContext(feature);
    if (context is Map) {
      return _firstNonEmpty([
        _nestedFeatureString(context, 'place', 'name'),
        _nestedFeatureString(context, 'locality', 'name'),
        _nestedFeatureString(context, 'district', 'name'),
        _nestedFeatureString(context, 'region', 'name'),
        _nestedFeatureString(context, 'neighborhood', 'name'),
      ]);
    }

    if (context is List) {
      String? findByPrefix(List<String> prefixes) {
        for (final entry in context.whereType<Map>()) {
          final id = '${entry['id'] ?? ''}';
          if (prefixes.any((prefix) => id.startsWith(prefix))) {
            final text = '${entry['text'] ?? ''}'.trim();
            if (text.isNotEmpty) {
              return text;
            }
          }
        }
        return null;
      }

      return findByPrefix([
            'place.',
            'locality.',
            'district.',
            'region.',
            'neighborhood.',
          ]) ??
          '';
    }

    return '';
  }

  String _extractAddressLine(
    Map<String, dynamic> feature,
    Map<String, dynamic> properties,
    String street,
    String placeName,
  ) {
    final placeFormatted = _featureString(properties, 'place_formatted');
    if (placeFormatted.isNotEmpty) {
      return placeFormatted;
    }

    final fullAddress = _featureString(properties, 'full_address');
    if (fullAddress.isNotEmpty) {
      return fullAddress;
    }

    if (street.trim().isNotEmpty) {
      return street.trim();
    }
    if (placeName.trim().isNotEmpty) {
      final parts = placeName
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        return parts.take(2).join(' - ');
      }
    }
    return _featureString(feature, 'text');
  }

  Map<String, dynamic> _featureProperties(Map<String, dynamic> feature) {
    final properties = feature['properties'];
    if (properties is Map) {
      return Map<String, dynamic>.from(properties);
    }
    return feature;
  }

  dynamic _featureContext(Map<String, dynamic> feature) {
    final properties = feature['properties'];
    if (properties is Map) {
      final context = properties['context'];
      if (context != null) {
        return context;
      }
    }
    return feature['context'];
  }

  LatLng? _extractFeatureCoordinates(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    if (geometry is Map) {
      final coordinates = geometry['coordinates'];
      if (coordinates is List && coordinates.length >= 2) {
        final lng = (coordinates[0] as num?)?.toDouble();
        final lat = (coordinates[1] as num?)?.toDouble();
        if (lng != null && lat != null) {
          return LatLng(lat, lng);
        }
      }
    }

    final center = feature['center'];
    if (center is List && center.length >= 2) {
      final lng = (center[0] as num?)?.toDouble();
      final lat = (center[1] as num?)?.toDouble();
      if (lng != null && lat != null) {
        return LatLng(lat, lng);
      }
    }

    final coordinates = feature['coordinates'];
    if (coordinates is List && coordinates.length >= 2) {
      final lng = (coordinates[0] as num?)?.toDouble();
      final lat = (coordinates[1] as num?)?.toDouble();
      if (lng != null && lat != null) {
        return LatLng(lat, lng);
      }
    }

    if (coordinates is Map) {
      final lng = _featureDouble(coordinates, 'longitude') ??
          _featureDouble(coordinates, 'lon');
      final lat = _featureDouble(coordinates, 'latitude') ??
          _featureDouble(coordinates, 'lat');
      if (lng != null && lat != null) {
        return LatLng(lat, lng);
      }
    }

    final properties = feature['properties'];
    if (properties is Map) {
      final coords = properties['coordinates'];
      if (coords is Map) {
        final lng = _featureDouble(coords, 'longitude') ??
            _featureDouble(coords, 'lon');
        final lat =
            _featureDouble(coords, 'latitude') ?? _featureDouble(coords, 'lat');
        if (lng != null && lat != null) {
          return LatLng(lat, lng);
        }
      }
    }

    return null;
  }

  String _featureString(Map<String, dynamic> feature, String key) {
    final value = feature[key];
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  String _nestedFeatureString(
    dynamic context,
    String outerKey,
    String innerKey,
  ) {
    if (context is! Map) {
      return '';
    }
    final outer = context[outerKey];
    if (outer is Map) {
      final value = outer[innerKey];
      if (value != null) {
        return value.toString().trim();
      }
    }
    return '';
  }

  double? _featureDouble(Map<dynamic, dynamic> feature, String key) {
    final value = feature[key];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('${value ?? ''}'.trim());
  }

  void _confirmAddress() {
    if (selectedPoint == null ||
        distanceKm == null ||
        deliveryPrice == null ||
        isResolvingAddress) {
      return;
    }
    final result = _buildSelectionResult();
    if (!_returnOnly && Get.isRegistered<DeliveryController>()) {
      Get.find<DeliveryController>().setDeliveryData(
        selectedPoint!,
        distanceKm!,
        deliveryPrice!,
      );
    }
    Get.back(result: result);
  }

  int _calculateDeliveryPrice(double distanceKm) {
    final blocks = (distanceKm / 5).ceil();
    return blocks * 7;
  }

  Future<int?> _fetchDeliveryPrice(double distanceKm) async {
    try {
      final response = await _client.post(
        Uri.parse(AppLink.deliveryPricing),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'distance_km': distanceKm.toString()},
      );
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final data = decoded is Map ? decoded['data'] : null;
      final fee = data is Map ? data['delivery_fee'] : null;
      final value = fee is num ? fee.toDouble() : double.tryParse('$fee');
      return value == null ? null : value.round();
    } catch (_) {
      return null;
    }
  }

  String get _selectedCoordinates {
    if (selectedPoint == null) {
      return '';
    }
    return '${selectedPoint!.latitude.toStringAsFixed(5)}, ${selectedPoint!.longitude.toStringAsFixed(5)}';
  }

  String get _selectedAddressLabel {
    final parts = <String>[
      if (selectedPlaceName.trim().isNotEmpty) selectedPlaceName.trim(),
      if (selectedAddressLine.trim().isNotEmpty) selectedAddressLine.trim(),
      if (selectedCity.trim().isNotEmpty) selectedCity.trim(),
    ];
    if (parts.isEmpty) {
      return selectedPoint == null ? _emptySelectionText : _selectedCoordinates;
    }
    return parts.join(' - ');
  }

  Map<String, dynamic> _buildSelectionResult() {
    return {
      'latitude': selectedPoint?.latitude,
      'longitude': selectedPoint?.longitude,
      'place_name': selectedPlaceName,
      'address_line': selectedAddressLine,
      'city': selectedCity,
      'street': selectedStreet,
      'coordinates': _selectedCoordinates,
      'distance_km': distanceKm,
      'delivery_price': deliveryPrice,
    };
  }

  double? _parseArgumentDouble(String key) {
    final value = _args[key];
    if (value is num) {
      return value.toDouble();
    }

    if (value == null) {
      return null;
    }

    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return double.tryParse(text);
  }

  bool _isSamePoint(LatLng? a, LatLng b) {
    if (a == null) {
      return false;
    }
    return (a.latitude - b.latitude).abs() < 0.000001 &&
        (a.longitude - b.longitude).abs() < 0.000001;
  }

  Future<_MapSearchResult?> _showSearchResults(
    List<_MapSearchResult> results,
  ) {
    final height = math
        .min(
          MediaQuery.of(context).size.height * 0.7,
          results.length * 84.0 + 84.0,
        )
        .toDouble();

    return showModalBottomSheet<_MapSearchResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _resultsTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: height,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final result = results[index];
                      return _SearchResultTile(
                        result: result,
                        onTap: () => Navigator.of(sheetContext).pop(result),
                      );
                    },
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

class _MapSearchResult {
  const _MapSearchResult({
    required this.point,
    required this.placeName,
    required this.addressLine,
    required this.city,
    required this.street,
  });

  final LatLng point;
  final String placeName;
  final String addressLine;
  final String city;
  final String street;

  String get title {
    final candidate =
        street.trim().isNotEmpty ? street.trim() : placeName.trim();
    if (candidate.isEmpty) {
      return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    }
    return candidate;
  }

  String get subtitle {
    final parts = <String>[
      if (addressLine.trim().isNotEmpty) addressLine.trim(),
      if (city.trim().isNotEmpty) city.trim(),
    ];
    if (parts.isNotEmpty) {
      return parts.join(' - ');
    }
    return placeName.trim();
  }

  _ResolvedMapLocation toResolvedLocation() {
    return _ResolvedMapLocation(
      placeName: placeName,
      addressLine: addressLine,
      city: city,
      street: street,
    );
  }
}

class _ResolvedMapLocation {
  const _ResolvedMapLocation({
    required this.placeName,
    required this.addressLine,
    required this.city,
    required this.street,
  });

  final String placeName;
  final String addressLine;
  final String city;
  final String street;
}

class _MapSearchBar extends StatelessWidget {
  const _MapSearchBar({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.isSearching,
    required this.onSearch,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool isSearching;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasText = controller.text.trim().isNotEmpty;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: SizedBox(
        height: 56,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.48),
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFFFF6500),
            ),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 52, minHeight: 44),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasText)
                  IconButton(
                    tooltip: 'Clear'.tr,
                    onPressed: onClear,
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: _SearchActionButton(
                    isSearching: isSearching,
                    onTap: onSearch,
                  ),
                ),
              ],
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
          ),
        ),
      ),
    );
  }
}

class _SearchActionButton extends StatelessWidget {
  const _SearchActionButton({
    required this.isSearching,
    required this.onTap,
  });

  final bool isSearching;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = Get.locale?.languageCode == 'ar';
    return Material(
      color: const Color(0xFFFF6500),
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: isSearching ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 88,
          height: 42,
          child: isSearching
              ? const Padding(
                  padding: EdgeInsets.all(11),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isArabic ? 'بحث' : 'Search',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
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

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.result,
    required this.onTap,
  });

  final _MapSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6500).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.place_outlined,
                  color: Color(0xFFFF6500),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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

class _BottomLocationPanel extends StatelessWidget {
  const _BottomLocationPanel({
    required this.selectedPoint,
    required this.distanceKm,
    required this.deliveryPrice,
    required this.addressLabel,
    required this.coordinates,
    required this.isResolvingAddress,
    required this.onConfirm,
    required this.confirmLabel,
    required this.locationSummaryTitle,
    required this.addressLabelText,
    required this.coordinatesLabelText,
    required this.distanceLabelText,
    required this.deliveryFeeLabelText,
    required this.emptySelectionText,
    required this.dragHint,
    required this.showDistanceMetrics,
  });

  final LatLng? selectedPoint;
  final double? distanceKm;
  final int? deliveryPrice;
  final String addressLabel;
  final String coordinates;
  final bool isResolvingAddress;
  final VoidCallback? onConfirm;
  final String confirmLabel;
  final String locationSummaryTitle;
  final String addressLabelText;
  final String coordinatesLabelText;
  final String distanceLabelText;
  final String deliveryFeeLabelText;
  final String emptySelectionText;
  final String dragHint;
  final bool showDistanceMetrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = selectedPoint != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            locationSummaryTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (hasSelection) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6500).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF6500).withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addressLabelText,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFFF6500),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    addressLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (dragHint.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      dragHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: coordinatesLabelText,
                  value: coordinates.isNotEmpty
                      ? coordinates
                      : '${selectedPoint!.latitude.toStringAsFixed(5)}, ${selectedPoint!.longitude.toStringAsFixed(5)}',
                ),
                if (showDistanceMetrics) ...[
                  _InfoChip(
                    label: distanceLabelText,
                    value: '${distanceKm?.toStringAsFixed(2) ?? '--'} km',
                  ),
                  _InfoChip(
                    label: deliveryFeeLabelText,
                    value: '${deliveryPrice ?? 0} ${AppCurrency.code}',
                  ),
                ],
              ],
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                emptySelectionText,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isResolvingAddress ? null : onConfirm,
              icon: isResolvingAddress
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(confirmLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6500),
                foregroundColor: Colors.white,
                minimumSize: const ui.Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingMapButton extends StatelessWidget {
  const _FloatingMapButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 8,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            icon,
            color: const Color(0xFFFF6500),
          ),
        ),
      ),
    );
  }
}

class _OsmMapFallback extends StatelessWidget {
  const _OsmMapFallback({
    required this.controller,
    required this.initialCenter,
    required this.initialZoom,
    required this.selectedPoint,
    required this.onTap,
  });

  final fm.MapController controller;
  final LatLng initialCenter;
  final double initialZoom;
  final LatLng? selectedPoint;
  final ValueChanged<LatLng> onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        fm.FlutterMap(
          mapController: controller,
          options: fm.MapOptions(
            initialCenter: initialCenter,
            initialZoom: initialZoom,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: const fm.InteractionOptions(
              flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
            ),
            onTap: (_, point) => onTap(point),
          ),
          children: [
            fm.TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.alepoo.eats',
              maxZoom: 19,
            ),
            if (selectedPoint != null)
              fm.MarkerLayer(
                markers: [
                  fm.Marker(
                    point: selectedPoint!,
                    width: 72,
                    height: 72,
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFFFF6500),
                      size: 58,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          left: 14,
          bottom: 252,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Text(
                '© OpenStreetMap',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFF6500),
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
