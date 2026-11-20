import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

class VoiceCallNotificationSettings {
  static const MethodChannel _notificationChannel =
      MethodChannel('voice_call_notification_settings');

  static Future<void> initialize() async {
    await _requestPermissions();
    _setupWorkManager();
    await _setupNotificationChannels();
  }

  static Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final plugin = FlutterLocalNotificationsPlugin();

      await plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notificationChannel.invokeMethod('requestNotificationPermissions');
    }
  }

  static void _setupWorkManager() {
    Workmanager().initialize(
      _callbackDispatcher,
    );

    Workmanager().registerPeriodicTask(
      'voice_call_check',
      'check_voice_calls',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> _setupNotificationChannels() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final plugin = FlutterLocalNotificationsPlugin();

      const callChannel = AndroidNotificationChannel(
        'voice_call_channel',
        'مكالمات السائق',
        description: 'قناة إشعارات المكالمات الصوتية من السائق',
        importance: Importance.high,
        playSound: true,
        enableLights: true,
        enableVibration: true,
      );

        await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(callChannel);

      const generalChannel = AndroidNotificationChannel(
        'general_notification_channel',
        'الإشعارات العامة',
        description: 'قناة الإشعارات العامة للتطبيق',
        importance: Importance.defaultImportance,
        playSound: true,
        enableLights: true,
        enableVibration: true,
      );

      await plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(generalChannel);
    }
  }

  static Future<void> scheduleCallNotification({
    required String orderId,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

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

    const details = NotificationDetails(android: androidDetails);

    await FlutterLocalNotificationsPlugin().show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
      payload: orderId,
    );
  }

  static Future<void> cancelAllNotifications() async {
    await FlutterLocalNotificationsPlugin().cancelAll();
  }

  static Future<void> cancelNotification(String orderId) async {
    await FlutterLocalNotificationsPlugin().cancel(id: int.parse(orderId));
  }
}

@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      return true;
    } catch (e) {
      return false;
    }
  });
}
