import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
    );
  }
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  CartProvider() {
    _loadCartFromPrefs();
  }

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.product.price * cartItem.quantity;
    });
    return total;
  }

  Future<void> _loadCartFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('cart_items')) return;

      final String? cartData = prefs.getString('cart_items');
      if (cartData != null) {
        final Map<String, dynamic> decodedData = json.decode(cartData);
        final Map<String, CartItem> loadedItems = {};
        decodedData.forEach((key, itemJson) {
          loadedItems[key] = CartItem.fromJson(itemJson);
        });
        _items = loadedItems;
        notifyListeners();
      }
    } catch (error) {
      print("Error loading cart from preferences: $error");
    }
  }

  Future<void> _saveCartToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> cartData = {};
      _items.forEach((key, cartItem) {
        cartData[key] = cartItem.toJson();
      });
      await prefs.setString('cart_items', json.encode(cartData));
    } catch (error) {
      print("Error saving cart to preferences: $error");
    }
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existing) => CartItem(product: existing.product, quantity: existing.quantity + 1),
      );
    } else {
      _items.putIfAbsent(product.id, () => CartItem(product: product));
    }
    notifyListeners();
    _saveCartToPrefs();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
    _saveCartToPrefs();
  }

  void decrementItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(product: existing.product, quantity: existing.quantity - 1),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
    _saveCartToPrefs();
  }

  void clear() {
    _items = {};
    notifyListeners();
    _saveCartToPrefs();
  }
}
