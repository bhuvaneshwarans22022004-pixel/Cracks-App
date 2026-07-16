import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> downloadAndInstallApkPlatform(BuildContext context, String url) async {
  try {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("Could not download update: Browser blocked URL launch.");
    }
  } catch (e) {
    print("[UPDATE] Web download failed: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Web download failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
