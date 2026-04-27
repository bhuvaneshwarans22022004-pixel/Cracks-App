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
      return User.fromJson(data['user'], token: data['token']);
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
      return User.fromJson(data['user'], token: data['token']);
    }
    return null;
  }
}
