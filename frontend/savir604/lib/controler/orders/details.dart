// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/core/services/order_reorder_service.dart';
import 'package:tks/data/datasource/model/cartmodel.dart';
import 'package:tks/data/datasource/model/ordersmodel.dart';
import 'package:tks/data/datasource/remote/orders/details_data.dart';

class OrdersDetailsController extends GetxController {
  final OrdersDetailsData ordersDetailsData = OrdersDetailsData(Get.find());
  final OrderReorderService reorderService = OrderReorderService();

  List<CartModel> data = [];
  late StatusRequest statusRequest;
  late OrdersModel ordersModel;

  @override
  void onInit() {
    ordersModel = Get.arguments['ordersmodel'];
    getData();
    super.onInit();
  }

  Future<void> getData() async {
    statusRequest = StatusRequest.loading;
    data.clear();
    update();

    final orderId = ordersModel.ordersId;
    if (orderId == null || orderId.trim().isEmpty) {
      statusRequest = StatusRequest.failure;
      update();
      return;
    }

    final response = await ordersDetailsData.getData(orderId);
    print("=============================== Controller $response ");

    statusRequest = handlingData(response);

    if (StatusRequest.success == statusRequest) {
      if (response is Map) {
        final responseMap = Map<String, dynamic>.from(response);

        if (responseMap['status'] == "success") {
          if (responseMap['order'] is Map) {
            ordersModel = OrdersModel.fromJson(
              Map<String, dynamic>.from(responseMap['order']),
            );
          }

          final rawItems = responseMap['items'];
          if (rawItems is Iterable) {
            final parsedItems = rawItems
                .whereType<Map>()
                .map(
                  (e) => CartModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false);
            data.addAll(parsedItems);
          }
        } else {
          statusRequest = StatusRequest.failure;
        }
      } else {
        statusRequest = StatusRequest.failure;
      }
    }
    update();
  }

  Future<void> reorderCurrentOrder() async {
    if ((ordersModel.ordersId ?? '').trim().isEmpty) {
      Get.snackbar('Reorder', 'Order id is missing.');
      return;
    }
    await reorderService.reorderOrder(ordersModel.ordersId!);
  }
}
