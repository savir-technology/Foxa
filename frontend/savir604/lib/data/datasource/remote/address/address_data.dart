import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';

class AddressData {
  Crud crud;
  AddressData(this.crud);
  getData(String usersid) async {
    var response =
        await crud.postData(AppLink.addressView, {"usersid": usersid});
    return response.fold((l) => l, (r) => r);
  }

  addData(
    String usersid,
    String name,
    String city,
    String street,
    String phone, {
    String? latitude,
    String? longitude,
    String? locationLabel,
  }) async {
    var response = await crud.postData(AppLink.addressAdd, {
      "usersid": usersid,
      "name": name,
      "city": city,
      "street": street,
      "phone": phone,
      "address_lat": latitude ?? '',
      "address_long": longitude ?? '',
      "address_latitude": latitude ?? '',
      "address_longitude": longitude ?? '',
      "location_label": locationLabel ?? '',
    });
    return response.fold((l) => l, (r) => r);
  }

  deleteData(String addressid) async {
    var response =
        await crud.postData(AppLink.addressDelete, {"addressid": addressid});
    return response.fold((l) => l, (r) => r);
  }
}
