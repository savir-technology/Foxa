import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/home/homescreen_controller.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/remote/content/cookie_consent_data.dart';
import 'package:tks/view/widget/home/custombottomappbarhome.dart';
import 'package:tks/view/widget/home/first_launch_welcome_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const String _cookiePolicyDialogSeenKey =
      'cookie_policy_dialog_seen_v3';
  late final AnimationController _pageTransitionController;
  late final Animation<double> _pageTransition;
  int _lastAnimatedPage = 0;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<HomeScreenControllerImp>()) {
      Get.put(HomeScreenControllerImp());
    }
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1,
    );
    _pageTransition = CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareCookieConsentFlow();
    });
  }

  @override
  void dispose() {
    _pageTransitionController.dispose();
    super.dispose();
  }

  Future<void> _prepareCookieConsentFlow() async {
    try {
      await _syncStoredCookieConsentIfNeeded();
    } catch (_) {
      // Keep the app responsive if the sync layer is temporarily unavailable.
    }

    await _showCookiePolicyDialogIfNeeded();
  }

  Future<void> _syncStoredCookieConsentIfNeeded() async {
    final services = Get.find<MyServices>();
    if (!services.hasCookieConsent) {
      return;
    }

    await const CookieConsentData().syncStoredConsent(services);
  }

  Future<void> _showCookiePolicyDialogIfNeeded() async {
    if (!mounted) return;

    final services = Get.find<MyServices>();
    if (services.hasCookieConsent) return;

    await Get.dialog(
      FirstLaunchCookiePolicyDialog(
        isArabic: Get.locale?.languageCode == 'ar',
        onFinish: () async {
          await services.sharedPreferences
              .setBool(_cookiePolicyDialogSeenKey, true);
          if (Get.isDialogOpen == true) {
            Get.back();
          }
        },
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeScreenControllerImp>(
      builder: (controller) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final homeBackground =
            isDark ? const Color(0xFF0B0B0B) : const Color(0xFFFAFAFA);
        if (controller.currentpage != _lastAnimatedPage) {
          _lastAnimatedPage = controller.currentpage;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _pageTransitionController.forward(from: 0);
            }
          });
        }

        final body = IndexedStack(
          index: controller.currentpage,
          children: controller.listPage,
        );

        return Scaffold(
          extendBody: true,
          backgroundColor: homeBackground,
          bottomNavigationBar: const CustomBottomAppBarHome(),
          body: ColoredBox(
            color: homeBackground,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(_pageTransition),
              child: FadeTransition(
                opacity: _pageTransition,
                child: body,
              ),
            ),
          ),
          resizeToAvoidBottomInset: false,
        );
      },
    );
  }
}
