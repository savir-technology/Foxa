import 'package:admin_tks/controler/user_controller.dart';
import 'package:admin_tks/model/user_model.dart';
import 'package:flutter/material.dart';

class UserData extends ChangeNotifier {
  final UserController _userController = UserController();

  List<User> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userController.fetchUsers();
    } catch (_) {
      _users = [];
      _errorMessage = 'تعذر تحميل المستخدمين حالياً. حاول مرة أخرى.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    await _userController.updateUserStatus(userId: userId, isActive: isActive);
    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1) return;

    final current = _users[index];
    _users[index] = User(
      id: current.id,
      name: current.name,
      phone: current.phone,
      email: current.email,
      verificationCode: current.verificationCode,
      isActive: isActive,
      password: current.password,
      imageName: current.imageName,
    );
    notifyListeners();
  }
}
