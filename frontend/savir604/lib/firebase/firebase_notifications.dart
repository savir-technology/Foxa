// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tks/controler/notification_con.dart';
import 'package:tks/core/functions/notification_navigation.dart';
import 'package:tks/core/services/order_voice_call_alert_service.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/linkapi/linkapi.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static const MethodChannel _permissionChannel =
      MethodChannel('notification_permissions');
  static const MethodChannel _voiceCallIntentChannel =
      MethodChannel('voice_call_intent');
  static const String _pendingPushTokenKey = 'aleppo_pending_fcm_token_v1';

  bool _nativeVoiceCallIntentBound = false;

  Future<void> initFirebaseMessaging() async {
    // Bind this before token/permission/network work. When Android launches
    // the app from a cold start via the Accept action, the intent must not
    // wait for FCM token synchronization to finish.
    _bindNativeVoiceCallIntentBridge();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumeInitialNativeVoiceCallIntent());
    });

    await _ensureAndroidNotificationPermission();
    final NotificationSettings settings =
        await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('FCM authorization: ${settings.authorizationStatus}');

    await _refreshToken();
    final token = await _firebaseMessaging.getToken();
    print('Firebase Token: $token');
    await _cachePendingToken(token);
    await _syncTokenWithServer(token, source: 'startup');

    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print('Firebase token refreshed: $newToken');
      await _cachePendingToken(newToken);
      await _syncTokenWithServer(newToken, source: 'refresh');
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = Map<String, dynamic>.from(message.data);
      debugPrint(
        '[VOICE CALL] Customer incoming FCM type=${data['type']?.toString() ?? ''} keys=${data.keys.toList(growable: false)}',
      );
      if (_isVoiceCallMessage(data)) {
        await _handleVoiceCallPayload(data);
        return;
      }

      final controller = Get.isRegistered<NotificationController>()
          ? Get.find<NotificationController>()
          : Get.put(NotificationController());

      controller.addForegroundNotification(
        id: message.data['notification_id']?.toString() ?? '',
        title: message.notification?.title ?? 'New notification',
        body: message.notification?.body ?? '',
        type: message.data['type']?.toString() ?? 'general',
        refType: message.data['ref_type']?.toString() ?? '',
        refId: message.data['ref_id']?.toString() ?? '',
        payload: Map<String, dynamic>.from(message.data),
      );

      Get.snackbar(
        message.notification?.title ?? 'New notification',
        message.notification?.body ?? '',
        snackPosition: SnackPosition.TOP,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
        '[VOICE CALL] Customer onMessageOpenedApp keys=${message.data.keys.toList(growable: false)}',
      );
      unawaited(_handleNotificationOpen(message));
    });

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '[VOICE CALL] Customer initialMessage keys=${initialMessage.data.keys.toList(growable: false)}',
      );
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
      debugPrint('Failed to clear stale Firebase token: $error');
    }
  }

  Future<void> syncTokenForUser(
    int userId, {
    String source = 'manual',
  }) async {
    if (userId <= 0) {
      debugPrint('[FCM] sync skipped ($source): invalid user id');
      return;
    }

    final token = await _resolveTokenForSync();
    if (token.isEmpty) {
      debugPrint('[FCM] sync skipped ($source): no token available');
      return;
    }

    await _syncTokenToServer(userId, token, source: source);
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
      // The Firebase permission request below is still a fallback.
    }
  }

  Future<void> _handleNotificationOpen(RemoteMessage message) async {
    final data = Map<String, dynamic>.from(message.data);
    debugPrint(
      '[VOICE CALL] Customer notification open type=${data['type']?.toString() ?? ''} keys=${data.keys.toList(growable: false)}',
    );
    if (_isVoiceCallMessage(data)) {
      await _handleVoiceCallPayload(data);
      return;
    }

    openNotificationDestination(
      type: data['type']?.toString() ?? '',
      refType: data['ref_type']?.toString() ?? '',
      refId: data['ref_id']?.toString() ?? '',
      payload: data,
      fallbackToInbox: true,
    );
  }

  bool _isVoiceCallMessage(Map<String, dynamic> payload) {
    final type = payload['type']?.toString().trim().toLowerCase() ?? '';
    return type == 'voice_call' || type == 'voice_call_status';
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

  void _bindNativeVoiceCallIntentBridge() {
    if (_nativeVoiceCallIntentBound) {
      return;
    }
    _nativeVoiceCallIntentBound = true;
    debugPrint('[VOICE CALL] native voice call intent bridge bound');

    _voiceCallIntentChannel.setMethodCallHandler((call) async {
      if (call.method != 'onVoiceCallIntent') {
        return null;
      }

      final payload = _normalizeMethodArguments(call.arguments);
      debugPrint(
        '[VOICE CALL] native voice call intent received keys=${payload.keys.toList(growable: false)} action=${payload['incoming_call_action']?.toString() ?? ''} orderId=${_extractOrderId(payload)}',
      );
      await _handleNativeVoiceCallIntent(payload);
      return null;
    });
  }

  Future<void> _consumeInitialNativeVoiceCallIntent() async {
    try {
      for (var attempt = 0; attempt < 20; attempt++) {
        final raw = await _voiceCallIntentChannel.invokeMethod<Object?>(
          'getInitialVoiceCallData',
        );
        final payload = _normalizeMethodArguments(raw);
        debugPrint(
          '[VOICE CALL] initial native voice call intent keys=${payload.keys.toList(growable: false)} action=${payload['incoming_call_action']?.toString() ?? ''} orderId=${_extractOrderId(payload)}',
        );
        if (_isVoiceCallMessage(payload) &&
            _hasNativeVoiceCallAction(payload)) {
          await _handleNativeVoiceCallIntent(payload);
        }
        if (payload.isNotEmpty || attempt == 19) {
          return;
        }
        await Future.delayed(const Duration(milliseconds: 120));
      }
    } on MissingPluginException catch (error) {
      debugPrint(
          '[VOICE CALL] initial native voice call bridge not ready: $error');
    } catch (error, stackTrace) {
      debugPrint(
          '[VOICE CALL] consumeInitialNativeVoiceCallIntent() failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  Map<String, dynamic> _normalizeMethodArguments(Object? arguments) {
    if (arguments is Map) {
      return arguments.map((key, value) => MapEntry('$key', value));
    }

    return <String, dynamic>{};
  }

  Future<void> _cachePendingToken(String? token) async {
    final normalizedToken = token?.trim() ?? '';
    if (normalizedToken.isEmpty) {
      return;
    }

    _cachedPushToken = normalizedToken;

    try {
      if (Get.isRegistered<MyServices>()) {
        final services = Get.find<MyServices>();
        await services.sharedPreferences.setString(
          _pendingPushTokenKey,
          normalizedToken,
        );
      }
    } catch (_) {
      // Best-effort cache only.
    }
  }

  String? _cachedPushToken;

  Future<String> _resolveTokenForSync() async {
    final cachedToken = _cachedPushToken?.trim() ?? '';
    if (cachedToken.isNotEmpty) {
      return cachedToken;
    }

    try {
      if (Get.isRegistered<MyServices>()) {
        final services = Get.find<MyServices>();
        final pendingToken = services.sharedPreferences
                .getString(_pendingPushTokenKey)
                ?.trim() ??
            '';
        if (pendingToken.isNotEmpty) {
          _cachedPushToken = pendingToken;
          return pendingToken;
        }
      }
    } catch (_) {
      // Keep going and ask Firebase directly.
    }

    final token = (await _firebaseMessaging.getToken())?.trim() ?? '';
    if (token.isNotEmpty) {
      _cachedPushToken = token;
    }

    return token;
  }

  Future<void> _handleVoiceCallPayload(Map<String, dynamic> payload) async {
    final orderId = _extractOrderId(payload);
    if (orderId.isEmpty) {
      debugPrint(
          '[VOICE CALL] Customer voice call payload ignored because orderId is empty');
      return;
    }

    if (_hasNativeVoiceCallAction(payload)) {
      debugPrint(
        '[VOICE CALL] Customer voice call payload routed to native intent orderId=$orderId',
      );
      await _handleNativeVoiceCallIntent(payload);
      return;
    }

    if (Get.isRegistered<OrderVoiceCallAlertService>()) {
      debugPrint(
        '[VOICE CALL] Customer voice call payload forwarded to alert service orderId=$orderId',
      );
      await Get.find<OrderVoiceCallAlertService>().handleVoiceCallSignal(
        orderId: orderId,
      );
      return;
    }

    final services = Get.find<MyServices>();
    await services.sharedPreferences.setString(
      MyServices.keyVoiceCallActiveOrderId,
      orderId,
    );
    debugPrint(
      '[VOICE CALL] Customer voice call payload stored active order orderId=$orderId',
    );
  }

  Future<void> _handleNativeVoiceCallIntent(
    Map<String, dynamic> payload,
  ) async {
    if (Get.key.currentState == null) {
      debugPrint(
        '[VOICE CALL] native voice call intent deferred because navigator is not ready orderId=${_extractOrderId(payload)}',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_handleNativeVoiceCallIntent(payload));
      });
      return;
    }

    final orderId = _extractOrderId(payload);
    if (orderId.isEmpty) {
      debugPrint(
          '[VOICE CALL] native voice call intent ignored because orderId is empty');
      return;
    }

    final action =
        payload['incoming_call_action']?.toString().trim().toLowerCase() ?? '';
    debugPrint(
      '[VOICE CALL] native voice call intent handling orderId=$orderId action=$action',
    );

    if (Get.isRegistered<OrderVoiceCallAlertService>()) {
      await Get.find<OrderVoiceCallAlertService>()
          .handleNativeIncomingCallIntent(
        payload,
      );
      debugPrint(
        '[VOICE CALL] native voice call intent forwarded to alert service orderId=$orderId action=$action',
      );
      return;
    }

    final services = Get.find<MyServices>();
    await services.sharedPreferences.setString(
      MyServices.keyVoiceCallActiveOrderId,
      orderId,
    );
    debugPrint(
      '[VOICE CALL] native voice call intent stored active order orderId=$orderId action=$action',
    );

    if (action == 'reject') {
      await services.sharedPreferences.remove(
        MyServices.keyVoiceCallActiveOrderId,
      );
      debugPrint(
        '[VOICE CALL] native voice call intent cleared active order after reject orderId=$orderId',
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print(
      'Background notification: ${message.notification?.title} - ${message.notification?.body}',
    );
  }

  Future<void> _syncTokenWithServer(
    String? token, {
    required String source,
  }) async {
    final normalizedToken = token?.trim() ?? '';
    if (normalizedToken.isEmpty) {
      return;
    }

    if (!Get.isRegistered<MyServices>()) {
      await _cachePendingToken(normalizedToken);
      return;
    }

    final services = Get.find<MyServices>();
    final currentUserId = services.sharedPreferences.getInt('id') ?? 0;
    if (currentUserId <= 0) {
      await _cachePendingToken(normalizedToken);
      debugPrint('[FCM] token cached ($source) because user id is unavailable');
      return;
    }

    await _syncTokenToServer(currentUserId, normalizedToken, source: source);
  }

  Future<void> _syncTokenToServer(
    int userId,
    String token, {
    required String source,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppLink.server}/chat/save_token.php'),
        body: {
          'user_id': userId.toString(),
          'fcm_token': token,
        },
      );

      debugPrint(
        '[FCM] token sync ($source) user=$userId status=${response.statusCode} body=${response.body}',
      );

      final decoded = jsonDecode(response.body);
      final success = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded is Map &&
          '${decoded['status']}' == 'success';

      if (success) {
        _cachedPushToken = token;
        if (Get.isRegistered<MyServices>()) {
          final services = Get.find<MyServices>();
          await services.sharedPreferences.remove(_pendingPushTokenKey);
        }
        return;
      }

      await _cachePendingToken(token);
    } catch (error, stackTrace) {
      debugPrint('[FCM] token sync failed ($source) user=$userId');
      debugPrint('$error');
      debugPrint('$stackTrace');
      await _cachePendingToken(token);
    }
  }
}
