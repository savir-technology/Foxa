// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/services.dart';

class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  State<InitPage> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final myServices = Get.find<MyServices>();
    if (myServices.hasPendingGoogleVerification) {
      Get.offAllNamed(AppRoutes.googlePhoneVerification);
      return;
    }

    if (myServices.hasPendingProfile) {
      Get.offAllNamed(AppRoutes.userProfileSetup);
    } else if (myServices.hasAuthenticatedSession || myServices.hasGuestSession) {
      Get.offAllNamed(AppRoutes.homepage);
    } else {
      // Non-authenticated users land on the welcome screen.
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
