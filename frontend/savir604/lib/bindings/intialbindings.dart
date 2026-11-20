import 'package:tks/core/class/crud.dart';
import 'package:tks/controler/delivery_controller.dart';
import 'package:get/get.dart';

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(Crud());
    Get.put(DeliveryController(), permanent: true);
  }
}
