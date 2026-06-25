import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Address {
  final String id;
  final String type; // 'Home', 'Office', etc.
  final String addressLine;
  final String city;
  final String state;
  final String zipCode;
  final String phoneNumber;

  Address({
    required this.id,
    required this.type,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phoneNumber,
  });

  String get formattedAddress => "$addressLine, $city, $state - $zipCode";

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['_id'] ?? '',
      type: json['name'] ?? '',
      addressLine: json['addressLine'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['pincode'] ?? '',
      phoneNumber: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': type,
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'pincode': zipCode,
      'phone': phoneNumber,
    };
  }
}

class AddressProvider with ChangeNotifier {
  List<Address> _addresses = [];
  bool _isLoading = false;
  Address? _selectedAddress;

  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;
  Address? get selectedAddress => _selectedAddress ?? (_addresses.isNotEmpty ? _addresses.first : null);

  Future<void> fetchAddresses(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('addresses', token: token);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _addresses = data.map((json) => Address.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching addresses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAddress(Address address, String token) async {
    try {
      final response = await ApiService.post('addresses', address.toJson(), token: token);
      if (response.statusCode == 201) {
        final newAddress = Address.fromJson(jsonDecode(response.body));
        _addresses.add(newAddress);
        if (_selectedAddress == null) {
          _selectedAddress = newAddress;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error adding address: $e');
    }
  }

  Future<void> removeAddress(String id, String token) async {
    try {
      final response = await ApiService.delete('addresses/$id', token: token);
      if (response.statusCode == 200) {
        _addresses.removeWhere((item) => item.id == id);
        if (_selectedAddress?.id == id) {
          _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error removing address: $e');
    }
  }

  void selectAddress(Address address) {
    _selectedAddress = address;
    notifyListeners();
  }
}
