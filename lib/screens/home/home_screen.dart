import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/banner_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/product_card.dart';
import '../cart/cart_screen.dart';
import '../enquiry/wholesale_enquiry_screen.dart';
import '../profile/profile_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../order/order_history_screen.dart';
import '../notifications/notification_screen.dart';
import '../settings/settings_screen.dart';
import '../../services/update_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../product/product_detail_screen.dart';
import '../offer/offer_detail_screen.dart';

String getAppCategory(String rawCat) {
  final cat = rawCat.trim();
  if (cat.isEmpty) return "Crackers";
  final lower = cat.toLowerCase();
  if (lower.contains("gift")) return "Gift Box";
  if (lower.contains("combo")) return "Combo Products";
  final oldCrackers = [
    "one sound crackers", "chorsa crackers", "bijili crackers",
    "flower pots", "ground chakkars", "sparklers",
    "aerial fancy novelties", "rockets", "unsorted"
  ];
  if (oldCrackers.contains(lower)) return "Crackers";
  return cat;
}

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Navigation & State variables
  late int _selectedIndex;
  String _selectedExploreCategory = "";
  String _currentLocation = "Select Location";
  bool _hasCustomLocation = false;

  late PageController _pageController;
  int _currentSlide = 0;
  late Timer _carouselTimer;
  late Timer _countdownTimer;
  Duration _timeLeft = const Duration();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _selectedExploreCategory = "All";
    _currentLocation = "Select Location";
    _pageController = PageController(initialPage: 0);

    // Load saved settings from last session
    _loadSavedValues();

    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      UpdateService.checkForUpdate(context);
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      Provider.of<BannerProvider>(context, listen: false).fetchBanners();
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null && auth.user!.token != null) {
        Provider.of<OrderProvider>(context, listen: false).fetchOrders(auth.user!.token!);
        Provider.of<WishlistProvider>(context, listen: false).fetchWishlist(auth.user!.token!);
        Provider.of<AddressProvider>(context, listen: false).fetchAddresses(auth.user!.token!).then((_) {
          if (!mounted) return;
          final addressProvider = Provider.of<AddressProvider>(context, listen: false);
          final selectedAddress = addressProvider.selectedAddress;
          if (selectedAddress != null && !_hasCustomLocation) {
            _setCurrentLocation("${selectedAddress.city}, ${selectedAddress.state}", hasCustom: false);
          }
        });
      }
    });

    // Banners carousel timer
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final bannerProvider = Provider.of<BannerProvider>(context, listen: false);
      final listLength = bannerProvider.banners.isNotEmpty ? bannerProvider.banners.length : 1;
      if (_currentSlide < listLength - 1) {
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
    });

    // Deals countdown timer (Targeting end of day)
    _calculateTimeLeft();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  Future<void> _loadSavedValues() async {
    final savedIndex = await StorageService.getLastSelectedIndex();
    final savedCategory = await StorageService.getLastExploreCategory();
    final savedLocation = await StorageService.getLastLocation();
    
    if (mounted) {
      setState(() {
        if (widget.initialIndex == 0 && savedIndex != 0) {
          _selectedIndex = savedIndex;
        }
        _selectedExploreCategory = savedCategory;
        if (savedLocation != null && savedLocation.isNotEmpty) {
          _currentLocation = savedLocation;
          _hasCustomLocation = true;
        }
      });
    }
  }

  void _setSelectedIndex(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
    StorageService.saveLastSelectedIndex(index);
  }

  void _setSelectedExploreCategory(String category) {
    if (!mounted) return;
    setState(() {
      _selectedExploreCategory = category;
    });
    StorageService.saveLastExploreCategory(category);
  }

  void _setCurrentLocation(String location, {required bool hasCustom}) {
    if (!mounted) return;
    setState(() {
      _currentLocation = location;
      _hasCustomLocation = hasCustom;
    });
    StorageService.saveLastLocation(location);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex = widget.initialIndex;
    }
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

  Future<List<String>> _getPlacesSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await ApiService.get('addresses/autocomplete?query=${Uri.encodeComponent(query.trim())}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item.toString()).toList();
      }
    } catch (e) {
      print("Error fetching places from backend: $e");
    }
    return [];
  }

  void _changeLocationDialog() {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    final selectedAddress = addressProvider.selectedAddress;
    
    String initialText = _currentLocation;
    if (!_hasCustomLocation && selectedAddress != null) {
      initialText = "${selectedAddress.city}, ${selectedAddress.state}";
    }
    
    final controller = TextEditingController(text: initialText);
    List<String> suggestions = [];
    bool isSearching = false;
    Timer? debounceTimer;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final addresses = addressProvider.addresses;
            final activeAddress = addressProvider.selectedAddress;
            
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              actionsPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 20, top: 12),
              title: Text(
                "Change Delivery Location", 
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                )
              ),
              content: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        onChanged: (val) {
                          if (debounceTimer?.isActive ?? false) debounceTimer!.cancel();
                          debounceTimer = Timer(const Duration(milliseconds: 500), () async {
                            if (val.trim().isEmpty) {
                              setModalState(() {
                                suggestions = [];
                              });
                              return;
                            }
                            setModalState(() {
                              isSearching = true;
                            });
                            final fetched = await _getPlacesSuggestions(val.trim());
                            setModalState(() {
                              suggestions = fetched;
                              isSearching = false;
                            });
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search location...",
                          hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
                          prefixIcon: const Icon(Icons.location_on, color: Color(0xFFFF8C00)),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
                          ),
                        ),
                        style: GoogleFonts.outfit(fontSize: 14),
                      ),
                      
                      if (isSearching)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF8C00)),
                            ),
                          ),
                        ),
                      
                      if (suggestions.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: suggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = suggestions[index];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                                title: Text(
                                  suggestion,
                                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.black87),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  controller.text = suggestion;
                                  setModalState(() {
                                    suggestions = [];
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                      
                      if (addresses.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          "Saved Addresses",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: addresses.length,
                            itemBuilder: (context, index) {
                              final addr = addresses[index];
                              final isSelected = activeAddress?.id == addr.id;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFF8C00).withOpacity(0.04) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFFF8C00) : Colors.grey[100]!,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  leading: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF8C00).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      addr.type.toLowerCase() == 'home' ? Icons.home_rounded : Icons.work_rounded,
                                      color: const Color(0xFFFF8C00),
                                      size: 16,
                                    ),
                                  ),
                                  title: Text(
                                    addr.type,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "${addr.city}, ${addr.state} - ${addr.zipCode}",
                                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: isSelected 
                                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF8C00), size: 18)
                                      : null,
                                  onTap: () {
                                    setModalState(() {
                                      addressProvider.selectAddress(addr);
                                      controller.text = "${addr.city}, ${addr.state}";
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final trimmed = controller.text.trim();
                    if (trimmed.isNotEmpty) {
                      bool matched = false;
                      for (var addr in addresses) {
                        if (trimmed.toLowerCase() == "${addr.city}, ${addr.state}".toLowerCase() ||
                            trimmed.toLowerCase() == addr.formattedAddress.toLowerCase()) {
                          addressProvider.selectAddress(addr);
                          matched = true;
                          break;
                        }
                      }
                      _setCurrentLocation(trimmed, hasCustom: !matched);
                    }
                    Navigator.pop(context);
                  },
                  child: Text("Update", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final productProvider = Provider.of<ProductProvider>(context);
    final bannerProvider = Provider.of<BannerProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final isWeb = MediaQuery.of(context).size.width > 800;

    final addressProvider = Provider.of<AddressProvider>(context);
    final selectedAddress = addressProvider.selectedAddress;
    if (!_hasCustomLocation && selectedAddress != null) {
      final formatted = "${selectedAddress.city}, ${selectedAddress.state}";
      if (_currentLocation != formatted) {
        _currentLocation = formatted;
      }
    }

    // Define child views for each tab
    final List<Widget> pages = [
      _buildHomeTab(productProvider, bannerProvider, cart, isWeb),
      ExploreTab(
        productProvider: productProvider,
        initialCategory: _selectedExploreCategory,
        onCategoryChanged: (cat) {
          _setSelectedExploreCategory(cat);
        },
        onBackPressed: () {
          _setSelectedIndex(0);
        },
      ),
      const OrderHistoryScreen(),
      ProfileScreen(
        onBackPressed: () {
          _setSelectedIndex(0);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      drawer: _buildDrawer(),
      body: pages[_selectedIndex],
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: (cart.itemCount > 0 && (_selectedIndex == 0 || _selectedIndex == 1))
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 4),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const CartScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeOutCubic;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        return SlideTransition(position: animation.drive(tween), child: child);
                      },
                    ),
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFF9F1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B00).withOpacity(0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${cart.itemCount}',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFF6B00),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      bottomNavigationBar: isWeb
          ? Container(
              color: const Color(0xFFFAF8F5), // Outer background to match screen margins
              height: 70,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                      top: BorderSide(color: Color(0xFFFAF8F5), width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, -3),
                      )
                    ],
                  ),
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    backgroundColor: Colors.transparent, // Inherited from Container
                    elevation: 0,
                    onTap: (index) {
                      _setSelectedIndex(index);
                      // Reset categories filters when navigating directly to Explore via bottom tab
                      if (index == 1) {
                        _setSelectedExploreCategory("All");
                      }
                    },
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: const Color(0xFFFF8C00),
                    unselectedItemColor: Colors.grey[600],
                    showUnselectedLabels: true,
                    selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
                    unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined),
                        activeIcon: Icon(Icons.home, color: Color(0xFFFF8C00)),
                        label: "Home",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.search_rounded),
                        activeIcon: Icon(Icons.search_rounded, color: Color(0xFFFF8C00)),
                        label: "Explore",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.history_rounded),
                        activeIcon: Icon(Icons.history_rounded, color: Color(0xFFFF8C00)),
                        label: "Orders",
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline_rounded),
                        activeIcon: Icon(Icons.person_rounded, color: Color(0xFFFF8C00)),
                        label: "Profile",
                      ),
                    ],
                  ),
                ),
              ),
            )
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              backgroundColor: Colors.white,
              elevation: 8,
              onTap: (index) {
                _setSelectedIndex(index);
                // Reset categories filters when navigating directly to Explore via bottom tab
                if (index == 1) {
                  _setSelectedExploreCategory("All");
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFFF8C00),
              unselectedItemColor: Colors.grey[600],
              showUnselectedLabels: true,
              selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home, color: Color(0xFFFF8C00)),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  activeIcon: Icon(Icons.search_rounded, color: Color(0xFFFF8C00)),
                  label: "Explore",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded),
                  activeIcon: Icon(Icons.history_rounded, color: Color(0xFFFF8C00)),
                  label: "Orders",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded, color: Color(0xFFFF8C00)),
                  label: "Profile",
                ),
              ],
            ),
    );
  }

  // Drawers
  Widget _buildDrawer() {
    return Drawer(
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
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: (user?.profileImage != null && user!.profileImage!.isNotEmpty)
                      ? NetworkImage(user.profileImage!)
                      : null,
                  child: (user?.profileImage == null || user!.profileImage!.isEmpty)
                      ? const Icon(Icons.person, color: Color(0xFFFF8C00), size: 40)
                      : null,
                ),
                accountName: Text(user?.name ?? "Guest User", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                accountEmail: Text(
                  (user?.buyerId != null && user!.buyerId.isNotEmpty)
                      ? "${user.email} • ${user.buyerId}"
                      : (user?.email ?? "Login to see more"),
                  style: GoogleFonts.outfit(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text("Home"),
            onTap: () {
              Navigator.pop(context);
              _setSelectedIndex(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.search_rounded),
            title: const Text("Explore Catalog"),
            onTap: () {
              Navigator.pop(context);
              _setSelectedIndex(1);
              _setSelectedExploreCategory("All");
            },
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
              _setSelectedIndex(2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: const Text("Wholesale Enquiry"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WholesaleEnquiryScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Profile"),
            onTap: () {
              Navigator.pop(context);
              _setSelectedIndex(3);
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
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return ListTile(
                leading: Icon(auth.isAuthenticated ? Icons.logout : Icons.login, color: Colors.red),
                title: Text(auth.isAuthenticated ? "Logout" : "Login", style: const TextStyle(color: Colors.red)),
                onTap: () {
                  auth.logout();
                  Navigator.pop(context);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Page 0 Content (Redesigned Home Storefront)
  Widget _buildHomeTab(ProductProvider productProvider, BannerProvider bannerProvider, CartProvider cart, bool isWeb) {
    // Determine dynamic list of banners (fallback if empty)
    final banners = bannerProvider.banners.isNotEmpty
        ? bannerProvider.banners
        : [
            {
              "title": "Biggest Diwali Sale",
              "subtitle": "Up to 70% Off",
              "desc": "Light up happiness this Diwali with green eco-friendly crackers at factory direct prices.",
              "imageUrl": ""
            }
          ];

    return SafeArea(
      child: LayoutBuilder(
          builder: (context, viewportConstraints) {
            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  productProvider.fetchProducts(),
                  bannerProvider.fetchBanners(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isWeb ? 1000 : double.infinity,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                  // 1. Delivery Selector Bar
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 16, top: 12, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Builder(
                              builder: (context) {
                                return IconButton(
                                  icon: const Icon(Icons.menu_rounded, color: Colors.black87),
                                  onPressed: () => Scaffold.of(context).openDrawer(),
                                );
                              },
                            ),
                            GestureDetector(
                              onTap: _changeLocationDialog,
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: Color(0xFFFF8C00), size: 24),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Deliver to",
                                        style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 10),
                                      ),
                                      Consumer<AddressProvider>(
                                        builder: (context, addressProvider, _) {
                                          final selectedAddress = addressProvider.selectedAddress;
                                          String displayLocation = _currentLocation;
                                          if (!_hasCustomLocation && selectedAddress != null) {
                                            displayLocation = "${selectedAddress.city}, ${selectedAddress.state}";
                                          }
                                          return Text(
                                            displayLocation,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Cart Badge
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                            ),
                            if (cart.itemCount > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(color: const Color(0xFFFF8C00), borderRadius: BorderRadius.circular(10)),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '${cart.itemCount}',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. Rounded Search Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: GestureDetector(
                      onTap: () {
                        _setSelectedIndex(1);
                        _setSelectedExploreCategory("All");
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: Color(0xFFFF8C00)),
                            const SizedBox(width: 12),
                            Text(
                              "Search for crackers, gifts...",
                              style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Carousel Banner Slider (Deep Blue/Purple theme)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: isWeb ? 3.5 : 2.5,
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              onPageChanged: (idx) {
                                setState(() {
                                  _currentSlide = idx;
                                });
                              },
                              itemCount: banners.length,
                              itemBuilder: (context, index) {
                                final slide = banners[index];
                                final hasImage = slide['imageUrl'] != null && slide['imageUrl'].toString().isNotEmpty;
                                return GestureDetector(
                                  onTap: () {
                                    final slideMap = (slide is Map) ? Map<String, dynamic>.from(slide) : <String, dynamic>{};
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OfferDetailScreen(banner: slideMap),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF415A77)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      image: hasImage ? DecorationImage(
                                        image: NetworkImage(slide['imageUrl']!),
                                        fit: BoxFit.cover,
                                        colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
                                      ) : null,
                                    ),
                                    child: Stack(
                                      children: [
                                        // Custom Vector sparks drawing on empty banner
                                        if (!hasImage) Positioned.fill(
                                          child: CustomPaint(
                                            painter: BannerSparkPainter(),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF9F1C).withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: const Color(0xFFFF9F1C).withOpacity(0.4), width: 1),
                                                ),
                                                child: Text(
                                                  "FESTIVE EXCLUSIVE",
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(0xFFFFD700),
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                slide['title'] ?? '',
                                                style: GoogleFonts.playfairDisplay(
                                                  color: const Color(0xFFFFD700),
                                                  fontSize: isWeb ? 30 : 22,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.1,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                slide['subtitle'] ?? '',
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontSize: isWeb ? 16 : 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                constraints: const BoxConstraints(maxWidth: 400),
                                                child: Text(
                                                  slide['desc'] ?? '',
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.white70,
                                                    fontSize: 10,
                                                    height: 1.3,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
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
                            // Dots Indicator
                            Positioned(
                              bottom: 12,
                              left: 24,
                              child: Row(
                                children: List.generate(banners.length, (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: _currentSlide == index ? 20 : 6,
                                    height: 6,
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
                  const SizedBox(height: 20),

                  _buildDynamicCategoriesList(productProvider),

                  const SizedBox(height: 25),

                  // 5. Deals of the day Section
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
                          onPressed: () {
                            _setSelectedIndex(1);
                            _setSelectedExploreCategory("All");
                          },
                          child: const Text("View All", style: TextStyle(color: Color(0xFFFF8C00))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 6. Products grid (Top Picks)
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
                          itemCount: math.min(productProvider.products.length, 6), // show up to 6 on homepage
                          itemBuilder: (context, index) => ProductCard(product: productProvider.products[index]),
                        ),
                  const SizedBox(height: 35),

                  // 7. Value Props
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

                  // 8. Customer reviews
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

                  // 9. Newsletter
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E0D08), Color(0xFF3B1E13)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.15), width: 1.5),
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
                          "Subscribe for safety alerts, diwali coupons and B2B factory deals.",
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
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Subscribed! Thank you.")),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF8C00),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text("Subscribe", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Footer
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
          },
        ),
      );
  }

  // Category widget helper
  Widget _categoryItem(String name, IconData icon, Color color, String badgeText, String filterCategory) {
    return GestureDetector(
      onTap: () {
        _setSelectedIndex(1);
        _setSelectedExploreCategory(filterCategory);
      },
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.15), color.withOpacity(0.02)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
          Text(name, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildDynamicCategoriesList(ProductProvider productProvider) {
    final List<Map<String, dynamic>> items = [
      {"name": "Crackers", "icon": Icons.celebration, "color": const Color(0xFFFF9F1C), "badge": "HOT", "target": "Crackers"},
      {"name": "Gift Box", "icon": Icons.card_giftcard, "color": const Color(0xFFE91E63), "badge": "", "target": "Gift Box"},
      {"name": "Combo Products", "icon": Icons.inventory_2_outlined, "color": const Color(0xFF00B0FF), "badge": "", "target": "Combo Products"},
    ];

    final seen = <String>{"crackers", "gift box", "combo products"};
    final colors = [const Color(0xFF7C4DFF), const Color(0xFFFF5722), const Color(0xFF10B981), const Color(0xFF8B5CF6)];
    int colorIdx = 0;

    for (var p in productProvider.products) {
      final normalizedCat = getAppCategory(p.category);
      final lower = normalizedCat.toLowerCase();
      if (!seen.contains(lower)) {
        seen.add(lower);
        items.add({
          "name": normalizedCat,
          "icon": lower.contains("decor") ? Icons.auto_awesome : Icons.category_rounded,
          "color": colors[colorIdx % colors.length],
          "badge": "NEW",
          "target": normalizedCat,
        });
        colorIdx++;
      }
    }

    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, idx) {
          final item = items[idx];
          return _categoryItem(
            item["name"] as String,
            item["icon"] as IconData,
            item["color"] as Color,
            item["badge"] as String,
            item["target"] as String,
          );
        },
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(color: const Color(0xFFFF8C00), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 6, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
            child: Icon(icon, color: const Color(0xFFFF8C00), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 10, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(String name, String review) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF8C00).withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
              const Icon(Icons.format_quote_rounded, color: Color(0xFFFF8C00), size: 16),
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

// Sparkles Decorator Painter for Banner Fallback
class BannerSparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.06)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    _drawBurst(canvas, Offset(size.width * 0.75, size.height * 0.3), 30, paint);
    _drawBurst(canvas, Offset(size.width * 0.9, size.height * 0.7), 24, paint);
  }

  void _drawBurst(Canvas canvas, Offset center, double radius, Paint paint) {
    const int rays = 8;
    for (int i = 0; i < rays; i++) {
      final double angle = (i * 2 * math.pi) / rays;
      final offsetStart = Offset(
        center.dx + (radius * 0.4) * math.cos(angle),
        center.dy + (radius * 0.4) * math.sin(angle),
      );
      final offsetEnd = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(offsetStart, offsetEnd, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Tab 1 Content: Explore/Search Category Tab widget
class ExploreTab extends StatefulWidget {
  final ProductProvider productProvider;
  final String initialCategory;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onBackPressed;

  const ExploreTab({
    super.key,
    required this.productProvider,
    required this.initialCategory,
    required this.onCategoryChanged,
    required this.onBackPressed,
  });

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final _searchController = TextEditingController();
  String _searchQuery = "";
  String _sortBy = "none";
  bool _inStockOnly = false;
  double _minRating = 0.0;
  bool _isSearching = false;

  final ScrollController _scrollController = ScrollController();
  bool _isManualScrolling = false;
  bool _isScrollingFromUser = false; // true when chip change was triggered by scroll, not chip tap

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialCategory != "All" && widget.initialCategory != "Crackers") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCategory(widget.initialCategory);
      });
    }
  }

  @override
  void didUpdateWidget(ExploreTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only auto-scroll if the change came from a chip tap (not from _onScroll updating the chip)
    if (oldWidget.initialCategory != widget.initialCategory && !_isManualScrolling && !_isScrollingFromUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCategory(widget.initialCategory);
      });
    }
    _isScrollingFromUser = false;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isManualScrolling) return;
    final filteredProducts = _getFilteredProducts();
    if (filteredProducts.isEmpty) return;
    if (!_scrollController.hasClients) return;
    
    double offset = _scrollController.offset;
    double accumulatedHeight = 0;
    int firstVisibleIndex = 0;
    
    for (int i = 0; i < filteredProducts.length; i++) {
      final showHeader = i == 0 || filteredProducts[i].category != filteredProducts[i - 1].category;
      double itemHeight = 120.0 + (showHeader ? 40.0 : 0.0);
      accumulatedHeight += itemHeight;
      if (accumulatedHeight > offset + 30.0) {
        firstVisibleIndex = i;
        break;
      }
    }
    
    final visibleProduct = filteredProducts[firstVisibleIndex];
    
    String getCategoryDisplayString(String cat) {
      final cLower = cat.toLowerCase();
      if (cLower.contains("cracker")) return "Crackers";
      if (cLower.contains("gift") || cLower.contains("box") || cLower.contains("combo")) return "Gifts";
      if (cLower.contains("new") || cLower.contains("arrival")) return "New Arrivals";
      return "New Arrivals"; // everything else goes into New Arrivals
    }
    
    String cat = getCategoryDisplayString(visibleProduct.category);
    if (widget.initialCategory != cat) {
      _isScrollingFromUser = true;
      widget.onCategoryChanged(cat);
    }

  }


  void _scrollToCategory(String category) {
    if (!_scrollController.hasClients) return;
    final targetOffset = _getOffsetForCategory(category);
    _isManualScrolling = true;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ).then((_) {
      _isManualScrolling = false;
    });
  }

  double _getOffsetForCategory(String category) {
    if (category == "All") return 0.0;
    final filteredProducts = _getFilteredProducts();
    
    String getCategoryDisplayString(String cat) {
      final cLower = cat.toLowerCase();
      if (cLower.contains("cracker")) return "Crackers";
      if (cLower.contains("gift") || cLower.contains("box") || cLower.contains("combo")) return "Gifts";
      if (cLower.contains("new") || cLower.contains("arrival")) return "New Arrivals";
      return "New Arrivals"; // everything else goes into New Arrivals
    }

    double accumulatedHeight = 0.0;
    for (int i = 0; i < filteredProducts.length; i++) {
      final product = filteredProducts[i];
      if (getCategoryDisplayString(product.category) == category) {
        break;
      }
      final showHeader = i == 0 || filteredProducts[i].category != filteredProducts[i - 1].category;
      double itemHeight = 120.0 + (showHeader ? 40.0 : 0.0);
      accumulatedHeight += itemHeight;
    }
    return accumulatedHeight;
  }


  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sort By", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ListTile(
                    title: Text("Default", style: GoogleFonts.outfit()),
                    leading: Radio<String>(
                      value: "none",
                      groupValue: _sortBy,
                      activeColor: const Color(0xFFFF8C00),
                      onChanged: (val) {
                        setModalState(() => _sortBy = val ?? "none");
                        setState(() => _sortBy = val ?? "none");
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text("Price: Low to High", style: GoogleFonts.outfit()),
                    leading: Radio<String>(
                      value: "price_low_high",
                      groupValue: _sortBy,
                      activeColor: const Color(0xFFFF8C00),
                      onChanged: (val) {
                        setModalState(() => _sortBy = val ?? "none");
                        setState(() => _sortBy = val ?? "none");
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text("Price: High to Low", style: GoogleFonts.outfit()),
                    leading: Radio<String>(
                      value: "price_high_low",
                      groupValue: _sortBy,
                      activeColor: const Color(0xFFFF8C00),
                      onChanged: (val) {
                        setModalState(() => _sortBy = val ?? "none");
                        setState(() => _sortBy = val ?? "none");
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  ListTile(
                    title: Text("Customer Rating", style: GoogleFonts.outfit()),
                    leading: Radio<String>(
                      value: "rating",
                      groupValue: _sortBy,
                      activeColor: const Color(0xFFFF8C00),
                      onChanged: (val) {
                        setModalState(() => _sortBy = val ?? "none");
                        setState(() => _sortBy = val ?? "none");
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Filter Products", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  SwitchListTile(
                    title: Text("In Stock Only", style: GoogleFonts.outfit()),
                    activeColor: const Color(0xFFFF8C00),
                    value: _inStockOnly,
                    onChanged: (val) {
                      setModalState(() => _inStockOnly = val);
                      setState(() => _inStockOnly = val);
                    },
                  ),
                  const Divider(),
                  Text("Minimum Customer Rating", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                  Slider(
                    value: _minRating,
                    min: 0.0,
                    max: 5.0,
                    divisions: 5,
                    label: "$_minRating★",
                    activeColor: const Color(0xFFFF8C00),
                    onChanged: (val) {
                      setModalState(() => _minRating = val);
                      setState(() => _minRating = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Apply Filters", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getProductPackSize(Product product) {
    final name = product.name.toLowerCase();
    if (name.contains("sky shot")) return "( pack of 1 )";
    if (name.contains("rocket")) return "( pack of 5 )";
    if (name.contains("sparkler")) return "( pack of 10 )";
    if (name.contains("ladi") || name.contains("bomb")) return "( pack of 10 )";
    if (name.contains("flower") || name.contains("pot")) return "( pack of 5 )";
    return "( pack of 1 )";
  }

  Map<String, dynamic> _getPricing(Product product) {
    if (product.price <= 0) {
      return {
        "originalPrice": 0.0,
        "discountPercent": 0,
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

  List<Product> _getFilteredProducts() {
    final allProducts = widget.productProvider.products;
    
    int getCategorySeqIndex(String cat) {
      final cLower = cat.toLowerCase();
      if (cLower.contains("cracker")) return 0;
      if (cLower.contains("gift") || cLower.contains("box") || cLower.contains("combo")) return 1;
      // New Arrivals (or anything unrecognized)
      return 2;
    }

    // 1. Filter logic
    List<Product> filtered = allProducts.where((product) {
      final normCat = getAppCategory(product.category);
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          normCat.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesCategory = false;
      if (widget.initialCategory == "All" || widget.initialCategory.isEmpty) {
        matchesCategory = true;
      } else {
        matchesCategory = normCat.trim().toLowerCase() == widget.initialCategory.trim().toLowerCase() ||
            (widget.initialCategory.toLowerCase() == "gifts" && normCat.toLowerCase().contains("gift"));
      }

          
      final matchesStock = !_inStockOnly || product.countInStock > 0;
      final matchesRating = product.rating >= _minRating;

      return matchesSearch && matchesCategory && matchesStock && matchesRating;
    }).toList();

    // 2. Sorting logic (Category grouping is primary key, selected option is secondary key)
    filtered.sort((a, b) {
      int idxA = getCategorySeqIndex(a.category);
      int idxB = getCategorySeqIndex(b.category);
      
      if (idxA != idxB) {
        return idxA.compareTo(idxB);
      }
      
      // Secondary sort
      if (_sortBy == "price_low_high") {
        return a.price.compareTo(b.price);
      } else if (_sortBy == "price_high_low") {
        return b.price.compareTo(a.price);
      } else if (_sortBy == "rating") {
        return b.rating.compareTo(a.rating);
      }
      return 0; // Maintain order
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();
    final cart = Provider.of<CartProvider>(context);

    final dynamicCategories = <String>["All"];
    final seenCats = <String>{};
    for (var p in widget.productProvider.products) {
      final normCat = getAppCategory(p.category);
      final lower = normCat.toLowerCase();
      if (!seenCats.contains(lower)) {
        seenCats.add(lower);
        dynamicCategories.add(normCat);
      }
    }
    if (!seenCats.contains("crackers")) dynamicCategories.add("Crackers");
    if (!seenCats.contains("gift box")) dynamicCategories.add("Gift Box");
    if (!seenCats.contains("combo products")) dynamicCategories.add("Combo Products");

    final categories = dynamicCategories;
    final isWeb = MediaQuery.of(context).size.width > 800;

    return SafeArea(
      child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: isWeb ? 1000 : double.infinity),
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
            child: Column(
              children: [
            // Top Header: Back Arrow & Category Title (or Search Bar inline)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 8),
              child: _isSearching
                  ? Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchQuery = "";
                              _searchController.clear();
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            style: GoogleFonts.outfit(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "Search for crackers, gifts...",
                              hintStyle: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF8C00)),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = "";
                                        });
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
                                borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: widget.onBackPressed,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Category",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.search_rounded, color: Colors.black87),
                          onPressed: () {
                            setState(() {
                              _isSearching = true;
                            });
                          },
                        ),
                      ],
                    ),
            ),

            // Sort & Filter buttons bar (Exactly aligned with mockup)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _showSortBottomSheet,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.filter_list_rounded, color: Colors.black87, size: 20),
                            const SizedBox(width: 8),
                            Text("Sort", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 24, color: Colors.grey[200]),
                    Expanded(
                      child: InkWell(
                        onTap: _showFilterBottomSheet,
                        borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.tune_rounded, color: Colors.black87, size: 20),
                            const SizedBox(width: 8),
                            Text("Filter", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category Chips Row (Horizontal Scroll)
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = widget.initialCategory == cat;
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
                      selectedColor: const Color(0xFF2E1A47), // Deep purple/black color matching the mockup
                      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
                      labelStyle: GoogleFonts.outfit(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      side: isSelected
                          ? BorderSide.none
                          : BorderSide(color: Colors.grey[200]!, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      pressElevation: 0,
                      elevation: 0,
                      onSelected: (val) {
                        widget.onCategoryChanged(cat);
                        _scrollToCategory(cat);
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 10, thickness: 1),

            // Products list view (Matching Category phone screen)
            Expanded(
              child: widget.productProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                "No products found matching your filters.",
                                style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredProducts.length,

                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final pricing = _getPricing(product);
                            final double originalPrice = pricing["originalPrice"];

                            final showHeader = index == 0 || filteredProducts[index].category != filteredProducts[index - 1].category;

                            String getCategoryHeader(String cat) {
                              final cLower = cat.toLowerCase();
                              if (cLower.contains("cracker")) return "Crackers";
                              if (cLower.contains("gift") || cLower.contains("box") || cLower.contains("combo")) return "Gift Boxes";
                              return cat;
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showHeader)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                                    child: Text(
                                      getCategoryHeader(product.category).toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFFF8C00),
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[100]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.015),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Left side: Image container
                                    Container(
                                      width: 90,
                                      height: 90,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F9FA), // Soft light grey matching mockup
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[100]!),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: product.image,
                                          fit: BoxFit.contain,
                                          errorWidget: (context, url, error) => const Icon(
                                            Icons.celebration,
                                            color: Color(0xFFFF8C00),
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Middle: Name, details, ratings, price
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _getProductPackSize(product),
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Price Row
                                          Row(
                                            children: [
                                              Text(
                                                "₹${product.price.toStringAsFixed(0)}",
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "₹${originalPrice.toStringAsFixed(0)}",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  color: Colors.grey[400],
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          // Rating text
                                          Row(
                                            children: [
                                              const Icon(Icons.star_rounded, color: Color(0xFFFFB703), size: 14),
                                              const SizedBox(width: 2),
                                              Text(
                                                "${product.rating}",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                " (${product.numReviews})",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Right side: arrow indicator & ADD button
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.grey,
                                          size: 18,
                                        ),
                                        const SizedBox(height: 20),
                                        // Outlined ADD button or Quantity Selector
                                        Builder(
                                          builder: (context) {
                                            final cartItem = cart.items[product.id];
                                            if (cartItem != null && cartItem.quantity > 0) {
                                              return Container(
                                                height: 30,
                                                width: 72,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: const Color(0xFFFF5722), width: 1.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                  color: Colors.white,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () => cart.decrementItem(product.id),
                                                      behavior: HitTestBehavior.opaque,
                                                      child: const Padding(
                                                        padding: EdgeInsets.symmetric(horizontal: 6),
                                                        child: Icon(Icons.remove, size: 12, color: Color(0xFFFF5722)),
                                                      ),
                                                    ),
                                                    Text(
                                                      '${cartItem.quantity}',
                                                      style: GoogleFonts.outfit(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                        color: const Color(0xFFFF5722),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () => cart.addItem(product),
                                                      behavior: HitTestBehavior.opaque,
                                                      child: const Padding(
                                                        padding: EdgeInsets.symmetric(horizontal: 6),
                                                        child: Icon(Icons.add, size: 12, color: Color(0xFFFF5722)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                            return SizedBox(
                                              width: 68,
                                              height: 30,
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: Color(0xFFFF5722), width: 1.2),
                                                  padding: EdgeInsets.zero,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                onPressed: product.countInStock > 0 ? () {
                                                  cart.addItem(product);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "${product.name} added to cart",
                                                        style: GoogleFonts.outfit(),
                                                      ),
                                                    ),
                                                  );
                                                } : null,
                                                child: Text(
                                                  "ADD",
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(0xFFFF5722),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
