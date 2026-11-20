import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/functions/handingdatacontroller.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/remote/wallet/wallet_data.dart';

class WalletController extends GetxController {
  WalletController({WalletData? walletData})
      : walletData = walletData ?? Get.put(WalletData(Get.find()));

  final WalletData walletData;
  final MyServices myServices = Get.find();

  StatusRequest statusRequest = StatusRequest.none;
  double walletBalance = 0;
  int referralPoints = 0;
  int totalReferrals = 0;
  int activatedReferrals = 0;
  String referralCode = '';

  String get userId =>
      (myServices.sharedPreferences.getInt('id') ?? 0).toString();

  Future<void> fetchWalletSummary() async {
    statusRequest = StatusRequest.loading;
    update();

    final response = await walletData.stats(userId);
    statusRequest = handlingData(response);

    if (statusRequest == StatusRequest.success && response is Map) {
      walletBalance =
          double.tryParse(response['wallet_balance']?.toString() ?? '') ?? 0;
      referralPoints =
          int.tryParse(response['referral_points']?.toString() ?? '') ?? 0;
      totalReferrals =
          int.tryParse(response['total_referrals']?.toString() ?? '') ?? 0;
      activatedReferrals =
          int.tryParse(response['activated_referrals']?.toString() ?? '') ?? 0;
      referralCode = response['referral_code']?.toString() ?? '';
    }

    update();
  }

  Future<void> convertPoints() async {
    if (referralPoints <= 0) {
      Get.snackbar('Wallet'.tr, 'There are no points available to convert.'.tr);
      return;
    }

    final response = await walletData.convertPoints(
      userId: userId,
      points: referralPoints.toString(),
    );

    final resultStatus = response is Map ? response['status']?.toString() : '';
    if (resultStatus == 'success') {
      Get.snackbar('Wallet'.tr, 'Points were converted to wallet balance.'.tr);
      await fetchWalletSummary();
      return;
    }

    Get.snackbar('Wallet'.tr, 'Unable to convert points right now.'.tr);
  }

  Future<void> copyReferralCode() async {
    if (referralCode.trim().isEmpty) {
      Get.snackbar('Wallet'.tr, 'No referral code is available yet.'.tr);
      return;
    }
    await Clipboard.setData(ClipboardData(text: referralCode));
    Get.snackbar('Wallet'.tr, 'Referral code copied.'.tr);
  }

  @override
  void onInit() {
    super.onInit();
    fetchWalletSummary();
  }
}
