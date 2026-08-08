import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MinimumOrderHelper {
  static const double minOrderAmount = 4500.0;

  /// Returns true if the order total satisfies the ₹4,500 requirement.
  /// If below ₹4,500, shows a bilingual note dialog in English and Tamil and returns false.
  static bool validateAndShowNotice(BuildContext context, double currentAmount) {
    if (currentAmount >= minOrderAmount) {
      return true;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Minimum Order Notice",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  Text(
                    "குறைந்தபட்ச ஆர்டர் அறிவிப்பு",
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFFF8C00)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // English Section
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
                  const SizedBox(height: 6),
                  Text(
                    "The total cost must be above ₹4,500 to proceed with purchase. Your current order total is ₹${currentAmount.toStringAsFixed(0)}. Please add more crackers to your cart.",
                    style: GoogleFonts.outfit(fontSize: 12.5, height: 1.4, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tamil Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("🇮🇳 ", style: TextStyle(fontSize: 14)),
                      Text(
                        "தமிழ் அறிவிப்பு (Tamil Notice)",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFFC2410C)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "கொள்முதல் செய்ய குறைந்தபட்ச ஆர்டர் தொகை ₹4,500 ஆக இருக்க வேண்டும். உங்கள் தற்போதைய ஆர்டர் தொகை ₹${currentAmount.toStringAsFixed(0)}. தயவுசெய்து உங்கள் கார்ட்டில் கூடுதல் பட்டாசுகளை சேர்க்கவும்.",
                    style: GoogleFonts.outfit(fontSize: 12.5, height: 1.4, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "+ Add More Crackers / மேலும் சேர்க்கவும்",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );

    return false;
  }
}
