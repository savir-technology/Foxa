import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';

class HomeData {
  Crud crud;
  HomeData(this.crud);

  getData({
    double? lat,
    double? lng,
    String? userId,
  }) async {
    final body = <String, dynamic>{};
    if (lat != null) {
      body['lat'] = lat.toString();
    }
    if (lng != null) {
      body['lng'] = lng.toString();
    }
    final normalizedUserId = userId?.trim() ?? '';
    if (normalizedUserId.isNotEmpty) {
      body['userid'] = normalizedUserId;
    }
    var response = await crud.postData(AppLink.homepage, body);
    return response.fold((l) => l, (r) => r);
  }

  searchData(String search) async {
    var response = await crud.postData(AppLink.searchitems, {"search": search});
    return response.fold((l) => l, (r) => r);
  }
}
