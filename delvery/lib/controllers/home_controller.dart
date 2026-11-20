import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/core/services/driver_orders_service.dart';
import 'package:delvery/data/models/driver_models.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  HomeController(this.ordersService);

  final DriverOrdersService ordersService;

  final RxInt tabIndex = 0.obs;
  final RxBool incomingSheetVisible = false.obs;
  final Rxn<DriverOrder> observedIncoming = Rxn<DriverOrder>();
  bool _initialTabApplied = false;

  @override
  void onInit() {
    super.onInit();
    ever<DriverOrder?>(ordersService.incomingOrder, (order) {
      observedIncoming.value = order;
      if (order != null && !incomingSheetVisible.value) {
        incomingSheetVisible.value = true;
        Get.toNamed(AppRoutes.incomingOrder)?.then((_) {
          incomingSheetVisible.value = false;
        });
      }
    });
  }

  void setTab(int index) {
    tabIndex.value = index.clamp(0, 4).toInt();
  }

  void openCurrentOrder() {
    tabIndex.value = 2;
  }

  void onPageReady([int? initialTab]) {
    if (!_initialTabApplied && initialTab != null) {
      tabIndex.value = initialTab.clamp(0, 4).toInt();
      _initialTabApplied = true;
    }
  }
}
