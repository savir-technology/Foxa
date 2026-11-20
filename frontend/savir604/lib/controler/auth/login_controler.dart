import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/functions/save_token.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/remote/auth/google_phone_login.dart';

class LoginControllerImp extends GetxController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final MyServices myServices = Get.find();
  final GooglePhoneLoginData googleLoginData = GooglePhoneLoginData(Get.find());

  bool isLoading = false;

  Future<void> loginWithGoogle() async {
    if (isLoading) {
      return;
    }

    isLoading = true;
    update();

    try {
      final socialUser = await _signInWithGoogle();
      if (socialUser == null) {
        return;
      }

      final email = (socialUser.email ?? '').trim();
      if (email.isEmpty) {
        await FirebaseAuth.instance.signOut();
        Get.snackbar(
          'Missing email'.tr,
          'The selected Google account did not provide an email address.'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final displayName = (socialUser.displayName ?? email).trim();
      final photoUrl = socialUser.photoURL ?? '';
      final response = await googleLoginData.postData(
        phone: '',
        email: email,
        name: displayName,
        uid: socialUser.uid,
        photoUrl: photoUrl,
        locale: Get.locale?.languageCode ?? 'en',
      );

      if (response is StatusRequest) {
        Get.snackbar(
          'Connection issue'.tr,
          'Check your connection and try again.'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final status = '${response['status'] ?? ''}';
      if (status == 'success') {
        final user = Map<String, dynamic>.from(
          (response['user'] as Map?)?.cast<String, dynamic>() ?? const {},
        );
        final profileCompleted = '${user['profile_completed'] ?? 1}' == '1';

        await myServices.clearAuthSession();
        await myServices.storeAuthSession(
          user: user,
          accessToken: '${response['token'] ?? ''}',
          refreshToken: '${response['refresh_token'] ?? ''}',
          expiresAt: '${response['expires_at'] ?? ''}',
          refreshExpiresAt: '${response['refresh_expires_at'] ?? ''}',
          profileCompleted: profileCompleted,
          sessionMode: 'google_backend',
        );

        final userId = int.tryParse('${user['users_id'] ?? 0}') ?? 0;
        if (userId > 0) {
          await saveUserToken(userId);
        }

        Get.offAllNamed(AppRoutes.homepage);
        return;
      }

      if (status == 'needs_phone') {
        await _startPhoneVerificationForGoogleUser(
          email: email,
          name: displayName,
          photoUrl: photoUrl,
          uid: socialUser.uid,
        );
        return;
      }

      Get.snackbar(
        'Unable to continue'.tr,
        '${response['message'] ?? 'Google sign-in failed'.tr}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase Google sign-in failed: ${e.code} ${e.message}');
      }
      Get.snackbar(
        'Google sign-in failed'.tr,
        _friendlyFirebaseAuthMessage(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Google sign-in error: $e');
      }
      Get.snackbar(
        'Google sign-in error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> _startPhoneVerificationForGoogleUser({
    required String email,
    required String name,
    required String photoUrl,
    required String uid,
  }) async {
    await myServices.clearAuthSession();
    await myServices.startGooglePhoneVerification(
      email: email,
      name: name,
      photoUrl: photoUrl,
      uid: uid,
    );

    Get.offAllNamed(AppRoutes.googlePhoneVerification);
  }

  Future<void> continueAsGuest() async {
    if (isLoading) {
      return;
    }

    try {
      await _firebaseAuth.signOut();
    } catch (_) {
      // Guest mode should still work even if Firebase was not signed in.
    }

    await myServices.startGuestSession();
    Get.offAllNamed(AppRoutes.homepage);
  }

  Future<User?> _signInWithGoogle() async {
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider()..addScope('email');
      final credential = await _firebaseAuth.signInWithPopup(googleProvider);
      return credential.user;
    }

    final googleProvider = GoogleAuthProvider()..addScope('email');
    final userCredential =
        await _firebaseAuth.signInWithProvider(googleProvider);
    return userCredential.user;
  }

  String _friendlyFirebaseAuthMessage(FirebaseAuthException error) {
    final rawMessage = '${error.code} ${error.message ?? ''}'.toUpperCase();
    if (rawMessage.contains('INVALID_APP_ID') ||
        rawMessage.contains('DEVELOPER_ERROR') ||
        rawMessage.contains('SIGN_IN_FAILED') ||
        rawMessage.contains('API_EXCEPTION: 10')) {
      return 'Firebase Android app is missing Google OAuth setup. Add SHA-1/SHA-256 for com.alepoo.eats in Firebase, enable Google sign-in, then replace google-services.json.';
    }

    return '${error.code}: ${error.message ?? 'Unknown FirebaseAuth error'.tr}';
  }
}
