import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../screens/cart/cart_screen.dart';
import '../utils/app_scroll_behavior.dart';
import '../utils/minimum_order_helper.dart';
import '../utils/whatsapp_helper.dart';
import '../providers/auth_provider.dart';
import '../providers/address_provider.dart';


class QuickOrderSheet extends StatefulWidget {
  const QuickOrderSheet({super.key});

  static void show(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: isWeb ? 1100 : double.infinity,
      ),
      builder: (context) => const QuickOrderSheet(),
    );
  }

  @override
  State<QuickOrderSheet> createState() => _QuickOrderSheetState();
}

class _QuickOrderSheetState extends State<QuickOrderSheet> {
  final Map<String, int> _selectedQuantities = {};
  String _searchQuery = "";
  String _selectedCategory = "All";
  final ScrollController _categoryScrollController = ScrollController();

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  Widget _buildProductRow(Product product) {
    final currentQty = _selectedQuantities[product.id] ?? 0;

    return Row(
      children: [
        // Product Image Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 52,
            height: 52,
            color: Colors.grey[100],
            child: CachedNetworkImage(
              imageUrl: product.image,
              fit: BoxFit.contain,
              errorWidget: (c, u, e) => const Icon(Icons.celebration, color: Color(0xFFFF9F1C), size: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Title & Pricing
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.name,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.tamilName.isNotEmpty)
                Text(
                  product.tamilName,
                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    "₹${product.price.toStringAsFixed(0)}",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF8C00),
                      fontSize: 14,
                    ),
                  ),
                  if (product.originalPrice > product.price) ...[
                    const SizedBox(width: 6),
                    Text(
                      "₹${product.originalPrice.toStringAsFixed(0)}",
                      style: GoogleFonts.outfit(
                        color: Colors.grey[400],
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Quantity Selector Box
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: currentQty > 0 ? const Color(0xFFFFF7ED) : Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: currentQty > 0 ? const Color(0xFFFF9F1C) : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.remove, size: 16, color: currentQty > 0 ? const Color(0xFFFF8C00) : Colors.grey[400]),
                onPressed: () {
                  if (currentQty > 0) {
                    setState(() {
                      _selectedQuantities[product.id] = currentQty - 1;
                    });
                  }
                },
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 24),
                alignment: Alignment.center,
                child: Text(
                  "$currentQty",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: currentQty > 0 ? const Color(0xFFFF8C00) : Colors.black87,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.add, size: 16, color: Color(0xFFFF8C00)),
                onPressed: () {
                  setState(() {
                    _selectedQuantities[product.id] = currentQty + 1;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cart = Provider.of<CartProvider>(context);

    final allProducts = productProvider.products;
    final categories = ["All", ...productProvider.categories];

    // Filter products by search query and category
    final filteredProducts = allProducts.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.tamilName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == "All" ||
          p.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();

    // Calculate quick order total items & amount
    int totalItemsCount = 0;
    double totalAmount = 0.0;

    _selectedQuantities.forEach((prodId, qty) {
      if (qty > 0) {
        final prod = allProducts.firstWhere(
          (p) => p.id == prodId,
          orElse: () => Product(
            id: '',
            name: '',
            tamilName: '',
            description: '',
            price: 0,
            category: '',
            image: '',
            countInStock: 0,
          ),
        );
        if (prod.id.isNotEmpty) {
          totalItemsCount += qty;
          totalAmount += (prod.price * qty);
        }
      }
    });

    final topPadding = MediaQuery.of(context).padding.top;

    final isWeb = MediaQuery.of(context).size.width > 800;

    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 1. Drag Handle & Header
          Container(
            padding: EdgeInsets.fromLTRB(20, topPadding > 0 ? topPadding + 10 : 16, 16, 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1E0A35),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9F1C).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flash_on_rounded, color: Color(0xFFFF9F1C), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "⚡ Quick Order Catalog",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Set quantities & order multiple crackers in seconds!",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Search & Category Filters
          Container(
            color: const Color(0xFFFAF8F5),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                // Search Input
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "Search crackers by name...",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF9F1C), size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF9F1C)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Horizontal Category Chips with Web mouse drag & arrow scroll support
                SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          if (_categoryScrollController.hasClients) {
                            _categoryScrollController.animateTo(
                              (_categoryScrollController.offset - 160).clamp(0.0, _categoryScrollController.position.maxScrollExtent),
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Icon(Icons.chevron_left, size: 18, color: Color(0xFFFF9F1C)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: AppScrollBehavior(),
                          child: ListView.builder(
                            controller: _categoryScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            itemCount: categories.length,
                            itemBuilder: (context, idx) {
                              final cat = categories[idx];
                              final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    cat,
                                    style: GoogleFonts.outfit(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFFFF9F1C),
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontSize: 12,
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFFFF9F1C) : Colors.grey[300]!,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  onSelected: (val) {
                                    setState(() => _selectedCategory = cat);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          if (_categoryScrollController.hasClients) {
                            _categoryScrollController.animateTo(
                              (_categoryScrollController.offset + 160).clamp(0.0, _categoryScrollController.position.maxScrollExtent),
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Icon(Icons.chevron_right, size: 18, color: Color(0xFFFF9F1C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Product Catalog Table List (Grid on Web Desktop, List on Mobile)
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      "No products found",
                      style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 14),
                    ),
                  )
                : isWeb
                    ? GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 72,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductRow(product);
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        separatorBuilder: (context, index) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductRow(product);
                        },
                      ),
          ),

          // 4. Bottom Sticky Action Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$totalItemsCount Items Selected",
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        "₹${totalAmount.toStringAsFixed(0)}",
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF8C00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // WhatsApp Bulk Order Button
                  SizedBox(
                    height: 48,
                    child: IconButton(
                      tooltip: "Send Bulk Order via WhatsApp",
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                      onPressed: totalItemsCount > 0
                          ? () {
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              final addr = Provider.of<AddressProvider>(context, listen: false).selectedAddress;
                              final user = auth.user;

                              final selectedItemsPayload = <Map<String, dynamic>>[];
                              _selectedQuantities.forEach((prodId, qty) {
                                if (qty > 0) {
                                  final prod = allProducts.firstWhere((p) => p.id == prodId);
                                  selectedItemsPayload.add({
                                    'name': prod.name,
                                    'quantity': qty,
                                  });
                                }
                              });

                              WhatsAppHelper.launchBulkOrderEnquiry(
                                name: user?.name ?? "Customer",
                                phone: user?.phone ?? "",
                                city: addr != null ? "${addr.city}, ${addr.state}" : "Tamil Nadu",
                                items: selectedItemsPayload,
                                totalAmount: totalAmount,
                              );
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9F1C),
                          foregroundColor: const Color(0xFF1E0A35),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: totalItemsCount > 0
                            ? () {
                                if (!MinimumOrderHelper.validateAndShowNotice(context, totalAmount)) {
                                  return;
                                }
                                // Add all selected items to cart
                                _selectedQuantities.forEach((prodId, qty) {
                                  if (qty > 0) {
                                    final prod = allProducts.firstWhere((p) => p.id == prodId);
                                    for (int i = 0; i < qty; i++) {
                                      cart.addItem(prod);
                                    }
                                  }
                                });
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                );
                              }
                            : null,
                        child: Text(
                          "Add & Checkout",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
