import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:workmanager/workmanager.dart';
import 'order_voice_call_service.dart';
import 'order_voice_call_alert_service.dart';

class VoiceCallNotificationService extends GetxService {
  static const MethodChannel _notificationChannel =
      MethodChannel('voice_call_notification');
  static const String _voiceCallTaskName = 'voice_call_check';

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final OrderVoiceCallService _voiceCallService;
  final OrderVoiceCallAlertService _alertService;
  Timer? _periodicCheckTimer;

  VoiceCallNotificationService(this._voiceCallService, this._alertService);

  @override
  void onInit() {
    debugPrint('[NOTIFICATION] Initializing Voice Call Notification Service');
    super.onInit();
    unawaited(_initializeNotifications());
    _setupWorkManager();
    _startPeriodicCheck();
    debugPrint(
        '[NOTIFICATION] Voice Call Notification Service initialized successfully');
  }

  @override
  void onClose() {
    debugPrint('[NOTIFICATION] Closing Voice Call Notification Service');
    _periodicCheckTimer?.cancel();
    debugPrint(
        '[NOTIFICATION] Voice Call Notification Service closed successfully');
    super.onClose();
  }

  Future<void> _initializeNotifications() async {
    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initAndroid,
      iOS: initIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    const channel = AndroidNotificationChannel(
      'voice_call_channel',
      'مكالمات السائق',
      description: 'قناة إشعارات المكالمات الصوتية من السائق',
      importance: Importance.high,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  void _setupWorkManager() {
    debugPrint('[NOTIFICATION] Setting up Work Manager');

    Workmanager().initialize(
      _callbackDispatcher,
    );

    Workmanager().registerPeriodicTask(
      'voice_call_check',
      _voiceCallTaskName,
      frequency: const Duration(minutes: 5),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    debugPrint('[NOTIFICATION] Work Manager setup completed');
  }

  static void _callbackDispatcher() {
    debugPrint('[NOTIFICATION] Work Manager callback started');

    Workmanager().executeTask((task, inputData) async {
      if (task == _voiceCallTaskName) {
        debugPrint('[NOTIFICATION] Executing voice call check task');

        try {
          if (Platform.isAndroid) {
            debugPrint('[NOTIFICATION] Checking for calls on Android');
            await _notificationChannel.invokeMethod('checkForCalls');
          }

          debugPrint(
              '[NOTIFICATION] Voice call check task completed successfully');
          return true;
        } catch (e) {
          debugPrint('[NOTIFICATION] Error in work manager task: $e');
          return false;
        }
      }

      debugPrint('[NOTIFICATION] Unknown task: $task');
      return false;
    });
  }

  void _startPeriodicCheck() {
    debugPrint('[NOTIFICATION] Starting periodic call check');

    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      unawaited(_checkForIncomingCalls());
    });

    unawaited(_checkForIncomingCalls());

    debugPrint('[NOTIFICATION] Periodic call check started successfully');
  }

  Future<void> _checkForIncomingCalls() async {
    try {
      debugPrint('[NOTIFICATION] Checking for incoming calls...');

      final activeOrderId = _alertService.activeOrderId;
      debugPrint('[NOTIFICATION] Active order ID: $activeOrderId');

      if (activeOrderId != null && activeOrderId.isNotEmpty) {
        final session = await _voiceCallService.loadSession(activeOrderId);
        debugPrint('[NOTIFICATION] Session status: ${session?.status}');

        if (session != null && session.status == 'ringing') {
          debugPrint(
              '[NOTIFICATION] Incoming call detected for order: $activeOrderId');
          await _showIncomingCallNotification(session);
        }
      }
    } catch (e) {
      debugPrint('[NOTIFICATION] Error checking for incoming calls: $e');
    }
  }

  Future<void> _showIncomingCallNotification(
      OrderVoiceCallSession session) async {
    final callerName = session.callerName.isNotEmpty
        ? session.callerName
        : (session.callerRole == 'driver' ? 'السائق' : 'العميل');

    const androidDetails = AndroidNotificationDetails(
      'voice_call_channel',
      'مكالمات السائق',
      channelDescription: 'إشعارات المكالمات الصوتية من السائق',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentSound: true,
      sound: 'ringtone.wav',
      badgeNumber: 1,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'مكالمة واردة',
      body: '$callerName يتصل بخصوص الطلب #${session.orderId}',
      notificationDetails: platformDetails,
      payload: session.orderId,
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final orderId = response.payload;
    if (orderId != null && orderId.isNotEmpty) {
      debugPrint('[NOTIFICATION] Notification clicked for order: $orderId');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _alertService.handleVoiceCallSignal(orderId: orderId);
      });
    }
  }

  Future<void> showCallNotification({
    required String orderId,
    required String callerName,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'voice_call_channel',
      'مكالمات السائق',
      channelDescription: 'إشعارات المكالمات الصوتية من السائق',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentSound: true,
      sound: 'ringtone.wav',
      badgeNumber: 1,
    );

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: orderId,
    );
  }
}
