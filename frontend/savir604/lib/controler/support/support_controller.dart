import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tks/data/datasource/remote/support/support_data.dart';

class SupportController {
  final SupportData supportData = SupportData();

  Future<void> sendComplaint(String complaint) async {
    try {
      final userId = await getUserId();

      if (userId != null) {
        final response = await supportData.sendComplaint(userId, complaint);
        if (response['message'] == 'تم إرسال الشكوى بنجاح') {
          // الشكوى تم إرسالها بنجاح
        } else {
          // التعامل مع حالة فشل الإرسال
        }
      } else {
        // التعامل مع حالة عدم وجود معرف المستخدم
        throw 'User ID not found';
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final numericId = prefs.getInt('id');
    if (numericId != null && numericId > 0) {
      return numericId.toString();
    }
    return prefs.getString('userId') ?? prefs.getString('id');
  }
}
