import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';

class InvoiceScreen extends StatelessWidget {
  final Order order;

  const InvoiceScreen({super.key, required this.order});

  String get displayOrderId {
    if (order.id.length >= 8) {
      return "FK${order.id.substring(order.id.length - 8).toUpperCase()}";
    }
    return "FK${order.id.toUpperCase()}";
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);
    
    // Inferred calculations
    double itemsMrpTotal = 0;
    double itemsSellingTotal = 0;

    for (var item in order.items) {
      final origPrice = item.originalPrice > 0 ? item.originalPrice : item.price;
      itemsMrpTotal += origPrice * item.quantity;
      itemsSellingTotal += item.price * item.quantity;
    }

    final double savingAmount = (itemsMrpTotal - itemsSellingTotal).clamp(0.0, double.infinity);
    // Calculate 3% Shipping Charge
    final double shippingPrice = order.shippingPrice > 0 
        ? order.shippingPrice 
        : itemsSellingTotal * 0.03;
    final double grandTotal = itemsSellingTotal + shippingPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5), // Soft cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Tax Invoice",
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: BoxConstraints(maxWidth: isWeb ? 700 : double.infinity),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Invoice Design
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Logo & Branding
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              height: 48,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Text(
                                "FESTIVEKART",
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF8C00),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Image.asset(
                              'assets/images/jj.png',
                              height: 48,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF8C00).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "TAX INVOICE",
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFFF8C00),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 24),

                        // Invoice Details Grid
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _metaItem("Invoice No:", displayOrderId),
                                  const SizedBox(height: 10),
                                  _metaItem("Date & Time:", formattedDate),
                                  const SizedBox(height: 10),
                                  _metaItem("Payment Method:", order.paymentMethod.toUpperCase()),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _metaItem(
                                    "Order Status:", 
                                    order.status,
                                    valueColor: order.status.toLowerCase() == 'cancelled' 
                                        ? Colors.red 
                                        : const Color(0xFFFF8C00),
                                  ),
                                  const SizedBox(height: 10),
                                  _metaItem(
                                    "Payment Status:", 
                                    order.isPaid ? "PAID" : "UNPAID / VERIFICATION PENDING",
                                    valueColor: order.isPaid ? Colors.green : Colors.red,
                                  ),
                                  if (order.transactionId != null && order.transactionId!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    _metaItem("Transaction ID / UTR:", order.transactionId!),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 24),

                        // Billing / Shipping Address Section
                        Text(
                          "DELIVER TO:",
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[500],
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (order.userName != null || order.userPhone != null) ...[
                          Text(
                            "${order.userName ?? 'Customer'}\nPhone: ${order.userPhone ?? 'N/A'}",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          order.shippingAddress,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 24),

                        // Items Table Header matching User Mockup
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                "ITEM DESCRIPTION",
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Original price",
                                textAlign: TextAlign.right,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Discount",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Price",
                                textAlign: TextAlign.right,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Qty",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "TOTAL",
                                textAlign: TextAlign.right,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Items List
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: order.items.length,
                          itemBuilder: (context, index) {
                            final item = order.items[index];
                            final origPrice = item.originalPrice > 0 ? item.originalPrice : item.price;
                            final discountPercent = origPrice > item.price 
                                ? (((origPrice - item.price) / origPrice) * 100).round() 
                                : 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "₹${(origPrice * item.quantity).toStringAsFixed(0)}",
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        decoration: origPrice > item.price ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      discountPercent > 0 ? "$discountPercent%" : "-",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: discountPercent > 0 ? Colors.green[700] : Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      "₹${item.price.toStringAsFixed(0)}",
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      "x ${item.quantity}",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      "₹${(item.price * item.quantity).toStringAsFixed(0)}",
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 24),

                        // Totals Summary Section matching User Image Annotations
                        _pricingRow("Subtotal (MRP)", itemsMrpTotal),
                        if (savingAmount > 0) ...[
                          const SizedBox(height: 10),
                          _pricingRow("Saving amount", savingAmount, isDiscount: true),
                        ],
                        const SizedBox(height: 10),
                        _pricingRow("Items Subtotal", itemsSellingTotal),
                        const SizedBox(height: 10),
                        _pricingRow(
                          "Shipping Charge (3%)", 
                          shippingPrice,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, thickness: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "GRAND TOTAL",
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "₹${grandTotal.toStringAsFixed(2)}",
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF8C00),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Bottom Decorative Barcode look / Note
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFBF7),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      border: Border(top: BorderSide(color: Colors.grey[100]!)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "This is a computer-generated tax invoice. No signature is required.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Barcode pattern representation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            25,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              width: (index % 3 == 0) ? 3 : (index % 5 == 0) ? 1.5 : 1,
                              height: 36,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
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

  Widget _metaItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _pricingRow(String label, double amount, {bool isDiscount = false, bool isFreeShipping = false}) {
    String valueText = "";
    if (isFreeShipping) {
      valueText = "FREE";
    } else {
      valueText = "${isDiscount ? '-' : ''}₹${amount.abs().toStringAsFixed(0)}";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          valueText,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDiscount || isFreeShipping ? const Color(0xFF2E7D32) : Colors.black87,
          ),
        ),
      ],
    );
  }
}
