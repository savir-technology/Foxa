import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';

class FoodItemDetailsData {
  FoodItemDetailsData(this.crud);

  final Crud crud;

  Future<dynamic> getData(String itemId) async {
    final response = await crud.postData(
      AppLink.foodItemDetails,
      {'item_id': itemId},
    );
    return response.fold((l) => l, (r) => r);
  }
}
