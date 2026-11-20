import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';

class PhoneCompleteProfileData {
  PhoneCompleteProfileData();

  Future<dynamic> postData({
    required String fullName,
    required String locale,
    required String accessToken,
    String? imagePath,
  }) async {
    String fcmToken = '';
    try {
      fcmToken = (await FirebaseMessaging.instance.getToken())?.trim() ?? '';
    } catch (_) {
      fcmToken = '';
    }

    final body = <String, dynamic>{
      'full_name': fullName,
      'locale': locale,
      'access_token': accessToken,
    };

    if (imagePath != null && imagePath.isNotEmpty) {
      body['image_path'] = imagePath;
    }

    if (fcmToken.isNotEmpty) {
      body['fcm_token'] = fcmToken;
    }

    final crud = Crud();
    final response = await crud.postData(
      AppLink.phoneCompleteProfile,
      body,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    return response.fold((l) => l, (r) => r);
  }
}
