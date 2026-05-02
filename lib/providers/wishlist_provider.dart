import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class WishlistProvider with ChangeNotifier {
  List<Product> _items = [];
  bool _isLoading = false;

  List<Product> get items => _items;
  bool get isLoading => _isLoading;

  Future<void> fetchWishlist(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('auth/wishlist', token: token);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _items = data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleWishlist(Product product, String token) async {
    final index = _items.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      _items.removeAt(index);
    } else {
      _items.add(product);
    }
    notifyListeners();

    try {
      await ApiService.post('auth/wishlist', {'productId': product.id}, token: token);
    } catch (e) {
      print(e);
    }
  }

  bool isInWishlist(String productId) {
    return _items.any((item) => item.id == productId);
  }
}
