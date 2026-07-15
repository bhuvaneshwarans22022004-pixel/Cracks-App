import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchOrders(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('orders/myorders', token: token);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _orders = data.map((json) => Order.fromJson(json)).toList();
      }
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createOrder(Map<String, dynamic> orderData, String token) async {
    try {
      print("[Order API] Sending order data: ${jsonEncode(orderData)}");
      final response = await ApiService.post('orders', orderData, token: token);
      print("[Order API] createOrder status code: ${response.statusCode}");
      print("[Order API] createOrder body: ${response.body}");
      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['_id'] as String?;
      }
      return null;
    } catch (e) {
      print("[Order API] Error in createOrder: $e");
      return null;
    }
  }
}
