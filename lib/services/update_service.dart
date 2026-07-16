import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import 'update_helper.dart';

class UpdateService {
  static bool _hasChecked = false;

  static Future<void> checkForUpdate(BuildContext context) async {
    if (_hasChecked) return;
    _hasChecked = true;

    try {
      // 🔹 Get current version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 🔹 Call your API
      final response = await http.get(
        Uri.parse("${AppConstants.baseUrl}/api/update.json"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String latestVersion = data["version"];
        String apkUrl = data["apk_url"];
        bool forceUpdate = data["force_update"];

        print("[UPDATE] Current: $currentVersion | Server: $latestVersion");

        if (apkUrl.isNotEmpty && _isNewVersion(currentVersion, latestVersion)) {
          print("[UPDATE] New version found. Showing dialog.");
          if (context.mounted) {
            _showUpdateDialog(context, apkUrl, forceUpdate);
          }
        } else {
          print("[UPDATE] You are up to date.");
        }
      }

    } catch (e) {
      print("[UPDATE] Error checking update: $e");
    }
  }

  // 🔍 Version Compare
  static bool _isNewVersion(String current, String latest) {
    try {
      List<int> c = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      List<int> l = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();

      // Normalize lengths (e.g. 1.0 vs 1.0.1)
      while (c.length < l.length) c.add(0);
      while (l.length < c.length) l.add(0);

      for (int i = 0; i < l.length; i++) {
        if (l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
    } catch (e) {
      print("Version Compare Error: $e");
    }
    return false;
  }

  // 📢 Show Update Dialog
  static void _showUpdateDialog(
      BuildContext context, String apkUrl, bool forceUpdate) {

    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Available 🚀", 
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("A new version of FestiveKart is available. Please update to enjoy the latest features and fixes."),
            if (forceUpdate) ...[
              const SizedBox(height: 16),
              const Text("This is a mandatory update.", 
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
              ),
            ]
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Later"),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD45D27),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              downloadAndInstallApk(context, apkUrl);
            },
            child: const Text("Update Now"),
          ),
        ],
      ),
    );
  }
}
