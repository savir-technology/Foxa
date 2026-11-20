import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/cart/cart_controller.dart';
import 'package:tks/controler/delivery_controller.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/core/services/local_json_cache.dart';
import 'package:tks/core/services/order_voice_call_alert_service.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/addressmodel.dart';
import 'package:tks/data/datasource/model/recipient_model.dart';
import 'package:tks/data/datasource/remote/orders/details_data.dart';
import 'package:tks/data/datasource/remote/address/address_data.dart';
import 'package:tks/data/datasource/remote/checkout/checkout_date.dart';
import 'package:tks/data/datasource/remote/payment/payment_data.dart';
import 'package:tks/data/datasource/remote/wallet/wallet_data.dart';
import 'package:tks/view/screen/webview_screen.dart';

class CheckoutController extends GetxController {
  final AddressData addressData = Get.put(AddressData(Get.find()));
  final CheckoutData checkoutData = Get.put(CheckoutData(Get.find()));
  final PaymentData paymentData = Get.put(PaymentData(Get.find()));
  final OrdersDetailsData ordersDetailsData =
      Get.put(OrdersDetailsData(Get.find()));
  final WalletData walletData = Get.put(WalletData(Get.find()));
  final DeliveryController deliveryController = Get.find<DeliveryController>();
  final MyServices myServices = Get.find();
  static String _orderModeKey(String restaurantId) =>
      'restaurant_order_mode_$restaurantId';
  static String _orderSlotKey(String restaurantId) =>
      'restaurant_order_slot_$restaurantId';

  StatusRequest statusRequest = StatusRequest.none;
  bool _isSubmittingOrder = false;

  bool get isSubmittingOrder => _isSubmittingOrder;

  String? paymentMethod;
  String? deliveryType;
  String selectedOrderMode = 'asap';
  String? selectedOrderSlotValue;
  String addressid = '0';
  String orderFor = 'self';
  RecipientModel? selectedRecipient;
  late TextEditingController giftMessageController;
  late TextEditingController deliveryNoteController;

  late String couponid;
  late String coupondiscount;
  late String priceorders;

  double walletBalance = 0;
  List<AddressModel> dataaddress = [];

  bool get isOrderingForOther => orderFor == 'other';

  bool get hasSelectedAddress => selectedShippingAddress != null;

  bool get hasRecipientDestination =>
      selectedRecipient != null &&
      (selectedRecipient!.addressLine.trim().isNotEmpty ||
          (selectedRecipientLatitude != null &&
              selectedRecipientLongitude != null));

  bool get hasSelectedAddressCoordinates =>
      selectedShippingLatitude != null && selectedShippingLongitude != null;

  bool get hasSelectedRecipientCoordinates =>
      selectedRecipientLatitude != null && selectedRecipientLongitude != null;

  String get selectedOrderModeLabel {
    final isArabic = Get.locale?.languageCode == 'ar';
    switch (selectedOrderMode) {
      case 'scheduled':
        return isArabic ? 'مجدول' : 'Scheduled';
      case 'preorder':
        return isArabic ? 'طلب مسبق' : 'Preorder';
      default:
        return isArabic ? 'فوري' : 'ASAP';
    }
  }

  double get shippingFee {
    if (deliveryType == '1') {
      return 0;
    }
    return (deliveryController.price ?? 0).toDouble();
  }

  double get checkoutTotal {
    final cartController = Get.find<CartController>();
    return cartController.getFinalTotal() + shippingFee;
  }

  AddressModel? get selectedShippingAddress {
    for (final address in dataaddress) {
      if (address.addressId == addressid) {
        return address;
      }
    }
    final cached = _cachedSelectedAddress();
    if (cached != null) {
      return cached;
    }
    return dataaddress.isNotEmpty ? dataaddress.first : null;
  }

  double? get selectedShippingLatitude {
    return selectedShippingAddress?.resolvedLatitude;
  }

  double? get selectedShippingLongitude {
    return selectedShippingAddress?.resolvedLongitude;
  }

  double? get selectedRecipientLatitude {
    return selectedRecipient?.resolvedLatitude;
  }

  double? get selectedRecipientLongitude {
    return selectedRecipient?.resolvedLongitude;
  }

  double? get deliveryLatitude {
    return isOrderingForOther
        ? selectedRecipientLatitude ?? selectedShippingLatitude
        : selectedShippingLatitude ?? selectedRecipientLatitude;
  }

  double? get deliveryLongitude {
    return isOrderingForOther
        ? selectedRecipientLongitude ?? selectedShippingLongitude
        : selectedShippingLongitude ?? selectedRecipientLongitude;
  }

  String get deliveryAddress {
    final parts = isOrderingForOther
        ? <String>[
            selectedRecipient?.addressName ?? '',
            selectedRecipient?.addressLine ?? '',
            selectedRecipient?.locationNote ?? '',
          ]
        : <String>[
            selectedShippingAddress?.addressName ?? '',
            selectedShippingAddress?.addressStreet ?? '',
            selectedShippingAddress?.addressCity ?? '',
          ];

    final cleaned = parts.where((part) => part.trim().isNotEmpty).toList();
    if (cleaned.isNotEmpty) {
      return cleaned.join(' - ');
    }

    if (isOrderingForOther) {
      return selectedRecipient?.label.trim() ?? '';
    }

    return <String>[
      selectedRecipient?.addressName ?? '',
      selectedRecipient?.addressLine ?? '',
      selectedShippingAddress?.addressName ?? '',
      selectedShippingAddress?.addressStreet ?? '',
      selectedShippingAddress?.addressCity ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' - ');
  }

  String get currentUserId =>
      (myServices.sharedPreferences.getInt('id') ?? 0).toString();

  String _activeRestaurantIdFromCart() {
    if (!Get.isRegistered<CartController>()) {
      return '';
    }
    final cartController = Get.find<CartController>();
    for (final item in cartController.data) {
      final vendorId = item.cartVendorId?.trim() ?? '';
      if (vendorId.isNotEmpty && vendorId != 'null') {
        return vendorId;
      }
    }
    return '';
  }

  void syncOrderModeSelection() {
    final restaurantId = _activeRestaurantIdFromCart();
    if (restaurantId.isEmpty) {
      selectedOrderMode = 'asap';
      selectedOrderSlotValue = null;
      update();
      return;
    }

    final storedMode = myServices.sharedPreferences
            .getString(_orderModeKey(restaurantId))
            ?.trim() ??
        '';
    final storedSlot = myServices.sharedPreferences
            .getString(_orderSlotKey(restaurantId))
            ?.trim() ??
        '';

    selectedOrderMode = storedMode.isNotEmpty ? storedMode : 'asap';
    selectedOrderSlotValue = storedSlot.isNotEmpty ? storedSlot : null;

    if (selectedOrderMode == 'asap') {
      selectedOrderSlotValue = null;
    }
    update();
  }

  void choosePaymentMethod(String value) {
    paymentMethod = value;
    update();
  }

  void chooseDeliveryType(String value) {
    deliveryType = value;
    update();
  }

  void chooseShippingAddress(String value) {
    addressid = value;
    final selected = selectedShippingAddress;
    if (selected != null) {
      unawaited(
        DeliverySelectionStore.saveAddress(
          myServices.sharedPreferences,
          addressId: selected.addressId,
          addressName: selected.addressName,
          addressCity: selected.addressCity,
          addressStreet: selected.addressStreet,
          addressPhone: selected.addressphone,
          latitude: selected.resolvedLatitude,
          longitude: selected.resolvedLongitude,
          locationLabel: <String>[
            selected.addressName ?? '',
            selected.addressStreet ?? '',
            selected.addressCity ?? '',
          ].where((part) => part.trim().isNotEmpty).join(' - '),
        ),
      );
    }
    update();
  }

  void chooseOrderFor(String value) {
    orderFor = value;
    if (orderFor == 'self') {
      selectedRecipient = null;
      giftMessageController.clear();
    }
    update();
  }

  Future<void> getShippingAddress() async {
    dataaddress.clear();
    addressid = '0';

    final cachedAddress = _cachedAddressSnapshot();
    final cachedSynthetic =
        cachedAddress == null ? null : _addressFromSnapshot(cachedAddress);
    statusRequest =
        cachedSynthetic != null ? StatusRequest.success : StatusRequest.loading;
    update();

    if (cachedSynthetic != null) {
      dataaddress.add(cachedSynthetic);
      addressid = cachedSynthetic.addressId ?? '0';
      statusRequest = StatusRequest.success;
      update();
    }

    final response = await addressData.getData(currentUserId);
    statusRequest = handlingData(response);

    if (statusRequest == StatusRequest.success) {
      if (response['status'] == 'success') {
        final List listdata = response['data'];
        final fetchedAddresses =
            listdata.map((e) => AddressModel.fromJson(e)).toList();
        dataaddress
          ..clear()
          ..addAll(fetchedAddresses);
        dataaddress.sort((a, b) {
          final aId = int.tryParse(a.addressId ?? '') ?? 0;
          final bId = int.tryParse(b.addressId ?? '') ?? 0;
          return bId.compareTo(aId);
        });
        if (cachedAddress != null) {
          final matchedIndex = dataaddress.indexWhere(
            (address) =>
                (address.addressId ?? '').trim() != '0' &&
                _matchesCachedAddress(address, cachedAddress),
          );
          if (matchedIndex >= 0) {
            addressid = dataaddress[matchedIndex].addressId ?? '0';
          } else {
            final synthetic = _addressFromSnapshot(cachedAddress);
            if (synthetic != null) {
              dataaddress.insert(0, synthetic);
              addressid = synthetic.addressId ?? '0';
            }
          }
        }
        if (addressid == '0' && dataaddress.isNotEmpty) {
          addressid = dataaddress.first.addressId ?? '0';
        }
      } else {
        statusRequest = StatusRequest.success;
      }
    } else if (cachedSynthetic != null) {
      statusRequest = StatusRequest.success;
    }

    update();
  }

  Map<String, dynamic>? _cachedAddressSnapshot() {
    return DeliverySelectionStore.readAddress(myServices.sharedPreferences);
  }

  AddressModel? _cachedSelectedAddress() {
    final snapshot = _cachedAddressSnapshot();
    if (snapshot == null) {
      return null;
    }
    return _addressFromSnapshot(snapshot);
  }

  AddressModel? _addressFromSnapshot(Map<String, dynamic> snapshot) {
    final latitude = _snapshotDouble(snapshot['latitude']);
    final longitude = _snapshotDouble(snapshot['longitude']);
    final addressName = '${snapshot['address_name'] ?? ''}'.trim();
    final addressCity = '${snapshot['address_city'] ?? ''}'.trim();
    final addressStreet = '${snapshot['address_street'] ?? ''}'.trim();
    final addressPhone = '${snapshot['address_phone'] ?? ''}'.trim();
    if (addressName.isEmpty &&
        addressCity.isEmpty &&
        addressStreet.isEmpty &&
        latitude == null &&
        longitude == null) {
      return null;
    }

    return AddressModel(
      addressId: '${snapshot['address_id'] ?? '0'}'.trim(),
      addressName: addressName,
      addressCity: addressCity,
      addressStreet: addressStreet,
      addressphone: addressPhone,
      addressLat: latitude?.toString(),
      addressLong: longitude?.toString(),
    );
  }

  bool _matchesCachedAddress(
    AddressModel address,
    Map<String, dynamic> snapshot,
  ) {
    final snapshotId = '${snapshot['address_id'] ?? ''}'.trim();
    if (snapshotId.isNotEmpty &&
        snapshotId != '0' &&
        address.addressId == snapshotId) {
      return true;
    }

    final snapshotLatitude = _snapshotDouble(snapshot['latitude']);
    final snapshotLongitude = _snapshotDouble(snapshot['longitude']);
    if (snapshotLatitude != null &&
        snapshotLongitude != null &&
        address.resolvedLatitude != null &&
        address.resolvedLongitude != null) {
      final sameLat =
          (address.resolvedLatitude! - snapshotLatitude).abs() < 0.0001;
      final sameLng =
          (address.resolvedLongitude! - snapshotLongitude).abs() < 0.0001;
      if (sameLat && sameLng) {
        return true;
      }
    }

    final snapshotName =
        '${snapshot['address_name'] ?? ''}'.trim().toLowerCase();
    final snapshotCity =
        '${snapshot['address_city'] ?? ''}'.trim().toLowerCase();
    final snapshotStreet =
        '${snapshot['address_street'] ?? ''}'.trim().toLowerCase();
    return snapshotName.isNotEmpty &&
        snapshotName == (address.addressName ?? '').trim().toLowerCase() &&
        (snapshotCity.isEmpty ||
            snapshotCity == (address.addressCity ?? '').trim().toLowerCase()) &&
        (snapshotStreet.isEmpty ||
            snapshotStreet ==
                (address.addressStreet ?? '').trim().toLowerCase());
  }

  double? _snapshotDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return double.tryParse(text);
  }

  Future<void> openRecipientPicker() async {
    final result = await Get.toNamed(
      AppRoutes.recipients,
      arguments: {'select_mode': true},
    );

    if (result is Map) {
      selectedRecipient =
          RecipientModel.fromJson(Map<String, dynamic>.from(result));
      update();
    }
  }

  void clearRecipient() {
    selectedRecipient = null;
    update();
  }

  Future<void> loadWalletBalance() async {
    final response = await walletData.stats(currentUserId);
    if (response is Map) {
      walletBalance =
          double.tryParse(response['wallet_balance']?.toString() ?? '') ?? 0;
      update();
    }
  }

  Future<void> checkout() async {
    if (_isSubmittingOrder) return;
    syncOrderModeSelection();

    if (paymentMethod == null) {
      Get.snackbar('Checkout'.tr, 'Please select a payment method.'.tr);
      return;
    }
    if (deliveryType == null) {
      Get.snackbar('Checkout'.tr, 'Please select a delivery type.'.tr);
      return;
    }
    if (isOrderingForOther && selectedRecipient == null) {
      Get.snackbar(
        'Checkout'.tr,
        'Please choose a saved recipient before placing the order.'.tr,
      );
      return;
    }
    if (!isOrderingForOther &&
        hasSelectedAddress &&
        !hasSelectedAddressCoordinates) {
      Get.snackbar(
        'Checkout'.tr,
        'Please update this saved address location on the map before placing the order.'
            .tr,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    if (isOrderingForOther &&
        selectedRecipient != null &&
        !hasSelectedRecipientCoordinates) {
      Get.snackbar(
        'Checkout'.tr,
        'Please update this saved recipient location on the map before placing the order.'
            .tr,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    if (deliveryType == '0' &&
        !hasSelectedAddress &&
        !hasRecipientDestination) {
      Get.snackbar(
        'Checkout'.tr,
        'Please add an address or choose a recipient with a saved address.'.tr,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    if (paymentMethod == '2' && walletBalance < checkoutTotal) {
      Get.snackbar(
        'Wallet'.tr,
        'Your wallet balance is not enough for this order.'.tr,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    if (selectedOrderMode != 'asap' &&
        (selectedOrderSlotValue == null ||
            selectedOrderSlotValue!.trim().isEmpty)) {
      Get.snackbar(
        'Checkout'.tr,
        'Please select a valid delivery time from the restaurant page.'.tr,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    _isSubmittingOrder = true;
    statusRequest = StatusRequest.loading;
    update();

    final cartController = Get.find<CartController>();
    priceorders = cartController.getFinalTotal().toStringAsFixed(2);
    final shippingFeeValue = shippingFee.toStringAsFixed(2);
    final shippingAddress = selectedShippingAddress;
    final shippingAddressName = shippingAddress?.addressName ?? '';
    final shippingAddressLine = shippingAddress?.addressStreet ?? '';
    final shippingAddressCity = shippingAddress?.addressCity ?? '';
    final shippingAddressPhone = shippingAddress?.addressphone ?? '';
    final shippingLatitudeValue = selectedShippingLatitude?.toString() ?? '';
    final shippingLongitudeValue = selectedShippingLongitude?.toString() ?? '';

    final orderPayload = {
      'usersid': currentUserId,
      'addressid':
          deliveryType == '0' && !isOrderingForOther && hasSelectedAddress
              ? addressid
              : '0',
      'orderstype': deliveryType.toString(),
      'pricedelivery': shippingFeeValue,
      'delivery_distance_km':
          deliveryController.distanceKm?.toString() ?? '',
      'ordersprice': priceorders,
      'couponid': couponid,
      'coupondiscount': coupondiscount.toString(),
      'paymentmethod':
          paymentMethod == '2' ? 'wallet' : paymentMethod.toString(),
      'recipient_name': isOrderingForOther
          ? (selectedRecipient?.name ?? '')
          : shippingAddressName,
      'recipient_phone': isOrderingForOther
          ? (selectedRecipient?.phone ?? '')
          : shippingAddressPhone,
      'recipient_label': isOrderingForOther
          ? (selectedRecipient?.label ?? '')
          : shippingAddressName,
      'recipient_address_name': isOrderingForOther
          ? (selectedRecipient?.addressName ?? '')
          : shippingAddressName,
      'recipient_address_line': isOrderingForOther
          ? (selectedRecipient?.addressLine ?? '')
          : shippingAddressLine,
      'recipient_location_note': isOrderingForOther
          ? (selectedRecipient?.locationNote ?? '')
          : shippingAddressCity,
      'recipient_building':
          isOrderingForOther ? (selectedRecipient?.building ?? '') : '',
      'recipient_floor':
          isOrderingForOther ? (selectedRecipient?.floor ?? '') : '',
      'recipient_lat': isOrderingForOther
          ? (selectedRecipientLatitude?.toString() ?? '')
          : shippingLatitudeValue,
      'recipient_lng': isOrderingForOther
          ? (selectedRecipientLongitude?.toString() ?? '')
          : shippingLongitudeValue,
      'address_lat': deliveryType == '0'
          ? (isOrderingForOther
              ? selectedRecipientLatitude?.toString() ?? ''
              : shippingLatitudeValue)
          : '',
      'address_lng': deliveryType == '0'
          ? (isOrderingForOther
              ? selectedRecipientLongitude?.toString() ?? ''
              : shippingLongitudeValue)
          : '',
      'delivery_latitude':
          deliveryType == '0' ? (deliveryLatitude?.toString() ?? '') : '',
      'delivery_longitude':
          deliveryType == '0' ? (deliveryLongitude?.toString() ?? '') : '',
      'delivery_address': deliveryType == '0' ? deliveryAddress : '',
      'order_mode': selectedOrderMode,
      'scheduled_for':
          selectedOrderMode == 'asap' ? '' : (selectedOrderSlotValue ?? ''),
      'gift_message': giftMessageController.text.trim(),
      'delivery_note': deliveryNoteController.text.trim(),
    };

    try {
      if (paymentMethod == '0') {
        await _checkoutCash(orderPayload, cartController);
        return;
      }

      if (paymentMethod == '1') {
        await _checkoutOnline(orderPayload, cartController);
        return;
      }

      if (paymentMethod == '2') {
        await _checkoutWallet(orderPayload, cartController);
        return;
      }
    } finally {
      _isSubmittingOrder = false;
    }
  }

  Future<void> _checkoutCash(
    Map<String, dynamic> orderPayload,
    CartController cartController,
  ) async {
    final response = await checkoutData.checkout(orderPayload);
    statusRequest = handlingData(response);

    if (statusRequest == StatusRequest.success && _isCheckoutSuccess(response)) {
      _bindVoiceCallOrderId('${response['order_id'] ?? ''}');
      cartController.clearCart(showMessage: false);
      Get.offNamed(
        AppRoutes.orderSuccess,
        arguments: _buildSuccessArgs(orderPayload, response, 'pending'),
      );
      return;
    }

    statusRequest = StatusRequest.none;
    update();
    Get.snackbar('Checkout'.tr, 'Unable to create the order right now.'.tr);
  }

  Future<void> _checkoutOnline(
    Map<String, dynamic> orderPayload,
    CartController cartController,
  ) async {
    final orderResponse = await checkoutData.checkout(orderPayload);
    statusRequest = handlingData(orderResponse);

    if (statusRequest != StatusRequest.success ||
        !_isCheckoutSuccess(orderResponse)) {
      statusRequest = StatusRequest.none;
      update();
      Get.snackbar('Payment'.tr, 'Unable to create the order.'.tr);
      return;
    }

    final orderId = '${orderResponse['order_id'] ?? ''}'.trim();
    if (orderId.isEmpty) {
      statusRequest = StatusRequest.none;
      update();
      await _openPaymentRejectedScreen(
        orderPayload,
        orderResponse,
        paymentStatus: 'failed',
        failureReason:
            'The order was created, but the payment session could not be prepared.'
                .tr,
      );
      return;
    }

    final paymentResponse = await paymentData.initPayment({
      'user_id': currentUserId,
      'order_id': orderId,
      'amount': orderResponse['total'] ?? checkoutTotal.toStringAsFixed(2),
    });

    statusRequest = handlingData(paymentResponse);

    if (statusRequest == StatusRequest.success &&
        paymentResponse['status'] == 'success') {
      final url = paymentResponse['iframe_url'];
      if (url is String && url.trim().isNotEmpty) {
        await Get.to(() => WebViewScreen(url: url));
        final paymentStatus = await _waitForPaymentStatus(orderId);
        if (_isSuccessfulPaymentStatus(paymentStatus)) {
          _bindVoiceCallOrderId(orderId);
          cartController.clearCart(showMessage: false);
          Get.offNamed(
            AppRoutes.orderSuccess,
            arguments: _buildSuccessArgs(
              orderPayload,
              _orderResponseWithId(orderResponse, orderId),
              'paid',
            ),
          );
          return;
        }

        await _openPaymentRejectedScreen(
          orderPayload,
          _orderResponseWithId(orderResponse, orderId),
          paymentStatus: paymentStatus,
          failureReason: _paymentFailureMessage(paymentStatus),
        );
        return;
      }

      statusRequest = StatusRequest.none;
      update();
      await _openPaymentRejectedScreen(
        orderPayload,
        _orderResponseWithId(orderResponse, orderId),
        paymentStatus: 'failed',
        failureReason:
            'The payment session was prepared, but the payment window could not be opened.'
                .tr,
      );
      return;
    }

    statusRequest = StatusRequest.none;
    update();
    await _openPaymentRejectedScreen(
      orderPayload,
      orderResponse,
      paymentStatus: 'failed',
      failureReason:
          'The order was created, but the online payment session could not be started.'
              .tr,
    );
  }

  Future<void> _checkoutWallet(
    Map<String, dynamic> orderPayload,
    CartController cartController,
  ) async {
    final response = await checkoutData.checkout(orderPayload);
    statusRequest = handlingData(response);

    if (statusRequest != StatusRequest.success ||
        !_isCheckoutSuccess(response)) {
      statusRequest = StatusRequest.none;
      update();
      Get.snackbar('Wallet'.tr, 'Unable to create the order.'.tr);
      return;
    }

    final payResponse = await walletData.payWithWallet(
      userId: currentUserId,
      orderId: '${response['order_id'] ?? ''}',
      total: '${response['total'] ?? checkoutTotal.toStringAsFixed(2)}',
    );

    final walletStatus =
        payResponse is Map ? payResponse['status']?.toString() : '';
    if (walletStatus == 'success') {
      _bindVoiceCallOrderId('${response['order_id'] ?? ''}');
      cartController.clearCart(showMessage: false);
      await loadWalletBalance();
      Get.offNamed(
        AppRoutes.orderSuccess,
        arguments: _buildSuccessArgs(orderPayload, response, 'paid'),
      );
      return;
    }

    statusRequest = StatusRequest.none;
    update();
    await _openPaymentRejectedScreen(
      orderPayload,
      response,
      paymentStatus: 'failed',
      failureReason:
          'The order was created, but the wallet payment could not be completed.'
              .tr,
    );
  }

  Map<String, dynamic> _orderResponseWithId(
    Map response,
    String orderId,
  ) {
    final normalized = Map<String, dynamic>.from(response);
    if (orderId.trim().isNotEmpty) {
      normalized['order_id'] = orderId.trim();
    }
    return normalized;
  }

  bool _isCheckoutSuccess(dynamic response) {
    if (response is! Map) return false;
    final directStatus = response['status']?.toString().trim().toLowerCase();
    if (directStatus == 'success') return true;

    final nested = response['data'];
    if (nested is Map) {
      return nested['status']?.toString().trim().toLowerCase() == 'success';
    }
    return false;
  }

  void _bindVoiceCallOrderId(String orderId) {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty ||
        !Get.isRegistered<OrderVoiceCallAlertService>()) {
      return;
    }

    Get.find<OrderVoiceCallAlertService>().bindActiveOrderId(normalizedOrderId);
  }

  String _extractOrderStatus(dynamic response) {
    if (response is Map) {
      final order = response['order'];
      if (order is Map) {
        final status = order['orders_status'] ?? order['status'];
        if (status != null) {
          return status.toString();
        }
      }

      final directStatus = response['orders_status'] ?? response['status'];
      if (directStatus != null) {
        return directStatus.toString();
      }
    }

    return '';
  }

  String _normalizePaymentStatus(String? status) {
    final value = (status ?? '').toLowerCase().trim();
    switch (value) {
      case 'paid':
      case 'success':
      case 'confirmed':
      case 'completed':
        return 'paid';
      case 'failed':
      case 'rejected':
      case 'declined':
      case 'cancelled':
      case 'canceled':
        return 'failed';
      case 'processing':
      case 'pending':
      case 'initiated':
      case 'created':
        return 'pending';
      default:
        return value;
    }
  }

  bool _isSuccessfulPaymentStatus(String status) {
    return _normalizePaymentStatus(status) == 'paid';
  }

  String _paymentFailureMessage(String status) {
    final normalized = _normalizePaymentStatus(status);
    switch (normalized) {
      case 'failed':
        return 'Payment failed or was rejected.';
      case 'pending':
        return 'Payment was not confirmed in time.';
      default:
        return 'Payment could not be completed.';
    }
  }

  Future<String> _waitForPaymentStatus(
    String orderId, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(timeout);
    String lastStatus = '';

    while (DateTime.now().isBefore(deadline)) {
      try {
        final response = await ordersDetailsData.getData(orderId);
        final status = _normalizePaymentStatus(_extractOrderStatus(response));
        if (status == 'paid' || status == 'failed') {
          return status;
        }
        if (status.isNotEmpty) {
          lastStatus = status;
        }
      } catch (_) {
        // Keep polling until the payment webhook settles the order state.
      }
      await Future.delayed(const Duration(seconds: 2));
    }

    return lastStatus.isEmpty ? 'pending' : lastStatus;
  }

  Future<void> _openPaymentRejectedScreen(
    Map<String, dynamic> orderPayload,
    Map response, {
    required String paymentStatus,
    String? failureReason,
  }) async {
    await Get.offNamed(
      AppRoutes.orderRejected,
      arguments: _buildFailureArgs(
        orderPayload,
        response,
        paymentStatus,
        failureReason: failureReason,
      ),
    );
  }

  Map<String, dynamic> _buildFailureArgs(
    Map<String, dynamic> orderPayload,
    Map response,
    String paymentStatus, {
    String? failureReason,
  }) {
    return {
      ...orderPayload,
      ...response,
      'status': paymentStatus,
      'payment_status': paymentStatus,
      'order_type': deliveryType,
      'total': response['total'] ?? checkoutTotal.toStringAsFixed(2),
      'estimated_minutes': response['estimated_minutes']?.toString() ??
          (deliveryType == '1' ? '20' : '45'),
      'delivery_code': response['delivery_code']?.toString() ?? '',
      'order_mode': orderPayload['order_mode'],
      'scheduled_for': orderPayload['scheduled_for'],
      'failure_reason': failureReason ?? '',
    };
  }

  Map<String, dynamic> _buildSuccessArgs(
    Map<String, dynamic> orderPayload,
    Map response,
    String paymentStatus,
  ) {
    return {
      ...orderPayload,
      ...response,
      'status': paymentStatus,
      'payment_status': paymentStatus,
      'order_type': deliveryType,
      'total': response['total'] ?? checkoutTotal.toStringAsFixed(2),
      'estimated_minutes': response['estimated_minutes']?.toString() ??
          (deliveryType == '1' ? '20' : '45'),
      'delivery_code': response['delivery_code']?.toString() ?? '',
      'order_mode': orderPayload['order_mode'],
      'scheduled_for': orderPayload['scheduled_for'],
    };
  }

  @override
  void onInit() {
    final args =
        Get.arguments is Map ? Get.arguments as Map : <String, dynamic>{};
    couponid = args['couponid']?.toString() ?? '0';
    coupondiscount = args['discountcoupon']?.toString() ?? '0';
    priceorders = args['priceorder']?.toString() ?? '0';
    giftMessageController = TextEditingController();
    deliveryNoteController = TextEditingController();
    paymentMethod = '1';
    deliveryType = '0';
    getShippingAddress();
    loadWalletBalance();
    syncOrderModeSelection();
    super.onInit();
  }

  @override
  void onClose() {
    giftMessageController.dispose();
    deliveryNoteController.dispose();
    super.onClose();
  }
}
