import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';

class WalletData {
  WalletData(this.crud);

  final Crud crud;

  Future<dynamic> stats(String userId) async {
    final response = await crud.postData(
      AppLink.walletStats,
      {'user_id': userId},
    );
    return response.fold((left) => left, (right) => right);
  }

  Future<dynamic> convertPoints({
    required String userId,
    required String points,
  }) async {
    final response = await crud.postData(
      AppLink.walletConvertPoints,
      {
        'user_id': userId,
        'points': points,
      },
    );
    return response.fold((left) => left, (right) => right);
  }

  Future<dynamic> payWithWallet({
    required String userId,
    required String orderId,
    required String total,
  }) async {
    final response = await crud.postData(
      AppLink.walletPay,
      {
        'user_id': userId,
        'order_id': orderId,
        'total': total,
      },
    );
    return response.fold((left) => left, (right) => right);
  }
}
