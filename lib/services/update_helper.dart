import 'package:flutter/material.dart';
import 'update_helper_mobile.dart' if (dart.library.html) 'update_helper_web.dart';

Future<void> downloadAndInstallApk(BuildContext context, String url) async {
  await downloadAndInstallApkPlatform(context, url);
}
