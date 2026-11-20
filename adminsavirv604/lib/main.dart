import 'dart:async';

import 'package:admin_tks/auth/dashboard_auth_pages.dart';
import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/core/services/dashboard_routes.dart';
import 'package:admin_tks/core/services/local_notification_service.dart';
import 'package:admin_tks/core/services/mapbox_runtime_config.dart';
import 'package:admin_tks/firebase/admin_notifications.dart';
import 'package:admin_tks/firebase_options.dart';
import 'package:admin_tks/add.dart';
import 'package:admin_tks/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_tks/categories_page.dart';
import 'package:admin_tks/delivery_operations_page.dart';
import 'package:admin_tks/menu_management_page.dart';
import 'package:admin_tks/order_page.dart';
import 'package:admin_tks/order_status_page.dart';
import 'package:admin_tks/offers_marketing_page.dart';
import 'package:admin_tks/profit_report_page.dart';
import 'package:admin_tks/restaurant_settings_page.dart';
import 'package:admin_tks/sales_report_page.dart';
import 'package:admin_tks/reviews_ratings_page.dart';
import 'package:admin_tks/waste_ledger_page.dart';
import 'package:admin_tks/working_hours_page.dart';
import 'package:admin_tks/vendors_page.dart';
import 'package:admin_tks/user_page.dart';
import 'package:admin_tks/ads.dart';
import 'package:admin_tks/story_management_page.dart';
import 'package:admin_tks/inventory_simple_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    debugPrint('Firebase startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  final authController = Get.put(DashboardAuthController(), permanent: true);

  runApp(const MyApp());

  // Optional integrations must never leave the dashboard on a white screen.
  unawaited(_initializeDashboard(authController));
}

Future<void> _initializeDashboard(
  DashboardAuthController authController,
) async {
  try {
    await authController.restoreSession();
  } catch (error, stackTrace) {
    debugPrint('Dashboard session restore failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  } finally {
    if (!authController.isReady.value) {
      authController.isReady.value = true;
    }
  }

  try {
    await MapboxRuntimeConfig.initialize();
  } catch (error) {
    debugPrint('Mapbox startup failed: $error');
  }

  if (!adminPushSupported) return;
  try {
    await LocalNotificationService.initialize();
    await AdminNotifications.initialize();
  } catch (error, stackTrace) {
    debugPrint('Dashboard notifications startup failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Roaq Vendor',
      theme: buildAppTheme(),
      initialRoute: '/',
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorKey: adminNavigatorKey,
      getPages: [
        GetPage(name: '/', page: () => const DashboardRootPage()),
        GetPage(
          name: '/DashboardRootPage',
          page: () => const DashboardRootPage(),
        ),
        GetPage(name: DashboardRoutes.orders, page: () => const OrderPage()),
        GetPage(
          name: DashboardRoutes.orderStatuses,
          page: () => const OrderStatusPage(),
        ),
        GetPage(
          name: DashboardRoutes.deliveryOperations,
          page: () => const DeliveryOperationsPage(),
        ),
        GetPage(
          name: DashboardRoutes.categories,
          page: () => const CategoriesPage(),
        ),
        GetPage(
          name: DashboardRoutes.menu,
          page: () => const MenuManagementPage(),
        ),
        GetPage(
          name: DashboardRoutes.addProduct,
          page: () => const AddProductPage(),
        ),
        GetPage(
          name: DashboardRoutes.inventory,
          page: () => const InventorySimplePage(),
        ),
        GetPage(
          name: DashboardRoutes.coupons,
          page: () => const OffersMarketingPage(),
        ),
        GetPage(
          name: DashboardRoutes.hours,
          page: () => const WorkingHoursPage(),
        ),
        GetPage(
          name: DashboardRoutes.reviews,
          page: () => const ReviewsRatingsPage(),
        ),
        GetPage(
            name: DashboardRoutes.analytics,
            page: () => const SalesReportPage()),
        GetPage(
            name: DashboardRoutes.salesReport,
            page: () => const SalesReportPage()),
        GetPage(
            name: DashboardRoutes.profitReport,
            page: () => const ProfitReportPage()),
        GetPage(
            name: DashboardRoutes.settings,
            page: () => const RestaurantSettingsPage()),
        GetPage(
            name: DashboardRoutes.waste, page: () => const WasteLedgerPage()),
        GetPage(
          name: DashboardRoutes.masterVendors,
          page: () => const VendorsPage(),
        ),
        GetPage(
          name: DashboardRoutes.masterUsers,
          page: () => const UserPage(),
        ),
        GetPage(
          name: DashboardRoutes.masterAds,
          page: () => const Ads2Page(),
        ),
        GetPage(
          name: DashboardRoutes.masterStories,
          page: () => const StoryManagementPage(),
        ),
      ],
    );
  }
}
