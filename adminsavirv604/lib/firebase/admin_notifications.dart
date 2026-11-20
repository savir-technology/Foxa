import 'dart:async';

import 'package:admin_tks/admin_chat_users.dart';
import 'package:admin_tks/controler/order_controller.dart';
import 'package:admin_tks/core/services/local_notification_service.dart';
import 'package:admin_tks/order_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/core/services/dashboard_session_service.dart';
import 'package:audioplayers/audioplayers.dart';

final GlobalKey<NavigatorState> adminNavigatorKey = GlobalKey<NavigatorState>();

bool get adminPushSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

@pragma('vm:entry-point')
Future<void> adminFirebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
}

class AdminNotifications {
  AdminNotifications._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static StreamSubscription<RemoteMessage>? _messageSubscription;
  static StreamSubscription<String>? _tokenSubscription;
  static int? _currentVendorId;
  static final AudioPlayer _webAlertPlayer = AudioPlayer();

  static Future<void> initialize() async {
    if (!adminPushSupported) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    FirebaseMessaging.onBackgroundMessage(
        adminFirebaseMessagingBackgroundHandler);

    if (!kIsWeb) {
      await _messaging.subscribeToTopic('admin_chat');
    }

    if (kIsWeb) {
      await _registerWebToken();
    }

    _messageSubscription?.cancel();
    _messageSubscription = FirebaseMessaging.onMessage.listen((message) async {
      final title = message.notification?.title ?? 'تنبيه جديد';
      final body =
          message.notification?.body ?? 'يوجد تحديث جديد داخل لوحة التحكم';
      await LocalNotificationService.show(title: title, body: body);
      if (kIsWeb) {
        try {
          await _webAlertPlayer.stop();
          await _webAlertPlayer.play(
            AssetSource('audio/notification.wav'),
          );
        } catch (_) {}
      }
      _refreshAdminData(message);
    });

    _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((_) async {
      if (!kIsWeb) {
        await _messaging.subscribeToTopic('admin_chat');
      }
      if (!kIsWeb && (_currentVendorId ?? 0) > 0) {
        await _messaging.subscribeToTopic('vendor_orders_${_currentVendorId!}');
      }
      if (kIsWeb) {
        await _registerWebToken();
      }
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleMessage(initialMessage);
      });
    }

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }

  static Future<void> _registerWebToken() async {
    try {
      final session = await DashboardSessionService.instance.loadSession();
      if (session == null || !session.isValid) return;

      final token = await _messaging.getToken(
        vapidKey:
            'BFHRbJJ6THR9RvDiWRWGKLg-EcOJ1cYRL9ZZcVUvwuF8VANlON9H4EADZpEf2Yr2iQaWQ2_Q_3IRQtNx4LQ-D7Y',
      );
      if (token == null || token.trim().isEmpty) return;
      await DashboardApiClient.postJsonUrl(
        DashboardApiClient.dashUri('/notifications/save_web_push_token.php')
            .toString(),
        body: {'token': token, 'platform': 'web'},
      );
    } catch (error) {
      debugPrint('[WEB PUSH] token registration skipped: $error');
    }
  }

  static void handleMessage(RemoteMessage message) {
    _refreshAdminData(message);

    final screen = (message.data['screen'] ?? '').toString().toLowerCase();
    final type = (message.data['type'] ?? '').toString().toLowerCase();
    final navigator = adminNavigatorKey.currentState;
    if (navigator == null) return;

    if (screen == 'chat' || type == 'admin_chat_message') {
      navigator.push(MaterialPageRoute(builder: (_) => const AdminChatUsers()));
      return;
    }

    if (screen == 'orders' ||
        type == 'admin_new_order' ||
        type == 'vendor_new_order') {
      navigator.push(MaterialPageRoute(builder: (_) => const OrderPage()));
    }
  }

  static Future<void> setVendorContext(int vendorId) async {
    if (!adminPushSupported) return;

    if (!kIsWeb && (_currentVendorId ?? 0) > 0) {
      await _messaging
          .unsubscribeFromTopic('vendor_orders_${_currentVendorId!}');
    }

    _currentVendorId = vendorId > 0 ? vendorId : null;

    if (!kIsWeb && (_currentVendorId ?? 0) > 0) {
      await _messaging.subscribeToTopic('vendor_orders_${_currentVendorId!}');
    }
    if (kIsWeb) {
      await _registerWebToken();
    }
  }

  static void _refreshAdminData(RemoteMessage message) {
    final type = (message.data['type'] ?? '').toString().toLowerCase();
    if (type == 'admin_new_order' || type == 'vendor_new_order') {
      try {
        Get.find<OrderController>().fetchOrders();
      } catch (_) {}
    }
  }
}
