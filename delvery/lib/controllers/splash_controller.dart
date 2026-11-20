import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/core/services/mapbox_runtime_config.dart';
import 'package:get/get.dart';
import 'package:delvery/core/localization/driver_text.dart';

class SplashController extends GetxController {
  SplashController(this.sessionService, this.ordersService);

  final DriverSessionService sessionService;
  final DriverOrdersService ordersService;

  final RxString statusText = tx('جارٍ تجهيز بيئة العمل...').obs;
  final RxBool ready = false.obs;

  @override
  void onReady() {
    super.onReady();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    try {
      await MapboxRuntimeConfig.initialize();
      await sessionService.init();
      await ordersService.init();
      await sessionService.refreshSystemChecks();
    } catch (_) {
      await sessionService.refreshSystemChecks();
    }

    if (!sessionService.hasInternet.value) {
      statusText.value = tx('لا يوجد اتصال بالإنترنت.');
      ready.value = true;
      return;
    }

    if (!sessionService.gpsEnabled.value) {
      statusText.value = tx('فعّل GPS للمتابعة.');
      ready.value = true;
      return;
    }

    final stage = sessionService.registrationStage.value;
    if (stage == DriverRegistrationStage.otp) {
      Get.offAllNamed(AppRoutes.otp);
      return;
    }
    if (stage == DriverRegistrationStage.password) {
      Get.offAllNamed(AppRoutes.passwordSetup);
      return;
    }
    if (stage == DriverRegistrationStage.profile) {
      Get.offAllNamed(AppRoutes.profileSetup);
      return;
    }

    if (!sessionService.isLoggedIn.value) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    if (!sessionService.profile.value.profileCompleted) {
      Get.offAllNamed(AppRoutes.profileSetup);
      return;
    }

    Get.offAllNamed(AppRoutes.home, arguments: {'tab': 0});
  }

  void retry() {
    statusText.value = tx('جاري إعادة التحقق...');
    ready.value = false;
    _bootstrap();
  }
}
