import 'package:get/get.dart';
import 'package:tks/controler/cart/cart_controller.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/remote/cart/cart_data.dart';
import 'package:tks/data/datasource/remote/orders/details_data.dart';

class OrderReorderService {
  OrderReorderService({
    OrdersDetailsData? ordersDetailsData,
    CartData? cartData,
  })  : _ordersDetailsData = ordersDetailsData ?? OrdersDetailsData(Get.find()),
        _cartData = cartData ?? CartData(Get.find());

  final OrdersDetailsData _ordersDetailsData;
  final CartData _cartData;
  final MyServices _myServices = Get.find();

  Future<bool> reorderOrder(String orderId) async {
    if (orderId.trim().isEmpty) {
      Get.snackbar('Reorder', 'Order id is missing.');
      return false;
    }

    final response = await _ordersDetailsData.getData(orderId);
    if (response is! Map || response['status'] != 'success') {
      Get.snackbar('Reorder', 'Unable to load order items.');
      return false;
    }

    final items = List<Map<String, dynamic>>.from(
      (response['items'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );

    if (items.isEmpty) {
      Get.snackbar('Reorder', 'This order does not contain any items.');
      return false;
    }

    final userId = (_myServices.sharedPreferences.getInt('id') ?? 0).toString();
    var addedCount = 0;

    for (final item in items) {
      final itemId = '${item['cart_itemsid'] ?? item['items_id'] ?? ''}'.trim();
      if (itemId.isEmpty) {
        continue;
      }

      final quantity = int.tryParse('${item['countitems'] ?? 1}') ?? 1;
      final payload = <String, dynamic>{
        if ('${item['cart_variantid'] ?? ''}'.trim().isNotEmpty)
          'variantid': '${item['cart_variantid']}',
        if ('${item['item_color'] ?? ''}'.trim().isNotEmpty)
          'item_color': '${item['item_color']}',
        if ('${item['item_size'] ?? ''}'.trim().isNotEmpty)
          'item_size': '${item['item_size']}',
        if ('${item['cart_lens_code'] ?? ''}'.trim().isNotEmpty)
          'lens_code': '${item['cart_lens_code']}',
        if ('${item['cart_lens_name'] ?? ''}'.trim().isNotEmpty)
          'lens_name': '${item['cart_lens_name']}',
        if ('${item['cart_lens_color'] ?? ''}'.trim().isNotEmpty)
          'lens_color': '${item['cart_lens_color']}',
        if ('${item['cart_lens_features'] ?? ''}'.trim().isNotEmpty)
          'lens_features': '${item['cart_lens_features']}',
        if ('${item['cart_lens_price'] ?? ''}'.trim().isNotEmpty)
          'lens_price': '${item['cart_lens_price']}',
        if ('${item['cart_prescription_json'] ?? ''}'.trim().isNotEmpty)
          'prescription_json': '${item['cart_prescription_json']}',
        if ('${item['cart_prescription_summary'] ?? ''}'.trim().isNotEmpty)
          'prescription_summary': '${item['cart_prescription_summary']}',
        if ('${item['vendor_id'] ?? ''}'.trim().isNotEmpty)
          'cart_vendor_id': '${item['vendor_id']}',
        if ('${item['items_price'] ?? ''}'.trim().isNotEmpty)
          'cart_unit_price': '${item['items_price']}',
      };

      for (var index = 0; index < quantity; index++) {
        final addResponse = await _cartData.addCart(
          userId,
          itemId,
          extraData: payload,
        );
        if (addResponse is Map && addResponse['status'] == 'success') {
          addedCount++;
        }
      }
    }

    if (Get.isRegistered<CartController>()) {
      await Get.find<CartController>().view();
    } else {
      await Get.put(CartController()).view();
    }

    if (addedCount == 0) {
      Get.snackbar('Reorder', 'No items could be added back to the cart.');
      return false;
    }

    Get.snackbar('Reorder', '$addedCount item(s) were added to your cart.');
    return true;
  }
}
