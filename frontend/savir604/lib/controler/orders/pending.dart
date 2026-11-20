// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/ordersmodel.dart';
import 'package:tks/data/datasource/remote/orders/pending_data.dart';
import 'package:tks/view/screen/support.dart';

class OrdersPendingController extends GetxController {
  OrdersPendingController({OrdersPendingData? ordersPendingData})
      : ordersPendingData = ordersPendingData ?? OrdersPendingData(Get.find());

  final OrdersPendingData ordersPendingData;
  final MyServices myServices = Get.find();

  final List<OrdersModel> data = [];
  StatusRequest statusRequest = StatusRequest.none;

  bool get isArabic => Get.locale?.languageCode == 'ar';
  int get userId => myServices.sharedPreferences.getInt('id') ?? 0;

  String printOrderType(String val) {
    return val == '0' ? 'Delivery' : 'Pickup';
  }

  String printPaymentMethod(String val) {
    return val == '0' ? 'Cash On Delivery' : 'Online Payment';
  }

  String printOrderStatus(String val) {
    switch (val.toLowerCase()) {
      case '0':
      case 'pending':
        return 'Pending approval';
      case 'paid':
        return 'Paid';
      case '1':
      case 'accepted':
      case 'approved':
        return 'Accepted';
      case '2':
      case 'preparing':
        return 'Preparing';
      case 'driver_at_restaurant':
        return 'Driver at restaurant';
      case '3':
      case 'on_the_way':
      case 'delivering':
        return 'On the way';
      case '4':
      case 'delivered':
      case 'completed':
        return 'Delivered';
      default:
        return 'Archive';
    }
  }

  Future<void> getOrders() async {
    data.clear();
    statusRequest = StatusRequest.loading;
    update();

    final response = await ordersPendingData.getData(userId.toString());
    print('Pending orders response: $response');
    statusRequest = handlingData(response);

    if (statusRequest == StatusRequest.success) {
      if (response['status'] == 'success') {
        final rawData = response['data'] ?? response['orders'] ?? const [];
        final listData = rawData is List
            ? rawData
            : rawData is Map && rawData['data'] is List
                ? rawData['data'] as List
                : const [];
        data.addAll(listData.map((e) => OrdersModel.fromJson(e)));
      } else {
        statusRequest = StatusRequest.failure;
      }
    }

    update();
  }

  Future<void> deleteOrder(String orderId) async {
    statusRequest = StatusRequest.loading;
    update();

    final response = await ordersPendingData.deleteData(orderId);
    print('Delete order response: $response');
    statusRequest = handlingData(response);

    if (statusRequest == StatusRequest.success &&
        response['status'] == 'success') {
      await getOrders();
      return;
    }

    statusRequest = StatusRequest.failure;
    update();
  }

  void refrehOrder() {
    getOrders();
  }

  void openTracking(OrdersModel order) {
    Get.toNamed(AppRoutes.orderTracking, arguments: order.toJson());
  }

  Future<void> openOrderChat(OrdersModel order) async {
    final orderId = (order.ordersId ?? '').trim();
    if (orderId.isEmpty) {
      Get.snackbar(
        isArabic ? 'الدردشة' : 'Order chat',
        isArabic
            ? 'لا يمكن فتح الدردشة بدون رقم طلب.'
            : 'Order chat cannot open without an order number.',
      );
      return;
    }

    await Get.toNamed(
      AppRoutes.orderChat,
      arguments: order.toJson(),
    );
  }

  void openDetails(OrdersModel order) {
    Get.toNamed(
      AppRoutes.ordersdetails,
      arguments: {'ordersmodel': order},
    );
  }

  Future<void> openSupportForOrder(OrdersModel order) async {
    if (order.ordersId != null && order.ordersId!.trim().isNotEmpty) {
      Get.snackbar(
        isArabic ? 'طلب مساعدة' : 'Help request',
        isArabic
            ? 'سيتم فتح الدعم مع رقم الطلب #${order.ordersId}.'
            : 'Opening support with order #${order.ordersId}.',
      );
    }
    await Get.to(() => ComplaintScreen(userId: userId));
  }

  @override
  void onInit() {
    super.onInit();
    getOrders();
  }
}
