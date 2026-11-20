import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';
class CartData {
  Crud crud;
  CartData(this.crud);
  addCart(
    String usersid,
    String itemsid, {
    String? size,
    String? color,
    Map<String, dynamic>? extraData,
  }) async {
    final payload = {
      "usersid": usersid,
      "itemsid": itemsid,
      ...?extraData,
    };
    var response = await crud.postData(AppLink.cartadd, payload);
    return response.fold((l) => l, (r) => r);
  }

  deleteCart(String usersid, {String? itemsid, String? cartid, Map<String, dynamic>? extraData}) async {
    final payload = {
      "usersid": usersid,
      if (itemsid != null) "itemsid": itemsid,
      if (cartid != null) "cartid": cartid,
      ...?extraData,
    };
    var response = await crud.postData(AppLink.cartdelete, payload);
    return response.fold((l) => l, (r) => r);
  }

  getCountCart(String usersid, String itemsid) async {
    var response = await crud.postData(
        AppLink.cartgetcountitems, {"usersid": usersid, "itemsid": itemsid});
    return response.fold((l) => l, (r) => r);
  }

  viewCart(String usersid) async {
    var response = await crud.postData(AppLink.cartview, {
      "usersid": usersid,
    });
    return response.fold((l) => l, (r) => r);
  }

  checkCoupon(String couponname) async {
    var response =
        await crud.postData(AppLink.checkcoupon, {"couponname": couponname});
    return response.fold((l) => l, (r) => r);
  }
}
