import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021B4A),
      body: Stack(
        children: [
          // Background soft glow
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8C00).withOpacity(0.08),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          // Logo content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                // Glowing cart icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C00).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF8C00).withOpacity(0.25), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Color(0xFFFFD700),
                    size: 52,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "FestiveKart",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFFD700),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Light Up Happiness",
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(flex: 2),
                // Soft loading indicator
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C00)),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
