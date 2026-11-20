import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/mapbox_runtime_config.dart';
import 'package:tks/core/services/navigation_service.dart';
import 'package:tks/core/services/order_voice_call_alert_service.dart';
import 'package:tks/core/services/order_tracking_map_service.dart';
import 'package:tks/core/services/order_tracking_realtime_service.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/ordersmodel.dart';
import 'package:tks/data/datasource/remote/orders/details_data.dart';
import 'package:tks/data/datasource/remote/orders/driver_rating_data.dart';
import 'package:tks/linkapi/linkapi.dart';
import 'package:tks/features/location/domain/entities/driver_location.dart';
import 'package:tks/features/navigation/domain/entities/driver_trip_destination.dart';
import 'package:tks/features/navigation/domain/entities/navigation_route_bundle.dart';
import 'package:tks/core/services/order_voice_call_service.dart';
import 'package:tks/view/screen/support.dart';
import 'package:tks/view/screen/order_voice_call_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackingStageItem {
  const TrackingStageItem({
    required this.title,
    required this.subtitle,
    required this.isDone,
  });

  final String title;
  final String subtitle;
  final bool isDone;
}

class OrderTrackingController extends GetxController {
  OrderTrackingController({
    OrderTrackingRealtimeService? trackingService,
    NavigationService? navigationService,
    OrderTrackingMapService? mapService,
    String? shareToken,
  })  : _trackingService = trackingService ?? OrderTrackingRealtimeService(),
        _navigationService = navigationService ?? NavigationService(),
        _mapService = mapService ?? OrderTrackingMapService(),
        _driverRatingData = DriverRatingData(Get.find()),
        _ordersDetailsData = OrdersDetailsData(Get.find()),
        _voiceCallService = Get.find<OrderVoiceCallService>(),
        _shareToken = (shareToken ?? '').trim();

  final OrderTrackingRealtimeService _trackingService;
  final NavigationService _navigationService;
  final OrderTrackingMapService _mapService;
  final DriverRatingData _driverRatingData;
  final OrdersDetailsData _ordersDetailsData;
  final OrderVoiceCallService _voiceCallService;
  final MyServices _myServices = Get.find();
  final String _shareToken;

  OrdersModel order = OrdersModel();
  StreamSubscription<OrderTrackingLiveSnapshot>? _subscription;
  StreamSubscription<OrderVoiceCallSession?>? _voiceCallSubscription;
  Timer? _orderDetailsRefreshTimer;
  OrderTrackingLiveSnapshot? snapshot;
  NavigationRouteBundle? route;

  MapboxMap? _mapboxMap;
  bool isMapReady = false;
  bool isFollowingDriver = true;
  bool isLoading = true;
  bool isSubmittingDriverRating = false;
  bool hasSubmittedDriverRating = false;
  String? errorMessage;
  double driverRating = 5.0;
  bool _voiceCallPromptOpen = false;
  String? _lastIncomingVoiceCallKey;
  Brightness mapBrightness = Brightness.light;

  DateTime _lastRouteRefresh = DateTime.fromMillisecondsSinceEpoch(0);
  TrackingCoordinate? _lastRouteOriginLocation;
  TrackingCoordinate? _lastRouteRecipientLocation;
  final Set<int> _spokenArrivalThresholds = <int>{};
  String? _driverRatingLookupKey;

  bool get isArabic => Get.locale?.languageCode == 'ar';
  bool get isMapboxReady => MapboxRuntimeConfig.isConfigured;
  String get trackingStatus => _resolveTrackingStatus();

  void setMapBrightness(Brightness brightness) {
    mapBrightness = brightness;
  }

  String get orderId => (order.ordersId ?? '').trim().isEmpty
      ? '-'
      : (order.ordersId ?? '').trim();

  String get recipientName {
    final recipient = (order.ordersRecipientName ?? '').trim();
    return recipient.isEmpty ? (isArabic ? 'المستلم' : 'Recipient') : recipient;
  }

  String get restaurantName {
    final name = (order.storeName ?? order.vendorName ?? '').trim();
    if (name.isNotEmpty) {
      return name;
    }
    return isArabic ? 'المطعم' : 'Restaurant';
  }

  String _resolveTrackingStatus() {
    final candidates = <String?>[
      snapshot?.status,
      order.status,
      order.ordersStatus,
    ];

    String resolved = 'pending';
    var resolvedRank = -1;
    for (final candidate in candidates) {
      final normalized = _normalizeTrackingStatus(candidate);
      final rank = _trackingStatusRank(normalized);
      if (rank > resolvedRank) {
        resolved = normalized;
        resolvedRank = rank;
      }
    }

    if (resolved == 'pending' && _driverId > 0) {
      return 'assigned';
    }

    return resolved;
  }

  String _normalizeTrackingStatus(String? value) {
    final status = (value ?? '').toLowerCase().trim();
    switch (status) {
      case '0':
      case 'pending':
      case 'new':
        return 'pending';
      case '1':
      case 'accepted':
      case 'approved':
        return 'accepted';
      case 'assigned':
        return 'assigned';
      case '2':
      case 'preparing':
        return 'preparing';
      case 'driver_at_restaurant':
      case 'heading_to_restaurant':
      case 'arrived_at_restaurant':
        return 'driver_at_restaurant';
      case 'picked_up':
      case '3':
      case 'on_the_way':
      case 'on the way':
      case 'delivering':
        return 'on_the_way';
      case 'arrived_at_customer':
        return 'arrived_at_customer';
      case 'awaiting_delivery_code':
      case 'awaiting_verification':
      case 'proof_uploaded':
      case 'waiting_code':
        return 'awaiting_delivery_code';
      case '4':
      case 'delivered':
      case 'completed':
        return 'delivered';
      default:
        return status.isEmpty ? 'pending' : status;
    }
  }

  int _trackingStatusRank(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'accepted':
        return 1;
      case 'assigned':
        return 2;
      case 'preparing':
        return 3;
      case 'driver_at_restaurant':
        return 4;
      case 'on_the_way':
        return 5;
      case 'arrived_at_customer':
        return 6;
      case 'awaiting_delivery_code':
        return 7;
      case 'delivered':
        return 8;
      default:
        return 0;
    }
  }

  TrackingCoordinate? get _deliveryLocation {
    final lat = order.resolvedDeliveryLatitude ??
        order.resolvedRecipientLatitude ??
        order.resolvedAddressLatitude;
    final lng = order.resolvedDeliveryLongitude ??
        order.resolvedRecipientLongitude ??
        order.resolvedAddressLongitude;

    if (lat != null && lng != null && lat != 0 && lng != 0) {
      return TrackingCoordinate(latitude: lat, longitude: lng);
    }

    return snapshot?.recipientLocation;
  }

  bool get hasDriverLocation => snapshot?.driverLocation?.isValid ?? false;
  bool get hasRestaurantLocation =>
      snapshot?.restaurantLocation?.isValid ?? false;

  bool get isDeliveredTracking {
    final status = trackingStatus;
    return status == '4' || status == 'delivered' || status == 'completed';
  }

  bool get isAwaitingDeliveryCode {
    final status = trackingStatus;
    return _isAwaitingDeliveryCodeStatus(status);
  }

  bool _isAwaitingDeliveryCodeStatus(String status) {
    switch (status) {
      case 'awaiting_delivery_code':
      case 'awaiting_verification':
      case 'proof_uploaded':
      case 'waiting_code':
        return true;
      default:
        return false;
    }
  }

  bool get canRateDriver {
    final driverId = _driverId;
    return isDeliveredTracking && driverId > 0;
  }

  int get _driverId {
    final snapshotDriverId = snapshot?.driver.id.trim() ?? '';
    final fallbackDriverId = (order.deliveryId ?? '').trim();
    final rawDriverId =
        snapshotDriverId.isNotEmpty ? snapshotDriverId : fallbackDriverId;
    return int.tryParse(rawDriverId) ?? 0;
  }

  bool get hasAssignedDriver => _driverId > 0;

  bool get canContactDriver => hasAssignedDriver;

  String get driverDisplayName {
    final driverName = snapshot?.driver.name.trim() ?? '';
    if (driverName.isNotEmpty) {
      return driverName;
    }

    if (hasAssignedDriver || trackingStatus == 'assigned') {
      return isArabic ? 'تم تعيين السائق' : 'Driver assigned';
    }

    return isArabic ? 'السائق سيظهر بعد التعيين' : 'Driver pending';
  }

  String get driverSubtitle {
    final driverVehicle = snapshot?.driver.vehicle.trim() ?? '';
    if (driverVehicle.isNotEmpty) {
      return driverVehicle;
    }

    if (hasAssignedDriver || trackingStatus == 'assigned') {
      return isArabic ? 'جاري تحميل بيانات السائق' : 'Driver details loading';
    }

    return isArabic
        ? 'بيانات السائق ستظهر بعد التعيين'
        : 'Driver details appear after assignment';
  }

  String get liveStatusLabel {
    final status = trackingStatus;
    switch (status) {
      case '0':
      case 'pending':
        return isArabic ? 'جاري تأكيد الطلب' : 'Order confirmed';
      case '1':
      case 'accepted':
      case 'approved':
        return isArabic ? 'تم قبول الطلب' : 'Order accepted';
      case 'assigned':
        return isArabic ? 'تم تعيين السائق' : 'Driver assigned';
      case '2':
      case 'preparing':
        return isArabic ? 'جاري تجهيز الطلب' : 'Preparing order';
      case 'driver_at_restaurant':
        return isArabic ? 'السائق عند المطعم' : 'Driver at restaurant';
      case 'heading_to_restaurant':
        return isArabic ? 'السائق في طريقه للمطعم' : 'Heading to restaurant';
      case 'picked_up':
        return isArabic ? 'تم استلام الطلب' : 'Order picked up';
      case '3':
      case 'on_the_way':
      case 'on the way':
      case 'delivering':
        return isArabic ? 'السائق في الطريق إليك' : 'On the way';
      case 'arrived_at_customer':
        return isArabic ? 'السائق عندك' : 'Driver arrived';
      case 'awaiting_delivery_code':
        return isArabic ? 'بانتظار رمز التحقق' : 'Awaiting verification code';
      case '4':
      case 'delivered':
      case 'completed':
        return isArabic ? 'تم التسليم' : 'Delivered';
      default:
        return status.isEmpty
            ? (isArabic ? 'جاري التتبع' : 'Tracking live')
            : status;
    }
  }

  String get liveStatusSubtitle {
    final driver = snapshot?.driver;
    final driverName = driver?.name.trim() ?? '';
    final eta = snapshot?.etaMinutes ??
        (int.tryParse(order.ordersEstimatedMinutes ?? '') ?? 45);

    if (isDeliveredTracking) {
      return isArabic
          ? 'تم تسليم طلبك بنجاح. يمكنك تقييم السائق الآن.'
          : 'Your order has been delivered. You can rate the driver now.';
    }

    final status = trackingStatus;
    if (_isAwaitingDeliveryCodeStatus(status)) {
      return isArabic
          ? 'تم التقاط صورة التسليم. اطلب من السائق إدخال رمز التحقق المكوّن من 4 أرقام لإكمال الطلب.'
          : 'The delivery photo has been captured. Ask the driver to enter the 4-digit verification code to complete the order.';
    }

    if (status == 'arrived_at_customer') {
      return isArabic
          ? 'السائق وصل إلى عنوانك وهو بانتظار خطوة التسليم الأخيرة.'
          : 'The driver has reached your address and is waiting for the final handoff.';
    }

    if (status == 'accepted' || status == 'assigned') {
      if (driverName.isNotEmpty) {
        return isArabic
            ? 'تم تعيين السائق $driverName${hasDriverLocation ? '. المسافة الحالية $liveDistanceLabel تقريبًا.' : '، وسيظهر موقعه مباشرة بعد التحرك.'}'
            : '$driverName has been assigned${hasDriverLocation ? '. Current distance is about $liveDistanceLabel.' : '. Live location will appear once the driver starts moving.'}';
      }

      return isArabic
          ? 'تم تعيين سائق للطلب.'
          : 'A driver has been assigned to this order.';
    }

    if (driverName.isNotEmpty && hasDriverLocation) {
      if (status == 'accepted' || status == 'assigned') {
        return isArabic
            ? 'تم تعيين السائق $driverName. المسافة الحالية $liveDistanceLabel تقريبًا.'
            : '$driverName has been assigned. Current distance is about $liveDistanceLabel.';
      }

      return isArabic
          ? 'السائق $driverName - متوقع الوصول خلال $eta دقيقة'
          : '$driverName is moving toward the delivery destination. ETA $eta min';
    }

    if (hasRestaurantLocation) {
      return isArabic
          ? 'المسافة بين $restaurantName ووجهة الطلب حوالي $liveDistanceLabel'
          : 'Distance between $restaurantName and your delivery destination is about $liveDistanceLabel';
    }

    return isArabic
        ? 'يتم تحديث الحالة مباشرة من قاعدة البيانات'
        : 'Realtime updates are coming from the live tracking feed';
  }

  String get recipientAddressText {
    final parts = _cleanAddressParts([
      order.ordersRecipientAddressName,
      order.ordersRecipientAddressLine,
      order.ordersRecipientLocationNote,
    ]);
    if (parts.isEmpty) {
      return isArabic ? 'العنوان غير متوفر' : 'Address not available';
    }
    return parts.join(', ');
  }

  List<String> get deliveryAddressParts {
    return _cleanAddressParts([
      order.deliveryAddress,
      order.ordersRecipientAddressName,
      order.ordersRecipientAddressLine,
      order.ordersRecipientLocationNote,
      order.addressName,
      order.addressStreet,
      order.addressCity,
    ]);
  }

  String get deliveryAddressText {
    final parts = deliveryAddressParts;
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    return recipientAddressText;
  }

  String get destinationSummaryLabel {
    final recipient = (order.ordersRecipientName ?? '').trim();
    if (recipient.isNotEmpty) {
      return recipient;
    }

    final address = deliveryAddressText.trim();
    if (address.isNotEmpty) {
      return address;
    }

    return isArabic ? 'الوجهة' : 'Destination';
  }

  String get liveDistanceLabel {
    final distance = liveDistanceMeters;
    if (distance == null) {
      return isArabic ? '0.0 كم' : '0.0 km';
    }

    final distanceKm = distance / 1000;
    final fractionDigits = distanceKm < 1
        ? 2
        : distanceKm < 10
            ? 1
            : 0;
    return '${distanceKm.toStringAsFixed(fractionDigits)} ${isArabic ? 'كم' : 'km'}';
  }

  int? get liveDistanceMeters {
    final currentSnapshot = snapshot;
    if (currentSnapshot == null) {
      return null;
    }

    final driver = currentSnapshot.driverLocation;
    final restaurant = currentSnapshot.restaurantLocation;
    final recipient = _deliveryLocation ?? currentSnapshot.recipientLocation;

    if (driver != null && recipient != null) {
      return geo.Geolocator.distanceBetween(
        driver.latitude,
        driver.longitude,
        recipient.latitude,
        recipient.longitude,
      ).round();
    }

    if (restaurant != null && recipient != null) {
      return geo.Geolocator.distanceBetween(
        restaurant.latitude,
        restaurant.longitude,
        recipient.latitude,
        recipient.longitude,
      ).round();
    }

    final routeDistance = currentSnapshot.routeDistanceKm;
    if (routeDistance > 0) {
      return (routeDistance * 1000).round();
    }

    return null;
  }

  String get etaText {
    final eta = snapshot?.etaMinutes ??
        (int.tryParse(order.ordersEstimatedMinutes ?? '') ?? 45);
    return isArabic ? '$eta دقيقة' : '$eta min';
  }

  Point get initialCameraCenter {
    final destination = _deliveryLocation;
    final driver = snapshot?.driverLocation;
    final restaurant = snapshot?.restaurantLocation;
    final target = destination ?? driver ?? restaurant;
    if (target != null) {
      return Point(
        coordinates: Position(target.longitude, target.latitude),
      );
    }

    return Point(
      coordinates: Position(31.2357, 30.0444),
    );
  }

  String get shareLink {
    const webBase = AppLink.server;
    final livePath = snapshot?.sharePath.trim() ?? '';
    if (livePath.isNotEmpty) {
      if (livePath.startsWith('http')) {
        return livePath;
      }
      final normalizedPath = livePath.startsWith('/') ? livePath : '/$livePath';
      if (normalizedPath.startsWith('/track/')) {
        final uri = Uri.tryParse(normalizedPath);
        final token = uri?.queryParameters['token'] ??
            normalizedPath.replaceFirst('/track/', '').split('?').first.trim();
        if (token.isNotEmpty) {
          return '$webBase/track.php?token=${Uri.encodeComponent(token)}';
        }
      }
      return '$webBase$normalizedPath';
    }

    final token = (order.ordersShareToken ?? '').trim();
    if (token.isEmpty) {
      return '';
    }
    return '$webBase/track.php?token=${Uri.encodeComponent(token)}';
  }

  List<String> _cleanAddressParts(Iterable<String?> parts) {
    final clean = <String>[];
    final seen = <String>{};
    for (final part in parts) {
      final normalized = _normalizeAddressPart(part);
      if (normalized.isEmpty) {
        continue;
      }
      final key = normalized.toLowerCase();
      if (seen.add(key)) {
        clean.add(normalized);
      }
    }
    return clean;
  }

  String _normalizeAddressPart(String? value) {
    final text = (value ?? '')
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return '';
    }
    return text;
  }

  List<TrackingStageItem> get stages {
    final status = trackingStatus;
    final currentIndex = _statusToIndex(status);
    final labels = isArabic
        ? <String>[
            'تم إنشاء الطلب',
            'تم قبول الطلب',
            'تم تعيين السائق',
            'جاري التجهيز',
            'السائق عند المطعم',
            'الطلب في الطريق',
            'بانتظار رمز التحقق',
            'تم التسليم',
          ]
        : <String>[
            'Order created',
            'Order accepted',
            'Driver assigned',
            'Preparing',
            'At restaurant',
            'On the way',
            'Awaiting code',
            'Delivered',
          ];

    return List<TrackingStageItem>.generate(
      labels.length,
      (index) => TrackingStageItem(
        title: labels[index],
        subtitle: index == currentIndex
            ? (isArabic ? 'المرحلة الحالية' : 'Current step')
            : index < currentIndex
                ? (isArabic ? 'مكتملة' : 'Completed')
                : (isArabic ? 'بانتظار التحديث' : 'Waiting for update'),
        isDone: index <= currentIndex,
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();
    order = _resolveOrder(Get.arguments);
    _setupVoiceCallMonitoring();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final resolved = await _hydrateOrderDetails();
    if (!resolved && (order.ordersId ?? '').trim().isEmpty) {
      isLoading = false;
      errorMessage = isArabic
          ? 'تعذر تحميل بيانات الطلب من الرابط.'
          : 'Unable to load the order from the shared link.';
      update();
      return;
    }

    await _subscribeToTrackingUpdates();
    _startOrderDetailsRefreshTimer();
  }

  void _startOrderDetailsRefreshTimer() {
    _orderDetailsRefreshTimer?.cancel();
    final orderId = (order.ordersId ?? '').trim();
    if (orderId.isEmpty) {
      return;
    }

    _orderDetailsRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        unawaited(_refreshOrderDetails());
      },
    );
  }

  Future<void> _refreshOrderDetails() async {
    final refreshed = await _hydrateOrderDetails();
    if (!refreshed) {
      return;
    }

    await _subscribeToTrackingUpdates();
  }

  Future<void> _subscribeToTrackingUpdates() async {
    await _subscription?.cancel();
    _subscription = _trackingService.watchOrder(order).listen(
      (event) async {
        snapshot = event;
        isLoading = false;
        errorMessage = null;
        await _syncMapVisuals();
        await _announceArrivalMilestones(event);
        unawaited(_syncDriverRatingState());
        update();
      },
      onError: (Object error) {
        errorMessage = error.toString();
        isLoading = false;
        update();
      },
    );
  }

  Future<bool> _hydrateOrderDetails() async {
    final orderId = (order.ordersId ?? '').trim();
    if (orderId.isNotEmpty) {
      try {
        final response = await _ordersDetailsData.getData(orderId);
        if (response['status'] == 'success' && response['order'] is Map) {
          order = OrdersModel.fromJson(
            Map<String, dynamic>.from(response['order'] as Map),
          );
          _bindVoiceCallOrderId();
          update();
          unawaited(_syncDriverRatingState(force: true));
        }
      } catch (_) {}
      return (order.ordersId ?? '').trim().isNotEmpty;
    }

    try {
      final token = _shareToken;
      if (token.isEmpty) {
        return false;
      }

      final response = await _ordersDetailsData.getDataByShareToken(token);
      if (response['status'] == 'success' && response['order'] is Map) {
        order = OrdersModel.fromJson(
          Map<String, dynamic>.from(response['order'] as Map),
        );
        _bindVoiceCallOrderId();
        update();
        unawaited(_syncDriverRatingState(force: true));
        return (order.ordersId ?? '').trim().isNotEmpty;
      }
    } catch (_) {}

    return false;
  }

  void _bindVoiceCallOrderId() {
    final orderIdValue = (order.ordersId ?? '').trim();
    if (orderIdValue.isEmpty ||
        !Get.isRegistered<OrderVoiceCallAlertService>()) {
      return;
    }

    Get.find<OrderVoiceCallAlertService>().bindActiveOrderId(orderIdValue);
  }

  OrdersModel _resolveOrder(dynamic args) {
    if (args is Map && args['ordersmodel'] is OrdersModel) {
      return args['ordersmodel'] as OrdersModel;
    }
    if (args is Map) {
      return OrdersModel.fromJson(Map<String, dynamic>.from(args));
    }
    return OrdersModel();
  }

  Future<void> onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await _mapService.attachMap(mapboxMap);
    await _syncMapVisuals(immediate: true);
  }

  Future<void> onStyleLoaded(StyleLoadedEventData _) async {
    isMapReady = true;
    if (_mapboxMap != null) {
      await MapboxRuntimeConfig.configureDetailedBasemapStyle(
        _mapboxMap!.style,
        mapBrightness,
      );
    }
    await _mapService.prepareMapStyle();
    await _syncMapVisuals(immediate: true);
  }

  Future<void> recenter() async {
    isFollowingDriver = true;
    if (!isMapReady || !isMapboxReady) {
      update();
      return;
    }

    await _mapService.focusOnTracking(
      driverLocation: snapshot?.driverLocation,
      restaurantLocation: snapshot?.restaurantLocation,
      recipientLocation: _deliveryLocation ?? snapshot?.recipientLocation,
      followDriver: true,
      immediate: true,
    );
    update();
  }

  void onUserMapGesture(MapContentGestureContext context) {
    if (context.gestureState == GestureState.started ||
        context.gestureState == GestureState.changed) {
      if (isFollowingDriver) {
        isFollowingDriver = false;
        update();
      }
    }
  }

  Future<void> showOverview() async {
    if (!isMapReady || !isMapboxReady) {
      return;
    }

    isFollowingDriver = false;
    await _mapService.showOverview(
      driverLocation: snapshot?.driverLocation,
      restaurantLocation: snapshot?.restaurantLocation,
      recipientLocation: _deliveryLocation ?? snapshot?.recipientLocation,
    );
    update();
  }

  Future<void> copyShareLink() async {
    if (shareLink.isEmpty) {
      Get.snackbar(
        isArabic ? 'مشاركة الطلب' : 'Share order',
        isArabic
            ? 'لا يوجد رابط مشاركة متاح حتى الآن.'
            : 'No share link is available yet.',
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: shareLink));
    Get.snackbar(
      isArabic ? 'تم النسخ' : 'Copied',
      isArabic
          ? 'تم نسخ رابط التتبع بنجاح.'
          : 'Tracking link copied successfully.',
    );
  }

  Future<bool> _isDriverAvailable(int driverId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppLink.server}/driver_dashboard.php'),
        body: {'driver_id': driverId.toString()},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return true;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return true;
      }

      final payload = decoded.map((key, value) => MapEntry('$key', value));
      if (payload['status']?.toString().toLowerCase() != 'success') {
        return true;
      }

      final profileRaw = payload['profile'];
      if (profileRaw is! Map) {
        return true;
      }

      final profile = profileRaw.map((key, value) => MapEntry('$key', value));
      final status = (profile['status'] ?? '').toString().toLowerCase().trim();
      if (status == 'offline') {
        return false;
      }

      final lastSeenText = (profile['last_seen_at'] ?? '').toString().trim();
      if (lastSeenText.isNotEmpty) {
        final lastSeen = DateTime.tryParse(lastSeenText);
        if (lastSeen != null) {
          return DateTime.now().difference(lastSeen).inMinutes <= 5;
        }
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> callDriver() async {
    final orderIdValue = (order.ordersId ?? '').trim();
    final driverIdValue = _driverId;
    final driverName = snapshot?.driver.name.trim() ?? '';

    if (orderIdValue.isEmpty || driverIdValue <= 0) {
      Get.snackbar(
        isArabic ? 'المكالمة' : 'Voice call',
        isArabic
            ? 'لا يمكن بدء المكالمة قبل تعيين السائق.'
            : 'Voice call is available after the driver is assigned.',
      );
      return;
    }

    final driverAvailable = await _isDriverAvailable(driverIdValue);
    if (!driverAvailable) {
      Get.snackbar(
        isArabic ? 'المكالمة' : 'Voice call',
        isArabic
            ? 'السائق غير متاح الآن. جاري تحديث حالته داخل التطبيق.'
            : 'The driver is currently unavailable. Try again later.',
      );
      return;
    }

    await Get.to(
      () => OrderVoiceCallScreen.outgoing(
        orderId: orderIdValue,
        myRole: 'user',
        myId: (_myServices.sharedPreferences.getInt('id') ?? 0).toString(),
        myName: _myServices.sharedPreferences.getString('username') ??
            (isArabic ? 'المستخدم' : 'User'),
        peerRole: 'driver',
        peerId: driverIdValue.toString(),
        peerName: driverName.isNotEmpty
            ? driverName
            : (isArabic ? 'السائق' : 'Driver'),
      ),
    );
  }

  Future<void> callSupport() async {
    final supportPhone = snapshot?.supportPhone.trim() ?? '';
    await _launchPhone(
      supportPhone,
      fallbackMessageAr: 'سأفتح الدعم داخل التطبيق بدلًا من ذلك.',
      fallbackMessageEn: 'Opening in-app support instead.',
      fallbackToSupport: true,
    );
  }

  Future<void> openOrderChat() async {
    final orderIdValue = (order.ordersId ?? '').trim();
    if (orderIdValue.isEmpty) {
      Get.snackbar(
        isArabic ? 'الدردشة' : 'Order chat',
        isArabic
            ? 'لا يمكن فتح الدردشة بدون رقم طلب.'
            : 'Order chat cannot open without an order number.',
      );
      return;
    }

    await Get.toNamed(
      AppRoutes.orderChat,
      arguments: order.toJson(),
    );
  }

  Future<void> openSupportChat() async {
    final userId = _myServices.sharedPreferences.getInt('id') ?? 0;
    await Get.to(() => SupportHome(userId: userId));
  }

  Future<void> _launchPhone(
    String phone, {
    required String fallbackMessageAr,
    required String fallbackMessageEn,
    bool fallbackToSupport = false,
  }) async {
    if (phone.isEmpty) {
      Get.snackbar(
        isArabic ? 'تنبيه' : 'Notice',
        isArabic ? fallbackMessageAr : fallbackMessageEn,
      );
      if (fallbackToSupport) {
        await openSupportChat();
      }
      return;
    }

    final uri = Uri.parse('tel:$phone');
    final launched = await launchUrl(uri);
    if (!launched && fallbackToSupport) {
      await openSupportChat();
    }
  }

  void _setupVoiceCallMonitoring() {
    final orderIdValue = (order.ordersId ?? '').trim();
    if (orderIdValue.isEmpty) {
      return;
    }

    if (Get.isRegistered<OrderVoiceCallAlertService>()) {
      Get.find<OrderVoiceCallAlertService>().bindActiveOrderId(orderIdValue);
      return;
    }

    _voiceCallSubscription?.cancel();
    _voiceCallSubscription =
        _voiceCallService.watchSession(orderIdValue).listen(
      (session) async {
        if (session == null) {
          return;
        }

        final currentUserId = _myServices.sharedPreferences.getInt('id') ?? 0;
        final currentUserName =
            _myServices.sharedPreferences.getString('username') ??
                (isArabic ? 'المستخدم' : 'User');

        final sessionKey =
            '${session.orderId}:${session.createdAtMs}:${session.callerId}:${session.calleeId}';

        if (session.status == 'ringing' &&
            session.isIncomingFor('user', currentUserId.toString()) &&
            !_voiceCallPromptOpen &&
            _lastIncomingVoiceCallKey != sessionKey) {
          _lastIncomingVoiceCallKey = sessionKey;
          await _showIncomingVoiceCallSheet(
            session,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
          );
          return;
        }

        if (session.status != 'ringing') {
          _lastIncomingVoiceCallKey = null;
          if (_voiceCallPromptOpen) {
            if (Get.isBottomSheetOpen == true) {
              Get.back();
            }
            _voiceCallPromptOpen = false;
          }
        }
      },
    );
  }

  Future<void> _showIncomingVoiceCallSheet(
    OrderVoiceCallSession session, {
    required int currentUserId,
    required String currentUserName,
  }) async {
    _voiceCallPromptOpen = true;
    await Get.bottomSheet(
      SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isArabic ? 'مكالمة صوتية واردة' : 'Incoming voice call',
                textAlign: TextAlign.center,
                style: Theme.of(Get.context!).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                session.callerName.isNotEmpty
                    ? session.callerName
                    : (isArabic ? 'السائق' : 'Driver'),
                textAlign: TextAlign.center,
                style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'يريد السائق التحدث معك الآن بخصوص الطلب #${session.orderId}.'
                    : 'The driver is calling you about order #${session.orderId}.',
                textAlign: TextAlign.center,
                style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        _voiceCallPromptOpen = false;
                        if (Get.isBottomSheetOpen == true) {
                          Get.back();
                        }
                        await _voiceCallService.markDeclined(session.orderId);
                      },
                      icon: const Icon(Icons.call_end_rounded),
                      label: Text(isArabic ? 'رفض' : 'Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        _voiceCallPromptOpen = false;
                        if (Get.isBottomSheetOpen == true) {
                          Get.back();
                        }
                        await Get.to(
                          () => OrderVoiceCallScreen.incoming(
                            orderId: session.orderId,
                            myRole: 'user',
                            myId: currentUserId.toString(),
                            myName: currentUserName,
                            peerRole: session.callerRole.isNotEmpty
                                ? session.callerRole
                                : 'driver',
                            peerId: session.callerId,
                            peerName: session.callerName.isNotEmpty
                                ? session.callerName
                                : (isArabic ? 'السائق' : 'Driver'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.call_rounded),
                      label: Text(isArabic ? 'قبول' : 'Accept'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF59D98E),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      barrierColor: Colors.black54,
    ).whenComplete(() {
      _voiceCallPromptOpen = false;
    });
  }

  Future<void> setDriverRating(double value) async {
    driverRating = value.clamp(1.0, 5.0).toDouble();
    update();
  }

  Future<void> submitDriverRating() async {
    if (isSubmittingDriverRating) {
      return;
    }

    final driverId = _driverId;
    final userId = _myServices.sharedPreferences.getInt('id') ?? 0;
    final orderIdValue = (order.ordersId ?? '').trim();
    if (orderIdValue.isEmpty || driverId <= 0 || userId <= 0) {
      Get.snackbar(
        isArabic ? 'التقييم' : 'Rating',
        isArabic
            ? 'لا يمكن حفظ التقييم الآن.'
            : 'Unable to save the rating right now.',
      );
      return;
    }

    isSubmittingDriverRating = true;
    update();

    try {
      final response = await _driverRatingData.submitRating(
        orderId: orderIdValue,
        driverId: driverId.toString(),
        userId: userId.toString(),
        rating: driverRating,
      );

      if (response is Map && response['status'] == 'success') {
        hasSubmittedDriverRating = true;
        _driverRatingLookupKey = _driverRatingLookupKeyValue();
        Get.snackbar(
          isArabic ? 'تم التقييم' : 'Rated',
          isArabic
              ? 'شكرًا لك. تم حفظ تقييم السائق ويمكنك تعديله لاحقًا.'
              : 'Thanks. The driver rating has been saved and can be updated later.',
        );
        update();
        return;
      }

      final message = response is Map
          ? response['message']?.toString()
          : response?.toString();
      throw Exception(message?.trim().isNotEmpty == true
          ? message
          : (isArabic ? 'فشل حفظ التقييم' : 'Failed to save the rating'));
    } catch (error) {
      Get.snackbar(
        isArabic ? 'خطأ' : 'Error',
        error.toString(),
      );
    } finally {
      isSubmittingDriverRating = false;
      update();
    }
  }

  String _driverRatingLookupKeyValue() {
    final orderIdValue = (order.ordersId ?? '').trim();
    final driverId = _driverId;
    final userId = _myServices.sharedPreferences.getInt('id') ?? 0;
    if (orderIdValue.isEmpty || driverId <= 0 || userId <= 0) {
      return '';
    }
    return '$orderIdValue:$driverId:$userId';
  }

  Future<void> _syncDriverRatingState({bool force = false}) async {
    if (!canRateDriver) {
      return;
    }

    final lookupKey = _driverRatingLookupKeyValue();
    if (lookupKey.isEmpty) {
      return;
    }

    if (!force && _driverRatingLookupKey == lookupKey) {
      return;
    }

    _driverRatingLookupKey = lookupKey;

    try {
      final response = await _driverRatingData.getRating(
        orderId: (order.ordersId ?? '').trim(),
        driverId: _driverId.toString(),
        userId: (_myServices.sharedPreferences.getInt('id') ?? 0).toString(),
      );

      if (response is Map && response['status'] == 'success') {
        final hasRating =
            response['has_rating'] == true || response['rating'] != null;
        if (hasRating) {
          final value =
              double.tryParse('${response['rating'] ?? driverRating}') ?? 0.0;
          driverRating = value.clamp(1.0, 5.0).toDouble();
          hasSubmittedDriverRating = true;
          update();
        }
      }
    } catch (_) {
      // Ignore rating lookup errors; submit flow still works.
    }
  }

  Future<void> _syncMapVisuals({bool immediate = false}) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null || !isMapReady || !isMapboxReady) {
      return;
    }

    final driver = snapshot?.driverLocation;
    final restaurant = snapshot?.restaurantLocation;
    final recipient = _deliveryLocation ?? snapshot?.recipientLocation;
    final driverIsActive = !isDeliveredTracking;
    await _mapService.renderMarkers(
      driverLocation: driver,
      restaurantLocation: restaurant,
      recipientLocation: recipient,
      driverIsActive: driverIsActive,
      restaurantIsActive: driverIsActive,
      driverVehicleType: snapshot?.driver.vehicle,
    );

    await _refreshRouteIfNeeded();

    if (!isFollowingDriver) {
      return;
    }

    await _mapService.focusOnTracking(
      driverLocation: driver,
      restaurantLocation: restaurant,
      recipientLocation: recipient,
      followDriver: true,
      immediate: immediate,
    );
  }

  Future<void> _refreshRouteIfNeeded() async {
    final driver = snapshot?.driverLocation;
    final restaurant = snapshot?.restaurantLocation;
    final recipient = _deliveryLocation ?? snapshot?.recipientLocation;
    final origin = driver ?? restaurant;
    if (origin == null ||
        recipient == null ||
        !origin.isValid ||
        !recipient.isValid ||
        !isMapboxReady) {
      route = null;
      await _mapService.renderRoute(null);
      return;
    }

    final now = DateTime.now();
    final shouldRefresh = route == null ||
        _lastRouteOriginLocation == null ||
        _lastRouteRecipientLocation == null ||
        geo.Geolocator.distanceBetween(
              _lastRouteOriginLocation!.latitude,
              _lastRouteOriginLocation!.longitude,
              origin.latitude,
              origin.longitude,
            ) >
            120 ||
        geo.Geolocator.distanceBetween(
              _lastRouteRecipientLocation!.latitude,
              _lastRouteRecipientLocation!.longitude,
              recipient.latitude,
              recipient.longitude,
            ) >
            20 ||
        now.difference(_lastRouteRefresh).inSeconds >= 45;

    if (!shouldRefresh) {
      await _mapService.renderRoute(route);
      return;
    }

    final previousRoute = route;
    try {
      route = await _navigationService.fetchRoute(
        origin: DriverLocation(
          latitude: origin.latitude,
          longitude: origin.longitude,
          heading: 0,
          speedMetersPerSecond: 0,
          accuracyMeters: 0,
          timestamp: now,
        ),
        destination: DriverTripDestination(
          latitude: recipient.latitude,
          longitude: recipient.longitude,
          passengerName: recipientName,
          tripStatus: trackingStatus,
          tripId: orderId,
          destinationLabel: deliveryAddressText,
        ),
        isArabic: isArabic,
      );
      _lastRouteOriginLocation = origin;
      _lastRouteRecipientLocation = recipient;
      _lastRouteRefresh = now;
      errorMessage = null;
    } catch (error) {
      route = previousRoute;
      errorMessage ??= error.toString();
    }

    await _mapService.renderRoute(route);
  }

  Future<void> _announceArrivalMilestones(
      OrderTrackingLiveSnapshot event) async {
    if (!event.hasLiveData || isDeliveredTracking) {
      return;
    }

    final status = event.status.toLowerCase().trim();
    if (status == 'pending' || status == 'assigned' || status == 'preparing') {
      return;
    }

    final distanceMeters = _currentTrackingDistanceMeters(event);
    if (distanceMeters == null) {
      return;
    }

    const thresholds = <int>[20, 50, 100];
    for (final threshold in thresholds) {
      if (distanceMeters <= threshold &&
          !_spokenArrivalThresholds.contains(threshold)) {
        _spokenArrivalThresholds.add(threshold);
        await _navigationService.speakText(
          _arrivalAnnouncementFor(threshold),
          isArabic: isArabic,
        );
        break;
      }
    }
  }

  int? _currentTrackingDistanceMeters(OrderTrackingLiveSnapshot event) {
    final driver = event.driverLocation;
    final restaurant = event.restaurantLocation;
    final recipient = _deliveryLocation ?? event.recipientLocation;
    if (driver != null && recipient != null) {
      return geo.Geolocator.distanceBetween(
        driver.latitude,
        driver.longitude,
        recipient.latitude,
        recipient.longitude,
      ).round();
    }

    if (restaurant != null && recipient != null) {
      return geo.Geolocator.distanceBetween(
        restaurant.latitude,
        restaurant.longitude,
        recipient.latitude,
        recipient.longitude,
      ).round();
    }

    final routeDistance = event.routeDistanceKm;
    if (routeDistance > 0) {
      return (routeDistance * 1000).round();
    }

    return null;
  }

  String _arrivalAnnouncementFor(int thresholdMeters) {
    switch (thresholdMeters) {
      case 20:
        return isArabic
            ? 'لقد وصلت إلى وجهتك'
            : 'You have arrived at your destination';
      case 50:
        return isArabic
            ? 'باقي 50 متر على الوصول'
            : '50 meters left to your destination';
      case 100:
      default:
        return isArabic
            ? 'باقي 100 متر على الوصول'
            : '100 meters left to your destination';
    }
  }

  int _statusToIndex(String status) {
    switch (status) {
      case '0':
      case 'pending':
        return 0;
      case '1':
      case 'accepted':
      case 'approved':
        return 1;
      case 'assigned':
        return 2;
      case '2':
      case 'preparing':
        return 3;
      case 'driver_at_restaurant':
      case 'heading_to_restaurant':
      case 'picked_up':
        return 4;
      case '3':
      case 'on_the_way':
      case 'on the way':
      case 'delivering':
      case 'arrived_at_customer':
        return 5;
      case 'awaiting_delivery_code':
      case 'awaiting_verification':
      case 'proof_uploaded':
      case 'waiting_code':
        return 6;
      case '4':
      case 'delivered':
      case 'completed':
        return 7;
      default:
        return 0;
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _voiceCallSubscription?.cancel();
    _orderDetailsRefreshTimer?.cancel();
    _navigationService.dispose();
    super.onClose();
  }
}
