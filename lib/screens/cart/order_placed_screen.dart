import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../order/invoice_screen.dart';
import '../home/home_screen.dart';
import '../../utils/whatsapp_helper.dart';


class OrderPlacedScreen extends StatefulWidget {
  final String orderId;
  final double toPay;

  const OrderPlacedScreen({
    super.key,
    required this.orderId,
    required this.toPay,
  });

  @override
  State<OrderPlacedScreen> createState() => _OrderPlacedScreenState();
}

class _OrderPlacedScreenState extends State<OrderPlacedScreen> {
  bool _hasAutoSentWhatsApp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSendWhatsApp();
    });
  }

  void _autoSendWhatsApp() {
    if (_hasAutoSentWhatsApp) return;
    _hasAutoSentWhatsApp = true;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final matchedOrder = orderProvider.orders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => null as dynamic,
    );

    if (matchedOrder != null) {
      final itemsList = matchedOrder.items.map((i) => {
        'name': i.name,
        'quantity': i.quantity,
        'price': i.price,
      }).toList();

      WhatsAppHelper.launchOrderPlacedNotice(
        orderId: displayOrderId,
        rawId: widget.orderId,
        customerName: user?.name ?? "Customer",
        phone: user?.phone ?? "",
        totalAmount: matchedOrder.totalAmount > 0 ? matchedOrder.totalAmount : widget.toPay,
        address: matchedOrder.shippingAddress,
        items: itemsList,
        paymentStatus: matchedOrder.paymentMethod,
      );
    } else {
      WhatsAppHelper.launchWhatsApp(
        message: "Hello FestiveKart! 🎆\nI have placed order #$displayOrderId (Total: ₹${widget.toPay.toStringAsFixed(0)}). Please confirm and send delivery updates. Name: ${user?.name ?? ''}, Phone: ${user?.phone ?? ''}",
      );
    }
  }

  String get displayOrderId {
    if (widget.orderId.length >= 8) {
      return "FK${widget.orderId.substring(widget.orderId.length - 8).toUpperCase()}";
    }
    return "FK${widget.orderId.toUpperCase()}";
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
              MaterialPageRoute(builder: (_) => HomeScreen(initialIndex: 0)),
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
                                "Amount Paid: ₹${widget.toPay.toStringAsFixed(0)}",
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

                        // Send Order Details to WhatsApp Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            key: const Key('whatsapp_order_notice_btn'),
                            icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                            label: Text(
                              "Send Order Details to WhatsApp 💬",
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              final user = auth.user;
                              final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                              
                              final matchedOrder = orderProvider.orders.firstWhere(
                                (o) => o.id == widget.orderId,
                                orElse: () => null as dynamic,
                              );

                              if (matchedOrder != null) {
                                final itemsList = matchedOrder.items.map((i) => {
                                  'name': i.name,
                                  'quantity': i.quantity,
                                  'price': i.price,
                                }).toList();

                                WhatsAppHelper.launchOrderPlacedNotice(
                                  orderId: displayOrderId,
                                  rawId: widget.orderId,
                                  customerName: user?.name ?? "Customer",
                                  phone: user?.phone ?? "",
                                  totalAmount: matchedOrder.totalAmount > 0 ? matchedOrder.totalAmount : widget.toPay,
                                  address: matchedOrder.shippingAddress,
                                  items: itemsList,
                                  paymentStatus: matchedOrder.paymentMethod,
                                );
                              } else {
                                WhatsAppHelper.launchWhatsApp(
                                  message: "Hello FestiveKart! 🎆\nI have placed order #$displayOrderId (Total: ₹${widget.toPay.toStringAsFixed(0)}). Please confirm and send delivery updates. Name: ${user?.name ?? ''}, Phone: ${user?.phone ?? ''}",
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

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
                                  builder: (_) => HomeScreen(initialIndex: 2),
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
                        
                        // View Invoice Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            key: const Key('view_invoice_btn'),
                            icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFFFF5722)),
                            label: Text(
                              "View Invoice",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF5722),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFF5722), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              final token = auth.user?.token;
                              if (token == null) return;
                              
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
                                ),
                              );

                              try {
                                await Provider.of<OrderProvider>(context, listen: false).fetchOrders(token);
                                
                                if (context.mounted) {
                                  Navigator.pop(context); // Close loading dialog
                                  
                                  final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                                  final order = orderProvider.orders.firstWhere(
                                    (o) => o.id == widget.orderId,
                                  );
                                  
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InvoiceScreen(order: order),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.pop(context); // Close loading dialog
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Failed to fetch invoice. Please try again.")),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),                        // Continue Shopping Button
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
                                  builder: (_) => HomeScreen(initialIndex: 0),
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
