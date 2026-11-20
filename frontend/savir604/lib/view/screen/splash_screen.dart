import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navigationTimer;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 4), _goNext);
  }

  Future<void> _goNext() async {
    if (_didNavigate || !mounted) {
      return;
    }
    _didNavigate = true;

    final services = Get.find<MyServices>();
    if (services.hasPendingGoogleVerification) {
      Get.offAllNamed(AppRoutes.googlePhoneVerification);
      return;
    }

    if (services.hasPendingProfile) {
      Get.offAllNamed(AppRoutes.userProfileSetup);
      return;
    }

    if (services.hasAuthenticatedSession || services.hasGuestSession) {
      Get.offAllNamed(AppRoutes.homepage);
      return;
    }

    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final logoWidth = (constraints.maxWidth * 0.62).clamp(
                220.0,
                330.0,
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: const Alignment(0, -0.12),
                    child: Image.asset(
                      'assets/images/logo1.png',
                      width: logoWidth,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
