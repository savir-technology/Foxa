import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/controler/order_controller.dart';
import 'package:admin_tks/core/services/dashboard_session_service.dart';
import 'package:admin_tks/model/order_model.dart';
import 'package:admin_tks/order_status_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeOrderController extends OrderController {
  @override
  void onInit() {
    // Intentionally skip the network fetch in widget tests.
  }
}

OrderModel _sampleOrder({
  required int id,
  required String name,
  required String status,
  required int itemsCount,
  required String total,
  required String orderDateTime,
  required int estimatedMinutes,
  int type = 0,
  String? mode,
}) {
  return OrderModel(
    ordersId: id,
    usersName: name,
    addressPhone: '+963 9${id.toString().padLeft(8, '0')}',
    addressCity: 'Aleppo',
    addressStreet: 'Street ${id % 10}',
    ordersStatus: status,
    ordersDatetime: orderDateTime,
    ordersEstimatedMinutes: estimatedMinutes,
    ordersItemsCount: itemsCount,
    ordersTotalprice: total,
    ordersType: type,
    orderMode: mode,
    vendorId: 1,
    flowStatus: status,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.put<DashboardAuthController>(DashboardAuthController());
    Get.put<OrderController>(_FakeOrderController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Order status page builds without layout exceptions', (tester) async {
    final auth = Get.find<DashboardAuthController>();
    auth.session.value = const DashboardSession(
      token: 'token',
      expiresAt: '2099-01-01T00:00:00.000',
      vendorId: 1,
      vendorName: 'Vendor',
      storeName: 'Restaurant',
      email: 'vendor@example.com',
      phone: '123456789',
      logo: null,
      vendorDescription: 'Test restaurant',
    );
    auth.isReady.value = true;

    final orderController = Get.find<OrderController>() as _FakeOrderController;
    final now = DateTime.now();
    orderController.isLoading.value = false;
    orderController.orders.assignAll([
      _sampleOrder(
        id: 5482,
        name: 'Ahmed Khalil',
        status: 'new',
        itemsCount: 3,
        total: '42000',
        orderDateTime: now.subtract(const Duration(minutes: 5)).toIso8601String(),
        estimatedMinutes: 25,
      ),
      _sampleOrder(
        id: 5476,
        name: 'Mohammed Hassan',
        status: 'assigned',
        itemsCount: 4,
        total: '50000',
        orderDateTime: now.subtract(const Duration(minutes: 12)).toIso8601String(),
        estimatedMinutes: 35,
      ),
      _sampleOrder(
        id: 5479,
        name: 'Sara Ali',
        status: 'arrived_at_restaurant',
        itemsCount: 2,
        total: '28000',
        orderDateTime: now.subtract(const Duration(minutes: 20)).toIso8601String(),
        estimatedMinutes: 45,
      ),
      _sampleOrder(
        id: 5459,
        name: 'Jasem Mohammed',
        status: 'new',
        itemsCount: 3,
        total: '33000',
        orderDateTime: now.subtract(const Duration(minutes: 90)).toIso8601String(),
        estimatedMinutes: 25,
      ),
    ]);

    await tester.binding.setSurfaceSize(const Size(1536, 1024));
    await tester.pumpWidget(
      const GetMaterialApp(
        home: OrderStatusPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(tester.takeException(), isNull);
  });
}
