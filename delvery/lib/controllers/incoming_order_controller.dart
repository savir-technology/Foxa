import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:get/get.dart';

class IncomingOrderController extends GetxController {
  IncomingOrderController(this.ordersService)
    : countdown = ordersService.incomingCountdown;

  final DriverOrdersService ordersService;
  final RxInt countdown;

  Future<void> acceptNow() async {
    final accepted = await ordersService.acceptIncomingOrder();
    if (accepted) {
      Get.offAllNamed(AppRoutes.home, arguments: {'tab': 2});
    }
  }
}
