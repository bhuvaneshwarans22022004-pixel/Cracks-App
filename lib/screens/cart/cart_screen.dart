import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart'; 
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/guest_auth_prompt.dart';
import '../../utils/minimum_order_helper.dart';
import 'address_screen.dart';
import 'payment_screen.dart';

class CartScreen extends StatefulWidget {
  final Product? buyNowProduct;
  final int buyNowQuantity;

  const CartScreen({
    super.key,
    this.buyNowProduct,
    this.buyNowQuantity = 1,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late int _buyNowQty;
  String? _appliedCouponCode;
  double _appliedDiscountAmount = 0.0;
  String? _appliedCouponTitle;

  Map<String, dynamic> _getProductPricing(Product product) {
    double origPrice = product.originalPrice;
    if (origPrice <= product.price || origPrice <= 0) {
      if (product.price <= 0) {
        origPrice = 0.0;
      } else {
        final int hash = product.name.codeUnits.fold(0, (prev, element) => prev + element);
        final double discountFactor = 1.35 + (hash % 4) * 0.08;
        origPrice = (product.price * discountFactor).roundToDouble();
      }
    }
    final int discountPercent = (origPrice > product.price && origPrice > 0 && product.price > 0)
        ? (((origPrice - product.price) / origPrice) * 100).round()
        : 0;
    return {
      "originalPrice": origPrice,
      "discountPercent": discountPercent,
    };
  }

  @override
  void initState() {
    super.initState();
    _buyNowQty = widget.buyNowQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final addressProvider = Provider.of<AddressProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final selectedAddress = addressProvider.selectedAddress;
    final isWeb = MediaQuery.of(context).size.width > 800;

    final bool isBuyNow = widget.buyNowProduct != null;

    // Calculations matching 3% Shipping Charge rule
    final double totalMrp = isBuyNow
        ? (widget.buyNowProduct!.price * _buyNowQty)
        : cart.totalAmount;
    final double deliveryCharge = totalMrp > 0 ? (totalMrp * 0.03) : 0.0;
    final double discount = _appliedDiscountAmount;
    final double toPay = (totalMrp + deliveryCharge - discount).clamp(0.0, double.infinity);

    final totalQty = isBuyNow
        ? _buyNowQty
        : cart.items.values.fold(0, (sum, item) => sum + item.quantity);

    final bool isCartEmpty = isBuyNow ? _buyNowQty <= 0 : cart.items.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isBuyNow ? "Direct Checkout" : "Cart",
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
                    child: isCartEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                                  const SizedBox(height: 20),
                                  Text(
                                    isBuyNow ? "No item selected" : "Your cart is empty",
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
                                  isBuyNow ? "Buy Now Item" : "$totalQty Items in Cart",
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              // Cart items list
                              if (isBuyNow)
                                _buildBuyNowItemCard(widget.buyNowProduct!)
                              else
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

                                     final itemPricing = _getProductPricing(item.product);
                                     final double itemOrigPrice = itemPricing["originalPrice"];
                                     final int itemDiscountPct = itemPricing["discountPercent"];

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
                                              cart.removeItem(item.product.id);
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
                                child: _appliedCouponCode != null
                                    ? Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFF10B981)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Coupon '$_appliedCouponCode' Applied",
                                                    style: GoogleFonts.outfit(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: const Color(0xFF047857),
                                                    ),
                                                  ),
                                                  Text(
                                                    "You saved ₹${_appliedDiscountAmount.toStringAsFixed(0)} on this order!",
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 11,
                                                      color: const Color(0xFF065F46),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _appliedCouponCode = null;
                                                  _appliedDiscountAmount = 0.0;
                                                  _appliedCouponTitle = null;
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text("Coupon removed", style: GoogleFonts.outfit()),
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                "REMOVE",
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : InkWell(
                                        onTap: () => _showCouponsBottomSheet(context, totalMrp, auth.user?.token),
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
                                          Text("₹${totalMrp.toStringAsFixed(2)}", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.local_shipping_outlined, size: 14, color: Colors.grey[500]),
                                              const SizedBox(width: 6),
                                              Text("Shipping Charge (3%)", style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13)),
                                            ],
                                          ),
                                          Text(
                                            "₹${deliveryCharge.toStringAsFixed(2)}",
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_appliedDiscountAmount > 0) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.local_offer_rounded, size: 14, color: Colors.green[600]),
                                                const SizedBox(width: 6),
                                                Text(
                                                  "Coupon Discount (${_appliedCouponCode})",
                                                  style: GoogleFonts.outfit(color: Colors.green[700], fontSize: 13, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              "-₹${_appliedDiscountAmount.toStringAsFixed(2)}",
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green[700],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
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
      bottomNavigationBar: isCartEmpty
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

  Widget _buildBuyNowItemCard(Product product) {
    final packLabel = product.packSize > 1 ? "(Pack of ${product.packSize})" : "(Pack of 1)";
    final nameWithSuffix = "${product.name} $packLabel";

    final buyNowPricing = _getProductPricing(product);
    final double bnOrigPrice = buyNowPricing["originalPrice"];
    final int bnDiscountPct = buyNowPricing["discountPercent"];

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
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
                  product.image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.celebration,
                    color: Color(0xFFFF8C00),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                    Row(
                      children: [
                        Text(
                          "₹${product.price.toStringAsFixed(0)}",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        if (bnOrigPrice > product.price && bnOrigPrice > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            "₹${bnOrigPrice.toStringAsFixed(0)}",
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: Colors.grey[400],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          if (bnDiscountPct > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "$bnDiscountPct% OFF",
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ],
                ),
              ),
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
                      onTap: () {
                        if (_buyNowQty > 1) {
                          setState(() {
                            _buyNowQty--;
                          });
                        }
                      },
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
                        '$_buyNowQty',
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
                      onTap: () {
                        setState(() {
                          _buyNowQty++;
                        });
                      },
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
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey[100]),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
                const SizedBox(width: 4),
                Text(
                  "Cancel Buy Now",
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

  void _showCouponsBottomSheet(BuildContext context, double cartTotal, String? token) {
    final codeController = TextEditingController();
    bool isApplying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8C00).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.confirmation_number_rounded, color: Color(0xFFFF8C00), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Coupons & Offers",
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Coupon Input Box
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: "Enter Coupon Code",
                              hintStyle: GoogleFonts.outfit(color: Colors.grey),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8C00),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          onPressed: isApplying
                              ? null
                              : () async {
                                  final enteredCode = codeController.text.trim();
                                  if (enteredCode.isEmpty) return;

                                  setBottomSheetState(() => isApplying = true);
                                  try {
                                    final res = await ApiService.post('coupons/apply', {
                                      'code': enteredCode,
                                      'cartTotal': cartTotal,
                                    }, token: token);

                                    final resData = jsonDecode(res.body);

                                    if (res.statusCode == 200 && resData['success'] == true) {
                                      final c = resData['coupon'];
                                      setState(() {
                                        _appliedCouponCode = c['code'];
                                        _appliedDiscountAmount = (c['discountAmount'] as num).toDouble();
                                        _appliedCouponTitle = c['title'];
                                      });
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("🎉 Coupon ${c['code']} applied! Saved ₹${c['discountAmount']}", style: GoogleFonts.outfit()),
                                          backgroundColor: const Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(resData['message'] ?? "Invalid coupon code", style: GoogleFonts.outfit()),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (err) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Failed to apply coupon: $err", style: GoogleFonts.outfit()),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  } finally {
                                    setBottomSheetState(() => isApplying = false);
                                  }
                                },
                          child: isApplying
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text("APPLY", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Available Coupons Header
                    Text(
                      "Available Coupons for You",
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),

                    // FutureBuilder to load active coupons
                    Expanded(
                      child: FutureBuilder<http.Response>(
                        future: ApiService.get('coupons/active', token: token),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)));
                          }
                          if (snapshot.hasError || snapshot.data == null || snapshot.data!.statusCode != 200) {
                            return Center(
                              child: Text("Unable to load coupons", style: GoogleFonts.outfit(color: Colors.grey)),
                            );
                          }

                          final resData = jsonDecode(snapshot.data!.body);
                          final couponsList = (resData['coupons'] as List? ?? []);

                          if (couponsList.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_offer_outlined, size: 48, color: Colors.grey[300]),
                                  const SizedBox(height: 10),
                                  Text("No active coupons available right now", style: GoogleFonts.outfit(color: Colors.grey[600])),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: couponsList.length,
                            itemBuilder: (context, index) {
                              final item = couponsList[index];
                              final String code = item['code'] ?? '';
                              final String title = item['title'] ?? '';
                              final String desc = item['description'] ?? '';
                              final double minAmount = (item['minPurchaseAmount'] as num? ?? 0).toDouble();
                              final bool isEligible = cartTotal >= minAmount;
                              final bool isUserReward = item['isUserSpecific'] == true;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUserReward ? const Color(0xFFECFDF5) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isUserReward ? const Color(0xFF10B981) : Colors.grey[200]!,
                                    width: isUserReward ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: isUserReward ? const Color(0xFF10B981) : const Color(0xFFFF8C00),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  code,
                                                  style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                              if (isUserReward) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF047857).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    "🎁 Reward Coupon",
                                                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF047857)),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            title,
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                          ),
                                          if (desc.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(desc, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600])),
                                          ],
                                          if (minAmount > 0) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              "Min purchase: ₹${minAmount.toStringAsFixed(0)}",
                                              style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isEligible ? const Color(0xFFFF8C00) : Colors.grey[300],
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        elevation: 0,
                                      ),
                                      onPressed: isEligible
                                          ? () async {
                                              try {
                                                final res = await ApiService.post('coupons/apply', {
                                                  'code': code,
                                                  'cartTotal': cartTotal,
                                                }, token: token);

                                                final resData = jsonDecode(res.body);

                                                if (res.statusCode == 200 && resData['success'] == true) {
                                                  final c = resData['coupon'];
                                                  setState(() {
                                                    _appliedCouponCode = c['code'];
                                                    _appliedDiscountAmount = (c['discountAmount'] as num).toDouble();
                                                    _appliedCouponTitle = c['title'];
                                                  });
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text("🎉 Coupon ${c['code']} applied! Saved ₹${c['discountAmount']}", style: GoogleFonts.outfit()),
                                                      backgroundColor: const Color(0xFF10B981),
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              } catch (err) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text("Error: $err")),
                                                );
                                              }
                                            }
                                          : null,
                                      child: Text(
                                        isEligible ? "APPLY" : "Add ₹${(minAmount - cartTotal).toStringAsFixed(0)}",
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isEligible ? Colors.white : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
              // Validate ₹4,500 minimum order requirement
              if (!MinimumOrderHelper.validateAndShowNotice(context, totalMrp)) {
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
                    discount: _appliedDiscountAmount,
                    deliveryCharge: deliveryCharge,
                    toPay: toPay,
                    buyNowProduct: widget.buyNowProduct,
                    buyNowQuantity: _buyNowQty,
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
