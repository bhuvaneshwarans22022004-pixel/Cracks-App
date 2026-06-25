import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showLoginForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              painter: FireworksPainter(),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.05),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _showLoginForm ? _buildLoginForm(auth) : _buildWelcomeView(auth),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Welcome View (Matches Left Phone in Image)
  Widget _buildWelcomeView(AuthProvider auth) {
    return Column(
      key: const ValueKey('WelcomeView'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 15),

        // Gold FestiveKart Logo
        Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 70,
                  width: 70,
                  child: CustomPaint(
                    painter: LogoSparkPainter(),
                  ),
                ),
                const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFFFFD700),
                  size: 38,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "FestiveKart",
              style: GoogleFonts.outfit(
                color: const Color(0xFFFFD700),
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // Slogan text
        Text(
          "Light Up Happiness\nThis Diwali",
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFFFE082),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 20),

        // Vector Diya Lamp Centerpiece
        Stack(
          alignment: Alignment.center,
          children: [
            // Background glow effect
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            // Diya Oil Lamp Custom Painter
            Container(
              height: 150,
              width: 150,
              child: CustomPaint(
                painter: DiyaPainter(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),

        // Bottom Actions
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
            onPressed: () {
              setState(() {
                _showLoginForm = true;
              });
            },
            child: Text(
              "Login / Signup",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF9F1C), width: 1.5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              auth.loginAsGuest();
            },
            child: Text(
              "Browse as Guest",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 15),
      ],
    );
  }

  // Login Form View (Frosted Glass Purple Theme)
  Widget _buildLoginForm(AuthProvider auth) {
    return Column(
      key: const ValueKey('LoginFormView'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Back Button & Header Row
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {
                  _showLoginForm = false;
                });
              },
            ),
            const SizedBox(width: 8),
            Text(
              "Login",
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 35),

        // Email TextField (Frosted glass style)
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

        // Password TextField
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

        // Forgot Password link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              );
            },
            child: Text(
              "Forgot Password?",
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF9F1C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 15),

        // Login Submit Button
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
                    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill all fields")),
                      );
                      return;
                    }
                    final success = await auth.login(_emailController.text.trim(), _passwordController.text);
                    if (success && mounted) {
                      Provider.of<AddressProvider>(context, listen: false).fetchAddresses(auth.user!.token!);
                    } else if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Login Failed. Please check your credentials.")),
                      );
                    }
                  },
            child: auth.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Color(0xFF1E0A35), strokeWidth: 2.5),
                  )
                : Text(
                    "Login",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // Signup navigation link
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
          },
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(fontSize: 14),
              children: const [
                TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(color: Colors.white60),
                ),
                TextSpan(
                  text: "Sign Up",
                  style: TextStyle(
                    color: Color(0xFFFF9F1C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Background Fireworks Painter
class FireworksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.08)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    _drawBurst(canvas, Offset(size.width * 0.2, size.height * 0.15), 32, paint);
    _drawBurst(canvas, Offset(size.width * 0.8, size.height * 0.22), 42, paint);
    _drawBurst(canvas, Offset(size.width * 0.15, size.height * 0.55), 24, paint);
    _drawBurst(canvas, Offset(size.width * 0.85, size.height * 0.68), 38, paint);
  }

  void _drawBurst(Canvas canvas, Offset center, double radius, Paint paint) {
    const int rays = 12;
    for (int i = 0; i < rays; i++) {
      final double angle = (i * 2 * math.pi) / rays;
      final offsetStart = Offset(
        center.dx + (radius * 0.35) * math.cos(angle),
        center.dy + (radius * 0.35) * math.sin(angle),
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

// Sparklines Shooter for Logo
class LogoSparkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF9F1C)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2 - 8);
    final angles = [-1.57, -1.05, -2.09, -0.52, -2.62]; // Radians pointing upwards
    for (var angle in angles) {
      final start = Offset(
        center.dx + 12 * math.cos(angle),
        center.dy + 12 * math.sin(angle),
      );
      final end = Offset(
        center.dx + 22 * math.cos(angle),
        center.dy + 22 * math.sin(angle),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Diya oil lamp custom painter
class DiyaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Bowl Gradient fill (copper/gold styling)
    final bowlPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE5A93C), Color(0xFFB45309), Color(0xFF78350F)],
        stops: [0.0, 0.6, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(w * 0.1, h * 0.35, w * 0.8, h * 0.65))
      ..style = PaintingStyle.fill;

    // Create Diya bowl shape
    final path = Path()
      ..moveTo(w * 0.15, h * 0.5)
      ..quadraticBezierTo(w * 0.5, h * 0.42, w * 0.85, h * 0.5)
      ..quadraticBezierTo(w * 0.9, h * 0.62, w * 0.76, h * 0.8)
      ..quadraticBezierTo(w * 0.5, h * 0.96, w * 0.24, h * 0.8)
      ..quadraticBezierTo(w * 0.1, h * 0.62, w * 0.15, h * 0.5)
      ..close();

    canvas.drawPath(path, bowlPaint);

    // 2. Rim Highlight
    final rimPaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rimPath = Path()
      ..moveTo(w * 0.15, h * 0.5)
      ..quadraticBezierTo(w * 0.5, h * 0.42, w * 0.85, h * 0.5);
    canvas.drawPath(rimPath, rimPaint);

    // 3. Oil Lamp Flame (Glow & Core)
    final flameCenter = Offset(w * 0.5, h * 0.28);
    
    // Outer flame aura
    final outerFlamePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD000).withOpacity(0.9),
          const Color(0xFFFF7A00).withOpacity(0.5),
          const Color(0xFFFF2E00).withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: flameCenter, radius: w * 0.25))
      ..style = PaintingStyle.fill;

    final flamePath = Path()
      ..moveTo(w * 0.5, h * 0.1) // tip
      ..quadraticBezierTo(w * 0.63, h * 0.32, w * 0.5, h * 0.45) // right curve
      ..quadraticBezierTo(w * 0.37, h * 0.32, w * 0.5, h * 0.1) // left curve
      ..close();

    canvas.drawPath(flamePath, outerFlamePaint);

    // Inner bright white-yellow core
    final innerFlamePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          const Color(0xFFFFE082).withOpacity(0.9),
          const Color(0xFFFF9000).withOpacity(0.0),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: flameCenter, radius: w * 0.12))
      ..style = PaintingStyle.fill;

    final innerFlamePath = Path()
      ..moveTo(w * 0.5, h * 0.2)
      ..quadraticBezierTo(w * 0.56, h * 0.31, w * 0.5, h * 0.4)
      ..quadraticBezierTo(w * 0.44, h * 0.31, w * 0.5, h * 0.2)
      ..close();

    canvas.drawPath(innerFlamePath, innerFlamePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
