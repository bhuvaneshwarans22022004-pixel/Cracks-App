import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../cart/address_screen.dart';
import 'edit_profile_screen.dart';
import '../../widgets/guest_auth_prompt.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onBackPressed;

  const ProfileScreen({super.key, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final addressProvider = Provider.of<AddressProvider>(context);
    final selectedAddress = addressProvider.selectedAddress;

    // Calculate Loyalty Tiers
    final int points = user?.loyaltyPoints ?? 120;
    String tier = 'Bronze Member';
    Color tierColor = const Color(0xFF8D5B4C);
    String nextTier = 'Silver Member';
    int pointsNeeded = 250 - points;
    double progressPercentage = (points / 250).clamp(0.0, 1.0);

    if (points >= 500) {
      tier = 'Diamond Member';
      tierColor = const Color(0xFF3A86C8);
      nextTier = 'Maximum Tier';
      pointsNeeded = 0;
      progressPercentage = 1.0;
    } else if (points >= 250) {
      tier = 'Gold Member';
      tierColor = const Color(0xFFFFD700);
      nextTier = 'Diamond Member';
      pointsNeeded = 500 - points;
      progressPercentage = ((points - 250) / 250).clamp(0.0, 1.0);
    } else if (points >= 100) {
      tier = 'Silver Member';
      tierColor = const Color(0xFFA19E9C);
      nextTier = 'Gold Member';
      pointsNeeded = 250 - points;
      progressPercentage = ((points - 100) / 150).clamp(0.0, 1.0);
    }

    final isWeb = MediaQuery.of(context).size.width > 800;

    return SafeArea(
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
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                // Custom Header Row (matching web view layout)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 12),
                  child: Row(
                    children: [
                      if (onBackPressed != null || Navigator.canPop(context)) ...[
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            if (onBackPressed != null) {
                              onBackPressed!();
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        "My Profile",
                        style: GoogleFonts.outfit(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                        label: Text(
                          "Logout",
                          style: GoogleFonts.outfit(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () {
                          auth.logout();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
            // User Header Card
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFFFF8C00).withOpacity(0.08),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFFFF8C00),
                      backgroundImage: (user?.profileImage != null && user!.profileImage!.isNotEmpty)
                          ? NetworkImage(user.profileImage!)
                          : null,
                      child: (user?.profileImage == null || user!.profileImage!.isEmpty)
                          ? Text(
                              (user?.name ?? "U").substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? "Guest User",
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (user?.buyerId != null && user!.buyerId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "ID: ${user.buyerId}",
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFF8C00),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  Text(
                    user?.email ?? "login to sync profile",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tierColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: tierColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      "🏆 $tier",
                      style: TextStyle(color: tierColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Loyalty Rewards Progress Widget
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFFFD700)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8C00).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("LOYALTY POINTS", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("$points Points", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(tier.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Next level: $nextTier", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                      Text(
                        pointsNeeded > 0 ? "$pointsNeeded pts needed" : "Max reached",
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: progressPercentage,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),

            // Profile detail cards
            Text("Profile Information", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _profileItem(Icons.phone_outlined, "Phone Number", user?.phone ?? "Not set"),
            GestureDetector(
              onTap: () {
                if (auth.isGuest) {
                  showGuestAuthPrompt(context, "Please log in or register to configure shipping addresses.");
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddressScreen(isCheckoutMode: false),
                  ),
                );
              },
              child: _profileItem(
                Icons.location_on_outlined,
                "Shipping Address",
                selectedAddress != null ? selectedAddress.formattedAddress : "Configure saved addresses",
              ),
            ),
            _profileItem(Icons.card_membership_outlined, "Loyalty Tier", tier),
            const SizedBox(height: 20),

            // Edit Profile Button
            ElevatedButton(
              onPressed: () {
                if (auth.isGuest) {
                  showGuestAuthPrompt(context, "Please log in or register to edit profile details.");
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Edit Profile Details", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 35),

            // Coupon Vouchers Section
            Text("Your Discount Coupons", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _couponCard(context, "FESTIVE100", "Flat ₹100 Off", "Orders above ₹999", true),
                  const SizedBox(width: 12),
                  _couponCard(context, "FREESHIP", "Free Delivery", "Orders above ₹499", true),
                  const SizedBox(width: 12),
                  _couponCard(context, "GOLD300", "Flat ₹300 Off", "Gold tier needed", points >= 250),
                ],
              ),
            ),
            const SizedBox(height: 20),
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

  Widget _profileItem(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF8C00).withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF8C00), size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _couponCard(BuildContext context, String code, String title, String condition, bool isUnlocked) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFFFF8C00).withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUnlocked ? const Color(0xFFFF8C00).withOpacity(0.15) : Colors.grey[200]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: isUnlocked ? const Color(0xFFFF8C00) : Colors.black)),
            Text(condition, style: const TextStyle(color: Colors.grey, fontSize: 9)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey[300]!)),
              child: Text(code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: isUnlocked
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Coupon code $code copied to clipboard!")),
                      );
                    }
                  : null,
              child: Text(
                isUnlocked ? "Copy Code" : "Locked",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? const Color(0xFFFF8C00) : Colors.grey,
                  decoration: isUnlocked ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
