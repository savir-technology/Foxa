import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';

class DriverRatingData {
  final Crud crud;

  DriverRatingData(this.crud);

  Future<dynamic> submitRating({
    required String orderId,
    required String driverId,
    required String userId,
    required double rating,
  }) async {
    final response = await crud.postData(
      AppLink.addDriverRating,
      {
        'order_id': orderId,
        'driver_id': driverId,
        'user_id': userId,
        'rating': rating.toStringAsFixed(1),
      },
    );
    return response.fold((l) => l, (r) => r);
  }

  Future<dynamic> getRating({
    required String orderId,
    required String driverId,
    required String userId,
  }) async {
    final response = await crud.postData(
      AppLink.getDriverRating,
      {
        'order_id': orderId,
        'driver_id': driverId,
        'user_id': userId,
      },
    );
    return response.fold((l) => l, (r) => r);
  }
}
