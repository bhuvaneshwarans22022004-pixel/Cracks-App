import 'dart:convert';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  Future<User?> login(String email, String password) async {
    final response = await ApiService.post('auth/login', {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userJson = data['user'] ?? data;
      return User.fromJson(userJson, token: data['token']);
    } else {
      print('Login failed: ${response.statusCode} - ${response.body}');
    }
    return null;
  }

  Future<User?> register(String name, String email, String password, String phone) async {
    final response = await ApiService.post('auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    });

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final userJson = data['user'] ?? data;
      return User.fromJson(userJson, token: data['token']);
    } else {
      print('Registration failed: ${response.statusCode} - ${response.body}');
    }
    return null;
  }

  Future<User?> updateProfile(String name, String phone, String token) async {
    final response = await ApiService.put(
      'auth/profile',
      {
        'name': name,
        'phone': phone,
      },
      token: token,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userJson = data['user'] ?? data;
      return User.fromJson(userJson, token: token);
    } else {
      print('Profile update failed: ${response.statusCode} - ${response.body}');
    }
    return null;
  }
}
