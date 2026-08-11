import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MinimumOrderHelper {
  static const double minOrderAmount = 4500.0;

  /// Returns true if the order total satisfies the ₹4,500 requirement.
  /// If below ₹4,500, shows a bilingual note dialog in English and Tamil matching the official guidelines and returns false.
  static bool validateAndShowNotice(BuildContext context, double currentAmount) {
    if (currentAmount >= minOrderAmount) {
      return true;
    }

    final double neededAmount = (minOrderAmount - currentAmount).clamp(0, minOrderAmount);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Minimum Order Notice",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: const Color(0xFF1E293B)),
                  ),
                  Text(
                    "குறைந்தபட்ச ஆர்டர் அறிவிப்பு",
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFD97706)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill Header Badge for Minimum Booking Value (Image 2 design)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF881337), // Crimson/Burgundy matching image 2
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_checkout, color: Color(0xFFFBBF24), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "₹4,500 MINIMUM BOOKING",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "For fireworks bookings, a minimum booking value of ₹4,500 may apply.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Current Order Status Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("🇬🇧 ", style: TextStyle(fontSize: 14)),
                          Text(
                            "English Notice",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF92400E)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "The total cost must be above ₹4,500 to proceed with purchase. Your current order total is ₹${currentAmount.toStringAsFixed(0)}. (Need ₹${neededAmount.toStringAsFixed(0)} more).",
                        style: GoogleFonts.outfit(fontSize: 12, height: 1.35, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text("🇮🇳 ", style: TextStyle(fontSize: 14)),
                          Text(
                            "தமிழ் அறிவிப்பு (Tamil Notice)",
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFFC2410C)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "கொள்முதல் செய்ய குறைந்தபட்ச ஆர்டர் தொகை ₹4,500 ஆக இருக்க வேண்டும். உங்கள் தற்போதைய ஆர்டர் தொகை ₹${currentAmount.toStringAsFixed(0)}. தயவுசெய்து உங்கள் கார்ட்டில் கூடுதல் பட்டாசுகளை சேர்க்கவும்.",
                        style: GoogleFonts.outfit(fontSize: 12, height: 1.35, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Why is the minimum booking value required? (Image 2 Exact Explanation)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Why is the minimum booking value required?",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5, color: const Color(0xFF9A3412)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "The minimum booking value is maintained to help us provide safer and more secure packing and transportation of your goods. Small individual products / very small quantities can have a higher possibility of movement or damage during transportation. Therefore, we use suitable larger packaging and consolidated packing wherever applicable.",
                        style: GoogleFonts.outfit(fontSize: 11, height: 1.35, color: const Color(0xFF334155)),
                      ),
                      const Divider(height: 14, color: Color(0xFFFED7AA)),
                      Text(
                        "ஏன் குறைந்தபட்ச ஆர்டர் தொகை தேவைப்படுகிறது?",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFFC2410C)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "பொருட்களை பாதுகாப்பாக மற்றும் பலமாக பேக்கிங் செய்து கொண்டு செல்ல ஏதுவாக குறைந்தபட்ச ஆர்டர் தொகை நிர்ணயிக்கப்பட்டுள்ளது. குறைந்த அளவு பொருட்கள் போக்குவரத்தின் போது சேதமடைய வாய்ப்புள்ளது. எனவே, பாதுகாப்பான பெரிய பேக்கேஜிங் மற்றும் ஒருங்கிணைந்த பேக்கிங் பயன்படுத்தப்படுகிறது.",
                        style: GoogleFonts.outfit(fontSize: 11, height: 1.35, color: const Color(0xFF334155)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Note Box (Image 2 Warning Note)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Note: Minimum booking requirements may vary depending on product, location, transport availability and applicable rules.",
                          style: GoogleFonts.outfit(fontSize: 10.5, height: 1.3, fontWeight: FontWeight.w600, color: const Color(0xFF991B1B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "+ Add More Crackers / மேலும் சேர்க்கவும்",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    );

    return false;
  }
}
