import 'dart:convert';

import 'package:admin_tks/core/services/dashboard_session_service.dart';
import 'package:admin_tks/model/order_model.dart';
import 'package:admin_tks/model/driver_dispatch_model.dart';
import 'package:admin_tks/remote/order_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderController extends GetxController {
  final orders = <OrderModel>[].obs;
  final isLoading = true.obs;
  final detailsByOrder = <int, List<OrderItemDetail>>{}.obs;
  final loadingDetails = <int, bool>{}.obs;
  bool _isFetchingOrders = false;
  String? _loadedOrdersScope;

  Future<void> fetchOrders({
    String scope = 'all',
    bool forceRefresh = true,
  }) async {
    if (!forceRefresh && _loadedOrdersScope == scope) return;

    // Avoid duplicate requests when the page is rebuilt or refreshed while
    // the previous request is still running.
    if (_isFetchingOrders) return;

    _isFetchingOrders = true;
    isLoading.value = true;
    try {
      final cachedOrders = await _readCachedOrders(scope);
      if (cachedOrders.isNotEmpty && orders.isEmpty) {
        orders.assignAll(cachedOrders);
        isLoading.value = false;
      }

      orders.assignAll(await OrderData.fetchOrders(scope: scope));
      _loadedOrdersScope = scope;
      await _writeCachedOrders(scope, orders.toList(growable: false));
    } catch (e) {
      debugPrint('Fetch Orders Error: $e');
    } finally {
      isLoading.value = false;
      _isFetchingOrders = false;
    }
  }

  Future<String> _ordersCacheKey(String scope) async {
    final session = await DashboardSessionService.instance.loadSession();
    final vendorId = session?.vendorId ?? 0;
    return 'roaq_vendor_orders_${vendorId}_$scope';
  }

  Future<List<OrderModel>> _readCachedOrders(String scope) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(await _ordersCacheKey(scope));
      if (raw == null || raw.isEmpty) return const <OrderModel>[];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <OrderModel>[];
      return decoded
          .whereType<Map>()
          .map((item) => OrderModel.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (_) {
      return const <OrderModel>[];
    }
  }

  Future<void> _writeCachedOrders(
    String scope,
    List<OrderModel> value,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        await _ordersCacheKey(scope),
        jsonEncode(value.map((order) => order.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<List<OrderItemDetail>> fetchOrderDetails(
    int orderId, {
    required int vendorId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && detailsByOrder.containsKey(orderId)) {
      return detailsByOrder[orderId]!;
    }

    loadingDetails[orderId] = true;
    try {
      final details = await OrderData.fetchOrderItemDetails(
        orderId.toString(),
        vendorId,
      );
      detailsByOrder[orderId] = details;
      return details;
    } catch (e) {
      debugPrint('Fetch Order Details Error: $e');
      return [];
    } finally {
      loadingDetails[orderId] = false;
    }
  }

  Future<void> updateOrderStatus(int orderId, int vendorId, String newStatus,
      {int? estimatedMinutes, String? reason}) async {
    try {
      await OrderData.updateOrderStatus(
        orderId.toString(),
        vendorId,
        newStatus,
        estimatedMinutes: estimatedMinutes,
        reason: reason,
      );
      await fetchOrders();
      await fetchOrderDetails(
        orderId,
        vendorId: vendorId,
        forceRefresh: true,
      );
    } catch (e) {
      debugPrint('Update Status Error: $e');
      rethrow;
    }
  }

  Future<void> updateOrderFlowStatus(
    int orderId,
    int vendorId,
    String newStatus,
  ) async {
    try {
      await OrderData.updateOrderFlowStatus(
        orderId.toString(),
        vendorId,
        newStatus,
      );
      await fetchOrders();
    } catch (e) {
      debugPrint('Update Flow Status Error: $e');
      rethrow;
    }
  }

  Future<void> deleteOrderByOrderId(int orderId) async {
    try {
      await OrderData.deleteOrderByOrderId(orderId.toString());
      detailsByOrder.remove(orderId);
      await fetchOrders();
    } catch (e) {
      debugPrint('Delete Order Error: $e');
      rethrow;
    }
  }

  Future<List<DriverDispatchOption>> fetchAvailableDrivers({
    required int vendorId,
    double? restaurantLatitude,
    double? restaurantLongitude,
    bool onlyAvailable = true,
  }) async {
    try {
      return await OrderData.fetchAvailableDrivers(
        vendorId: vendorId,
        restaurantLatitude: restaurantLatitude,
        restaurantLongitude: restaurantLongitude,
        onlyAvailable: onlyAvailable,
      );
    } catch (e) {
      debugPrint('Fetch Drivers Error: $e');
      rethrow;
    }
  }

  Future<void> assignOrderToDriver({
    required int orderId,
    required int driverId,
    required int vendorId,
  }) async {
    try {
      await OrderData.assignOrderToDriver(
        orderId: orderId,
        driverId: driverId,
        vendorId: vendorId,
      );
      detailsByOrder.remove(orderId);
      await fetchOrders();
      await fetchOrderDetails(
        orderId,
        vendorId: vendorId,
        forceRefresh: true,
      );
    } catch (e) {
      debugPrint('Assign Driver Error: $e');
      rethrow;
    }
  }
}
