import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';

class GooglePhoneLoginData {
  GooglePhoneLoginData(this.crud);

  final Crud crud;

  Future<dynamic> postData({
    required String phone,
    required String email,
    required String name,
    required String uid,
    String? photoUrl,
    String? locale,
  }) async {
    String fcmToken = '';
    try {
      fcmToken = (await FirebaseMessaging.instance.getToken())?.trim() ?? '';
    } catch (_) {
      fcmToken = '';
    }

    final body = <String, dynamic>{
      'phone': phone,
      'email': email,
      'name': name,
      'firebase_uid': uid,
      'photo': photoUrl ?? '',
      'locale': locale ?? '',
    };

    if (fcmToken.isNotEmpty) {
      body['fcm_token'] = fcmToken;
    }

    final response = await crud.postData(
      AppLink.googlePhoneLogin,
      body,
      allowHttpErrorBody: true,
    );

    return response.fold((l) => l, (r) => r);
  }
}
