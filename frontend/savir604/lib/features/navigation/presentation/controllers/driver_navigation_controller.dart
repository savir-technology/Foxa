import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:tks/core/services/driver_trip_socket_service.dart';
import 'package:tks/core/services/location_service.dart';
import 'package:tks/core/services/mapbox_runtime_config.dart';
import 'package:tks/core/services/mapbox_service.dart';
import 'package:tks/core/services/navigation_service.dart';
import 'package:tks/features/location/domain/entities/driver_location.dart';
import 'package:tks/features/navigation/domain/entities/driver_trip_destination.dart';
import 'package:tks/features/navigation/domain/entities/navigation_progress_snapshot.dart';
import 'package:tks/features/navigation/domain/entities/navigation_route_bundle.dart';

class DriverNavigationController extends GetxController {
  DriverNavigationController({
    LocationService? locationService,
    NavigationService? navigationService,
    MapboxService? mapboxService,
    DriverTripSocketService? socketService,
  })  : _locationService = locationService ?? const LocationService(),
        _navigationService = navigationService ?? NavigationService(),
        _mapboxService = mapboxService ?? MapboxService(),
        _socketService = socketService ?? DriverTripSocketStubService();

  final LocationService _locationService;
  final NavigationService _navigationService;
  final MapboxService _mapboxService;
  final DriverTripSocketService _socketService;

  late final DriverTripDestination tripDestination;

  DriverLocation? currentLocation;
  NavigationRouteBundle? route;
  NavigationProgressSnapshot? progress;
  StreamSubscription<DriverLocation>? _locationSubscription;
  MapboxMap? _mapboxMap;
  bool isBootstrapping = true;
  bool isRerouting = false;
  bool isMapStyleReady = false;
  bool isFollowingDriver = true;
  bool hasMap = false;
  String? errorMessage;
  DateTime _lastRerouteAt = DateTime.fromMillisecondsSinceEpoch(0);
  Brightness mapBrightness = Brightness.light;

  bool get isArabic => Get.locale?.languageCode == 'ar';
  bool get isMapboxReady => MapboxRuntimeConfig.isConfigured;

  void setMapBrightness(Brightness brightness) {
    mapBrightness = brightness;
  }

  @override
  void onInit() {
    tripDestination = DriverTripDestination.fromArguments(
      Get.arguments is Map ? Get.arguments as Map : null,
    );
    _bootstrap();
    super.onInit();
  }

  Future<void> _bootstrap() async {
    if (!isMapboxReady) {
      errorMessage = isArabic
          ? 'لم يتم توفير MAPBOX_ACCESS_TOKEN عبر متغيرات البيئة.'
          : 'MAPBOX_ACCESS_TOKEN was not provided via environment variables.';
      isBootstrapping = false;
      update();
      return;
    }

    final accessState = await _locationService.ensureAccess();
    if (accessState != LocationAccessState.granted) {
      errorMessage = switch (accessState) {
        LocationAccessState.deniedForever => isArabic
            ? 'تم رفض إذن الموقع نهائيًا. افتح الإعدادات لتفعيله.'
            : 'Location permission is permanently denied. Open settings to enable it.',
        LocationAccessState.serviceDisabled => isArabic
            ? 'خدمة الموقع متوقفة. فعّل GPS ثم أعد المحاولة.'
            : 'Location services are disabled. Turn GPS on and try again.',
        _ => isArabic
            ? 'نحتاج إذن الموقع لبدء الملاحة.'
            : 'Location access is required to start navigation.',
      };
      isBootstrapping = false;
      update();
      return;
    }

    currentLocation = await _locationService.getCurrentLocation();
    if (currentLocation == null) {
      errorMessage = isArabic
          ? 'تعذر الحصول على موقع السائق الحالي.'
          : 'Unable to determine the current driver location.';
      isBootstrapping = false;
      update();
      return;
    }

    await _socketService.connect(tripDestination.tripId);
    await _refreshRoute(initialLoad: true);

    _locationSubscription = _locationService.driverLocationStream().listen(
      _handleLocationUpdate,
      onError: (Object error) {
        errorMessage = error.toString();
        update();
      },
    );

    isBootstrapping = false;
    update();
  }

  Future<void> onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    hasMap = true;
    await _mapboxService.attachMap(mapboxMap);
    if (isMapStyleReady) {
      await _synchronizeMapState();
    }
    update();
  }

  Future<void> onStyleLoaded(StyleLoadedEventData _) async {
    isMapStyleReady = true;
    if (_mapboxMap != null) {
      await MapboxRuntimeConfig.configureDetailedBasemapStyle(
        _mapboxMap!.style,
        mapBrightness,
      );
    }
    await _mapboxService.prepareMapStyle();
    await _synchronizeMapState();
    update();
  }

  Future<void> _synchronizeMapState() async {
    if (!hasMap || !isMapStyleReady || currentLocation == null) {
      return;
    }

    await _mapboxService.renderDriverMarker(currentLocation!);
    if (isFollowingDriver) {
      await _mapboxService.focusOnDriver(
        location: currentLocation!,
        immediate: route == null,
      );
    }
    if (route != null) {
      await _mapboxService.renderRoutePolyline(route!);
    }
  }

  Future<void> _handleLocationUpdate(DriverLocation location) async {
    currentLocation = location;
    await _socketService.emitDriverLocation(
      tripId: tripDestination.tripId,
      location: location,
    );

    if (hasMap && isMapStyleReady) {
      await _mapboxService.renderDriverMarker(location);
      if (isFollowingDriver) {
        await _mapboxService.focusOnDriver(location: location);
      }
    }

    if (route != null) {
      progress = _navigationService.buildProgress(
        route: route!,
        currentLocation: location,
        previousStepIndex: progress?.currentStepIndex ?? 0,
      );
      await _navigationService.speakInstructionIfNeeded(
        progress: progress!,
        isArabic: isArabic,
      );

      final canReroute = progress!.isOffRoute &&
          DateTime.now().difference(_lastRerouteAt).inSeconds >= 8;
      if (canReroute) {
        await _refreshRoute(initialLoad: false);
      }
    }

    update();
  }

  Future<void> _refreshRoute({required bool initialLoad}) async {
    final origin = currentLocation;
    if (origin == null) {
      return;
    }

    if (!initialLoad) {
      isRerouting = true;
      update();
    }

    try {
      route = await _navigationService.fetchRoute(
        origin: origin,
        destination: tripDestination,
        isArabic: isArabic,
      );
      _navigationService.resetSpeechState();
      progress = _navigationService.buildProgress(
        route: route!,
        currentLocation: origin,
        previousStepIndex: 0,
      );
      _lastRerouteAt = DateTime.now();

      if (hasMap && isMapStyleReady) {
        await _mapboxService.renderRoutePolyline(route!);
        if (isFollowingDriver) {
          await _mapboxService.focusOnDriver(
            location: origin,
            immediate: true,
          );
        }
      }
      errorMessage = null;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isRerouting = false;
      update();
    }
  }

  Future<void> recenterCamera() async {
    if (currentLocation == null) {
      return;
    }

    isFollowingDriver = true;
    update();
    await _mapboxService.focusOnDriver(
      location: currentLocation!,
      immediate: true,
    );
  }

  Future<void> showOverview() async {
    if (route == null) {
      return;
    }

    isFollowingDriver = false;
    update();
    await _mapboxService.showRouteOverview(route!);
  }

  Future<void> openSystemSettings() async {
    await _locationService.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    _navigationService.dispose();
    _socketService.disconnect();
    super.onClose();
  }
}
