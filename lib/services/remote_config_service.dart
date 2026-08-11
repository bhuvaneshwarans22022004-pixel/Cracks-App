import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../utils/constants.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      // 1. Ensure Firebase is initialized
      bool isInitialized = false;
      try {
        isInitialized = Firebase.apps.isNotEmpty;
      } catch (_) {
        isInitialized = false;
      }

      if (!isInitialized) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyAk8s3xuL_jO5NZAygrWImiO8tfyNU7XYQ",
            appId: kIsWeb
                ? "1:734262498360:web:c73f1f1053f1f615bf82cd"
                : "1:734262498360:android:6eeb3a130fc5fac0bf82cd",
            messagingSenderId: "734262498360",
            projectId: "festivekart-101",
            storageBucket: "festivekart-101.firebasestorage.app",
          ),
        );
      }

      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

      // 2. Set Remote Config configuration
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(seconds: 0), // Enable instant fetch
      ));

      // 3. Set local fallback defaults
      await remoteConfig.setDefaults(<String, dynamic>{
        'base_url': AppConstants.baseUrl,
        'whatsapp_number': AppConstants.whatsappNumber,
        'upi_id': AppConstants.upiId,
        'gpay_number': AppConstants.gpayNumber,
      });

      // 4. Fetch from Firebase and activate
      bool activated = await remoteConfig.fetchAndActivate();
      log('Remote Config activated. Dynamic fetch result: $activated');

      // 5. Update runtime constants
      _updateConstants(remoteConfig);
      _isInitialized = true;

      // 6. Listen for real-time Remote Config updates
      if (!kIsWeb) {
        remoteConfig.onConfigUpdated.listen((event) async {
          try {
            await remoteConfig.activate();
            _updateConstants(remoteConfig);
            log('Remote Config values dynamically updated in real-time!');
          } catch (err) {
            log('Error activating real-time Remote Config updates: $err');
          }
        });
      }
    } catch (e) {
      log('Error initializing Firebase Remote Config: $e. Using offline defaults.');
    }
  }

  void _updateConstants(FirebaseRemoteConfig remoteConfig) {
    final remoteBaseUrl = remoteConfig.getString('base_url');
    final remoteWhatsapp = remoteConfig.getString('whatsapp_number');
    final remoteUpiId = remoteConfig.getString('upi_id');
    final remoteGpayNumber = remoteConfig.getString('gpay_number');

    if (remoteBaseUrl.isNotEmpty) {
      AppConstants.baseUrl = remoteBaseUrl;
      log('Applied Remote Config base_url: $remoteBaseUrl');
    }
    if (remoteWhatsapp.isNotEmpty) {
      AppConstants.whatsappNumber = remoteWhatsapp;
      log('Applied Remote Config whatsapp_number: $remoteWhatsapp');
    }
    if (remoteUpiId.isNotEmpty) {
      AppConstants.upiId = remoteUpiId;
      log('Applied Remote Config upi_id: $remoteUpiId');
    }
    if (remoteGpayNumber.isNotEmpty) {
      AppConstants.gpayNumber = remoteGpayNumber;
      log('Applied Remote Config gpay_number: $remoteGpayNumber');
    }
  }
}
