import 'package:bits_mobile_app/core/services/api_service.dart';
import 'package:bits_mobile_app/core/services/auth_service.dart';
import 'package:bits_mobile_app/models/user_model.dart';
import 'package:flutter/material.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authService);

  final AuthService _authService;
  UserModel? user;
  bool loading = false;
  String? error;

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();
    try {
      user = await _authService.restoreUser();
      error = null;
    } on ApiException catch (e) {
      user = null;
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      user = await _authService.login(email, password);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    loading = true;
    notifyListeners();
    await _authService.logout();
    user = null;
    loading = false;
    notifyListeners();
  }
}
