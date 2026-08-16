import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/cms_provider.dart';
import '../utils/whatsapp_helper.dart';
import '../utils/constants.dart';


class WebFooter extends StatelessWidget {
  final Function(int)? onNavigateTab;
  final VoidCallback? onOpenContact;

  const WebFooter({
    super.key,
    this.onNavigateTab,
    this.onOpenContact,
  });

  Future<void> _launchUrl(String urlStr) async {
    final Uri uri = Uri.parse(urlStr);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("Error launching URL $urlStr: $e");
    }
  }

  Future<void> _downloadLatestApk(BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse("${AppConstants.baseUrl}/api/update.json"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String apkUrl = data["apk_url"] ?? "";
        if (apkUrl.isNotEmpty) {
          await _launchUrl(apkUrl);
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching APK URL: $e");
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to fetch latest app. Please try again later."),
        ),
      );
    }
  }

  void _showCmsDialog(BuildContext context, String title, String contentKey) {
    final cms = Provider.of<CmsProvider>(context, listen: false);
    final text = cms.content[contentKey] ?? 'Content not available.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            text,
            style: GoogleFonts.outfit(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Close", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFFFF8C00))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;
    final cms = Provider.of<CmsProvider>(context);
    final cmsData = cms.content;

    final termsText = cmsData['footer_terms_and_conditions'] ??
        'Minimum order value Starts from Rs.2000 to Unlimited, Customized Gift Box and Combo Fund Items Available at Reasonable Price, Available for Bulk Orders As per Requirement, Wholesale and Retail Also Available';
    final aboutUsText = cmsData['footer_about_us'] ??
        'Our company lies in manufacturing and supplying colourful Crackers. We are equipped with a state of art infrastructural unit and production facility.';
    final addressText = cmsData['footer_address'] ??
        '3/1322/3/1 , Opposite to SNM Matriculation School, Checkpost, Parapatti, Sivakasi, Tamil Nadu 626 189';
    final phone1 = cmsData['footer_phone_1'] ?? '+91 80720 11455';
    final phone2 = cmsData['footer_phone_2'] ?? '+91 93451 89265';
    final phone3 = cmsData['footer_phone_3'] ?? '+91 70102 55290';
    final emailText = cmsData['footer_email'] ?? 'festivekart@gmail.com';
    final disclaimerText = cmsData['footer_legal_disclaimer'] ??
        'As per 2018 supreme court order, online sale of firecrackers are not permitted! We value our customers and at the same time, respect jurisdiction. We request you to add your products to the cart and submit the required crackers through the enquiry button. We will contact you within 24 hrs and confirm the order through WhatsApp or phone call. Please add and submit your enquiries and enjoy your Diwali with FestiveKart. Our License No.---. FestiveKart as a company following 100% legal & statutory compliances and all our shops, go-downs are maintained as per the explosive acts. We send the parcels through registered and legal transport service providers as like every other major companies in Sivakasi is doing so.';
    final mapsUrl = cmsData['footer_maps_url'] ??
        'https://maps.google.com/?q=Parapatti,Sivakasi,TamilNadu';

    return Column(
      children: [
        // 1. Terms & Conditions Header Banner
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  Text(
                    "Terms & Conditions",
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, color: Colors.grey, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          termsText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. Main Footer Section (Golden-Orange Gradient from Screenshot)
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF78B1E), Color(0xFFFFC82C)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 48 : 20,
            vertical: 40,
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: isWeb
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Col 1: About Us & Follow Us
                        Expanded(flex: 3, child: _buildAboutCol(context, aboutUsText, mapsUrl)),
                        const SizedBox(width: 32),
                        // Col 2: Quick Links
                        Expanded(flex: 2, child: _buildQuickLinksCol(context)),
                        const SizedBox(width: 32),
                        // Col 3: Contact Info
                        Expanded(
                          flex: 3,
                          child: _buildContactInfoCol(
                            addressText,
                            phone1,
                            phone2,
                            phone3,
                            emailText,
                            mapsUrl,
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Col 4: Route Map
                        Expanded(flex: 3, child: _buildRouteMapCol(mapsUrl)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAboutCol(context, aboutUsText, mapsUrl),
                        const SizedBox(height: 28),
                        _buildQuickLinksCol(context),
                        const SizedBox(height: 28),
                        _buildContactInfoCol(
                          addressText,
                          phone1,
                          phone2,
                          phone3,
                          emailText,
                          mapsUrl,
                        ),
                        const SizedBox(height: 28),
                        _buildRouteMapCol(mapsUrl),
                      ],
                    ),
            ),
          ),
        ),

        // 3. Supreme Court Legal Compliance Footer Bar
        Container(
          width: double.infinity,
          color: const Color(0xFFD45D27), // Rust Orange Footer Accent Bar
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Text(
                disclaimerText,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.95),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Column 1: About Us & Follow Us
  Widget _buildAboutCol(BuildContext context, String aboutUsText, String mapsUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "About Us",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 12),
          width: 36,
          height: 2,
          color: Colors.white,
        ),
        Text(
          aboutUsText,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.white.withOpacity(0.95),
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Follow Us",
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Google Maps Icon
            InkWell(
              onTap: () => _launchUrl(mapsUrl),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Image.network(
                  "https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Google_Maps_icon_%282015-2020%29.svg/512px-Google_Maps_icon_%282015-2020%29.svg.png",
                  width: 20,
                  height: 20,
                  errorBuilder: (c, e, s) => const Icon(Icons.location_on, color: Colors.red, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Youtube Icon
            InkWell(
              onTap: () => _launchUrl("https://youtube.com"),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          "Download Mobile App",
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _downloadLatestApk(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.android, color: Color(0xFF3DDC84), size: 24),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "GET IT FOR",
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Android (.APK)",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Column 2: Quick Links
  Widget _buildQuickLinksCol(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Links",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 12),
          width: 36,
          height: 2,
          color: Colors.white,
        ),
        _linkItem("Home", () => onNavigateTab?.call(0)),
        _linkItem("Explore", () => onNavigateTab?.call(1)),
        _linkItem("Orders", () => onNavigateTab?.call(2)),
        _linkItem("Profile", () => onNavigateTab?.call(3)),
        _linkItem("About Us", () => _showCmsDialog(context, "About Us", "about_us")),
        _linkItem("Privacy Policy", () => _showCmsDialog(context, "Privacy Policy", "privacy_policy")),
        _linkItem("Help & Support", () => _showCmsDialog(context, "Help & Support", "help_support")),
      ],
    );
  }

  Widget _linkItem(String title, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.white.withOpacity(0.95),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Column 3: Contact Info
  Widget _buildContactInfoCol(
    String addressText,
    String phone1,
    String phone2,
    String phone3,
    String emailText,
    String mapsUrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Contact Info",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 12),
          width: 36,
          height: 2,
          color: Colors.white,
        ),
        if (addressText.isNotEmpty)
          _contactRow(
            Icons.near_me_outlined,
            addressText,
            onTap: () => _launchUrl(mapsUrl),
          ),
        if (phone1.isNotEmpty) ...[
          const SizedBox(height: 10),
          _contactRow(
            Icons.phone_android_rounded,
            phone1,
            onTap: () => _launchUrl("tel:${phone1.replaceAll(RegExp(r'[^\d+]'), '')}"),
          ),
          const SizedBox(height: 6),
          _contactRow(
            Icons.chat_bubble_rounded,
            "WhatsApp Support (9385757220)",
            onTap: () => WhatsAppHelper.launchGeneralChat(),
          ),
        ],
        if (phone2.isNotEmpty) ...[
          const SizedBox(height: 6),
          _contactRow(
            Icons.phone_android_rounded,
            phone2,
            onTap: () => _launchUrl("tel:${phone2.replaceAll(RegExp(r'[^\d+]'), '')}"),
          ),
        ],
        if (phone3.isNotEmpty) ...[
          const SizedBox(height: 6),
          _contactRow(
            Icons.phone_android_rounded,
            phone3,
            onTap: () => _launchUrl("tel:${phone3.replaceAll(RegExp(r'[^\d+]'), '')}"),
          ),
        ],
        if (emailText.isNotEmpty) ...[
          const SizedBox(height: 10),
          _contactRow(
            Icons.email_outlined,
            emailText,
            onTap: () => _launchUrl("mailto:${emailText.trim()}"),
          ),
        ],
      ],
    );
  }

  Widget _contactRow(IconData icon, String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: Colors.white.withOpacity(0.95),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Column 4: Route Map
  Widget _buildRouteMapCol(String mapsUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Route Map",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 12),
          width: 36,
          height: 2,
          color: Colors.white,
        ),
        InkWell(
          onTap: () => _launchUrl(mapsUrl),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              color: Colors.white,
            ),
            child: Stack(
              children: [
                // Map Preview Mock / Network Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(
                    "https://maps.googleapis.com/maps/api/staticmap?center=9.4533,77.7997&zoom=14&size=400x300&markers=color:red%7C9.4533,77.7997&key=AIzaSyA_mock",
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: const Color(0xFFE5DCD0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map_rounded, color: Colors.red, size: 36),
                            const SizedBox(height: 4),
                            Text(
                              "Sivakasi, Tamil Nadu",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // "Open in Maps ↗" Pill Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Open in Maps",
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A73E8),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.open_in_new, size: 10, color: Color(0xFF1A73E8)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
