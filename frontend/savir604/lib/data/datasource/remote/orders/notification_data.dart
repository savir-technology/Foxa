import 'package:tks/core/class/crud.dart';
import 'package:tks/core/services/services.dart';
import 'package:get/get.dart';
import 'package:tks/linkapi/linkapi.dart';
class NotificationData {
  Crud crud;
  NotificationData(this.crud);
  getData(String id) async {
    final services = Get.find<MyServices>();
    final token = services.accessToken.trim();
    var response = await crud.postData(
      AppLink.notification,
      {"id": id},
      headers: token.isEmpty ? null : {'Authorization': 'Bearer $token'},
    );
    return response.fold((l) => l, (r) => r);
  }
}
