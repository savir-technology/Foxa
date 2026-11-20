// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tks/bindings/intialbindings.dart';
import 'package:tks/controler/them/theme_controller.dart';
import 'package:tks/core/localization/changelocal.dart';
import 'package:tks/core/services/background_music_service.dart';
import 'package:tks/core/services/order_voice_call_alert_service.dart';
import 'package:tks/core/services/order_voice_call_service.dart';
import 'package:tks/core/services/mapbox_runtime_config.dart';
import 'package:tks/core/services/route_observer.dart';
import 'package:tks/core/localization/transaltion.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:tks/core/theme/app_theme.dart';
import 'package:tks/firebase/firebase_notifications.dart';
import 'package:tks/firebase_options.dart';
import 'package:tks/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _ensureFirebaseInitialized();
  await initializeDateFormatting();

  await initialServices();
  await AppCurrency.load();
  Get.put(OrderVoiceCallService(), permanent: true);
  Get.put(OrderVoiceCallAlertService(), permanent: true);
  if (!kIsWeb) {
    // Register synchronously because Home's IndexedStack creates Settings
    // before optional startup services finish initializing.
    Get.put(BackgroundMusicService(), permanent: true);
  }

  // Start rendering immediately so the splash screen is visible while the
  // non-essential integrations finish initializing.
  runApp(const TksApp());

  unawaited(_initializeOptionalServices());
}

Future<void> _initializeOptionalServices() async {
  try {
    await MapboxRuntimeConfig.initialize();

    if (!kIsWeb) {
      final firebaseMessagingService =
          Get.put(FirebaseMessagingService(), permanent: true);
      await firebaseMessagingService.initFirebaseMessaging();
    }

    if (!kIsWeb) {
      await Get.find<BackgroundMusicService>().init();
    }
  } catch (error, stackTrace) {
    // These integrations must not prevent the splash/auth flow from opening.
    debugPrint('Optional startup service failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
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

class TksApp extends StatelessWidget {
  const TksApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = Get.put(LocaleController());
    final themeController = Get.put(ThemeController(Get.find()));

    return Obx(
      () => GetMaterialApp(
        translations: MyTranslation(),
        debugShowCheckedModeBanner: false,
        defaultTransition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 280),
        locale: localeController.language,
        fallbackLocale: const Locale('ar'),
        builder: (context, child) {
          final isArabic = (Get.locale?.languageCode ??
                  localeController.language.languageCode) ==
              'ar';
          return Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          );
        },
        theme: AppTheme.lightTheme(
          isArabic: localeController.language.languageCode == 'ar',
        ),
        darkTheme: AppTheme.darkTheme(
          isArabic: localeController.language.languageCode == 'ar',
        ),
        themeMode: themeController.themeMode,
        initialRoute: AppRoutes.splash,
        initialBinding: InitialBindings(),
        navigatorObservers: [appRouteObserver],
        getPages: routes,
      ),
    );
  }
}
