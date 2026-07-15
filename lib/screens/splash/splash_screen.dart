import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021B4A),
      body: Stack(
        children: [
          // Full screen premium splash image with fireworks & logo branding
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Safe fallback in case image file hasn't been copied yet
                return Container(
                  color: const Color(0xFF021B4A),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF8C00),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Loading spinner near the bottom
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C00)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
