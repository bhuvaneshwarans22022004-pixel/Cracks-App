import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isGuestMode = false;
  final AuthService _authService = AuthService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isGuest => _isGuestMode;
  bool get isAuthenticated => _user != null || _isGuestMode;

  void loginAsGuest() {
    _isGuestMode = true;
    _user = null;
    notifyListeners();
  }

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
    _isGuestMode = false;
    await StorageService.clear();
    notifyListeners();
  }

  Future<bool> updateProfile(String name, String phone) async {
    if (_user == null || _user!.token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = await _authService.updateProfile(name, phone, _user!.profileImage, _user!.token!);
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

  Future<bool> uploadAndSaveProfileImage(List<int> bytes, String filename) async {
    if (_user == null || _user!.token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final imageUrl = await _authService.uploadProfileImage(bytes, filename, _user!.token!);
      if (imageUrl != null) {
        final updatedUser = await _authService.updateProfile(
          _user!.name,
          _user!.phone,
          imageUrl,
          _user!.token!,
        );
        if (updatedUser != null) {
          _user = updatedUser;
          return true;
        }
      }
    } catch (e) {
      print('Error uploading and saving profile image: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> tryAutoLogin() async {
    final token = await StorageService.getToken();
    if (token == null) return false;

    try {
      final fetchedUser = await _authService.getProfile(token);
      if (fetchedUser != null) {
        _user = fetchedUser;
        notifyListeners();
        return true;
      } else {
        await StorageService.clear();
      }
    } catch (e) {
      print('Auto-login error: $e');
    }
    return false;
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _authService.forgotPassword(email);
    } catch (e) {
      print('Forgot password error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> verifyOTP(String email, String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _authService.verifyOTP(email, otp);
    } catch (e) {
      print('Verify OTP error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _authService.resetPassword(email, otp, newPassword);
    } catch (e) {
      print('Reset password error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_user == null || _user!.token == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      return await _authService.changePassword(currentPassword, newPassword, _user!.token!);
    } catch (e) {
      print('Change password error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
