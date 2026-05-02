import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        _user = user;
        await StorageService.saveToken(user.token!);
        return true;
      }
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> register(String name, String email, String password, String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.register(name, email, password, phone);
      if (user != null) {
        _user = user;
        await StorageService.saveToken(user.token!);
        return true;
      }
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> logout() async {
    _user = null;
    await StorageService.clear();
    notifyListeners();
  }

  Future<bool> updateProfile(String name, String phone) async {
    if (_user == null || _user!.token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = await _authService.updateProfile(name, phone, _user!.token!);
      if (updatedUser != null) {
        _user = updatedUser;
        return true;
      }
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Add auto-login logic if needed
}
