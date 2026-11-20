import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:delvery/core/localization/driver_text.dart';

class ShiftController extends GetxController {
  ShiftController(this.sessionService, this.ordersService);

  final DriverSessionService sessionService;
  final DriverOrdersService ordersService;

  final RxBool startLoading = false.obs;
  final RxString statusMessage = tx('جاهز لبدء المناوبة.').obs;

  Future<void> startShift() async {
    startLoading.value = true;
    try {
      statusMessage.value = tx('جاري بدء المناوبة...');
      await sessionService.ensureOfficialWorkingHours(force: true);
      if (!sessionService.isWithinOfficialWorkingHours()) {
        final blockedMessage = sessionService.officialWorkingHoursBlockedText();
        statusMessage.value = blockedMessage;
        Get.snackbar(tx('تعذر بدء المناوبة'), blockedMessage);
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        statusMessage.value = tx('يرجى تفعيل GPS أولاً.');
        await Geolocator.openLocationSettings();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        statusMessage.value = tx('مطلوب إذن الموقع.');
        return;
      }

      await sessionService.startShift();
      ordersService.startOrderPolling();
      Get.offAllNamed(AppRoutes.home, arguments: {'tab': 0});
    } on Object catch (error) {
      statusMessage.value = error.toString();
      Get.snackbar(tx('تعذر بدء المناوبة'), error.toString());
    } finally {
      startLoading.value = false;
    }
  }

  Future<void> endShift() async {
    await sessionService.endShift();
    ordersService.stopOrderPolling();
    Get.offAllNamed(AppRoutes.shift);
  }
}
