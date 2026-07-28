import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product.dart';
import '../cart/cart_screen.dart';
import '../product/product_detail_screen.dart';

class OfferDetailScreen extends StatefulWidget {
  final Map<String, dynamic> banner;

  const OfferDetailScreen({super.key, required this.banner});

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    // Extract banner parameters with fallbacks
    final title = widget.banner['title'] ?? 'Diwali Special Offer';
    final subtitle = widget.banner['subtitle'] ?? 'Exclusive Discount';
    final desc = widget.banner['desc'] ?? 'Add products to your cart to reach the minimum order amount and claim this offer!';
    final imageUrl = widget.banner['imageUrl'] ?? '';
    final double discountPercent = (widget.banner['discountPercent'] != null)
        ? (widget.banner['discountPercent'] as num).toDouble()
        : 50.0;
    final double minOrderAmount = (widget.banner['minOrderAmount'] != null)
        ? (widget.banner['minOrderAmount'] as num).toDouble()
        : 5000.0;
    final String offerCode = widget.banner['offerCode'] ?? 'DIWALI50';

    // Calculate live progress
    final double cartTotal = cart.totalAmount;
    final double progress = (minOrderAmount > 0) ? (cartTotal / minOrderAmount).clamp(0.0, 1.0) : 1.0;
    final bool isUnlocked = cartTotal >= minOrderAmount;
    final double remainingAmount = (minOrderAmount - cartTotal).clamp(0.0, minOrderAmount);

    // Filter products matching search query
    final products = productProvider.products.where((p) {
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E0A35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Special Offer Zone",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 1. Banner Hero Card
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E0A35), Color(0xFF3B1568)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 160,
                                  color: Colors.white10,
                                  child: const Center(child: CircularProgressIndicator(color: Color(0xFFFFB703))),
                                ),
                                errorWidget: (context, url, error) => const SizedBox(),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB703),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "🔥 ${discountPercent.toInt()}% OFF",
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF1E0A35),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Text(
                                  "CODE: $offerCode",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFFB703),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            desc,
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Interactive Offer Tracker Progress Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUnlocked ? const Color(0xFFF0FDF4) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUnlocked ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
                          width: isUnlocked ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isUnlocked ? "🎉 Offer Unlocked!" : "Offer Target Progress",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isUnlocked ? const Color(0xFF166534) : const Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                "₹${cartTotal.toStringAsFixed(0)} / ₹${minOrderAmount.toStringAsFixed(0)}",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isUnlocked ? const Color(0xFF166534) : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              backgroundColor: const Color(0xFFE5E7EB),
                              color: isUnlocked ? const Color(0xFF22C55E) : const Color(0xFFFFB703),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (isUnlocked)
                            Text(
                              "Great job! You unlocked ${discountPercent.toInt()}% OFF! Instant savings will be applied automatically at checkout.",
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFF15803D),
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            Text(
                              "Add ₹${remainingAmount.toStringAsFixed(0)} more worth of products to get ${discountPercent.toInt()}% OFF!",
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: const Color(0xFFB45309),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Search & Eligible Products List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Qualifying Products",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          "${products.length} items",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Search products to complete offer...",
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFFFB703)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFB703), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Products Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final inCartQty = cart.items[product.id]?.quantity ?? 0;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(product: product),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: CachedNetworkImage(
                                      imageUrl: product.image,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => Container(color: Colors.grey[100]),
                                      errorWidget: (context, url, error) => const Icon(Icons.inventory_2_outlined),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: const Color(0xFF1F2937),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "₹${product.price.toStringAsFixed(2)}",
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Cart Add / Increment / Decrement & Delete Control
                                      if (inCartQty > 0)
                                        Container(
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF166534),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Delete / Decrement Icon
                                              InkWell(
                                                onTap: () {
                                                  cart.decrementItem(product.id);
                                                },
                                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  child: Icon(
                                                    inCartQty == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                "$inCartQty",
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              // Increment Icon
                                              InkWell(
                                                onTap: () {
                                                  cart.addItem(product);
                                                },
                                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  child: Icon(
                                                    Icons.add_rounded,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        SizedBox(
                                          width: double.infinity,
                                          height: 34,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFFB703),
                                              foregroundColor: const Color(0xFF1E0A35),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: EdgeInsets.zero,
                                            ),
                                            onPressed: () {
                                              cart.addItem(product);
                                            },
                                            child: Text(
                                              "+ ADD",
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Floating Bottom Cart Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUnlocked ? const Color(0xFF166534) : const Color(0xFFFFB703),
                  foregroundColor: isUnlocked ? Colors.white : const Color(0xFF1E0A35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isUnlocked ? "CLAIM ${discountPercent.toInt()}% OFF IN CART" : "VIEW CART (₹${cartTotal.toStringAsFixed(0)})",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
