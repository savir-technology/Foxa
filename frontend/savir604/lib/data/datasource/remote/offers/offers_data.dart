import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';

class OffersData {
  final Crud crud;

  OffersData(this.crud);

  Future<dynamic> getCoupons() async {
    final response = await crud.postData(AppLink.coupons, {});
    return response.fold((l) => l, (r) => r);
  }
}
