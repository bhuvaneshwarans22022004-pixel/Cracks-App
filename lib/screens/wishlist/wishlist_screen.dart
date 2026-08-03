import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product.dart';
import '../../screens/product/product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String _searchQuery = "";
  String _selectedCategory = "All";
  String _selectedSort = "Recently Added";
  bool _isSearching = false;

  final List<String> _sortOptions = [
    "Recently Added",
    "Price: Low to High",
    "Price: High to Low",
    "Top Rated",
    "Most Popular"
  ];

  @override
  Widget build(BuildContext context) {
    final wishlist = Provider.of<WishlistProvider>(context);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isWeb = MediaQuery.of(context).size.width > 800;

    // Filter items locally based on search query and category
    List<Product> filteredItems = wishlist.items.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (product.description ?? "").toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == "All" ||
          product.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();

    // Sort items locally
    if (_selectedSort == "Price: Low to High") {
      filteredItems.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSort == "Price: High to Low") {
      filteredItems.sort((a, b) => b.price.compareTo(a.price));
    } else if (_selectedSort == "Top Rated") {
      filteredItems.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedSort == "Most Popular") {
      filteredItems.sort((a, b) => b.numReviews.compareTo(a.numReviews));
    }

    // Dynamic Categories list from wishlist items
    List<String> categories = ["All"];
    for (var item in wishlist.items) {
      if (!categories.contains(item.category)) {
        categories.add(item.category);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: isWeb,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search wishlist...",
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 16),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.black87),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : Text(
                "My Wishlist",
                style: GoogleFonts.outfit(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
        actions: [
          if (wishlist.items.isNotEmpty) ...[
            IconButton(
              icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: Colors.black87),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) _searchQuery = "";
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.black87),
              onPressed: () => _shareWishlistDialog(context, wishlist.items),
            ),
          ]
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isWeb ? 1000 : double.infinity),
            child: wishlist.items.isEmpty
                ? _buildEmptyState(context)
                : Column(
                    children: [
                      // Filters & Sort Bar
                      _buildFiltersBar(categories),
                      
                      // Price Drop Alert Banner (Subtle Diwali/Premium UI style)
                      if (wishlist.items.isNotEmpty) _buildDiwaliOfferBanner(),

                      // Wishlist Grid
                      Expanded(
                        child: filteredItems.isEmpty
                            ? Center(
                                child: Text(
                                  "No matching products found",
                                  style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 16),
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWeb ? 4 : 2,
                                  childAspectRatio: isWeb ? 0.7 : 0.62,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  final product = filteredItems[index];
                                  return _buildWishlistItemCard(context, product, wishlist, cart, auth);
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Beautiful empty state with custom Diwali background & Premium UI layout
  Widget _buildEmptyState(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width > 800;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isWeb ? 1000 : double.infinity),
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: isWeb ? 80 : 60),
          decoration: isWeb
              ? BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Custom Diwali Ring & Diya Aura
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00).withOpacity(0.06),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 60,
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "Your Wishlist is Empty",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Save your favourite crackers and gift boxes to buy them later during the festive rush.",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Continue Shopping",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Filter chips and sorting menu builder
  Widget _buildFiltersBar(List<String> categories) {
    final bool isWeb = MediaQuery.of(context).size.width > 800;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isWeb ? 1000 : double.infinity),
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
        children: [
          // Category filter row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      cat,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    selectedColor: const Color(0xFFFF8C00),
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 16, thickness: 1),
          // Sorting selection bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sort_rounded, color: Colors.grey, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "Sort by:",
                      style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedSort,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      underline: const SizedBox(),
                      style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedSort = newValue;
                          });
                        }
                      },
                      items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Text(
                  "Total Items: ${categories.length - 1 == 0 ? 0 : categories.length}",
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                )
              ],
            ),
          ),
        ],
      ),
     ),
    );
  }

  // Premium Diwali Sparkler notification banner
  Widget _buildDiwaliOfferBanner() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFF8C00).withOpacity(0.08), const Color(0xFFFFD700).withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF8C00).withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C00).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration_rounded, color: Color(0xFFFF8C00), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Price Drop Alerts Enabled!",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  "We will notify you immediately if any of your wishlisted items drop in price.",
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // High resolution custom product card builder
  Widget _buildWishlistItemCard(BuildContext context, Product product, WishlistProvider wishlist, CartProvider cart, AuthProvider auth) {
    // Custom logic to simulate tags
    final isBestSeller = product.rating >= 4.5;
    final isOutOfStock = product.countInStock == 0;
    final isLimitedStock = product.countInStock > 0 && product.countInStock <= 5;
    
    // Simulate original vs discount prices (diwali offers)
    final double discountFactor = 1.3; // original price 30% higher
    final originalPrice = (product.price * discountFactor).round();
    final discountPercent = 23; 

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Column of content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image Section
                  Expanded(
                    flex: 12,
                    child: Container(
                      color: Colors.grey[50],
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: product.image,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[100]),
                            errorWidget: (context, url, error) => const Icon(Icons.celebration, color: Color(0xFFFF8C00)),
                          ),
                          // Badges overlay
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isBestSeller)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD45D27),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "Best Seller",
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                if (isLimitedStock && !isOutOfStock)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "Only ${product.countInStock} Left",
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                if (isOutOfStock)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[700],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "Out of Stock",
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Product Details Section
                  Expanded(
                    flex: 13,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rating & Category
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.category.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFF8C00),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    "${product.rating}",
                                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          
                          // Product Name
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),

                          // Price block
                          Row(
                            children: [
                              Text(
                                "₹${product.price}",
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "₹$originalPrice",
                                style: GoogleFonts.outfit(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "$discountPercent% Off",
                                style: GoogleFonts.outfit(
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),

                          // Quick Action CTA Buttons (Add to Cart / Share / Delete)
                          Row(
                            children: [
                              // Add to Cart Button
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isOutOfStock ? Colors.grey[200] : const Color(0xFFFF8C00),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: isOutOfStock
                                      ? () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("We will notify you when ${product.name} is back in stock!", style: GoogleFonts.outfit()),
                                              backgroundColor: Colors.black87,
                                            ),
                                          );
                                        }
                                      : () {
                                          cart.addItem(product);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Moved to Cart Successfully",
                                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                              ),
                                              backgroundColor: Colors.green[700],
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                  child: Text(
                                    isOutOfStock ? "Notify Me" : "Add to Cart",
                                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: isOutOfStock ? Colors.grey[500] : Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Remove button
                              InkWell(
                                onTap: () => _confirmRemoveBottomSheet(context, product, wishlist, auth.user!.token!),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Floating Favorite filled heart on the image top corner to toggle quickly
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _confirmRemoveBottomSheet(context, product, wishlist, auth.user!.token!),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    radius: 14,
                    child: const Icon(Icons.favorite_rounded, color: Colors.red, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Remove confirmation bottom sheet
  void _confirmRemoveBottomSheet(BuildContext context, Product product, WishlistProvider wishlist, String token) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                "Remove from Wishlist?",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Are you sure you want to remove '${product.name}' from your wishlist?",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.outfit(color: Colors.grey[700], fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        wishlist.toggleWishlist(product, token);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Removed Successfully",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: Colors.grey[800],
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        "Remove",
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Share wishlist modal popup dialog
  void _shareWishlistDialog(BuildContext context, List<Product> items) {
    final shareLink = "https://festivekart.com/wishlist/share?items=${items.length}";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Share Wishlist",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Invite friends and family to view or add items to your Diwali wishlist!",
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Color(0xFFFF8C00)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        shareLink,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _shareChannelIcon(Icons.copy_rounded, "Copy Link", () {
                    Clipboard.setData(ClipboardData(text: shareLink));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Link copied to clipboard!", style: GoogleFonts.outfit()),
                        backgroundColor: const Color(0xFFFF8C00),
                      ),
                    );
                  }),
                  _shareChannelIcon(Icons.message_rounded, "WhatsApp", () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Opening WhatsApp...", style: GoogleFonts.outfit())),
                    );
                  }),
                  _shareChannelIcon(Icons.qr_code_rounded, "QR Code", () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Generating QR Code...", style: GoogleFonts.outfit())),
                    );
                  }),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: GoogleFonts.outfit(color: Colors.grey[700], fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _shareChannelIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFF8C00).withOpacity(0.1),
            radius: 20,
            child: Icon(icon, color: const Color(0xFFFF8C00), size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w600),
          )
        ],
      ),
    );
  }
}
