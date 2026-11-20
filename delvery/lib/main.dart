import 'package:firebase_core/firebase_core.dart';
import 'package:delvery/app/driver_app.dart';
import 'package:delvery/core/services/driver_background_service.dart';
import 'package:delvery/core/services/driver_api_service.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/core/services/driver_order_voice_call_alert_service.dart';
import 'package:delvery/core/services/driver_order_voice_call_service.dart';
import 'package:delvery/firebase/driver_firebase_notifications.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/core/services/driver_platform_settings.dart';
import 'package:delvery/controllers/auth_controller.dart';
import 'package:delvery/controllers/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:delvery/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DriverBackgroundService.configure();
  await _ensureFirebaseInitialized();
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');
  await initializeDateFormatting();
  await DriverPlatformSettings.load();

  final apiService = Get.put(DriverApiService(), permanent: true);
  final sessionService = Get.put(
    DriverSessionService(apiService),
    permanent: true,
  );
  Get.put(AuthController(sessionService), permanent: true);
  Get.put(DriverOrdersService(sessionService, apiService), permanent: true);
  Get.put(DriverOrderVoiceCallService(apiService), permanent: true);
  Get.put(DriverOrderVoiceCallAlertService(), permanent: true);
  Get.put(SettingsController(sessionService), permanent: true);
  await DriverFirebaseMessagingService().initFirebaseMessaging();

  runApp(DriverApp(sessionService: sessionService));
}

Future<void> _ensureFirebaseInitialized() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') {
      rethrow;
    }
  }
}
