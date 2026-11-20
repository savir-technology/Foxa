import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/linkapi/linkapi.dart';

class SettingsController extends GetxController {
  final MyServices myServices = Get.find();

  Map<String, dynamic>? userData;
  bool isLoadingProfile = false;
  bool isDeletingAccount = false;

  Future<void> _signOutFirebase() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      debugPrint('Firebase sign out error: $error');
    }
  }

  Future<void> logout() async {
    final userId = myServices.sharedPreferences.getInt('id') ?? 0;
    debugPrint('Logging out user: $userId');
    await _signOutFirebase();

    await myServices.clearAuthSession();
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> deleteAccount() async {
    final token = myServices.accessToken.trim();
    if (token.isEmpty) {
      throw Exception('Session expired');
    }

    isDeletingAccount = true;
    update();

    try {
      final url = Uri.parse('${AppLink.server}/auth/delete_account.php');
      final response = await http
          .post(
            url,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      dynamic decoded;
      try {
        decoded = json.decode(response.body);
      } catch (_) {
        throw Exception('Unable to delete account right now.');
      }

      final payload = decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);
      final responseMessage =
          (payload['message'] ?? 'Unable to delete account right now.').toString();

      if (response.statusCode != 200) {
        throw Exception(responseMessage);
      }

      if ((payload['status'] ?? '').toString() != 'success') {
        throw Exception(responseMessage);
      }

      await _signOutFirebase();
      await myServices.clearAuthSession();
      Get.offAllNamed(AppRoutes.login);
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      if (message == 'Session expired' ||
          message == 'Unable to delete account right now.') {
        throw Exception(message);
      }
      throw Exception('Unable to delete account right now.');
    } finally {
      isDeletingAccount = false;
      update();
    }
  }

  Future<void> getProfile() async {
    final id = myServices.sharedPreferences.getInt('id');
    if (id == null) return;

    isLoadingProfile = true;
    update();

    final url =
        Uri.parse('${AppLink.server}/dash/users/profile/get_profile.php');
    try {
      final response = await http.post(url, body: {'user_id': id.toString()});
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        userData = decoded is Map<String, dynamic>
            ? decoded
            : Map<String, dynamic>.from(decoded);
      }
    } catch (error) {
      debugPrint('getProfile error: $error');
    }

    isLoadingProfile = false;
    update();
  }

  @override
  void onInit() {
    super.onInit();
    getProfile();
  }
}
