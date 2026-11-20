import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';

class RestaurantDetailsData {
  RestaurantDetailsData(this.crud);

  final Crud crud;

  Future<dynamic> getData(
    String restaurantId, {
    double? lat,
    double? lng,
  }) async {
    final body = <String, dynamic>{
      'restaurant_id': restaurantId,
    };
    if (lat != null) {
      body['lat'] = lat.toString();
    }
    if (lng != null) {
      body['lng'] = lng.toString();
    }
    final response = await crud.postData(AppLink.restaurantDetails, body);
    return response.fold((l) => l, (r) => r);
  }
}
