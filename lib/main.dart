import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/wishlist_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'providers/cms_provider.dart';
import 'providers/banner_provider.dart';
import 'providers/address_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'utils/theme.dart';
import 'utils/app_scroll_behavior.dart';
import 'services/remote_config_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => CmsProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
      ],
      child: const FestiveKartApp(),
    ),
  );
}

class FestiveKartApp extends StatelessWidget {
  const FestiveKartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'FestiveKart',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          scrollBehavior: AppScrollBehavior(),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<List<Object?>> _initializationFuture;

  Future<void> _initializeFirebaseAndConfig() async {
    try {
      bool isInitialized = Firebase.apps.isNotEmpty;
      if (!isInitialized) {
        if (kIsWeb) {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: "AIzaSyBkVKhTQyRBnmgU3sKmjsnKRyLalRQc8QQ",
              authDomain: "festivekart-101.firebaseapp.com",
              appId: "1:734262498360:web:c73f1f1053f1f615bf82cd",
              messagingSenderId: "734262498360",
              projectId: "festivekart-101",
              storageBucket: "festivekart-101.firebasestorage.app",
              measurementId: "G-S8VHK4MQ9B",
            ),
          );
        } else {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: "AIzaSyAk8s3xuL_jO5NZAygrWImiO8tfyNU7XYQ",
              appId: "1:734262498360:android:6eeb3a130fc5fac0bf82cd",
              messagingSenderId: "734262498360",
              projectId: "festivekart-101",
              storageBucket: "festivekart-101.firebasestorage.app",
            ),
          );
        }
      }
    } catch (e) {
      print("Firebase initialization error: $e");
    }
    await RemoteConfigService().initialize();
  }

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeFirebaseAndConfig().then((_) {
      return Future.wait([
        Provider.of<AuthProvider>(context, listen: false).tryAutoLogin().then((loggedIn) {
          if (loggedIn) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (auth.user != null && auth.user!.token != null) {
              Provider.of<AddressProvider>(context, listen: false).fetchAddresses(auth.user!.token!);
              Provider.of<WishlistProvider>(context, listen: false).fetchWishlist(auth.user!.token!);
            }
          }
          return loggedIn;
        }),
        Future.delayed(const Duration(milliseconds: 2000)), // Snappy transition timing
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object?>>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        return Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
          },
        );
      },
    );
  }
}
