import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

class UtrDialog extends StatefulWidget {
  final String orderId;

  const UtrDialog({super.key, required this.orderId});

  @override
  State<UtrDialog> createState() => _UtrDialogState();
}

class _UtrDialogState extends State<UtrDialog> {
  final _utrController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _submitUtr() async {
    final utr = _utrController.text.trim();
    if (utr.isEmpty) {
      setState(() {
        _errorMessage = "Please enter the UTR/Reference number";
      });
      return;
    }

    if (utr.length != 12 || double.tryParse(utr) == null) {
      setState(() {
        _errorMessage = "UTR number must be exactly 12 digits";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.user?.token;
      if (token == null) {
        setState(() {
          _errorMessage = "Authentication failed. Please log in again.";
          _isLoading = false;
        });
        return;
      }

      final response = await ApiService.put(
        'orders/${widget.orderId}/utr',
        {'utr': utr},
        token: token,
      );

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Refresh orders list
        if (mounted) {
          await Provider.of<OrderProvider>(context, listen: false).fetchOrders(token);
          if (mounted) {
            Navigator.pop(context, true); // Return true indicating success
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("UTR number submitted successfully! Verification pending.")),
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? "Failed to submit UTR. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred. Please check your connection.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Color(0xFFFF8C00)),
          const SizedBox(width: 10),
          Text(
            "Verify UTR Number",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Please enter the 12-digit transaction ID / UTR number from GPay/PhonePe/Paytm to verify your payment.",
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _utrController,
              decoration: InputDecoration(
                labelText: "Transaction Ref / UTR No.",
                labelStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                hintText: "12-digit transaction ID",
                hintStyle: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                errorText: _errorMessage,
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C00),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isLoading ? null : _submitUtr,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  "Submit UTR",
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
