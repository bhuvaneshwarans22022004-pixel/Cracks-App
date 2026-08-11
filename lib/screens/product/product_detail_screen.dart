import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/guest_auth_prompt.dart';
import '../cart/cart_screen.dart';
import '../../utils/whatsapp_helper.dart';


class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;

  // Pincode checker state
  final TextEditingController _pincodeController = TextEditingController();
  String? _pincodeStatus;
  bool _isCheckingPincode = false;

  // Dynamic reviews state
  late List<Map<String, dynamic>> _userReviews;

  @override
  void initState() {
    super.initState();
    _userReviews = _generateDynamicReviews(widget.product);
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }

  // Dynamic Reviews Generator seeded per Product ID & Product Name
  List<Map<String, dynamic>> _generateDynamicReviews(Product product) {
    final int seed = (product.id.hashCode.abs()) + (product.name.hashCode.abs());
    final List<String> reviewerNames = [
      "Rajesh Kumar",
      "Ananya Sharma",
      "Suresh V.",
      "Priya Raman",
      "Karthik Raja",
      "Meena Gopal",
      "Venkatesh S.",
      "Divya Bharathi",
      "Arun Prasad",
      "Lakshmi Narayanan",
      "Deepak Verma",
      "Pooja Hegde"
    ];

    final categoryLabel = product.category.isNotEmpty ? product.category.toLowerCase() : 'cracker';

    final List<String> reviewTemplates = [
      "Super loud sound and bright vibrant colors for ${product.name}! Safe festive packaging.",
      "Excellent quality $categoryLabel. Arrived in 3 days in perfect condition.",
      "Value for money ${product.name}. Generous pack size of ${product.packSize} and kids loved it!",
      "Very happy with this ${product.name}. High burst height and beautiful sparkle effects.",
      "Genuine certified quality product from FestiveKart. Will definitely buy again for Diwali!",
      "Top-notch performance! The pack of ${product.packSize} was well worth the price."
    ];

    final List<Map<String, dynamic>> generated = [];
    final int baseRating = product.rating > 0 ? product.rating.round().clamp(1, 5) : 5;
    final int count = product.numReviews > 0 ? (product.numReviews.clamp(3, 8)) : (3 + (seed % 3));

    for (int i = 0; i < count; i++) {
      final name = reviewerNames[(seed + i * 3) % reviewerNames.length];
      final comment = reviewTemplates[(seed + i * 2) % reviewTemplates.length];
      
      int rating = baseRating;
      if (i % 3 == 1 && rating > 1) rating -= 1;
      if (i % 5 == 0 && rating < 5) rating += 1;
      rating = rating.clamp(1, 5);

      final daysAgo = 1 + ((seed + i * 7) % 25);

      generated.add({
        "name": name,
        "rating": rating,
        "date": "$daysAgo days ago",
        "verified": true,
        "comment": comment,
      });
    }

    return generated;
  }

  double _calculateAverageRating() {
    if (_userReviews.isEmpty) return widget.product.rating > 0 ? widget.product.rating : 4.5;
    double sum = _userReviews.fold(0.0, (prev, r) => prev + (r['rating'] as int));
    return double.parse((sum / _userReviews.length).toStringAsFixed(1));
  }

  Map<int, double> _calculateRatingBreakdown() {
    if (_userReviews.isEmpty) return {5: 0.8, 4: 0.15, 3: 0.03, 2: 0.01, 1: 0.01};
    int total = _userReviews.length;
    int c5 = _userReviews.where((r) => r['rating'] == 5).length;
    int c4 = _userReviews.where((r) => r['rating'] == 4).length;
    int c3 = _userReviews.where((r) => r['rating'] == 3).length;
    int c2 = _userReviews.where((r) => r['rating'] == 2).length;
    int c1 = _userReviews.where((r) => r['rating'] == 1).length;

    return {
      5: c5 / total,
      4: c4 / total,
      3: c3 / total,
      2: c2 / total,
      1: c1 / total,
    };
  }

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
    final double discountFactor = 1.35 + (hash % 4) * 0.08;
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

  void _checkPincode() {
    final code = _pincodeController.text.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      setState(() {
        _pincodeStatus = "Please enter a valid 6-digit pincode";
      });
      return;
    }
    setState(() {
      _isCheckingPincode = true;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        final deliveryDate = DateTime.now().add(const Duration(days: 3));
        final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        final days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        final dayName = days[deliveryDate.weekday % 7];
        final monthName = months[deliveryDate.month - 1];

        setState(() {
          _isCheckingPincode = false;
          _pincodeStatus = "Express delivery to $code by $dayName, ${deliveryDate.day} $monthName";
        });
      }
    });
  }

  void _showWriteReviewDialog() {
    int userRating = 5;
    final nameController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                "Write a Review for ${widget.product.name}",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Your Rating:", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          icon: Icon(
                            star <= userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: const Color(0xFFFFB703),
                            size: 32,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              userRating = star;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Your Name",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Write your review...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final comment = commentController.text.trim();
                    if (name.isNotEmpty && comment.isNotEmpty) {
                      setState(() {
                        _userReviews.insert(0, {
                          "name": name,
                          "rating": userRating,
                          "date": "Just now",
                          "verified": true,
                          "comment": comment,
                        });
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Thank you! Your review has been published."),
                          backgroundColor: Color(0xFF2E7D32),
                        ),
                      );
                    }
                  },
                  child: Text("Submit Review", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context);
    final product = widget.product;
    final isWeb = MediaQuery.of(context).size.width > 800;

    final pricing = _getPricing(product);
    final double originalPrice = pricing["originalPrice"];
    final int discountPercent = pricing["discountPercent"];

    final avgRating = _calculateAverageRating();
    final breakdown = _calculateRatingBreakdown();

    // Find similar products in the same category
    final similarProducts = productProvider.products
        .where((p) => p.category.toLowerCase() == product.category.toLowerCase() && p.id != product.id)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
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
                      maxWidth: isWeb ? 850 : double.infinity,
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
                          // 1. Header Row (Back Arrow & Title)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 8),
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

                          // 2. Category Breadcrumb Tag (Flipkart / Amazon style)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8C00).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFF8C00).withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.category_outlined, size: 14, color: Color(0xFFFF8C00)),
                                const SizedBox(width: 6),
                                Text(
                                  "Home  >  ${product.category}  >  ${product.name}",
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF8C00),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. Image Gallery View
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

                          // 4. Product Title & Pack Size
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

                          // 5. Rating Badge & Reviews Count Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      "$avgRating",
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${product.numReviews > 0 ? product.numReviews : (_userReviews.length * 6)} Ratings & ${_userReviews.length} Reviews",
                                style: GoogleFonts.outfit(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "✔ Verified Brand",
                                  style: GoogleFonts.outfit(color: Colors.blue[700], fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 6. Price & Discount Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                "₹${product.price.toStringAsFixed(0)}",
                                style: GoogleFonts.outfit(
                                  fontSize: 26,
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
                          const SizedBox(height: 6),

                          // 7. Stock Status Indicator
                          Text(
                            product.countInStock > 0 ? "In stock" : "Out of stock",
                            style: GoogleFonts.outfit(
                              color: product.countInStock > 0 ? const Color(0xFF2E7D32) : Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // 8. Quantity & Add to Cart / Buy Now Action Row
                          Row(
                            children: [
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

                          // Buy Now Button
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
                          const SizedBox(height: 12),

                          // WhatsApp Inquiry Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                              label: Text(
                                "Inquire on WhatsApp 💬",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                WhatsAppHelper.launchWhatsApp(
                                  message: "Hello FestiveKart! 🎆\nI am interested in *${product.name}* (Price: ₹${product.price.toStringAsFixed(0)}). Please share details / bulk availability.",
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 25),

                          // 9. Delivery Details & Pincode Checker Card (Flipkart / Amazon style)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.local_shipping_outlined, color: Color(0xFFFF8C00), size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Delivery & Service Details",
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Pincode Input Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _pincodeController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 6,
                                        decoration: InputDecoration(
                                          counterText: "",
                                          hintText: "Enter 6-digit Pincode",
                                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: Color(0xFFFF8C00)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      height: 44,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFF8C00),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                        onPressed: _isCheckingPincode ? null : _checkPincode,
                                        child: _isCheckingPincode
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : Text("Check", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),

                                if (_pincodeStatus != null) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        _pincodeStatus!.contains("available")
                                            ? Icons.check_circle_rounded
                                            : Icons.error_outline_rounded,
                                        color: _pincodeStatus!.contains("available")
                                            ? const Color(0xFF2E7D32)
                                            : Colors.red[700],
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _pincodeStatus!,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _pincodeStatus!.contains("available")
                                                ? const Color(0xFF2E7D32)
                                                : Colors.red[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 14),

                                // Delivery Trust Badges Grid
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _deliveryFeatureBadge(Icons.bolt_outlined, "Express Delivery", "3-5 Days"),
                                    _deliveryFeatureBadge(Icons.payments_outlined, "COD / UPI", "On Delivery"),
                                    _deliveryFeatureBadge(Icons.verified_user_outlined, "Certified", "100% Safe"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),

                          // 9.5 Combo Pack Contents Breakdown Card
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

                          // 10. Description / Details Section
                          Text(
                            "Product Specifications",
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
                          const SizedBox(height: 25),

                          // 11. Ratings & Reviews Breakdown (Flipkart / Amazon style)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Ratings & Reviews",
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.rate_review_outlined, size: 16, color: Color(0xFFFF8C00)),
                                      label: Text(
                                        "Rate Product",
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFFF8C00),
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFFFF8C00)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: _showWriteReviewDialog,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Dynamic Ratings Summary Row
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          "$avgRating",
                                          style: GoogleFonts.outfit(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (i) => Icon(
                                              i < avgRating.floor() ? Icons.star_rounded : Icons.star_half_rounded,
                                              color: const Color(0xFFFFB703),
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${_userReviews.length * 5} Verified Ratings",
                                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 24),

                                    // Dynamic Rating Progress Bars
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _ratingProgressBar("5★", breakdown[5] ?? 0.8, Colors.green),
                                          _ratingProgressBar("4★", breakdown[4] ?? 0.15, Colors.lightGreen),
                                          _ratingProgressBar("3★", breakdown[3] ?? 0.03, Colors.amber),
                                          _ratingProgressBar("2★", breakdown[2] ?? 0.01, Colors.orange),
                                          _ratingProgressBar("1★", breakdown[1] ?? 0.01, Colors.red),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(height: 1),
                                const SizedBox(height: 16),

                                // Customer Reviews List
                                ..._userReviews.map((rev) => Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2E7D32),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "${rev['rating']}",
                                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                    const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                rev['name'],
                                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              const Spacer(),
                                              Text(
                                                rev['date'],
                                                style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            rev['comment'],
                                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[700]),
                                          ),
                                          if (rev['verified'] == true) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Verified Buyer",
                                                  style: GoogleFonts.outfit(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // 12. Similar Products in Category (Amazon / Flipkart style)
                          if (similarProducts.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Similar Products in ${product.category}",
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "${similarProducts.length} Items",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 240,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: similarProducts.length,
                                itemBuilder: (context, index) {
                                  final simProd = similarProducts[index];
                                  final simPricing = _getPricing(simProd);
                                  final double simOrigPrice = simPricing["originalPrice"];

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(product: simProd),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 155,
                                      margin: const EdgeInsets.only(right: 14),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.grey[200]!),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.03),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          )
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            height: 100,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: simProd.image,
                                              fit: BoxFit.contain,
                                              errorWidget: (c, u, e) => const Icon(Icons.celebration, color: Color(0xFFFF8C00)),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            simProd.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                "₹${simProd.price.toStringAsFixed(0)}",
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFFFF8C00),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              if (simOrigPrice > simProd.price)
                                                Text(
                                                  "₹${simOrigPrice.toStringAsFixed(0)}",
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.grey[400],
                                                    fontSize: 11,
                                                    decoration: TextDecoration.lineThrough,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const Spacer(),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 32,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFFF8C00).withOpacity(0.1),
                                                foregroundColor: const Color(0xFFFF8C00),
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () {
                                                cart.addItem(simProd);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text("Added ${simProd.name} to cart"),
                                                    duration: const Duration(seconds: 1),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                "ADD",
                                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
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

  Widget _deliveryFeatureBadge(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFFF8C00).withOpacity(0.08),
          child: Icon(icon, color: const Color(0xFFFF8C00), size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
        ),
        Text(
          subtitle,
          style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 10),
        ),
      ],
    );
  }

  Widget _ratingProgressBar(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
