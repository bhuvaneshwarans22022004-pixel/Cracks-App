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

    double progress = 0.0;
    StateSetter? dialogSetState;

    // Show a progress dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (progressContext) => StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                "Downloading Update...",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      color: const Color(0xFFD45D27),
                      backgroundColor: Colors.grey[200],
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Please wait...",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      Text(
                        "${(progress * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          color: Color(0xFFD45D27),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    Dio dio = Dio();
    await dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final newProgress = received / total;
          if (dialogSetState != null) {
            dialogSetState!(() {
              progress = newProgress;
            });
          }
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
