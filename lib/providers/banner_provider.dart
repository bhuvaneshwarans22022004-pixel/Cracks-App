import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class BannerProvider with ChangeNotifier {
  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = false;
  String _error = '';

  List<Map<String, dynamic>> get banners => _banners;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchBanners() async {
    _isLoading = true;
    _error = '';
    // Let listeners know we are loading, but do not notify if we already have some banners
    if (_banners.isEmpty) {
        notifyListeners();
    }

    try {
      final response = await ApiService.get('banners/active');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _banners = data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      } else {
        _error = 'Failed to load banners. Status Code: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'An error occurred while fetching banners.';
      print('Error fetching banners: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
