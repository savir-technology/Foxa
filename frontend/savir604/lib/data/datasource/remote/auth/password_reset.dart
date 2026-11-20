import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';

class PasswordResetData {
  PasswordResetData(this.crud);
  final Crud crud;
  Future<dynamic> _post(String url, Map<String, dynamic> body) async {
    final result = await crud.postData(url, body, allowHttpErrorBody: true);
    return result.fold((error) => error, (data) => data);
  }
  Future<dynamic> checkEmail(String email) => _post(AppLink.checkEmail, {'email': email});
  Future<dynamic> verifyCode(String email, String code) => _post(AppLink.verifyResetCode, {'email': email, 'verifycode': code});
  Future<dynamic> reset(String email, String code, String password) => _post(AppLink.resetPassword, {'email': email, 'verifycode': code, 'password': password});
}
