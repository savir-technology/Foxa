import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';

class RestaurantRatingsData {
  final Crud crud;

  RestaurantRatingsData(this.crud);

  Future<dynamic> getRatings({required String vendorId}) async {
    final response = await crud.postData(
      AppLink.getVendorRatings,
      {
        "vendor_id": vendorId,
      },
    );
    return response.fold((l) => l, (r) => r);
  }
}
