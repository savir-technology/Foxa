import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/model/addressmodel.dart';
import 'package:tks/data/datasource/remote/address/address_data.dart';

class AddressViewController extends GetxController {
  final AddressData addressData = AddressData(Get.find());
  final MyServices myServices = Get.find();

  List<AddressModel> data = [];
  StatusRequest statusRequest = StatusRequest.none;

  Future<void> deleteAddress(String addressid) async {
    await addressData.deleteData(addressid);
    data.removeWhere((element) => element.addressId == addressid);
    update();
  }

  Future<void> getData() async {
    statusRequest = StatusRequest.loading;
    update();

    data.clear();
    final userId = myServices.sharedPreferences.getInt('id') ?? 0;
    if (userId <= 0) {
      statusRequest = StatusRequest.success;
      update();
      return;
    }

    final response = await addressData.getData(
      userId.toString(),
    );

    statusRequest = handlingData(response);

    if (statusRequest == StatusRequest.success) {
      if (response['status'] == 'success') {
        final List listData = response['data'];
        data.addAll(listData.map((e) => AddressModel.fromJson(e)));
        data.sort((a, b) {
          final aId = int.tryParse(a.addressId ?? '') ?? 0;
          final bId = int.tryParse(b.addressId ?? '') ?? 0;
          return bId.compareTo(aId);
        });
        if (data.isEmpty) {
          statusRequest = StatusRequest.failure;
        }
      } else {
        statusRequest = StatusRequest.failure;
      }
    }
    update();
  }

  @override
  void onInit() {
    super.onInit();
    getData();
  }
}
