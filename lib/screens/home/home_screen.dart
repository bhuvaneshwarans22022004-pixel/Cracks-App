import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/banner_provider.dart';
import '../../widgets/product_card.dart';
import '../cart/cart_screen.dart';
import '../enquiry/wholesale_enquiry_screen.dart';
import '../profile/profile_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../order/order_history_screen.dart';
import '../notifications/notification_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int _currentSlide = 0;
  late Timer _carouselTimer;
  late Timer _countdownTimer;
  Duration _timeLeft = const Duration();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    // Auto-fetch products and banners
    Future.delayed(Duration.zero, () {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      Provider.of<BannerProvider>(context, listen: false).fetchBanners();
    });

    // Banners carousel timer
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final banners = Provider.of<BannerProvider>(context, listen: false).banners;
      if (banners.isNotEmpty) {
        if (_currentSlide < banners.length - 1) {
          _currentSlide++;
        } else {
          _currentSlide = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentSlide,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    // Deals countdown timer (Targeting end of day)
    _calculateTimeLeft();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final diff = endOfDay.difference(now);
    if (mounted) {
      setState(() {
        _timeLeft = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  void dispose() {
    _carouselTimer.cancel();
    _countdownTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours : $minutes : $seconds';
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final bannerProvider = Provider.of<BannerProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Image.network(
          'https://i.imgur.com/G2yS9wX.png',
          height: 35,
          errorBuilder: (_, __, ___) => Text(
            "FestiveKart",
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF8C00),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: const Color(0xFFFF8C00), borderRadius: BorderRadius.circular(10)),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: TextField(
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Search for crackers, gifts, decorations...",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF8C00)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: const Color(0xFFFF8C00).withOpacity(0.15), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: const Color(0xFFFF8C00).withOpacity(0.15), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = auth.user;
                return UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF8C00), Color(0xFFFFD700)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Color(0xFFFF8C00)),
                  ),
                  accountName: Text(user?.name ?? "Guest User", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  accountEmail: Text(user?.email ?? "Login to see more", style: GoogleFonts.outfit()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text("Notifications"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text("Wishlist"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("Order History"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => productProvider.fetchProducts(),
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const SizedBox(height: 15),

              // Category row
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _categoryItem("Crackers", Icons.celebration, const Color(0xFFFF8C00), "HOT"),
                    _categoryItem("Gifts", Icons.card_giftcard, const Color(0xFFFF4D4D), ""),
                    _categoryItem("Decor", Icons.lightbulb, const Color(0xFFFFD700), ""),
                    _categoryItem("Sweets", Icons.restaurant, const Color(0xFFFF69B4), "NEW"),
                    _categoryItem("Wholesale", Icons.business, const Color(0xFF1E90FF), "B2B"),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Custom Image Banner Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: AspectRatio(
                    aspectRatio: isWeb ? 3.5 : 2.5,
                    child: Stack(
                      children: [
                        bannerProvider.isLoading ? const Center(child: CircularProgressIndicator()) : PageView.builder(
                          controller: _pageController,
                          onPageChanged: (idx) {
                            setState(() {
                              _currentSlide = idx;
                            });
                          },
                          itemCount: bannerProvider.banners.length,
                          itemBuilder: (context, index) {
                            final slide = bannerProvider.banners[index];
                            final hasImage = slide['imageUrl'] != null && slide['imageUrl'].toString().isNotEmpty;
                            return Container(
                              decoration: BoxDecoration(
                                gradient: hasImage ? null : const LinearGradient(
                                  colors: [Color(0xFF1E0D08), Color(0xFF5C2C16)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                image: hasImage ? DecorationImage(
                                  image: NetworkImage(slide['imageUrl']),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                                ) : null,
                              ),
                              child: Stack(
                                children: [
                                  // Background design elements (glowing orbits/particles)
                                  if (!hasImage) Positioned(
                                    right: -50,
                                    bottom: -50,
                                    child: Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFFF8C00).withOpacity(0.15),
                                      ),
                                    ),
                                  ),
                                  if (!hasImage) Positioned(
                                    right: 20,
                                    top: -20,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFFFD700).withOpacity(0.08),
                                      ),
                                    ),
                                  ),
                                  if (!hasImage) const Positioned(
                                    right: 15,
                                    bottom: 15,
                                    child: Icon(Icons.celebration, size: 100, color: Colors.white12),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF8C00).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color(0xFFFF8C00).withOpacity(0.4), width: 1),
                                          ),
                                          child: Text(
                                            "FESTIVE EXCLUSIVE",
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFFFD700),
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          slide['title'] ?? '',
                                          style: GoogleFonts.playfairDisplay(
                                            color: const Color(0xFFFFD700),
                                            fontSize: isWeb ? 32 : 24,
                                            fontWeight: FontWeight.bold,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          slide['subtitle'] ?? '',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: isWeb ? 18 : 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          constraints: const BoxConstraints(maxWidth: 450),
                                          child: Text(
                                            slide['desc'] ?? '',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              height: 1.3,
                                            ),
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
                        // Slider Dots Indicator
                        if (!bannerProvider.isLoading) Positioned(
                          bottom: 12,
                          left: 24,
                          child: Row(
                            children: List.generate(bannerProvider.banners.length, (index) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: _currentSlide == index ? 24 : 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: _currentSlide == index ? Colors.white : Colors.white54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Deals Section with Timer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on, color: Color(0xFFFF8C00)),
                        const SizedBox(width: 6),
                        Text("Deals of the Day", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 15),
                        Row(
                          children: [
                            _buildTimerBlock(_timeLeft.inHours.toString().padLeft(2, '0'), "HRS"),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(":", style: TextStyle(color: Color(0xFFFF8C00), fontWeight: FontWeight.bold)),
                            ),
                            _buildTimerBlock(_timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0'), "MIN"),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(":", style: TextStyle(color: Color(0xFFFF8C00), fontWeight: FontWeight.bold)),
                            ),
                            _buildTimerBlock(_timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0'), "SEC"),
                          ],
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text("View All", style: TextStyle(color: Color(0xFFFF8C00))),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Products Grid
              productProvider.isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWeb ? 4 : 2,
                        childAspectRatio: 0.76,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: productProvider.products.length,
                      itemBuilder: (context, index) => ProductCard(product: productProvider.products[index]),
                    ),
              const SizedBox(height: 35),

              // Value Props
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[50]!, Colors.white],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                child: isWeb
                    ? Row(
                        children: [
                          Expanded(child: _valuePropCard(Icons.local_shipping_outlined, "Express Shipping", "Secure dispatch inside heavy duty box in 24 hours")),
                          const SizedBox(width: 16),
                          Expanded(child: _valuePropCard(Icons.card_giftcard_outlined, "Diwali Gifting Mode", "Send customized assortments directly to your relatives")),
                          const SizedBox(width: 16),
                          Expanded(child: _valuePropCard(Icons.security_outlined, "Green Cracker Safe", "100% adherence to standard eco-friendly levels")),
                        ],
                      )
                    : Column(
                        children: [
                          _valuePropCard(Icons.local_shipping_outlined, "Express Shipping", "Secure dispatch inside heavy duty box in 24 hours"),
                          const SizedBox(height: 15),
                          _valuePropCard(Icons.card_giftcard_outlined, "Diwali Gifting Mode", "Send customized assortments directly to your relatives"),
                          const SizedBox(height: 15),
                          _valuePropCard(Icons.security_outlined, "Green Cracker Safe", "100% adherence to standard eco-friendly levels"),
                        ],
                      ),
              ),

              // Customer Reviews
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("What Families Say", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _reviewCard("Rajesh S.", "The sparklers were completely smoke-free! Kids had great fun. Safely packed."),
                          const SizedBox(width: 12),
                          _reviewCard("Priya P.", "Corporate gift boxes were a big hit. Unbelievable bulk price discount."),
                          const SizedBox(width: 12),
                          _reviewCard("Ankit V.", "Live customer support resolved a routing address delay instantly. Amazing."),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Newsletter Signup
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E0D08), Color(0xFF3B1E13)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.15), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E0D08).withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          "Join the Festive VIP Club",
                          style: GoogleFonts.playfairDisplay(color: const Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Subscribe for safety alerts, diwali coupons and exclusive B2B factory deals.",
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: "Enter email address",
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.06),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8C00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          child: Text(
                            "Subscribe",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Web Footer (Visible on Web layouts)
              if (isWeb)
                Container(
                  color: const Color(0xFF160E0D),
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("FestiveKart", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          const Text("Celebrate safely since 2021", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                      const Row(
                        children: [
                          Text("Privacy Policy", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          SizedBox(width: 20),
                          Text("Terms of Service", style: TextStyle(color: Colors.grey, fontSize: 11)),
                          SizedBox(width: 20),
                          Text("Contact Us", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  child: const Text("© 2026 FestiveKart. All Rights Reserved.", style: TextStyle(color: Colors.grey, fontSize: 10)),
                ),
            ],
          ),
        ),
      ),
    ),
      ),
    );
  }

  Widget _buildTimerBlock(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFF8C00).withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C00).withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              color: const Color(0xFFFF8C00),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 7, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _categoryItem(String name, IconData icon, Color color, String badgeText) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 58,
              height: 58,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.12), color.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            if (badgeText.isNotEmpty)
              Positioned(
                top: -2,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(name, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _valuePropCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF8C00).withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C00).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFFF8C00), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.grey, fontSize: 10, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(String name, String review) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF8C00).withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
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
              Row(
                children: List.generate(5, (index) => const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14)),
              ),
              const Icon(Icons.format_quote_rounded, color: Color(0xFFFF8C00), size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review,
            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFF8C00).withOpacity(0.1),
                radius: 12,
                child: Text(
                  name.substring(0, 1),
                  style: const TextStyle(color: Color(0xFFFF8C00), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}
