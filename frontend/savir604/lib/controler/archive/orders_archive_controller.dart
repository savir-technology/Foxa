// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:tks/core/services/order_reorder_service.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/orders_archive_model.dart';
import 'package:tks/data/datasource/remote/order/orders_archive_data.dart';
import 'package:tks/data/datasource/model/ordersmodel.dart';
import 'package:tks/core/constant/routes.dart';

class OrdersArchiveControllerr extends GetxController {
  var isLoading = true.obs;
  var ordersList = <OrdersArchiveModel>[].obs;
  late int userId;

  final OrdersArchiveData _ordersData = OrdersArchiveData();
  final OrderReorderService reorderService = OrderReorderService();

  Future<void> fetchOrdersArchive(int userId) async {
    try {
      isLoading.value = true;
      final data = await _ordersData.getOrdersArchive(userId);
      ordersList.assignAll(data);
    } catch (e) {
      print("Error loading archive orders: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    final myServices = Get.find<MyServices>();
    userId = myServices.sharedPreferences.getInt("id") ?? 0;
    fetchOrdersArchive(userId);
  }

  Future<void> reorderOrder(String orderId) async {
    await reorderService.reorderOrder(orderId);
  }

  void openOrderDetails(OrdersArchiveModel order) {
    final orderModel = OrdersModel(
      ordersId: order.ordersId,
      ordersDatetime: order.ordersDatetime,
      ordersStatus: order.ordersStatus,
      ordersType: order.ordersType,
      ordersTotalprice: order.ordersTotalprice,
    );

    Get.toNamed(
      AppRoutes.ordersdetails,
      arguments: {
        'ordersmodel': orderModel,
      },
    );
  }
}
