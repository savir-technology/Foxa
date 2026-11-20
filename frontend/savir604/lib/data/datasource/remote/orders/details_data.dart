import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';

class OrdersDetailsData {
  Crud crud;

  OrdersDetailsData(this.crud);

  getData(String id) async {
    var response = await crud.postData(AppLink.ordersdetails, {"id": id});
    return response.fold((l) => l, (r) => r);
  }

  getDataByShareToken(String token) async {
    var response =
        await crud.postData(AppLink.ordersdetails, {"share_token": token});
    return response.fold((l) => l, (r) => r);
  }
}
