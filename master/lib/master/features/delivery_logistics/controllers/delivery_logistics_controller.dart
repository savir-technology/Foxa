// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class _DeliveryLogisticsController {
  _DeliveryLogisticsController({
    required this.api,
    required this.token,
    required this.view,
  }) {
    future = _load();
  }

  final MasterAuthApiService api;
  final String token;
  final String view;
  final TextEditingController searchController = TextEditingController();

  late Future<_MasterDeliveryLogisticsData> future;
  bool showNavigationSidebar = true;
  bool assigning = false;
  int? selectedOrderId;
  int selectedVendorId = 0;
  int? selectedDriverId;
  String statusFilter = 'all';
  String vehicleFilter = 'all';

  Future<_MasterDeliveryLogisticsData> _load() {
    return api
        ._fetchDeliveryLogistics(
          token,
          view: view,
          query: searchController.text.trim(),
          status: statusFilter,
          vehicle: vehicleFilter,
        )
        .timeout(const Duration(seconds: 20));
  }

  void reload() {
    future = _load();
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    reload();
  }

  void setVehicleFilter(String value) {
    vehicleFilter = value;
    reload();
  }

  void toggleNavigationSidebar() {
    showNavigationSidebar = !showNavigationSidebar;
  }

  void hideNavigationSidebar() {
    showNavigationSidebar = false;
  }

  void selectOrder(int orderId, {int vendorId = 0}) {
    selectedOrderId = orderId;
    selectedVendorId = vendorId;
  }

  void selectDriver(int driverId) {
    selectedDriverId = driverId;
  }

  Future<String> assignSelected() async {
    final orderId = selectedOrderId;
    final driverId = selectedDriverId;
    if (orderId == null || driverId == null) {
      return 'اختر طلبا وسائقا أولا لإتمام التوزيع اليدوي';
    }

    assigning = true;
    try {
      await api._assignDriverToOrder(
        token,
        orderId: orderId,
        driverId: driverId,
        vendorId: selectedVendorId,
      );
      selectedOrderId = null;
      selectedVendorId = 0;
      selectedDriverId = null;
      reload();
      return 'تم تعيين السائق للطلب وتحديث قائمة التوزيع';
    } finally {
      assigning = false;
    }
  }

  Future<String> assignAutomatic(_MasterDeliveryLogisticsData data) async {
    final order = _firstUnassignedOrder(data);
    final driver = _bestAvailableDriver(data);
    if (order == null) {
      return 'لا توجد طلبات غير موزعة حاليا';
    }
    if (driver == null) {
      return 'لا يوجد سائق متاح بدون حمولة نشطة حاليا';
    }

    assigning = true;
    try {
      await api._assignDriverToOrder(
        token,
        orderId: order.orderId,
        driverId: driver.driverId,
        vendorId: order.vendorId,
      );
      selectedOrderId = null;
      selectedVendorId = 0;
      selectedDriverId = null;
      reload();
      return 'تم توزيع الطلب ${order.orderNo} على السائق ${driver.name}';
    } finally {
      assigning = false;
    }
  }

  Future<String> assignScheduledBatch(_MasterDeliveryLogisticsData data) async {
    final orders = data.unassignedOrders
        .where((order) => order.orderId > 0)
        .take(6)
        .toList();
    final drivers = _availableDrivers(data).take(orders.length).toList();
    if (orders.isEmpty) {
      return 'لا توجد طلبات مجدولة أو غير موزعة حاليا';
    }
    if (drivers.isEmpty) {
      return 'لا يوجد سائقون متاحون للتوزيع المجدول حاليا';
    }

    assigning = true;
    var assignedCount = 0;
    try {
      for (var i = 0; i < orders.length && i < drivers.length; i++) {
        await api._assignDriverToOrder(
          token,
          orderId: orders[i].orderId,
          driverId: drivers[i].driverId,
          vendorId: orders[i].vendorId,
        );
        assignedCount++;
      }
      selectedOrderId = null;
      selectedVendorId = 0;
      selectedDriverId = null;
      reload();
      return assignedCount == 1
          ? 'تم توزيع طلب واحد ضمن الجدولة'
          : 'تم توزيع $assignedCount طلبات ضمن الجدولة';
    } finally {
      assigning = false;
    }
  }

  _DeliveryOrderData? _firstUnassignedOrder(_MasterDeliveryLogisticsData data) {
    for (final order in data.unassignedOrders) {
      if (order.orderId > 0) {
        return order;
      }
    }
    return null;
  }

  _DeliveryDriverData? _bestAvailableDriver(_MasterDeliveryLogisticsData data) {
    final drivers = _availableDrivers(data);
    return drivers.isEmpty ? null : drivers.first;
  }

  List<_DeliveryDriverData> _availableDrivers(
    _MasterDeliveryLogisticsData data,
  ) {
    final drivers = data.drivers
        .where(
          (driver) =>
              driver.driverId > 0 &&
              driver.statusKey == 'available' &&
              driver.activeOrders == 0,
        )
        .toList();
    drivers.sort((a, b) {
      final loadCompare = a.activeOrders.compareTo(b.activeOrders);
      if (loadCompare != 0) {
        return loadCompare;
      }
      final ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) {
        return ratingCompare;
      }
      return a.todayOrders.compareTo(b.todayOrders);
    });
    return drivers;
  }

  void dispose() {
    searchController.dispose();
  }
}
