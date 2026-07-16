import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> downloadAndInstallApkPlatform(BuildContext context, String url) async {
  try {
    // 🔐 Check for Install Permission (Android 8+)
    if (Platform.isAndroid) {
      var status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please allow 'Install Unknown Apps' for FestiveKart to continue.")),
          );
        }
        status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          throw Exception("Permission to install unknown apps is required to update.");
        }
      }
    }

    // 📂 Use cache directory for reliable FileProvider access
    final tempDir = await getTemporaryDirectory();
    final filePath = "${tempDir.path}/update.apk";

    // 🧹 Cleanup previous attempt
    final oldFile = File(filePath);
    if (await oldFile.exists()) await oldFile.delete();

    print("[UPDATE] Downloading to: $filePath");

    // Show a progress dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (progressContext) => const AlertDialog(
          title: Text("Downloading Update..."),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(color: Color(0xFFD45D27)),
              SizedBox(height: 16),
              Text("Please wait while we download the latest version."),
            ],
          ),
        ),
      );
    }

    Dio dio = Dio();
    await dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          print("Downloading: ${(received / total * 100).toStringAsFixed(0)}%");
        }
      },
    );

    // Verify download
    final downloadedFile = File(filePath);
    if (!(await downloadedFile.exists()) || (await downloadedFile.length()) == 0) {
      throw Exception("Download failed or file empty.");
    }

    // Close progress dialog
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    print("[UPDATE] Download complete. Opening installer...");
    
    // 📲 Open APK
    final result = await OpenFile.open(filePath);
    
    if (result.type != ResultType.done) {
      print("[UPDATE] Installer Error: ${result.message}");
      throw Exception("Installer failed: ${result.message}");
    }

  } catch (e) {
    print("[UPDATE] Failure: $e");
    if (context.mounted) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Installation failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
