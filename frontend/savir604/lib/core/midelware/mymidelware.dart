import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyMiddleWare extends GetMiddleware {
  @override
  int? get priority => 1;

  MyServices myServices = Get.find();

  @override
  RouteSettings? redirect(String? route) {
    if (myServices.hasPendingGoogleVerification) {
      return const RouteSettings(name: AppRoutes.googlePhoneVerification);
    }
    if (myServices.hasPendingProfile) {
      return const RouteSettings(name: AppRoutes.userProfileSetup);
    }
    if (myServices.hasGuestSession || myServices.hasAuthenticatedSession) {
      return const RouteSettings(name: AppRoutes.homepage);
    }
    if (myServices.sharedPreferences.getString("step") == "1") {
      return const RouteSettings(name: AppRoutes.login);
    }

    return null;
  }
}
