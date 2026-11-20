import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';
class ItemsData {
  Crud crud;
  ItemsData(this.crud);

  Future<dynamic> getData(String id, String userid) async {
    final body = <String, dynamic>{
      "id": id.toString(),
    };
    if (userid.trim().isNotEmpty) {
      body["usersid"] = userid.trim();
    }
    var response = await crud.postData(AppLink.items, body);
    return response.fold((l) => l, (r) => r);
  }

  Future<dynamic> searchData(String searchQuery) async {
    var response =
        await crud.postData(AppLink.searchitems, {"search": searchQuery});
    return response.fold((l) => l, (r) => r);
  }
}
