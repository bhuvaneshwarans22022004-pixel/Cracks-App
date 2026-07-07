import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import 'order_placed_screen.dart';
import '../../utils/constants.dart';

class PaymentScreen extends StatefulWidget {
  final Address selectedAddress;
  final double totalMrp;
  final double discount;
  final double deliveryCharge;
  final double toPay;

  const PaymentScreen({
    super.key,
    required this.selectedAddress,
    required this.totalMrp,
    required this.discount,
    required this.deliveryCharge,
    required this.toPay,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedMethod;

  Widget _buildPaymentOption({
    required String method,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF8C00) : Colors.grey[100]!,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.005),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFFF8C00), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF8C00) : Colors.grey[300]!,
                  width: isSelected ? 5.5 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5), // Theme background color
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Payment",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewportConstraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isWeb ? 800 : double.infinity,
                      minHeight: viewportConstraints.maxHeight,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: isWeb ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ] : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Total Payable Section
                          Text(
                            "Total Payable",
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "₹${widget.toPay.toStringAsFixed(0)}",
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(height: 1, thickness: 1),
                          ),

                          // Choose Payment Method Title
                          Text(
                            "Choose Payment Method",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Options list
                          _buildPaymentOption(
                            method: 'UPI',
                            title: 'UPI',
                            subtitle: '(GPay, PhonePe, Paytm)',
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                          _buildPaymentOption(
                            method: 'Card',
                            title: 'Credit / Debit Card',
                            subtitle: '',
                            icon: Icons.credit_card_rounded,
                          ),
                          _buildPaymentOption(
                            method: 'NetBanking',
                            title: 'Net Banking',
                            subtitle: '',
                            icon: Icons.account_balance_rounded,
                          ),
                          _buildPaymentOption(
                            method: 'Wallet',
                            title: 'Wallets',
                            subtitle: '',
                            icon: Icons.wallet_giftcard_rounded,
                          ),
                          _buildPaymentOption(
                            method: 'COD',
                            title: 'Cash on Delivery',
                            subtitle: '',
                            icon: Icons.local_shipping_rounded,
                          ),

                          const SizedBox(height: 40),

                          // Action button: Pay
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5722),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: orderProvider.isLoading
                                  ? null
                                  : () async {
                                      if (_selectedMethod == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Please select a payment method to proceed"),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                        return;
                                      }

                                      final token = auth.user?.token;
                                      if (token == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Please login to place your order")),
                                        );
                                        return;
                                      }

                                      if (_selectedMethod == 'UPI') {
                                        _showUPIDialog(context, auth, cart, orderProvider);
                                        return;
                                      }

                                      final orderData = {
                                        'orderItems': cart.items.values.map((item) => {
                                          'name': item.product.name,
                                          'qty': item.quantity,
                                          'image': item.product.image,
                                          'price': item.product.price,
                                          'product': item.product.id,
                                        }).toList(),
                                        'shippingAddress': widget.selectedAddress.formattedAddress,
                                        'paymentMethod': _selectedMethod,
                                        'itemsPrice': widget.totalMrp,
                                        'shippingPrice': widget.deliveryCharge,
                                        'totalPrice': widget.toPay,
                                      };

                                      final orderId = await orderProvider.createOrder(orderData, token);

                                      if (orderId != null) {
                                        if (mounted) {
                                          cart.clear();
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => OrderPlacedScreen(
                                                orderId: orderId,
                                                toPay: widget.toPay,
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("Failed to place order. Try again.")),
                                          );
                                        }
                                      }
                                    },
                              child: orderProvider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      _selectedMethod == null
                                          ? "Select Payment Method"
                                          : _selectedMethod == 'COD'
                                              ? "Place Order"
                                              : "Pay ₹${widget.toPay.toStringAsFixed(0)}",
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 100% Secure Payments
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.security_rounded, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 6),
                              Text(
                                "100% Secure Payments",
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showUPIDialog(BuildContext context, AuthProvider auth, CartProvider cart, OrderProvider orderProvider) {
    final utrController = TextEditingController();
    final String upiId = AppConstants.upiId; 
    final String gpayNumber = AppConstants.gpayNumber; 
    final String payUrl = "upi://pay?pa=$upiId&pn=FestiveKart&am=${widget.toPay.toStringAsFixed(0)}&cu=INR";
    final String qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(payUrl)}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFFF8C00)),
                  const SizedBox(width: 10),
                  Text(
                    "Scan & Pay via UPI",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Scan the QR code below or use the GPay / PhonePe details to make a direct payment of ₹${widget.toPay.toStringAsFixed(0)}.",
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.network(
                        qrUrl,
                        width: 180,
                        height: 180,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C00).withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("GPay / PhonePe:", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[700])),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: gpayNumber));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Number copied to clipboard!")),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(gpayNumber, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.copy_rounded, size: 12, color: Color(0xFFFF8C00)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("UPI ID:", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[700])),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: upiId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("UPI ID copied to clipboard!")),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(upiId, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.copy_rounded, size: 12, color: Color(0xFFFF8C00)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: utrController,
                      decoration: InputDecoration(
                        labelText: "Enter Transaction Ref / UTR No.",
                        labelStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                        hintText: "12-digit transaction ID",
                        hintStyle: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final utr = utrController.text.trim();
                    if (utr.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter the UTR/Reference number")),
                      );
                      return;
                    }
                    
                    Navigator.pop(context);
                    
                    final token = auth.user?.token;
                    if (token == null) return;
                    
                    final orderData = {
                      'orderItems': cart.items.values.map((item) => {
                        'name': item.product.name,
                        'qty': item.quantity,
                        'image': item.product.image,
                        'price': item.product.price,
                        'product': item.product.id,
                      }).toList(),
                      'shippingAddress': widget.selectedAddress.formattedAddress,
                      'paymentMethod': 'UPI',
                      'paymentResult': {
                        'id': utr,
                        'status': 'Pending Verification',
                        'update_time': DateTime.now().toIso8601String(),
                        'email_address': auth.user?.email ?? '',
                      },
                      'itemsPrice': widget.totalMrp,
                      'shippingPrice': widget.deliveryCharge,
                      'totalPrice': widget.toPay,
                    };

                    final orderId = await orderProvider.createOrder(orderData, token);

                    if (orderId != null) {
                      cart.clear();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderPlacedScreen(
                              orderId: orderId,
                              toPay: widget.toPay,
                            ),
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to place order. Try again.")),
                        );
                      }
                    }
                  },
                  child: Text("Confirm Payment", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
