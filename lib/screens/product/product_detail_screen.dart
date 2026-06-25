import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  String _getProductPackSuffix(Product product) {
    final name = product.name.toLowerCase();
    if (name.contains("sky shot")) return "(Pack of 1)";
    if (name.contains("rocket")) return "(Pack of 5)";
    if (name.contains("sparkler")) return "(Pack of 10)";
    if (name.contains("ladi") || name.contains("bomb")) return "(Pack of 10)";
    if (name.contains("flower") || name.contains("pot")) return "(Pack of 5)";
    return "(Pack of 1)";
  }

  Map<String, dynamic> _getPricing(Product product) {
    final int hash = product.name.codeUnits.fold(0, (prev, element) => prev + element);
    final double discountFactor = 1.35 + (hash % 4) * 0.08; // 1.35, 1.43, 1.51, 1.59
    final double originalPrice = (product.price * discountFactor).roundToDouble();
    final int discountPercent = (((originalPrice - product.price) / originalPrice) * 100).round();
    return {
      "originalPrice": originalPrice,
      "discountPercent": discountPercent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final product = widget.product;
    final isWeb = MediaQuery.of(context).size.width > 800;

    final pricing = _getPricing(product);
    final double originalPrice = pricing["originalPrice"];
    final int discountPercent = pricing["discountPercent"];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5), // Theme background color
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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                // Custom Header Row (Back Arrow & Screen Title)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Product Details",
                        style: GoogleFonts.outfit(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                // 1. Centered Product Image in White/Grey Container
                Center(
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[100]!),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF8C00)),
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.celebration,
                        color: Color(0xFFFF8C00),
                        size: 96,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Title & Pack size
                Text(
                  "${product.name} ${_getProductPackSuffix(product)}",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // 3. Ratings & Reviews Row
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB703), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      "${product.rating}",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "(${product.numReviews} reviews)",
                      style: GoogleFonts.outfit(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "₹${product.price.toStringAsFixed(0)}",
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF8C00),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "₹${originalPrice.toStringAsFixed(0)}",
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        color: Colors.grey[400],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "($discountPercent% OFF)",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 5. Stock status indicator
                Text(
                  product.countInStock > 0 ? "In stock" : "Out of stock",
                  style: GoogleFonts.outfit(
                    color: product.countInStock > 0 ? const Color(0xFF2E7D32) : Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 25),

                // 6. Action Controls: Quantity + Add to Cart Row
                Row(
                  children: [
                    // Quantity Controller
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16, color: Colors.black54),
                            onPressed: () {
                              if (_quantity > 1) {
                                setState(() => _quantity--);
                              }
                            },
                          ),
                          Text(
                            "$_quantity",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16, color: Colors.black54),
                            onPressed: () {
                              setState(() => _quantity++);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Add to Cart Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: product.countInStock > 0
                              ? () {
                                  for (int i = 0; i < _quantity; i++) {
                                    cart.addItem(product);
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Added $_quantity x ${product.name} to cart",
                                        style: GoogleFonts.outfit(),
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            "Add to Cart",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 7. Buy Now Button (Yellow/Gold)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB703),
                      foregroundColor: const Color(0xFF1E0A35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: product.countInStock > 0
                        ? () {
                            for (int i = 0; i < _quantity; i++) {
                              cart.addItem(product);
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CartScreen()),
                            );
                          }
                        : null,
                    child: Text(
                      "Buy Now",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 35),

                // 8. Description / Details Section
                Text(
                  "Product Details",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  product.description.isNotEmpty
                      ? product.description
                      : "Premium quality cracker with spectacular colors. High altitude fireworks, manufactured under strict guidelines for a safe and happy festival of lights.",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 60),
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
}
