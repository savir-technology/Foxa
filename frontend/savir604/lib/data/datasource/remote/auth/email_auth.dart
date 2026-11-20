import 'package:tks/core/class/crud.dart';
import 'package:tks/linkapi/linkapi.dart';

class EmailAuthData {
  EmailAuthData(this.crud);

  final Crud crud;

  Future<dynamic> login({required String email, required String password}) =>
      _post(AppLink.login, {'email': email, 'password': password});

  Future<dynamic> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) =>
      _post(AppLink.signup, {
        'username': name,
        'email': email,
        'phone': phone,
        'password': password,
      });

  Future<dynamic> verify({required String email, required String code}) =>
      _post(AppLink.verifyCode, {'email': email, 'verifycode': code});

  Future<dynamic> resend({required String email}) =>
      _post(AppLink.resendCode, {'email': email});

  Future<dynamic> _post(String url, Map<String, dynamic> body) async {
    final response = await crud.postData(url, body, allowHttpErrorBody: true);
    return response.fold((error) => error, (data) => data);
  }
}
