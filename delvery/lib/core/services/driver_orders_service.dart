import 'dart:async';
import 'dart:math';

import 'package:delvery/core/services/driver_api_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/data/mappers/driver_remote_parser.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class DriverOrdersService extends GetxService {
  DriverOrdersService(this.sessionService, this.api);

  final DriverSessionService sessionService;
  final DriverApiService api;

  final Rxn<DriverOrder> incomingOrder = Rxn<DriverOrder>();
  final Rxn<DriverOrder> activeOrder = Rxn<DriverOrder>();
  final RxList<DriverOrder> history = <DriverOrder>[].obs;
  final Rxn<DateTime> dashboardStatsDate = Rxn<DateTime>();
  final RxInt incomingCountdown = 10.obs;
  final RxBool showingIncomingAlert = false.obs;
  final RxString emergencyReason = ''.obs;
  final RxList<String> quickReplies = <String>[
    'أنا في الطريق.',
    'وصلت للموقع.',
    'الرجاء الرد.',
    'سأتأخر دقائق قليلة.',
  ].obs;

  Timer? _pollTimer;
  Timer? _countdownTimer;

  Future<void> init() async {
    if (sessionService.isShiftActive.value &&
        sessionService.driverId.value != null) {
      startOrderPolling();
      await _refreshDashboard();
    }
  }

  DriverDashboardStats buildStats() {
    sessionService.dashboardTick.value;
    final selectedDate = _normalizeDate(
      dashboardStatsDate.value ?? DateTime.now(),
    );
    final ordersForSelectedDate = history
        .where((order) => _isSameDay(order.createdAt.toLocal(), selectedDate))
        .toList(growable: false);
    final delivered = ordersForSelectedDate
        .where((order) => order.isDelivered)
        .length;
    final active = activeOrder.value;
    final activeCountsForDate =
        active != null && _isSameDay(active.createdAt.toLocal(), selectedDate);

    return DriverDashboardStats(
      todayOrders: ordersForSelectedDate.length + (activeCountsForDate ? 1 : 0),
      deliveredOrders: delivered,
      shiftHours: _shiftHoursFor(selectedDate),
      compliance: active == null
          ? min(99, 84 + delivered * 4)
          : min(99, 79 + delivered * 4),
      onlineMinutes: sessionService.isShiftActive.value
          ? '${sessionService.shiftElapsedMinutes} min'
          : '0 min',
    );
  }

  void setDashboardStatsDate(DateTime? date) {
    dashboardStatsDate.value = date == null ? null : _normalizeDate(date);
  }

  void startOrderPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _refreshDashboard();
    });
    _refreshDashboard();
  }

  void refreshDashboardNow() {
    _refreshDashboard(forceIncomingAlert: true);
  }

  void stopOrderPolling() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    showingIncomingAlert.value = false;
    incomingCountdown.value = 10;
    incomingOrder.value = null;
  }

  Future<void> _refreshDashboard({bool forceIncomingAlert = false}) async {
    final remoteDriverId = sessionService.driverId.value;
    if (remoteDriverId == null) {
      return;
    }

    try {
      final response = await api.fetchDriverDashboard(driverId: remoteDriverId);
      final status = (response['status'] ?? '').toString().toLowerCase();
      if (status != 'success') {
        return;
      }

      final active = DriverRemoteParser.parseOrder(
        response['active_order'] ??
            response['activeOrder'] ??
            response['current_order'] ??
            response['currentOrder'],
      );
      final incoming = DriverRemoteParser.parseOrder(
        response['incoming_order'] ??
            response['incomingOrder'] ??
            response['pending_order'] ??
            response['pendingOrder'],
      );
      final historyPayload =
          response['history'] ??
          response['orders_history'] ??
          response['completed_orders'] ??
          response['orders'];
      final remoteHistory = DriverRemoteParser.parseOrders(historyPayload);

      if (remoteHistory.isNotEmpty) {
        history.assignAll(remoteHistory);
      }

      final previousActive = activeOrder.value;
      if (active != null) {
        activeOrder.value = active;
        sessionService.availability.value = DriverAvailability.busy;
        unawaited(_pushCurrentLiveTrackingFeed());
      } else if (previousActive != null) {
        final previousStillOpen = !remoteHistory.any(
          (order) => order.id == previousActive.id && order.isDelivered,
        );
        if (previousStillOpen) {
          activeOrder.value = previousActive;
          sessionService.availability.value = DriverAvailability.busy;
        } else {
          activeOrder.value = null;
          if (sessionService.isShiftActive.value &&
              sessionService.availability.value != DriverAvailability.offline) {
            sessionService.availability.value = DriverAvailability.available;
          }
        }
      } else {
        activeOrder.value = null;
        if (sessionService.isShiftActive.value &&
            sessionService.availability.value != DriverAvailability.offline) {
          sessionService.availability.value = DriverAvailability.available;
        }
      }

      if (incoming != null && activeOrder.value == null) {
        final currentIncomingId = incomingOrder.value?.id;
        if (forceIncomingAlert || currentIncomingId != incoming.id) {
          _presentIncomingOrder(incoming);
        }
      } else if (!showingIncomingAlert.value) {
        incomingOrder.value = null;
        incomingCountdown.value = 10;
      }
    } catch (_) {
      // Best effort sync. Keep the last known state.
    }
  }

  void _presentIncomingOrder(DriverOrder order) {
    if (activeOrder.value != null || showingIncomingAlert.value) {
      return;
    }

    incomingOrder.value = order;
    incomingCountdown.value = 10;
    showingIncomingAlert.value = true;
    if (sessionService.notificationsEnabled.value) {
      SystemSound.play(SystemSoundType.alert);
    }
    if (sessionService.vibrationEnabled.value) {
      HapticFeedback.heavyImpact();
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (incomingCountdown.value <= 1) {
        timer.cancel();
        acceptIncomingOrder();
        return;
      }
      incomingCountdown.value--;
    });
  }

  Future<bool> acceptIncomingOrder() async {
    final order = incomingOrder.value;
    final remoteDriverId = sessionService.driverId.value;
    if (order == null || remoteDriverId == null) {
      return false;
    }

    try {
      final response = await api.updateOrderAction(
        driverId: remoteDriverId,
        orderId: order.id,
        action: 'accept',
        vendorId: order.vendorId,
      );

      if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
        Get.snackbar(
          'الطلب غير متاح',
          (response['message'] ?? 'تعذر قبول الطلب').toString(),
        );
        return false;
      }

      final updatedOrder =
          DriverRemoteParser.parseOrder(
            response['order'] ?? response['data'] ?? order,
          ) ??
          order.copyWith(status: DriverOrderStatus.assigned);

      activeOrder.value = updatedOrder.copyWith(
        status: DriverOrderStatus.assigned,
      );
      unawaited(_pushCurrentLiveTrackingFeed());
      showingIncomingAlert.value = false;
      incomingOrder.value = null;
      incomingCountdown.value = 10;
      _countdownTimer?.cancel();
      sessionService.availability.value = DriverAvailability.busy;
      return true;
    } catch (error) {
      Get.snackbar('خطأ في الطلب', error.toString());
      return false;
    }
  }

  Future<bool> updateActiveOrder(DriverOrderStatus status) async {
    final order = activeOrder.value;
    final remoteDriverId = sessionService.driverId.value;
    if (order == null || remoteDriverId == null) {
      return false;
    }

    final action = _actionForStatus(status);
    if (action == null) {
      return false;
    }

    try {
      final response = await api.updateOrderAction(
        driverId: remoteDriverId,
        orderId: order.id,
        action: action,
        vendorId: order.vendorId,
      );

      if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
        Get.snackbar(
          'فشل التحديث',
          (response['message'] ?? 'تعذر تحديث حالة الطلب').toString(),
        );
        return false;
      }

      final updatedOrder =
          DriverRemoteParser.parseOrder(
            response['order'] ?? response['data'] ?? order,
          ) ??
          order.copyWith(status: status);

      if (status == DriverOrderStatus.delivered) {
        history.insert(
          0,
          updatedOrder.copyWith(status: DriverOrderStatus.delivered),
        );
        activeOrder.value = null;
        sessionService.availability.value = DriverAvailability.available;
        startOrderPolling();
      } else {
        activeOrder.value = updatedOrder.copyWith(status: status);
        if (status == DriverOrderStatus.arrivedAtCustomer) {
          sessionService.availability.value = DriverAvailability.busy;
        }
        unawaited(_pushCurrentLiveTrackingFeed());
      }

      return true;
    } catch (error) {
      Get.snackbar('فشل التحديث', error.toString());
      return false;
    }
  }

  Future<bool> confirmDeliveryCode(String code) async {
    return completeDelivery(proofCode: code);
  }

  Future<bool> completeDelivery({String? proofCode}) async {
    final order = activeOrder.value;
    final remoteDriverId = sessionService.driverId.value;
    if (order == null || remoteDriverId == null) {
      return false;
    }

    if (order.status != DriverOrderStatus.awaitingVerification) {
      Get.snackbar('التسليم غير مجهز', 'يجب تصوير الطلب قبل إدخال رمز التحقق.');
      return false;
    }

    final normalizedCode = proofCode?.trim() ?? '';
    if (!RegExp(r'^\d{4}$').hasMatch(normalizedCode)) {
      Get.snackbar('رمز غير صحيح', 'رمز التحقق يجب أن يكون مكونًا من 4 أرقام.');
      return false;
    }

    try {
      final response = await api.uploadDeliveryProof(
        driverId: remoteDriverId,
        orderId: order.id,
        proofType: 'code',
        proofCode: normalizedCode,
      );

      if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
        Get.snackbar(
          'فشل التسليم',
          (response['message'] ?? 'تعذر إكمال التسليم').toString(),
        );
        return false;
      }

      final updatedOrder =
          DriverRemoteParser.parseOrder(
            response['order'] ?? response['data'] ?? order,
          ) ??
          order.copyWith(status: DriverOrderStatus.delivered);

      final deliveredOrder = updatedOrder.copyWith(
        status: DriverOrderStatus.delivered,
      );
      history.insert(0, deliveredOrder);
      activeOrder.value = null;
      sessionService.availability.value = DriverAvailability.available;
      startOrderPolling();
      return true;
    } catch (error) {
      Get.snackbar('فشل التسليم', error.toString());
      return false;
    }
  }

  Future<bool> completeDeliveryWithPhoto({
    required String imageBase64,
    required String imageName,
  }) async {
    final order = activeOrder.value;
    final remoteDriverId = sessionService.driverId.value;
    if (order == null || remoteDriverId == null) {
      return false;
    }

    try {
      final response = await api.uploadDeliveryProof(
        driverId: remoteDriverId,
        orderId: order.id,
        proofType: 'image',
        imageBase64: imageBase64,
        imageName: imageName,
      );

      if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
        Get.snackbar(
          'فشل التسليم',
          (response['message'] ?? 'تعذر إكمال التسليم').toString(),
        );
        return false;
      }

      final updatedOrder =
          DriverRemoteParser.parseOrder(
            response['order'] ?? response['data'] ?? order,
          ) ??
          order.copyWith(status: DriverOrderStatus.awaitingVerification);

      activeOrder.value = updatedOrder.copyWith(
        status: DriverOrderStatus.awaitingVerification,
      );
      sessionService.availability.value = DriverAvailability.busy;
      unawaited(_pushCurrentLiveTrackingFeed());
      return true;
    } catch (error) {
      Get.snackbar('فشل التسليم', error.toString());
      return false;
    }
  }

  Future<void> pushLiveTrackingFeed({
    required double latitude,
    required double longitude,
  }) async {
    final order = activeOrder.value;
    final remoteDriverId = sessionService.driverId.value;
    if (order == null || remoteDriverId == null) {
      return;
    }

    try {
      await api.updateTrackingFeed(
        driverId: remoteDriverId,
        orderId: order.id,
        status: _apiStatusFor(order.status),
        driverLatitude: latitude,
        driverLongitude: longitude,
        restaurantLatitude: _latitudeOrNull(order.restaurantLocation),
        restaurantLongitude: _longitudeOrNull(order.restaurantLocation),
        recipientLatitude: _latitudeOrNull(order.customerLocation),
        recipientLongitude: _longitudeOrNull(order.customerLocation),
        etaMinutes: order.etaMinutes,
        driverName: sessionService.profile.value.name,
        driverPhone: sessionService.profile.value.phone,
        vehicleType: sessionService.profile.value.vehicleType,
        vehicleNumber: sessionService.profile.value.vehicleNumber,
      );
    } catch (_) {
      // Live tracking feed is best effort.
    }
  }

  Future<bool> setEmergencyReason(String reason) async {
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) {
      return false;
    }

    final order = activeOrder.value;
    final remoteDriverId = sessionService.driverId.value;
    if (order == null || remoteDriverId == null) {
      return false;
    }

    try {
      final response = await api.reportEmergency(
        driverId: remoteDriverId,
        orderId: order.id,
        reason: normalizedReason,
      );

      if ((response['status'] ?? '').toString().toLowerCase() != 'success') {
        return false;
      }

      emergencyReason.value = normalizedReason;
      return true;
    } catch (_) {
      return false;
    }
  }

  void addQuickReply(String text) {
    if (!quickReplies.contains(text)) {
      quickReplies.insert(0, text);
    }
  }

  void sendQuickReply(String text) {
    addQuickReply(text);
  }

  Future<void> _pushCurrentLiveTrackingFeed() async {
    final order = activeOrder.value;
    final remoteDriverId = sessionService.driverId.value;
    final coordinate = sessionService.liveCoordinate.value;

    if (order == null || remoteDriverId == null || coordinate == null) {
      return;
    }

    try {
      await pushLiveTrackingFeed(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
      );
    } catch (_) {
      // Best effort: keep the active order working even if the sync fails.
    }
  }

  String? _actionForStatus(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.headingToRestaurant:
        return 'heading_to_restaurant';
      case DriverOrderStatus.arrivedAtRestaurant:
        return 'arrived_at_restaurant';
      case DriverOrderStatus.pickedUp:
        return 'picked_up';
      case DriverOrderStatus.headingToCustomer:
        return 'heading_to_customer';
      case DriverOrderStatus.arrivedAtCustomer:
        return 'arrived_at_customer';
      case DriverOrderStatus.awaitingVerification:
        return 'awaiting_delivery_code';
      case DriverOrderStatus.delivered:
        return 'delivered';
      case DriverOrderStatus.incoming:
      case DriverOrderStatus.assigned:
        return 'accept';
    }
  }

  String _apiStatusFor(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.incoming:
        return 'assigned';
      case DriverOrderStatus.assigned:
        return 'accepted';
      case DriverOrderStatus.headingToRestaurant:
        return 'heading_to_restaurant';
      case DriverOrderStatus.arrivedAtRestaurant:
        return 'arrived_at_restaurant';
      case DriverOrderStatus.pickedUp:
        return 'picked_up';
      case DriverOrderStatus.headingToCustomer:
        return 'heading_to_customer';
      case DriverOrderStatus.arrivedAtCustomer:
        return 'arrived_at_customer';
      case DriverOrderStatus.awaitingVerification:
        return 'awaiting_delivery_code';
      case DriverOrderStatus.delivered:
        return 'delivered';
    }
  }

  double? _latitudeOrNull(DriverCoordinate coordinate) {
    if (coordinate.latitude == 0 || coordinate.longitude == 0) {
      return null;
    }
    return coordinate.latitude;
  }

  double? _longitudeOrNull(DriverCoordinate coordinate) {
    if (coordinate.latitude == 0 || coordinate.longitude == 0) {
      return null;
    }
    return coordinate.longitude;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _shiftHoursFor(DateTime selectedDate) {
    if (_isSameDay(selectedDate, DateTime.now())) {
      return sessionService.shiftElapsedText;
    }
    return '--';
  }
}
