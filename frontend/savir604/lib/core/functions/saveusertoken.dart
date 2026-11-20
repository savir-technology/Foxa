// ignore_for_file: avoid_print

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tks/firebase/firebase_notifications.dart';
import 'package:tks/linkapi/linkapi.dart';

Future<void> saveUserToken(int userId) async {
  try {
    if (Get.isRegistered<FirebaseMessagingService>()) {
      await Get.find<FirebaseMessagingService>()
          .syncTokenForUser(userId, source: 'saveusertoken_helper');
      return;
    }

    final messaging = FirebaseMessaging.instance;
    final token = (await messaging.getToken())?.trim() ?? '';
    if (token.isEmpty) {
      print('[FCM] saveUserToken fallback skipped: no token available');
      return;
    }

    final response = await http.post(
      Uri.parse('${AppLink.server}/chat/save_token.php'),
      body: {'user_id': userId.toString(), 'fcm_token': token},
    );

    print(
      '[FCM] saveUserToken fallback user=$userId status=${response.statusCode} body=${response.body}',
    );
  } catch (e, stackTrace) {
    print('[FCM] Error saving token: $e');
    print(stackTrace);
  }
}
