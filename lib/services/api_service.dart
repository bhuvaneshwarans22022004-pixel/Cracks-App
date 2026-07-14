import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  static Future<http.Response> get(String endpoint, {String? token}) async {
    return await http.get(
      Uri.parse('${AppConstants.baseUrl}/api/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
    return await http.post(
      Uri.parse('${AppConstants.baseUrl}/api/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body, {String? token}) async {
    return await http.put(
      Uri.parse('${AppConstants.baseUrl}/api/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String endpoint, {String? token}) async {
    return await http.delete(
      Uri.parse('${AppConstants.baseUrl}/api/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }
}
