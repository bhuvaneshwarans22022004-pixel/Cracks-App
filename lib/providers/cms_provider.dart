import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';

class CmsProvider with ChangeNotifier {
  Map<String, String> _content = {
    'about_us': 'Loading...',
    'privacy_policy': 'Loading...',
    'help_support': 'Loading...',
  };
  bool _isLoading = false;

  Map<String, String> get content => _content;
  bool get isLoading => _isLoading;

  Future<void> fetchContent() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('cms/content');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _content = {
          'about_us': data['about_us'] ?? 'About Us content not available.',
          'privacy_policy': data['privacy_policy'] ?? 'Privacy Policy content not available.',
          'help_support': data['help_support'] ?? 'Help & Support content not available.',
        };
      }
    } catch (e) {
      print('Error fetching CMS content: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
