// ignore_for_file: avoid_print

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/core/services/driver_api_service.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/core/services/driver_order_voice_call_alert_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/screens/order_chat_screen.dart';

class DriverFirebaseMessagingService {
  DriverFirebaseMessagingService({
    DriverSessionService? sessionService,
    DriverApiService? apiService,
  }) : _sessionService = sessionService ?? Get.find<DriverSessionService>(),
       _apiService = apiService ?? Get.find<DriverApiService>();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DriverSessionService _sessionService;
  final DriverApiService _apiService;
  static const MethodChannel _permissionChannel = MethodChannel(
    'notification_permissions',
  );
  static const MethodChannel _voiceCallIntentChannel = MethodChannel(
    'voice_call_intent',
  );

  Worker? _driverIdWorker;
  String? _pendingPushToken;
  bool _initialized = false;
  bool _nativeVoiceCallIntentBound = false;

  Future<void> initFirebaseMessaging() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    // Bind the native Accept action before permission/token/network work so a
    // cold-start call is not lost while Firebase initialization is running.
    _bindNativeVoiceCallIntentBridge();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumeInitialNativeVoiceCallIntent());
    });

    await _ensureAndroidNotificationPermission();
    final NotificationSettings settings = await _firebaseMessaging
        .requestPermission(alert: true, badge: true, sound: true);

    print('Driver FCM authorization: ${settings.authorizationStatus}');

    await _refreshToken();
    final token = await _firebaseMessaging.getToken();
    print('Driver Firebase Token: $token');
    await _rememberAndSyncToken(token);

    _driverIdWorker?.dispose();
    _driverIdWorker = ever<int?>(_sessionService.driverId, (_) {
      unawaited(_syncPendingToken());
    });

    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print('Driver Firebase token refreshed: $newToken');
      await _rememberAndSyncToken(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = Map<String, dynamic>.from(message.data);
      if (_isNotificationForAnotherDriver(data)) {
        debugPrint('[FCM] Ignoring assignment notification for another driver');
        return;
      }
      debugPrint(
        '[VOICE CALL] Driver incoming FCM type=${data['type']?.toString() ?? ''} keys=${data.keys.toList(growable: false)}',
      );
      if (_isVoiceCallMessage(data)) {
        await _handleVoiceCallPayload(data);
        return;
      }

      if (_isOrderChatMessage(data)) {
        debugPrint(
          '[FCM] Driver foreground order chat notification type=${data['type']?.toString() ?? ''} orderId=${_extractOrderId(data)}',
        );
      }

      Get.snackbar(
        message.notification?.title ?? 'New notification',
        message.notification?.body ?? '',
        snackPosition: SnackPosition.TOP,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_handleNotificationOpen(message));
    });

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_handleNotificationOpen(initialMessage));
      });
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
    } catch (error) {
      debugPrint('Failed to clear stale driver Firebase token: $error');
    }
  }

  void _bindNativeVoiceCallIntentBridge() {
    if (_nativeVoiceCallIntentBound) {
      return;
    }
    _nativeVoiceCallIntentBound = true;

    _voiceCallIntentChannel.setMethodCallHandler((call) async {
      if (call.method != 'onVoiceCallIntent') {
        return null;
      }

      final data = _normalizeMethodArguments(call.arguments);
      debugPrint(
        '[VOICE CALL] Driver native intent bridge received keys=${data.keys.toList(growable: false)}',
      );
      if (_isVoiceCallMessage(data) && _hasNativeVoiceCallAction(data)) {
        await _handleNativeVoiceCallIntent(data);
      }
      return null;
    });
  }

  Future<void> _consumeInitialNativeVoiceCallIntent() async {
    try {
      for (var attempt = 0; attempt < 20; attempt++) {
        final result = await _voiceCallIntentChannel.invokeMethod<Object?>(
          'getInitialVoiceCallData',
        );
        final data = _normalizeMethodArguments(result);
        if (_isVoiceCallMessage(data) && _hasNativeVoiceCallAction(data)) {
          debugPrint(
            '[VOICE CALL] Driver initial native intent consumed keys=${data.keys.toList(growable: false)}',
          );
          await _handleNativeVoiceCallIntent(data);
        }
        if (data.isNotEmpty || attempt == 19) {
          return;
        }
        await Future.delayed(const Duration(milliseconds: 120));
      }
    } on MissingPluginException catch (error) {
      debugPrint('[VOICE CALL] initial driver native bridge not ready: $error');
    } catch (error, stackTrace) {
      debugPrint(
        '[VOICE CALL] consumeInitialNativeVoiceCallIntent() failed: $error',
      );
      debugPrint(stackTrace.toString());
    }
  }

  Map<String, dynamic> _normalizeMethodArguments(dynamic arguments) {
    if (arguments is Map) {
      final normalized = <String, dynamic>{};
      arguments.forEach((key, value) {
        normalized['$key'] = value;
      });
      return normalized;
    }

    return <String, dynamic>{};
  }

  Future<void> _ensureAndroidNotificationPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _permissionChannel.invokeMethod<bool>(
        'ensureNotificationPermission',
      );
    } catch (_) {
      // The Firebase permission request below remains as a fallback.
    }
  }

  Future<void> _handleNotificationOpen(RemoteMessage message) async {
    final data = Map<String, dynamic>.from(message.data);
    if (_isNotificationForAnotherDriver(data)) {
      debugPrint('[FCM] Ignoring opened notification for another driver');
      return;
    }
    if (_isVoiceCallMessage(data)) {
      await _handleVoiceCallPayload(data);
      return;
    }

    if (_isOrderChatMessage(data)) {
      await _handleOrderChatNotificationOpen(data);
      return;
    }

    Get.snackbar(
      message.notification?.title ?? 'New notification',
      message.notification?.body ?? '',
      snackPosition: SnackPosition.TOP,
    );
  }

  bool _isVoiceCallMessage(Map<String, dynamic> payload) {
    final type = payload['type']?.toString().trim().toLowerCase() ?? '';
    return type == 'voice_call' || type == 'voice_call_status';
  }

  bool _isNotificationForAnotherDriver(Map<String, dynamic> payload) {
    final type = payload['type']?.toString().trim().toLowerCase() ?? '';
    if (type != 'driver_order_assignment') {
      return false;
    }
    final targetId = int.tryParse(
      (payload['driver_id'] ?? payload['delivery_id'] ?? '').toString(),
    );
    final currentId = _sessionService.driverId.value;
    return targetId != null &&
        targetId > 0 &&
        currentId != null &&
        targetId != currentId;
  }

  bool _isOrderChatMessage(Map<String, dynamic> payload) {
    final type = payload['type']?.toString().trim().toLowerCase() ?? '';
    final refType = payload['ref_type']?.toString().trim().toLowerCase() ?? '';
    final screen = payload['screen']?.toString().trim().toLowerCase() ?? '';
    return type == 'order_chat_message' ||
        refType == 'order_chat' ||
        screen == 'order_chat';
  }

  bool _hasNativeVoiceCallAction(Map<String, dynamic> payload) {
    final action =
        payload['incoming_call_action']?.toString().trim().toLowerCase() ?? '';
    return action.isNotEmpty;
  }

  String _extractOrderId(Map<String, dynamic> payload) {
    final candidates = <Object?>[
      payload['order_id'],
      payload['ref_id'],
      payload['notification_ref_id'],
      payload['orderId'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty && value != '0' && value.toLowerCase() != 'null') {
        return value;
      }
    }

    return '';
  }

  Future<void> _handleVoiceCallPayload(Map<String, dynamic> payload) async {
    final orderId = _extractOrderId(payload);
    if (orderId.isEmpty) {
      return;
    }

    if (_hasNativeVoiceCallAction(payload)) {
      await _handleNativeVoiceCallIntent(payload);
      return;
    }

    if (Get.isRegistered<DriverOrderVoiceCallAlertService>()) {
      await Get.find<DriverOrderVoiceCallAlertService>().handleVoiceCallSignal(
        orderId: orderId,
      );
      return;
    }

    await _sessionService.setVoiceCallActiveOrderId(orderId);
  }

  Future<void> _handleOrderChatNotificationOpen(
    Map<String, dynamic> payload,
  ) async {
    final orderId = _extractOrderId(payload);
    debugPrint(
      '[FCM] Driver order chat notification opened orderId=$orderId keys=${payload.keys.toList(growable: false)}',
    );

    if (Get.isRegistered<DriverOrdersService>()) {
      final ordersService = Get.find<DriverOrdersService>();
      final activeOrder = ordersService.activeOrder.value;
      final activeOrderId = activeOrder?.id.toString().trim() ?? '';

      if (activeOrder != null &&
          (orderId.isEmpty || orderId == activeOrderId)) {
        debugPrint(
          '[FCM] Driver navigating to active order chat orderId=$activeOrderId',
        );
        await Get.to(() => OrderChatScreen(order: activeOrder));
        return;
      }
    }

    debugPrint(
      '[FCM] Driver falling back to current order screen orderId=$orderId',
    );
    await Get.toNamed(AppRoutes.currentOrder);
  }

  Future<void> _handleNativeVoiceCallIntent(
    Map<String, dynamic> payload,
  ) async {
    if (Get.key.currentState == null) {
      debugPrint(
        '[VOICE CALL] Driver native intent deferred until navigator ready orderId=${_extractOrderId(payload)}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_handleNativeVoiceCallIntent(payload));
      });
      return;
    }

    final orderId = _extractOrderId(payload);
    if (orderId.isEmpty) {
      return;
    }

    final action =
        payload['incoming_call_action']?.toString().trim().toLowerCase() ?? '';

    debugPrint(
      '[VOICE CALL] Driver native intent received orderId=$orderId action=$action',
    );

    if (action == 'reject') {
      await _sessionService.setVoiceCallActiveOrderId(null);
    } else {
      await _sessionService.setVoiceCallActiveOrderId(orderId);
    }

    if (Get.isRegistered<DriverOrderVoiceCallAlertService>()) {
      debugPrint(
        '[VOICE CALL] Driver native intent forwarded to alert service orderId=$orderId action=$action',
      );
      await Get.find<DriverOrderVoiceCallAlertService>()
          .handleNativeIncomingCallIntent(payload);
    }
  }

  Future<void> _rememberAndSyncToken(String? token) async {
    final normalizedToken = token?.trim() ?? '';
    if (normalizedToken.isEmpty) {
      return;
    }

    _pendingPushToken = normalizedToken;
    await _syncPendingToken();
  }

  Future<void> _syncPendingToken() async {
    final token = _pendingPushToken?.trim().isNotEmpty == true
        ? _pendingPushToken!.trim()
        : (await _firebaseMessaging.getToken())?.trim() ?? '';
    if (token.isEmpty) {
      return;
    }

    final driverId = _sessionService.driverId.value ?? 0;
    if (driverId <= 0) {
      _pendingPushToken = token;
      return;
    }

    try {
      await _apiService.saveDriverPushToken(
        driverId: driverId,
        pushToken: token,
        platform: defaultTargetPlatform.name,
        deviceName: defaultTargetPlatform.name,
      );
      _pendingPushToken = null;
    } catch (error) {
      debugPrint('Failed to sync driver push token: $error');
      _pendingPushToken = token;
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print(
      'Driver background notification: ${message.notification?.title} - ${message.notification?.body}',
    );
  }
}
