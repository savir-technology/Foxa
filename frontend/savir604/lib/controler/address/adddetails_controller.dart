import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/core/services/local_json_cache.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/remote/address/address_data.dart';

class AddAddressDetailsController extends GetxController {
  AddAddressDetailsController();

  final AddressData addressData = AddressData(Get.find());
  final MyServices myServices = Get.find();

  final TextEditingController name = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController street = TextEditingController();
  final TextEditingController phone = TextEditingController();

  StatusRequest statusRequest = StatusRequest.none;
  bool isPickingLocation = false;
  double? selectedLatitude;
  double? selectedLongitude;
  String selectedPlaceName = '';
  String selectedAddressLine = '';

  String get selectedMapLabel {
    final parts = <String>[
      if (selectedPlaceName.trim().isNotEmpty) selectedPlaceName.trim(),
      if (selectedAddressLine.trim().isNotEmpty) selectedAddressLine.trim(),
    ];
    if (parts.isEmpty) {
      return 'Choose a location on the map'.tr;
    }
    return parts.join(' - ');
  }

  String get selectedCoordinates {
    if (selectedLatitude == null || selectedLongitude == null) {
      return '';
    }
    return '${selectedLatitude!.toStringAsFixed(5)}, ${selectedLongitude!.toStringAsFixed(5)}';
  }

  bool get hasSelectedLocation =>
      selectedLatitude != null && selectedLongitude != null;

  void applyMapSelection(Map<String, dynamic> selection) {
    selectedLatitude = double.tryParse('${selection['latitude'] ?? ''}');
    selectedLongitude = double.tryParse('${selection['longitude'] ?? ''}');
    selectedPlaceName =
        '${selection['place_name'] ?? selection['address_name'] ?? ''}'.trim();
    selectedAddressLine = '${selection['address_line'] ?? ''}'.trim();

    final cityName = '${selection['city'] ?? ''}'.trim();
    final streetName = '${selection['street'] ?? ''}'.trim();

    if (name.text.trim().isEmpty && selectedPlaceName.isNotEmpty) {
      name.text = selectedPlaceName;
    }
    if (city.text.trim().isEmpty && cityName.isNotEmpty) {
      city.text = cityName;
    }
    if (street.text.trim().isEmpty) {
      if (selectedAddressLine.isNotEmpty) {
        street.text = selectedAddressLine;
      } else if (streetName.isNotEmpty) {
        street.text = streetName;
      }
    }
    update();
  }

  Future<void> openMapPicker() async {
    isPickingLocation = true;
    update();

    final result = await Get.toNamed(
      AppRoutes.selectAddressMap,
      arguments: {
        'mode': 'address',
        'country': 'EG',
        'title': 'Choose delivery address'.tr,
        'hint_title': 'Enter the address where you want the order delivered'.tr,
        'hint_body':
            'Tap on the map and we will fill in the delivery details for you, whether it is for you or for someone else.'
                .tr,
        'confirm_label': 'Save delivery location'.tr,
        'return_only': true,
      },
    );

    isPickingLocation = false;
    if (result is Map) {
      applyMapSelection(Map<String, dynamic>.from(result));
    }
    update();
  }

  Future<void> addAddress() async {
    statusRequest = StatusRequest.loading;
    update();

    if (name.text.isEmpty ||
        city.text.isEmpty ||
        street.text.isEmpty ||
        phone.text.isEmpty) {
      statusRequest = StatusRequest.failure;
      update();
      return;
    }

    if (!hasSelectedLocation) {
      Get.snackbar(
        'Location required'.tr,
        'Please choose the address location from the map before saving.'.tr,
      );
      statusRequest = StatusRequest.failure;
      update();
      return;
    }

    final userId = myServices.sharedPreferences.getInt("id")?.toString() ?? '';
    if (userId.isEmpty) {
      Get.snackbar(
        'Login required'.tr,
        'Please sign in first to save a delivery address.'.tr,
      );
      statusRequest = StatusRequest.failure;
      update();
      return;
    }

    final response = await addressData.addData(
      userId,
      name.text.trim(),
      city.text.trim(),
      street.text.trim(),
      phone.text.trim(),
      latitude: selectedLatitude?.toString(),
      longitude: selectedLongitude?.toString(),
      locationLabel: selectedMapLabel,
    );

    statusRequest = handlingData(response);

    if (StatusRequest.success == statusRequest) {
      if (response['status'] == "success") {
        await DeliverySelectionStore.saveAddress(
          myServices.sharedPreferences,
          addressName: name.text.trim(),
          addressCity: city.text.trim(),
          addressStreet: street.text.trim(),
          addressPhone: phone.text.trim(),
          latitude: selectedLatitude,
          longitude: selectedLongitude,
          locationLabel: selectedMapLabel,
        );
        Get.back(result: true);
      } else {
        statusRequest = StatusRequest.failure;
      }
    }
    update();
  }

  @override
  void onClose() {
    name.dispose();
    city.dispose();
    street.dispose();
    phone.dispose();
    super.onClose();
  }
}
