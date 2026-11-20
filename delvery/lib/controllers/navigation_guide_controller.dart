import 'dart:async';
import 'dart:math' as math;

import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/core/services/driver_mapbox_service.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/data/models/navigation_models.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

class DriverNavigationGuideController extends GetxController {
  DriverNavigationGuideController({
    required this.order,
    required this.sessionService,
    required DriverMapboxService directionsService,
  }) : _directionsService = directionsService;

  final DriverOrder? order;
  final DriverSessionService sessionService;
  final DriverMapboxService _directionsService;

  final RxBool loading = true.obs;
  final RxBool routeReady = false.obs;
  final RxBool muted = false.obs;
  final RxBool arrived = false.obs;
  final RxString headline = tx('جاري تحضير الملاحة...').obs;
  final RxString subheadline = tx('نحسب أفضل طريق الآن.').obs;
  final RxString routeDistanceText = '--'.obs;
  final RxString routeDurationText = '--'.obs;
  final RxString destinationDistanceText = '--'.obs;
  final RxInt activeStepIndex = (-1).obs;
  final Rxn<DriverNavigationPlan> navigationPlan = Rxn<DriverNavigationPlan>();
  final Rxn<DriverNavigationStep> upcomingStep = Rxn<DriverNavigationStep>();

  Worker? _locationWorker;
  final FlutterTts _tts = FlutterTts();

  int _lastProgressIndex = -1;
  int _lastSpokenStepIndex = -1;
  bool _arrivalSpoken = false;
  bool _voiceConfigured = false;
  String? _planTargetKey;

  bool get _english => sessionService.localeCode.value.trim().toLowerCase() == 'en';

  String _pick(String arabic, String english) => _english ? english : arabic;

  DriverOrder? get _effectiveOrder {
    final liveOrder = Get.isRegistered<DriverOrdersService>()
        ? Get.find<DriverOrdersService>().activeOrder.value
        : null;
    final seedOrder = order;
    if (seedOrder == null) {
      return liveOrder;
    }
    if (liveOrder?.id == seedOrder.id) {
      return liveOrder;
    }
    return seedOrder;
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_configureVoice());
    _locationWorker = ever<DriverCoordinate?>(sessionService.liveCoordinate, (
      _,
    ) {
      if (navigationPlan.value == null) {
        unawaited(_preparePlan());
      } else {
        _updateGuidance();
      }
    });
    unawaited(_preparePlan());
  }

  @override
  void onClose() {
    _locationWorker?.dispose();
    _tts.stop();
    _directionsService.dispose();
    super.onClose();
  }

  Future<void> _configureVoice() async {
    if (_voiceConfigured) {
      return;
    }

    try {
      await _tts.awaitSpeakCompletion(true);
      final locale = sessionService.localeCode.value.trim();
      if (locale.startsWith('ar')) {
        await _tts.setLanguage('ar');
      } else {
        await _tts.setLanguage('en-US');
      }
      await _tts.setSpeechRate(0.47);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _voiceConfigured = true;
    } catch (_) {
      // Voice is optional. Keep navigation running even if TTS setup fails.
    }
  }

  Future<void> _preparePlan() async {
    final currentOrder = _effectiveOrder;
    if (currentOrder == null) {
      loading.value = false;
      headline.value = tx('لا يوجد طلب نشط');
      subheadline.value = tx('افتح طلبًا لتبدأ الملاحة المباشرة.');
      return;
    }

    final origin = sessionService.liveCoordinate.value;
    final target = _targetForOrder(currentOrder);
    if (origin == null || target == null) {
      loading.value = false;
      headline.value = tx('بانتظار GPS');
      subheadline.value = tx('سيظهر المسار عندما يرسل الجهاز موقعه.');
      return;
    }

    loading.value = true;
    final plan = await _directionsService.fetchNavigationPlan(
      origin: origin,
      destination: target,
    );

    loading.value = false;
    if (plan == null || !plan.hasRoute) {
      headline.value = tx('تعذر تحميل الطريق');
      subheadline.value = tx('تحقق من الاتصال ومفتاح Mapbox.');
      return;
    }

    navigationPlan.value = plan;
    routeReady.value = true;
    routeDistanceText.value = _formatDistance(plan.routeDistanceMeters);
    routeDurationText.value = _formatDuration(plan.routeDurationSeconds);
    _planTargetKey = _coordinateKey(target);
    _updateGuidance(forceSpeak: true);
  }

  void toggleMute() {
    muted.value = !muted.value;
    if (muted.value) {
      _tts.stop();
    }
  }

  void repeatCurrentInstruction() {
    if (headline.value.trim().isEmpty) {
      return;
    }
    unawaited(_speak(headline.value));
  }

  DriverCoordinate? get targetLocation => _targetForOrder(_effectiveOrder);

  String get destinationLabel {
    final currentOrder = _effectiveOrder;
    if (currentOrder == null) {
      return tx('الوجهة');
    }

    switch (currentOrder.status) {
      case DriverOrderStatus.incoming:
      case DriverOrderStatus.assigned:
      case DriverOrderStatus.headingToRestaurant:
      case DriverOrderStatus.arrivedAtRestaurant:
        return currentOrder.restaurantName;
      case DriverOrderStatus.pickedUp:
      case DriverOrderStatus.headingToCustomer:
      case DriverOrderStatus.arrivedAtCustomer:
      case DriverOrderStatus.awaitingVerification:
      case DriverOrderStatus.delivered:
        return currentOrder.customerName;
    }
  }

  void _updateGuidance({bool forceSpeak = false}) {
    final current = sessionService.liveCoordinate.value;
    final target = targetLocation;
    if (current == null || target == null) {
      return;
    }

    final targetKey = _coordinateKey(target);
    if (navigationPlan.value != null &&
        _planTargetKey != null &&
        targetKey != _planTargetKey) {
      navigationPlan.value = null;
      routeReady.value = false;
      loading.value = true;
      routeDistanceText.value = '--';
      routeDurationText.value = '--';
      unawaited(_preparePlan());
      return;
    }

    final distanceToDestination = _distanceMeters(current, target);
    destinationDistanceText.value = _formatDistance(distanceToDestination);

    if (distanceToDestination <= 35) {
      _announceArrival();
      return;
    }

    final plan = navigationPlan.value;
    if (plan == null || plan.steps.isEmpty) {
      headline.value = tx('تابع السير نحو الوجهة');
      subheadline.value = tx('المسار سيظهر بمجرد توفر البيانات.');
      return;
    }

    final progressIndex = plan.closestRouteIndex(current);
    if (progressIndex != null) {
      _lastProgressIndex = math.max(_lastProgressIndex, progressIndex);
    }

    final step = plan.nextStepAfter(_lastProgressIndex);
    if (step == null) {
      headline.value = tx('تابع السير نحو الوجهة');
      subheadline.value = tx('اقتربت من النهاية.');
      return;
    }

    upcomingStep.value = step;
    activeStepIndex.value = step.index;

    final stepDistance = _distanceMeters(current, step.location);
    final instruction = _buildArabicInstruction(step);
    headline.value = instruction;
    subheadline.value = _buildSubheadline(
      step,
      stepDistance,
      distanceToDestination,
    );

    if (_shouldSpeak(step, stepDistance, forceSpeak)) {
      unawaited(_speak(instruction));
    }
  }

  bool _shouldSpeak(
    DriverNavigationStep step,
    double stepDistance,
    bool forceSpeak,
  ) {
    if (muted.value) {
      return false;
    }

    if (step.index == _lastSpokenStepIndex && !forceSpeak) {
      return false;
    }

    if (forceSpeak || step.index == 0) {
      return true;
    }

    return stepDistance <= 220;
  }

  Future<void> _speak(String text) async {
    if (muted.value || text.trim().isEmpty) {
      return;
    }

    try {
      await _tts.stop();
      await _tts.speak(text);
      final step = upcomingStep.value;
      if (step != null) {
        _lastSpokenStepIndex = step.index;
      }
    } catch (_) {
      // Speech is best effort.
    }
  }

  void _announceArrival() {
    if (_arrivalSpoken) {
      return;
    }

    _arrivalSpoken = true;
    arrived.value = true;
    headline.value = tx('لقد وصلت إلى وجهتك');
    subheadline.value = tx('تم الوصول بنجاح.');
    destinationDistanceText.value = _english ? '0 m' : '0 م';
    if (!muted.value) {
      unawaited(_speak(tx('لقد وصلت إلى وجهتك')));
    }
  }

  DriverCoordinate? _targetForOrder(DriverOrder? currentOrder) {
    final orderValue = currentOrder;
    if (orderValue == null) {
      return null;
    }

    bool isValid(DriverCoordinate coordinate) {
      return coordinate.latitude != 0 && coordinate.longitude != 0;
    }

    switch (orderValue.status) {
      case DriverOrderStatus.incoming:
      case DriverOrderStatus.assigned:
      case DriverOrderStatus.headingToRestaurant:
      case DriverOrderStatus.arrivedAtRestaurant:
        return isValid(orderValue.restaurantLocation)
            ? orderValue.restaurantLocation
            : null;
      case DriverOrderStatus.pickedUp:
      case DriverOrderStatus.headingToCustomer:
      case DriverOrderStatus.arrivedAtCustomer:
      case DriverOrderStatus.awaitingVerification:
      case DriverOrderStatus.delivered:
        return isValid(orderValue.customerLocation)
            ? orderValue.customerLocation
            : null;
    }
  }

  String _buildArabicInstruction(DriverNavigationStep step) {
    if (step.isArrival) {
      return tx('لقد وصلت إلى وجهتك');
    }

    final road = step.streetName.trim();
    final modifier = _turnModifierLabel(step.modifier);
    switch (step.maneuverType) {
      case 'depart':
        return road.isEmpty
            ? _pick('ابدأ السير الآن', 'Start driving now')
            : _pick('ابدأ السير على $road', 'Start on $road');
      case 'turn':
        if (road.isEmpty) {
          return _pick('انعطف $modifier', 'Turn $modifier');
        }
        return _pick('انعطف $modifier إلى $road', 'Turn $modifier onto $road');
      case 'new name':
      case 'continue':
      case 'straight':
        return road.isEmpty
            ? _pick('تابع السير', 'Continue')
            : _pick('تابع السير على $road', 'Continue on $road');
      case 'merge':
        return road.isEmpty
            ? _pick('اندمج مع الطريق القادم', 'Merge with the upcoming road')
            : _pick('اندمج مع $road', 'Merge onto $road');
      case 'fork':
        return road.isEmpty
            ? _pick('اسلك المفرق المناسب', 'Take the appropriate fork')
            : _pick('اسلك $road', 'Take $road');
      case 'roundabout':
        final exit = step.exitNumber;
        if (exit != null && exit > 0) {
          return _pick(
            'ادخل الدوار وخذ المخرج رقم $exit',
            'Enter the roundabout and take exit $exit',
          );
        }
        return _pick('ادخل الدوار', 'Enter the roundabout');
      case 'off ramp':
        return road.isEmpty
            ? _pick('خذ المخرج القادم', 'Take the upcoming exit')
            : _pick('خذ المخرج نحو $road', 'Take the exit toward $road');
      default:
        return road.isEmpty
            ? _pick('تابع السير', 'Continue')
            : _pick('تابع السير على $road', 'Continue on $road');
    }
  }

  String _buildSubheadline(
    DriverNavigationStep step,
    double stepDistance,
    double destinationDistance,
  ) {
    if (step.isArrival) {
      return _pick(
        'المسار النهائي فقط. ${_formatDistance(destinationDistance)} متبقية',
        'Final route. ${_formatDistance(destinationDistance)} remaining',
      );
    }

    return _pick(
      'الخطوة التالية بعد ${_formatDistance(stepDistance)}',
      'Next step in ${_formatDistance(stepDistance)}',
    );
  }

  String _turnModifierLabel(String? modifier) {
    switch (modifier?.trim().toLowerCase()) {
      case 'left':
        return _pick('يسار', 'left');
      case 'slight left':
        return _pick('خفيف يسار', 'slightly left');
      case 'sharp left':
        return _pick('يسار حاد', 'sharp left');
      case 'right':
        return _pick('يمين', 'right');
      case 'slight right':
        return _pick('خفيف يمين', 'slightly right');
      case 'sharp right':
        return _pick('يمين حاد', 'sharp right');
      case 'uturn':
        return _pick('للخلف', 'back');
      case 'straight':
        return _pick('مستقيم', 'straight');
      default:
        return _pick('باتجاه مناسب', 'as guided');
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      final value = (meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1);
      return _english ? '$value km' : '$value كم';
    }
    return _english ? '${meters.round()} m' : '${meters.round()} م';
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).ceil();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remaining = minutes % 60;
      if (_english) {
        return remaining == 0 ? '${hours}h' : '${hours}h ${remaining}m';
      }
      return remaining == 0 ? '$hours س' : '$hours س $remaining د';
    }
    return _english ? '${minutes}m' : '$minutes د';
  }

  String _coordinateKey(DriverCoordinate coordinate) {
    return '${coordinate.latitude.toStringAsFixed(5)},${coordinate.longitude.toStringAsFixed(5)}';
  }

  double _distanceMeters(DriverCoordinate from, DriverCoordinate to) {
    const earthRadiusKm = 6371.0;
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);
    final deltaLat = _toRadians(to.latitude - from.latitude);
    final deltaLng = _toRadians(to.longitude - from.longitude);

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(math.max(0, 1 - a)));
    return earthRadiusKm * c * 1000.0;
  }

  double _toRadians(double degree) => degree * math.pi / 180.0;
}
