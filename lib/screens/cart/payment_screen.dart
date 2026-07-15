import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String? _selectedMethod = 'UPI';

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
                                        'taxPrice': 0.0,
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
    final String upiId = AppConstants.upiId; 
    final String gpayNumber = AppConstants.gpayNumber; 
    final String payUrl = "upi://pay?pa=$upiId&pn=FestiveKart&am=${widget.toPay.toStringAsFixed(0)}&cu=INR";
    final String qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(payUrl)}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _UPIDialogContent(
          payUrl: payUrl,
          qrUrl: qrUrl,
          gpayNumber: gpayNumber,
          upiId: upiId,
          toPay: widget.toPay,
          auth: auth,
          cart: cart,
          orderProvider: orderProvider,
          selectedAddress: widget.selectedAddress,
          totalMrp: widget.totalMrp,
          deliveryCharge: widget.deliveryCharge,
        );
      },
    );
  }
}

class _UPIDialogContent extends StatefulWidget {
  final String payUrl;
  final String qrUrl;
  final String gpayNumber;
  final String upiId;
  final double toPay;
  final AuthProvider auth;
  final CartProvider cart;
  final OrderProvider orderProvider;
  final Address selectedAddress;
  final double totalMrp;
  final double deliveryCharge;

  const _UPIDialogContent({
    required this.payUrl,
    required this.qrUrl,
    required this.gpayNumber,
    required this.upiId,
    required this.toPay,
    required this.auth,
    required this.cart,
    required this.orderProvider,
    required this.selectedAddress,
    required this.totalMrp,
    required this.deliveryCharge,
  });

  @override
  State<_UPIDialogContent> createState() => _UPIDialogContentState();
}

class _UPIDialogContentState extends State<_UPIDialogContent> with WidgetsBindingObserver {
  bool _hasOpenedUPI = false;
  bool _showStatusVerification = false;
  bool _showUtrForm = false;
  bool _showFailedOptions = false;
  bool _isSubmitting = false;
  final _utrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _utrController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _hasOpenedUPI) {
      setState(() {
        _showStatusVerification = true;
        _showUtrForm = false;
        _showFailedOptions = false;
        _hasOpenedUPI = false; // Reset to avoid double triggering
      });
    }
  }

  Future<void> _launchUPI() async {
    final uri = Uri.parse(widget.payUrl);
    try {
      setState(() {
        _hasOpenedUPI = true;
      });
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success) {
        setState(() {
          _hasOpenedUPI = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open UPI app automatically. Please use details below.")),
        );
      }
    } catch (e) {
      setState(() {
        _hasOpenedUPI = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No UPI apps found. Please copy the details below to pay.")),
      );
    }
  }

  Future<void> _submitOrder() async {
    final utr = _utrController.text.trim();
    if (utr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the UTR/Reference number")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final token = widget.auth.user?.token;
    if (token == null) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final orderData = {
      'orderItems': widget.cart.items.values.map((item) => {
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
        'email_address': widget.auth.user?.email ?? '',
      },
      'itemsPrice': widget.totalMrp,
      'taxPrice': 0.0,
      'shippingPrice': widget.deliveryCharge,
      'totalPrice': widget.toPay,
    };

    final orderId = await widget.orderProvider.createOrder(orderData, token);

    if (orderId != null) {
      widget.cart.clear();
      if (mounted) {
        Navigator.pop(context); // Close dialog
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
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to place order. Try again.")),
        );
      }
    }
  }

  Future<void> _submitFailedOrCancelledOrder(String reason) async {
    final token = widget.auth.user?.token;
    if (token == null) return;

    final orderData = {
      'orderItems': widget.cart.items.values.map((item) => {
        'name': item.product.name,
        'qty': item.quantity,
        'image': item.product.image,
        'price': item.product.price,
        'product': item.product.id,
      }).toList(),
      'shippingAddress': widget.selectedAddress.formattedAddress,
      'paymentMethod': 'UPI',
      'paymentResult': {
        'id': 'FAILED-${DateTime.now().millisecondsSinceEpoch}',
        'status': reason,
        'update_time': DateTime.now().toIso8601String(),
        'email_address': widget.auth.user?.email ?? '',
      },
      'itemsPrice': widget.totalMrp,
      'taxPrice': 0.0,
      'shippingPrice': widget.deliveryCharge,
      'totalPrice': widget.toPay,
      'status': 'Failed',
    };

    await widget.orderProvider.createOrder(orderData, token);
  }

  @override
  Widget build(BuildContext context) {
    if (_showUtrForm) {
      return _buildUtrFormView();
    }
    if (_showStatusVerification) {
      return _buildStatusVerificationView();
    }
    if (_showFailedOptions) {
      return _buildFailedOptionsView();
    }
    return _buildInitialPayView();
  }

  Widget _buildInitialPayView() {
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
              child: GestureDetector(
                onTap: _launchUPI,
                child: Image.network(
                  widget.qrUrl,
                  width: 180,
                  height: 180,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _launchUPI,
              icon: const Icon(Icons.flash_on, color: Colors.white, size: 16),
              label: Text(
                "Open GPay / PhonePe directly",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                minimumSize: const Size(200, 40),
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
                          Clipboard.setData(ClipboardData(text: widget.gpayNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Number copied to clipboard!")),
                          );
                        },
                        child: Row(
                          children: [
                            Text(widget.gpayNumber, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                          Clipboard.setData(ClipboardData(text: widget.upiId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("UPI ID copied to clipboard!")),
                          );
                        },
                        child: Row(
                          children: [
                            Text(widget.upiId, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _submitFailedOrCancelledOrder("User Cancelled Checkout");
            Navigator.pop(context);
          },
          child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C00),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            setState(() {
              _showStatusVerification = true;
            });
          },
          child: Text("I Paid Successfully", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildStatusVerificationView() {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFFFF8C00)),
          const SizedBox(width: 10),
          Text(
            "Verify Payment Status",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            "Did you complete the payment of ₹${widget.toPay.toStringAsFixed(0)} successfully in your UPI app?",
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        OutlinedButton(
          onPressed: () {
            setState(() {
              _showStatusVerification = false;
              _showFailedOptions = true;
            });
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text("No, Failed / Cancelled", style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _showStatusVerification = false;
              _showUtrForm = true;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C00),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text("Yes, Successful", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildUtrFormView() {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        "Enter Payment Details",
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Please enter your 12-digit transaction ID / UTR number from GPay/PhonePe to confirm your order.",
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
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _showUtrForm = false;
              _showStatusVerification = true;
            });
          },
          child: Text("Back", style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C00),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isSubmitting ? null : _submitOrder,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text("Confirm & Place Order", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildFailedOptionsView() {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Text(
            "Payment Failed",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
          ),
        ],
      ),
      content: Text(
        "Your payment transaction was failed or cancelled. Would you like to retry or cancel order processing?",
        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        OutlinedButton(
          onPressed: () {
            _submitFailedOrCancelledOrder("User Cancelled / Failed");
            Navigator.pop(context); // Dismiss dialog and return back to payment options
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[400]!),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text("Quit & Go Back", style: GoogleFonts.outfit(color: Colors.grey[700], fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _showFailedOptions = false;
              _showStatusVerification = false;
              _showUtrForm = false;
            });
            _launchUPI(); // Retry opening the UPI app
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C00),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text("Retry Payment", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
