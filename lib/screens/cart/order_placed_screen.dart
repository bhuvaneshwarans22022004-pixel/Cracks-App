import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/home_screen.dart';

class OrderPlacedScreen extends StatelessWidget {
  final String orderId;
  final double toPay;

  const OrderPlacedScreen({
    super.key,
    required this.orderId,
    required this.toPay,
  });

  String get displayOrderId {
    if (orderId.length >= 8) {
      return "FK${orderId.substring(orderId.length - 8).toUpperCase()}";
    }
    return "FK${orderId.toUpperCase()}";
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5), // Soft cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: const Key('order_placed_back_btn'),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Safe exit to Home tab
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 0)),
              (route) => false,
            );
          },
        ),
        title: Text(
          "Order Placed",
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
                      boxShadow: isWeb
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Premium Checkmark Container
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 66,
                              height: 66,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50), // Vibrant Green
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          "Thank You!",
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Success Subtitle
                        Text(
                          "Your order has been placed successfully.",
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Order ID Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Order ID: $displayOrderId",
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Amount Paid: ₹${toPay.toStringAsFixed(0)}",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Shipment Status Info
                        Text(
                          "We will notify you once your order is shipped.",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // Action Buttons: Track Order
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            key: const Key('track_order_btn'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5722), // Accent Orange/Coral
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              // Route to HomeScreen, Order History Tab
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(initialIndex: 2),
                                ),
                                (route) => false,
                              );
                            },
                            child: Text(
                              "Track Order",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Continue Shopping Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            key: const Key('continue_shopping_btn'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF007AFF), width: 1.5), // Premium iOS blue outline
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              // Route to HomeScreen, Shop Tab
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(initialIndex: 0),
                                ),
                                (route) => false,
                              );
                            },
                            child: Text(
                              "Continue Shopping",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF007AFF),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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
}
