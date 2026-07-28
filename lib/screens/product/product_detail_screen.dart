import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/guest_auth_prompt.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;

  Map<String, dynamic> _getPricing(Product product) {
    if (product.price <= 0) {
      return {
        "originalPrice": 0.0,
        "discountPercent": 0,
      };
    }
    if (product.originalPrice > product.price) {
      final double originalPrice = product.originalPrice;
      if (originalPrice <= 0) {
        return {
          "originalPrice": product.price,
          "discountPercent": 0,
        };
      }
      final int discountPercent = (((originalPrice - product.price) / originalPrice) * 100).round();
      return {
        "originalPrice": originalPrice,
        "discountPercent": discountPercent,
      };
    }
    final int hash = product.name.codeUnits.fold(0, (prev, element) => prev + element);
    final double discountFactor = 1.35 + (hash % 4) * 0.08; // 1.35, 1.43, 1.51, 1.59
    final double originalPrice = (product.price * discountFactor).roundToDouble();
    if (originalPrice <= 0) {
      return {
        "originalPrice": product.price,
        "discountPercent": 0,
      };
    }
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
                // 1. Centered Product Image Gallery (Front, Middle, Back)
                Builder(
                  builder: (context) {
                    final displayImages = product.images.isNotEmpty ? product.images : [product.image];
                    final activeImage = displayImages.length > _selectedImageIndex ? displayImages[_selectedImageIndex] : product.image;
                    
                    return Column(
                      children: [
                        Container(
                          height: 280,
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[100]!),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: activeImage,
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
                        if (displayImages.length > 1) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(displayImages.length, (idx) {
                              final isSelected = idx == _selectedImageIndex;
                              final angleLabel = idx == 0 ? 'Front' : (idx == 1 ? 'Middle' : 'Back');
                              return GestureDetector(
                                onTap: () => setState(() => _selectedImageIndex = idx),
                                child: Column(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                      width: 56,
                                      height: 56,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFFFF8C00) : Colors.grey[300]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: displayImages[idx],
                                        fit: BoxFit.contain,
                                        errorWidget: (context, url, error) => const Icon(Icons.image, size: 20),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      angleLabel,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? const Color(0xFFFF8C00) : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 2. Title & Pack size
                Text(
                  "${product.name} (Pack of ${product.packSize})",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (product.tamilName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.tamilName,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
                                      behavior: SnackBarBehavior.floating,
                                      width: MediaQuery.of(context).size.width > 800 ? 400.0 : null,
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
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            if (auth.isGuest) {
                              showGuestAuthPrompt(context, "Please log in or register to buy products directly.");
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CartScreen(
                                  buyNowProduct: product,
                                  buyNowQuantity: _quantity,
                                ),
                              ),
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
                const SizedBox(height: 25),

                // 7.5 Combo Pack Contents Breakdown Card
                if (product.isCombo || product.comboItems.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "🎁 Combo Pack Contents",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF166534),
                              ),
                            ),
                            if (product.comboDiscountPercent > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${product.comboDiscountPercent.toStringAsFixed(0)}% EXTRA COMBO OFF",
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...product.comboItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${item.name} (x${item.quantity})",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF14532D),
                                  ),
                                ),
                              ),
                              Text(
                                "₹${((item.originalPrice > 0 ? item.originalPrice : item.price) * item.quantity).toStringAsFixed(0)}",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                ],

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
