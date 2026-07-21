import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/guest_auth_prompt.dart';
import 'address_screen.dart';
import 'payment_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});



  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final addressProvider = Provider.of<AddressProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final selectedAddress = addressProvider.selectedAddress;
    final isWeb = MediaQuery.of(context).size.width > 800;

    // Calculations matching mockup rules
    final double totalMrp = cart.totalAmount;
    final double deliveryCharge = totalMrp > 1000 || totalMrp == 0 ? 0.0 : 30.0;
    final double handlingCharge = totalMrp == 0 ? 0.0 : 8.0;
    final double surgeCharge = (totalMrp >= 499 || totalMrp == 0) ? 0.0 : 30.0;
    final double discount = 0.0; // Coupon discount if applicable
    final double toPay = totalMrp + deliveryCharge + handlingCharge + surgeCharge - discount;

    final totalQty = cart.items.values.fold(0, (sum, item) => sum + item.quantity);

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
          "Cart",
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
                    child: cart.items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                                  const SizedBox(height: 20),
                                  Text(
                                    "Your cart is empty",
                                    style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF8C00),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("Start Shopping", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Items Header Counter
                              Padding(
                                padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
                                child: Text(
                                  "$totalQty Items in Cart",
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              // Cart items list
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: cart.items.length,
                                itemBuilder: (context, index) {
                                  final item = cart.items.values.toList()[index];
                                  final packLabel = item.product.packSize > 1
                                      ? "(Pack of ${item.product.packSize})"
                                      : "(Pack of 1)";
                                  final nameWithSuffix = "${item.product.name} $packLabel";

                                   return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey[100]!),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.01),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // Product Image Container
                                            Container(
                                              width: 76,
                                              height: 76,
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey[100]!),
                                              ),
                                              child: Image.network(
                                                item.product.image,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) => const Icon(
                                                  Icons.celebration,
                                                  color: Color(0xFFFF8C00),
                                                  size: 32,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Product Name & Price
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    nameWithSuffix,
                                                    style: GoogleFonts.outfit(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    "₹${item.product.price.toStringAsFixed(0)}",
                                                    style: GoogleFonts.outfit(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Premium custom quantity selector
                                            Container(
                                              height: 36,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey[200]!),
                                                borderRadius: BorderRadius.circular(10),
                                                color: Colors.white,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () => cart.decrementItem(item.product.id),
                                                    behavior: HitTestBehavior.opaque,
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 10),
                                                      child: Icon(Icons.remove, size: 14, color: Colors.black54),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 1,
                                                    height: 20,
                                                    color: Colors.grey[200],
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    child: Text(
                                                      '${item.quantity}',
                                                      style: GoogleFonts.outfit(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: 1,
                                                    height: 20,
                                                    color: Colors.grey[200],
                                                  ),
                                                  GestureDetector(
                                                    onTap: () => cart.addItem(item.product),
                                                    behavior: HitTestBehavior.opaque,
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 10),
                                                      child: Icon(Icons.add, size: 14, color: Colors.black54),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Divider + Remove button
                                        const SizedBox(height: 10),
                                        Divider(height: 1, color: Colors.grey[100]),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: () {
                                            showModalBottomSheet(
                                              context: context,
                                              shape: const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                              ),
                                              builder: (ctx) => Padding(
                                                padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 40,
                                                      height: 4,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[300],
                                                        borderRadius: BorderRadius.circular(2),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    const Icon(Icons.delete_outline, size: 44, color: Color(0xFFFF5722)),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      "Remove item?",
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      "Are you sure you want to remove this item from your cart?",
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 13,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 24),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: OutlinedButton(
                                                            style: OutlinedButton.styleFrom(
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                              side: BorderSide(color: Colors.grey[300]!),
                                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                                            ),
                                                            onPressed: () => Navigator.pop(ctx),
                                                            child: Text(
                                                              "Cancel",
                                                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.black87),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFFFF5722),
                                                              elevation: 0,
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                                            ),
                                                            onPressed: () {
                                                              Navigator.pop(ctx);
                                                              cart.removeItem(item.product.id);
                                                            },
                                                            child: Text(
                                                              "Remove",
                                                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Remove",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.red[400],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                 },
                              ),

                              const SizedBox(height: 16),

                              // 1. Use Coupons Card
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("No coupons available right now", style: GoogleFonts.outfit()),
                                        behavior: SnackBarBehavior.floating,
                                        width: isWeb ? 400 : null,
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFF1F1F1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.percent_rounded, color: Colors.blueAccent, size: 16),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Use Coupons",
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // 2. Bill Details Card
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFF1F1F1)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Bill details",
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.article_outlined, size: 14, color: Colors.grey[500]),
                                              const SizedBox(width: 6),
                                              Text("Items total", style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                                            ],
                                          ),
                                          Text("₹${totalMrp.toStringAsFixed(0)}", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.directions_bike_rounded, size: 14, color: Colors.grey[500]),
                                              const SizedBox(width: 6),
                                              Text("Delivery charge", style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                                            ],
                                          ),
                                          Text(
                                            deliveryCharge > 0 ? "₹${deliveryCharge.toStringAsFixed(0)}" : "FREE",
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              color: deliveryCharge > 0 ? Colors.black87 : const Color(0xFF2E7D32),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.room_service_outlined, size: 14, color: Colors.grey[500]),
                                              const SizedBox(width: 6),
                                              Text("Handling charge", style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                                            ],
                                          ),
                                          Text("₹${handlingCharge.toStringAsFixed(0)}", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                                        ],
                                      ),
                                      if (surgeCharge > 0) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.trending_up_rounded, size: 14, color: Colors.grey[500]),
                                                const SizedBox(width: 6),
                                                Text("High demand surge charge", style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                                              ],
                                            ),
                                            Text("₹${surgeCharge.toStringAsFixed(0)}", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 20),
                                          child: Text(
                                            "No surge charge on shopping products worth ₹499 or more",
                                            style: GoogleFonts.outfit(color: const Color(0xFFFF5722), fontSize: 10, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 14),
                                        child: Divider(height: 1, thickness: 1),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Grand total",
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Colors.black87,
                                              decoration: TextDecoration.underline,
                                              decorationStyle: TextDecorationStyle.dotted,
                                            ),
                                          ),
                                          Text(
                                            "₹${toPay.toStringAsFixed(0)}",
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // 3. Add GSTIN Card
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: InkWell(
                                  onTap: () => _showGstinDialog(context),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFF1F1F1)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.receipt_long_rounded, color: Colors.blueAccent, size: 16),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Add GSTIN",
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "Claim GST input credit up to 18% on your order",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : isWeb
              ? Container(
                  color: const Color(0xFFFAF8F5),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: 1.0,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, -3),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAddressSection(context, selectedAddress, totalMrp, deliveryCharge, toPay),
                          _buildPaymentStickyBar(context, selectedAddress, totalMrp, deliveryCharge, toPay),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, -3),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAddressSection(context, selectedAddress, totalMrp, deliveryCharge, toPay),
                      _buildPaymentStickyBar(context, selectedAddress, totalMrp, deliveryCharge, toPay),
                    ],
                  ),
                ),
    );
  }

  void _showGstinDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Add GSTIN", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter 15-digit GSTIN",
            hintStyle: GoogleFonts.outfit(color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                final isWeb = MediaQuery.of(context).size.width > 800;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("GSTIN ${controller.text} added successfully!", style: GoogleFonts.outfit()),
                    behavior: SnackBarBehavior.floating,
                    width: isWeb ? 400 : null,
                  ),
                );
              }
            },
            child: Text("Add", style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context, Address? selectedAddress, double totalMrp, double deliveryCharge, double toPay) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.home_filled, color: Colors.amber[800], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedAddress != null ? "Delivering to ${selectedAddress.type}" : "Select Delivery Address",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedAddress != null 
                      ? selectedAddress.formattedAddress 
                      : "Please add or select an address to proceed",
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (auth.isGuest) {
                showGuestAuthPrompt(context, "Please log in or register to manage your delivery address.");
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddressScreen(
                    isCheckoutMode: true,
                    totalMrp: totalMrp,
                    discount: 0.0,
                    deliveryCharge: deliveryCharge,
                    toPay: toPay,
                  ),
                ),
              );
            },
            child: Text(
              selectedAddress != null ? "Change" : "Select",
              style: GoogleFonts.outfit(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStickyBar(BuildContext context, Address? selectedAddress, double totalMrp, double deliveryCharge, double toPay) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "PAY USING",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        "Google Pay UPI",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_up, size: 16, color: Colors.black87),
                    ],
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (auth.isGuest) {
                showGuestAuthPrompt(context, "Please log in or register to place your order.");
                return;
              }
              if (selectedAddress == null) {
                final isWeb = MediaQuery.of(context).size.width > 800;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Please select a delivery address first"),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    width: isWeb ? 400 : null,
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    selectedAddress: selectedAddress,
                    totalMrp: totalMrp,
                    discount: 0.0,
                    deliveryCharge: deliveryCharge,
                    toPay: toPay,
                  ),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "₹${toPay.toStringAsFixed(0)}",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "TOTAL",
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 24, color: Colors.white30),
                const SizedBox(width: 12),
                Text(
                  "Place Order",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_right, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
