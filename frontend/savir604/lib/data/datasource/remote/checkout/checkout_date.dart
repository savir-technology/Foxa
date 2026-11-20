import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';
class CheckoutData {
  Crud crud;
  CheckoutData(this.crud);
  checkout(Map data) async {
    // The checkout endpoint can commit the order before a late server-side
    // notification fails. Keep the JSON body so the client can still detect
    // the successful order instead of showing a false error.
    var response = await crud.postData(
      AppLink.checkout,
      data,
      allowHttpErrorBody: true,
    );
    return response.fold((l) => l, (r) => r);
  }
}
