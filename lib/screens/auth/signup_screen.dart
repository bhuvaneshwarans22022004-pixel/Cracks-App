import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Dark Purple/Indigo Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1C0A35),
                  Color(0xFF0F041C),
                ],
              ),
            ),
          ),

          // 2. Decorative Fireworks Background Painter
          Positioned.fill(
            child: CustomPaint(
              painter: SignupFireworksPainter(),
            ),
          ),

          // 3. Main Form
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 15),

                      Text(
                        "Join FestiveKart",
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Create an account to track orders and save your favorites.",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 35),

                      // Name Field
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Full Name",
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFFF9F1C)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFFF9F1C), width: 1.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Email Address",
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFF9F1C)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFFF9F1C), width: 1.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Phone Field
                      TextField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Phone Number",
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFFFF9F1C)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFFF9F1C), width: 1.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFF9F1C)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFFF9F1C), width: 1.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9F1C),
                            foregroundColor: const Color(0xFF1E0A35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  if (_nameController.text.trim().isEmpty ||
                                      _emailController.text.trim().isEmpty ||
                                      _passwordController.text.isEmpty ||
                                      _phoneController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please fill all fields")),
                                    );
                                    return;
                                  }

                                  final success = await auth.register(
                                    _nameController.text.trim(),
                                    _emailController.text.trim(),
                                    _passwordController.text,
                                    _phoneController.text.trim(),
                                  );

                                  if (success) {
                                    if (mounted) {
                                      Provider.of<AddressProvider>(context, listen: false).fetchAddresses(auth.user!.token!);
                                      Navigator.pop(context);
                                    }
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Registration failed. Please try again.")),
                                      );
                                    }
                                  }
                                },
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1E0A35)),
                                )
                              : Text(
                                  "Create Account",
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Background Fireworks Painter for Sign Up Screen
class SignupFireworksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.06)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    _drawBurst(canvas, Offset(size.width * 0.15, size.height * 0.1), 26, paint);
    _drawBurst(canvas, Offset(size.width * 0.85, size.height * 0.25), 34, paint);
    _drawBurst(canvas, Offset(size.width * 0.2, size.height * 0.75), 30, paint);
  }

  void _drawBurst(Canvas canvas, Offset center, double radius, Paint paint) {
    const int rays = 10;
    for (int i = 0; i < rays; i++) {
      final double angle = (i * 2 * math.pi) / rays;
      final offsetStart = Offset(
        center.dx + (radius * 0.4) * math.cos(angle),
        center.dy + (radius * 0.4) * math.sin(angle),
      );
      final offsetEnd = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(offsetStart, offsetEnd, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
