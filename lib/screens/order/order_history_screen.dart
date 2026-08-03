import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'order_tracking_screen.dart';
import 'utr_dialog.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final token = Provider.of<AuthProvider>(context, listen: false).user?.token;
      if (token != null) {
        Provider.of<OrderProvider>(context, listen: false).fetchOrders(token);
      }
    });
  }

  String _formatOrderId(String rawId) {
    if (rawId.length >= 8) {
      return "FK${rawId.substring(rawId.length - 8).toUpperCase()}";
    }
    return "FK${rawId.toUpperCase()}";
  }

  Widget _buildOrderList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              "No orders found",
              style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final displayId = _formatOrderId(order.id);
        final formattedDate = DateFormat('dd MMM yyyy').format(order.createdAt);
        final isCancelled = order.status.toLowerCase() == 'cancelled';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderTrackingScreen(order: order),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID and Right Chevron
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Order ID: $displayId",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Placement Date
                Text(
                  formattedDate,
                  style: GoogleFonts.outfit(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),

                // Pricing and Status Alignments
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total: ₹${order.totalAmount.toStringAsFixed(0)}",
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      order.status,
                      style: GoogleFonts.outfit(
                        color: isCancelled ? const Color(0xFFF44336) : const Color(0xFFFF8C00),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (order.transactionId == 'PENDING') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF44336), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Payment Pending (No UTR)",
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFF44336),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          backgroundColor: const Color(0xFFFF8C00).withOpacity(0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFFFF8C00)),
                        label: Text(
                          "Verify Now",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFF8C00),
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => UtrDialog(orderId: order.id),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final isWeb = MediaQuery.of(context).size.width > 800;
    final orders = orderProvider.orders;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 0)),
              (route) => false,
            );
          },
        ),
        title: Text(
          "My Orders",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isWeb ? 650 : double.infinity),
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
            child: orderProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
                : DefaultTabController(
                    length: 4,
                    child: Column(
                      children: [
                        // Custom styled sub-header tab selectors
                        Container(
                          color: Colors.white,
                          child: TabBar(
                            indicatorColor: const Color(0xFFFF8C00),
                            labelColor: const Color(0xFFFF8C00),
                            unselectedLabelColor: Colors.grey[400],
                            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
                            tabs: const [
                              Tab(text: "All"),
                              Tab(text: "Processing"),
                              Tab(text: "Delivered"),
                              Tab(text: "Cancelled"),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildOrderList(orders),
                              _buildOrderList(orders
                                  .where((o) =>
                                      o.status.toLowerCase() == 'processing' ||
                                      o.status.toLowerCase() == 'pending' ||
                                      o.status.toLowerCase() == 'shipped' ||
                                      o.status.toLowerCase() == 'dispatched' ||
                                      o.status.toLowerCase() == 'out for delivery')
                                  .toList()),
                              _buildOrderList(orders.where((o) => o.status.toLowerCase() == 'delivered').toList()),
                              _buildOrderList(orders.where((o) => o.status.toLowerCase() == 'cancelled').toList()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
