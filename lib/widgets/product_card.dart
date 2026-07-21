import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/product/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = product.countInStock <= 0;
    final bool isLowStock = product.countInStock > 0 && product.countInStock <= 5;

    Widget cardContent = Card(
      clipBehavior: Clip.antiAlias,
      elevation: isOutOfStock ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: product.image,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.celebration, color: Color(0xFFFF8C00)),
                ),
                if (isLowStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Only ${product.countInStock} left",
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (isOutOfStock)
                  Container(
                    color: Colors.black.withOpacity(0.55),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          "OUT OF STOCK",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer2<AuthProvider, WishlistProvider>(
                    builder: (context, auth, wishlist, _) {
                      final isInWish = wishlist.isInWishlist(product.id);
                      return GestureDetector(
                        onTap: () {
                          if (auth.user == null || auth.user!.token == null) {
                            _showLoginBottomSheet(context);
                          } else {
                            final wasInWish = isInWish;
                            wishlist.toggleWishlist(product, auth.user!.token!);
                            
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  wasInWish 
                                    ? "Removed from Wishlist" 
                                    : "Added to Wishlist ❤️",
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                                backgroundColor: wasInWish ? Colors.grey[800] : const Color(0xFFFF8C00),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                width: MediaQuery.of(context).size.width > 800 ? 400.0 : null,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          radius: 16,
                          child: Icon(
                            isInWish ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
                    color: isOutOfStock ? Colors.grey[500] : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.tamilName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.tamilName,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: isOutOfStock ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          Text('${product.rating}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          const Icon(Icons.star, color: Colors.white, size: 10),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('(${product.numReviews})', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "₹${product.price.toStringAsFixed(0)}",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isOutOfStock ? Colors.grey : Colors.black,
                                ),
                              ),
                              if (product.originalPrice > product.price) ...[
                                const SizedBox(width: 4),
                                Text(
                                  "₹${product.originalPrice.toStringAsFixed(0)}",
                                  style: GoogleFonts.outfit(
                                    decoration: TextDecoration.lineThrough,
                                    fontSize: 9,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (product.originalPrice > product.price) ...[
                            const SizedBox(height: 2),
                            Text(
                              "${((product.originalPrice - product.price) / product.originalPrice * 100).round()}% OFF",
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isOutOfStock)
                      Consumer<CartProvider>(
                        builder: (context, cart, _) {
                          final cartItem = cart.items[product.id];
                          if (cartItem == null) {
                            return InkWell(
                              onTap: () {
                                cart.addItem(product);
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Added ${product.name} to Cart 🛒",
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                    backgroundColor: const Color(0xFFFF8C00),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    width: MediaQuery.of(context).size.width > 800 ? 400.0 : null,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFFF8C00), width: 1.2),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: Text(
                                  "ADD",
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF8C00),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8C00),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => cart.decrementItem(product.id),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      child: Icon(Icons.remove, size: 12, color: Colors.white),
                                    ),
                                  ),
                                  Text(
                                    '${cartItem.quantity}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => cart.addItem(product),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      child: Icon(Icons.add, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isOutOfStock) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Colors.grey,
          BlendMode.saturation,
        ),
        child: Opacity(
          opacity: 0.75,
          child: cardContent,
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: cardContent,
    );
  }

  void _showLoginBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
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
              const SizedBox(height: 24),
              const Icon(Icons.favorite_rounded, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                "Login to save your favorites",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Keep track of the products you love by adding them to your wishlist.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C00),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Text(
                  "Login Now",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
