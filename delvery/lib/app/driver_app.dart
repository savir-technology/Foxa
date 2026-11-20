import 'package:delvery/controllers/home_controller.dart';
import 'package:delvery/controllers/incoming_order_controller.dart';
import 'package:delvery/controllers/order_controller.dart';
import 'package:delvery/controllers/shift_controller.dart';
import 'package:delvery/controllers/splash_controller.dart';
import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/core/theme/app_theme.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:delvery/screens/current_order_screen.dart';
import 'package:delvery/screens/delivery_success_screen.dart';
import 'package:delvery/screens/help_screen.dart';
import 'package:delvery/screens/history_screen.dart';
import 'package:delvery/screens/home_shell.dart';
import 'package:delvery/screens/incoming_order_screen.dart';
import 'package:delvery/screens/login_screen.dart';
import 'package:delvery/screens/notifications_screen.dart';
import 'package:delvery/screens/order_details_screen.dart';
import 'package:delvery/screens/otp_screen.dart';
import 'package:delvery/screens/password_setup_screen.dart';
import 'package:delvery/screens/profile_setup_screen.dart';
import 'package:delvery/screens/settings_screen.dart';
import 'package:delvery/screens/shift_screen.dart';
import 'package:delvery/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

class DriverApp extends StatelessWidget {
  const DriverApp({super.key, required this.sessionService});

  final DriverSessionService sessionService;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final appLocale = Locale(
        sessionService.localeCode.value.trim().toLowerCase() == 'en'
            ? 'en'
            : 'ar',
      );

      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Jeeb',
        translations: DriverTranslations(),
        theme: AppTheme.lightTheme(),
        themeMode: ThemeMode.light,
        locale: appLocale,
        fallbackLocale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final direction = appLocale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr;

          return Localizations.override(
            context: context,
            locale: appLocale,
            delegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            child: Directionality(
              textDirection: direction,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        initialRoute: AppRoutes.splash,
        initialBinding: BindingsBuilder(() {
          Get.lazyPut<SplashController>(
            () => SplashController(Get.find(), Get.find()),
          );
          Get.lazyPut<ShiftController>(
            () => ShiftController(Get.find(), Get.find()),
          );
          Get.lazyPut<OrderController>(
            () => OrderController(Get.find(), Get.find()),
            fenix: true,
          );
        }),
        getPages: [
          GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
          GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
          GetPage(name: AppRoutes.otp, page: () => const OtpScreen()),
          GetPage(
            name: AppRoutes.passwordSetup,
            page: () => const PasswordSetupScreen(),
          ),
          GetPage(
            name: AppRoutes.profileSetup,
            page: () => const ProfileSetupScreen(),
          ),
          GetPage(
            name: AppRoutes.shift,
            page: () => const ShiftScreen(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<ShiftController>()) {
                Get.lazyPut<ShiftController>(
                  () => ShiftController(Get.find(), Get.find()),
                  fenix: true,
                );
              }
            }),
          ),
          GetPage(
            name: AppRoutes.home,
            page: () => const HomeShell(),
            binding: BindingsBuilder(() {
              Get.lazyPut<HomeController>(
                () => HomeController(Get.find()),
                fenix: true,
              );
            }),
          ),
          GetPage(
            name: AppRoutes.incomingOrder,
            page: () => const IncomingOrderScreen(),
            fullscreenDialog: true,
            binding: BindingsBuilder(() {
              Get.put(IncomingOrderController(Get.find()));
            }),
          ),
          GetPage(
            name: AppRoutes.currentOrder,
            page: () => const CurrentOrderScreen(),
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<OrderController>()) {
                Get.lazyPut<OrderController>(
                  () => OrderController(Get.find(), Get.find()),
                  fenix: true,
                );
              }
            }),
          ),
          GetPage(
            name: AppRoutes.deliverySuccess,
            page: () {
              final args = Get.arguments;
              final data = args is Map ? args : <dynamic, dynamic>{};
              return DeliverySuccessScreen(
                orderId: int.tryParse('${data['orderId'] ?? 0}') ?? 0,
                elapsedText: '${data['elapsedText'] ?? '0m'}',
              );
            },
          ),
          GetPage(name: AppRoutes.history, page: () => const HistoryScreen()),
          GetPage(name: AppRoutes.help, page: () => const HelpScreen()),
          GetPage(
            name: AppRoutes.notifications,
            page: () => const NotificationsScreen(),
          ),
          GetPage(
            name: AppRoutes.orderDetails,
            page: () {
              final args = Get.arguments;
              if (args is! DriverOrder) {
                return Scaffold(
                  body: SafeArea(
                    child: Center(child: Text(tk('order_data_unavailable'))),
                  ),
                );
              }
              return OrderDetailsScreen(order: args);
            },
          ),
          GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
        ],
      );
    });
  }
}
