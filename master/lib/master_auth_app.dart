import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:lottie/lottie.dart' hide Marker;
import 'package:qr/qr.dart' as qr;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'master/core/services/master_web_push_service.dart';
import 'master/core/platform/master_html.dart' as html;
import 'master/core/platform/master_ui_web.dart' as ui_web;

// ignore_for_file: unused_element

part 'master/features/delivery_logistics/models/delivery_logistics_models.dart';
part 'master/features/delivery_logistics/controllers/delivery_logistics_api.dart';
part 'master/features/delivery_logistics/controllers/delivery_logistics_controller.dart';
part 'master/features/delivery_logistics/views/pages/delivery_logistics_pages.dart';
part 'master/features/delivery_logistics/views/workspaces/delivery_logistics_workspaces.dart';
part 'master/features/delivery_logistics/views/workspaces/delivery_distribution_workspace.dart';
part 'master/features/delivery_logistics/views/workspaces/delivery_tracking_workspace.dart';
part 'master/features/delivery_logistics/views/workspaces/delivery_additional_workspaces.dart';
part 'master/features/delivery_logistics/views/widgets/delivery_logistics_widgets.dart';
part 'master/features/delivery_logistics/views/widgets/delivery_logistics_sidebar.dart';
part 'master/features/restaurants/views/restaurant_management_pages.dart';
part 'master/features/users/views/users_management_pages.dart';
part 'master/features/users/views/users_additional_pages.dart';
part 'master/features/finance/views/finance_management_pages.dart';
part 'master/features/marketing/views/marketing_growth_pages.dart';
part 'master/features/reports/views/reports_pages.dart';
part 'master/features/reports/views/reports_unified_page.dart';
part 'master/features/operations/views/access_management_page.dart';
part 'master/features/operations/views/legal_content_workspace.dart';
part 'master/features/auth/views/auth_pages.dart';
part 'master/features/dashboard_home/views/dashboard_home_page.dart';
part 'master/features/support/views/master_support_chats_page.dart';
part 'master/features/support/views/master_support_unified_page.dart';
part 'master/features/notifications/views/master_notifications_page.dart';
part 'master/features/operations/views/operations_pages.dart';
part 'master/features/operations/views/operations_unified_page.dart';
part 'master/features/orders/views/pages/orders_pages.dart';
part 'master/features/orders/views/workspaces/orders_main_workspace.dart';
part 'master/features/orders/views/workspaces/order_statuses_workspace.dart';
part 'master/features/orders/views/workspaces/pickup_orders_workspace.dart';
part 'master/features/orders/views/workspaces/order_chats_workspace.dart';
part 'master/features/orders/views/workspaces/printing_invoices_workspace.dart';
part 'master/features/orders/views/workspaces/scheduled_orders_workspace.dart';
part 'master/features/orders/views/widgets/orders_shared_widgets.dart';
part 'master/features/operations/views/operations_components.dart';
part 'master/features/operations/views/operations_activity_widgets.dart';
part 'master/features/operations/views/operations_tracking_widgets.dart';
part 'master/features/operations/models/operations_models.dart';
part 'master/features/operations/views/operations_map_widgets.dart';
part 'master/shared/widgets/auth_form_widgets.dart';
part 'master/core/utils/master_formatters.dart';
part 'master/core/api/master_auth_api_service.dart';
part 'master/core/navigation/master_navigation_registry.dart';

const String _kApiBaseUrl = 'https://savir-technology.online/roaqv2/';
// FOXA brand palette shared with the customer app.
const Color _kDeepGreen = Color(0xFF0B0B0B);
const Color _kPrimaryGreen = Color(0xFFF97316);
const Color _kAccentGreen = Color(0xFFFFA366);
const Color _kInk = Color(0xFF0B0B0B);
const Color _kMutedInk = Color(0xFF4B5563);
const Color _kLightBackground = Color(0xFFF8FAF9);
const Color _kSurfaceAlt = Color(0xFFFFF7ED);
const String _kBackgroundAsset = 'assets/img/delivery_banner.png';
const String _kAuthBackgroundAsset = 'assets/img/back_auth.png';
const String _kAuthBackdropAsset = 'assets/img/backer.png';
const String _kLogoAsset = 'assets/img/logo.png';

class _SmoothPageTransitionBuilder extends PageTransitionsBuilder {
  const _SmoothPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final slide = Tween<Offset>(
      begin: const Offset(0.018, 0),
      end: Offset.zero,
    ).animate(curvedAnimation);

    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class MasterBrandMark extends StatelessWidget {
  const MasterBrandMark({
    super.key,
    this.width = 110,
    this.height = 42,
    this.onDark = false,
  });

  final double width;
  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kAccentGreen, _kPrimaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: _kAccentGreen.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: _kDeepGreen,
                size: 25,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'FOXA',
              style: TextStyle(
                color: onDark ? Colors.white : _kDeepGreen,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unified branded state animation used by loading, empty and unavailable
/// states. Keeping the animations local avoids a network request for UI state.
class MasterStateAnimation extends StatelessWidget {
  const MasterStateAnimation({
    super.key,
    this.asset = 'assets/lottie/loading.json',
    this.size = 86,
    this.label,
    this.color,
  });

  final String asset;
  final double size;
  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            asset,
            repeat: true,
            delegates: color == null
                ? null
                : LottieDelegates(
                    values: [
                      ValueDelegate.color(const ['**'], value: color!),
                    ],
                  ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 10),
          Text(
            label!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kMutedInk,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

const String _kMapboxAccessToken = String.fromEnvironment(
  'MAPBOX_ACCESS_TOKEN',
  // Public Mapbox token used by the platform web map. It can be overridden
  // at build time with --dart-define=MAPBOX_ACCESS_TOKEN=...
  defaultValue:
      'pk.eyJ1IjoiaXNsYW04ODkwIiwiYSI6ImNtcTVwdnlpczAwcjQycnNrcTZkYnNqa3IifQ.NY-wxxxpO5XoCZTD9v7kiQ',
);
const String _kMapboxStyleId = 'mapbox/streets-v12';
const String _kMapboxTileUrl =
    'https://api.mapbox.com/styles/v1/$_kMapboxStyleId/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}';
const String _kOsmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String _kCartoTileUrl =
    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
const String _kEsriTileUrl =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';

/// Currency metadata shared by every Master page.
///
/// It is populated from `platform_settings` after authentication, so pages
/// never need to hard-code the Saudi Riyal symbol in their own widgets.
class MasterCurrency {
  static String code = 'SAR';
  static String symbol = 'ر.س';
  static String name = 'الريال السعودي';
  static String nameEn = 'Saudi Riyal';

  static void apply(Map<String, dynamic> settings) {
    final nextCode = (settings['default_currency_code'] ?? '')
        .toString()
        .trim();
    final nextSymbol = (settings['default_currency_symbol'] ?? '')
        .toString()
        .trim();
    final nextName = (settings['default_currency_name'] ?? '')
        .toString()
        .trim();
    final nextNameEn = (settings['default_currency_name_en'] ?? '')
        .toString()
        .trim();
    if (nextCode.isNotEmpty) code = nextCode;
    if (nextSymbol.isNotEmpty) symbol = nextSymbol;
    if (nextName.isNotEmpty) name = nextName;
    if (nextNameEn.isNotEmpty) nameEn = nextNameEn;
  }
}

class MasterApp extends StatefulWidget {
  const MasterApp({super.key});

  @override
  State<MasterApp> createState() => _MasterAppState();
}

class _MasterAppState extends State<MasterApp> {
  final MasterAuthApiService _api = MasterAuthApiService();
  final MasterAuthStorage _storage = MasterAuthStorage();

  MasterSession? _session;
  bool _booting = true;
  final MasterWebPushService _webPushService = MasterWebPushService();

  String? _portalForRoleId(int roleId) {
    return <int, String>{
      2: 'finance',
      10: 'finance',
      11: 'support',
      12: 'operations',
      13: 'merchants',
      14: 'analytics',
      15: 'legal',
    }[roleId];
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _api.dispose();
    unawaited(_webPushService.dispose());
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final stored = await _storage.loadSession();
      if (stored == null) {
        if (!mounted) {
          return;
        }
        setState(() => _booting = false);
        return;
      }

      if (stored.isExpired) {
        await _storage.clearSession();
        if (!mounted) {
          return;
        }
        setState(() {
          _session = null;
          _booting = false;
        });
        return;
      }

      final master = await _api.me(stored.token);
      try {
        await _api.refreshMasterCurrency(stored.token);
      } catch (_) {
        // Currency loading must not prevent an already-authenticated Master
        // session from opening.
      }
      final refreshed = stored.copyWith(
        master: master,
        portal: stored.portal ?? _portalForRoleId(master.adminRoleId),
      );
      await _storage.saveSession(refreshed);

      if (!mounted) {
        return;
      }
      setState(() {
        _session = refreshed;
        _booting = false;
      });
      unawaited(_initializeWebPushSafely(refreshed.token));
    } catch (_) {
      await _storage.clearSession();
      if (!mounted) {
        return;
      }
      setState(() {
        _session = null;
        _booting = false;
      });
    }
  }

  Future<void> _handleAuthenticated(MasterSession session) async {
    await _storage.saveSession(session);
    try {
      await _api.refreshMasterCurrency(session.token);
    } catch (_) {
      // The platform can still open with the safe default if this request
      // temporarily fails; the settings page retries when opened.
    }
    if (!mounted) {
      return;
    }
    _masterRouteStack.clear();
    setState(() => _session = session);
    // Notifications must never block the first screen after login.
    unawaited(_initializeWebPushSafely(session.token));
  }

  Future<void> _initializeWebPushSafely(String token) async {
    try {
      await _webPushService.initialize(token);
    } catch (error) {
      debugPrint('Master web push initialization failed: $error');
    }
  }

  Future<void> _handleLogout() async {
    final token = _session?.token;
    if (token != null && token.isNotEmpty) {
      try {
        await _api.logout(token);
      } catch (_) {
        // Ignore network issues during logout and clear local state anyway.
      }
    }
    await _storage.clearSession();
    if (!mounted) {
      return;
    }
    _masterRouteStack.clear();
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FOXA Master',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: <NavigatorObserver>[_masterNavigatorObserver],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.notoKufiArabic().fontFamily,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: _kPrimaryGreen,
          onPrimary: Colors.white,
          secondary: _kMutedInk,
          onSecondary: Colors.white,
          error: Color(0xFFDC2626),
          onError: Colors.white,
          surface: Colors.white,
          onSurface: _kInk,
        ),
        textTheme: GoogleFonts.notoKufiArabicTextTheme().apply(
          bodyColor: _kInk,
          displayColor: _kInk,
        ),
        scaffoldBackgroundColor: _kLightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: _kInk,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        shadowColor: const Color(0x180B0B0B),
        dividerColor: const Color(0x1A4B5563),
        splashFactory: InkRipple.splashFactory,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: _SmoothPageTransitionBuilder(),
            TargetPlatform.linux: _SmoothPageTransitionBuilder(),
          },
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shadowColor: const Color(0x180B0B0B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0x1A4B5563)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: _kMutedInk),
          labelStyle: const TextStyle(color: _kMutedInk),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0x224B5563)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0x224B5563)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kAccentGreen, width: 2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _kPrimaryGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimaryGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFB8C3BC),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(132, 46),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return _kPrimaryGreen;
            }
            return Colors.white;
          }),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 34),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            textStyle: const TextStyle(
              fontSize: 12.2,
              fontWeight: FontWeight.w700,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
      builder: (context, child) {
        final wrapped = child ?? const SizedBox.shrink();
        return Directionality(textDirection: TextDirection.rtl, child: wrapped);
      },
      home: _booting
          ? const MasterLoadingPage()
          : _session == null
          ? MasterPortalPageV2(api: _api, onAuthenticated: _handleAuthenticated)
          : MasterDashboardPage(
              session: _session!,
              onLogout: _handleLogout,
              api: _api,
            ),
    );
  }
}
