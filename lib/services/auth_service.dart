import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user.dart';
import '../utils/constants.dart';
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

  Future<User?> updateProfile(String name, String phone, String? profileImage, String token) async {
    final response = await ApiService.put(
      'auth/profile',
      {
        'name': name,
        'phone': phone,
        if (profileImage != null) 'profileImage': profileImage,
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

  Future<String?> uploadProfileImage(List<int> bytes, String filename, String token) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/upload');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['type'] = 'profile';
      
      String mimeType = 'image/jpeg';
      if (filename.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (filename.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (filename.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      } else {
        print('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error uploading profile image: $e');
    }
    return null;
  }

  Future<User?> getProfile(String token) async {
    try {
      final response = await ApiService.get('auth/profile', token: token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data, token: token);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('Profile fetch failed (Unauthorized): ${response.statusCode} - ${response.body}');
        return null;
      } else {
        print('Profile fetch failed (Server error): ${response.statusCode} - ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<bool> forgotPassword(String email) async {
    final response = await ApiService.post('auth/forgot-password', {'email': email});
    return response.statusCode == 200;
  }

  Future<bool> verifyOTP(String email, String otp) async {
    final response = await ApiService.post('auth/verify-otp', {
      'email': email,
      'otp': otp,
    });
    return response.statusCode == 200;
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    final response = await ApiService.post('auth/reset-password', {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
    return response.statusCode == 200;
  }

  Future<bool> changePassword(String currentPassword, String newPassword, String token) async {
    final response = await ApiService.post(
      'auth/change-password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      token: token,
    );
    return response.statusCode == 200;
  }
}
