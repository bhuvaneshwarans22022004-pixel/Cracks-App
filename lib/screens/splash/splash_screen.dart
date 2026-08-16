import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fireworksController;
  late AnimationController _pulseController;
  late AnimationController _logoEntranceController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _pulseScale;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Fireworks & sparklers continuous loop (3.2 seconds cycle)
    _fireworksController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    // 2. Subtle pulse loop for central logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.98, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 3. Entrance animation for logo & text
    _logoEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = CurvedAnimation(
      parent: _logoEntranceController,
      curve: Curves.elasticOut,
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoEntranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.45),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoEntranceController,
      curve: const Interval(0.3, 0.85, curve: Curves.easeOutBack),
    ));

    _logoEntranceController.forward();
  }

  @override
  void dispose() {
    _fireworksController.dispose();
    _pulseController.dispose();
    _logoEntranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    // 1. Build the animated branding widget (Logo + Titles)
    Widget brandingWidget = AnimatedBuilder(
      animation: _logoEntranceController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: ScaleTransition(
              scale: _pulseScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing Emblem Container
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Pulsing Glow Aura
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8C00).withOpacity(0.55),
                              blurRadius: 50,
                              spreadRadius: 15,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.35),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),

                      // Inner Circle containing logo.png
                      Container(
                        width: 105,
                        height: 105,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.95),
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF8C00).withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Transform.scale(
                            scale: 2.2,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Brand Title: FestiveKart with Slide-up and Gradient Shimmer Style
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFFFD700),
                          Color(0xFFFF9F1C),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: Text(
                        "FestiveKart",
                        style: GoogleFonts.outfit(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle Badge with Golden Accent
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.14),
                          Colors.white.withOpacity(0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withOpacity(0.55),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          "A COMPLETE FESTIVAL NEEDS",
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFFE082),
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // 2. Build the animated loading widget (Spinner + Status text)
    Widget loaderWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2.8,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9F1C)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "PREPARING FESTIVE SELECTIONS",
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: Colors.white.withOpacity(0.75),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF02091D),
      body: Stack(
        children: [
          // Background Radial Midnight Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.3,
                  colors: [
                    Color(0xFF0F2B66),
                    Color(0xFF051336),
                    Color(0xFF02091D),
                  ],
                ),
              ),
            ),
          ),

          // Animated Rocket Launch & Sky Fireworks Starbursts
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fireworksController,
              builder: (context, child) {
                return CustomPaint(
                  painter: PremiumFireworksPainter(
                    progress: _fireworksController.value,
                  ),
                );
              },
            ),
          ),

          // Responsive Layout Switcher
          Positioned.fill(
            child: isLandscape
                ? Row(
                    children: [
                      // Left Half: Show the Family Illustration (Full Image Card)
                      Expanded(
                        flex: 6,
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/family_diwali_splash.jpg',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Right Half: Flutter-native branding & loader
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                brandingWidget,
                                const SizedBox(height: 50),
                                loaderWidget,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      // Mobile: Family Illustration (Bottom 42% height, fit and fade top)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: screenSize.height * 0.42,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                              Colors.black,
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ).createShader(bounds),
                          blendMode: BlendMode.dstIn,
                          child: Image.asset(
                            'assets/images/family_diwali_splash.jpg',
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),

                      // Mobile: Branding in the top half (no overlap!)
                      Positioned(
                        top: screenSize.height * 0.08,
                        left: 0,
                        right: 0,
                        height: screenSize.height * 0.44,
                        child: Center(child: brandingWidget),
                      ),

                      // Mobile: Loader in the middle space
                      Positioned(
                        bottom: screenSize.height * 0.44,
                        left: 0,
                        right: 0,
                        child: Center(child: loaderWidget),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// Master Custom Painter for Rocket Launch, Fireworks Starbursts & Shockwaves
class PremiumFireworksPainter extends CustomPainter {
  final double progress;
  PremiumFireworksPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(12345);

    // 1. Draw Floating Background Ambient Stars
    final ambientPaint = Paint()..color = Colors.white.withOpacity(0.4);
    for (int i = 0; i < 40; i++) {
      final x = (rand.nextDouble() * size.width);
      final y = (rand.nextDouble() * size.height);
      final alpha = 0.2 + (sin((progress * 2 * pi) + i) + 1.0) * 0.35;
      ambientPaint.color = Colors.white.withOpacity(alpha.clamp(0.0, 0.8));
      canvas.drawCircle(Offset(x, y), rand.nextDouble() * 1.8 + 0.5, ambientPaint);
    }

    // 5 Distinct Fireworks Burst Locations
    final burstLocations = [
      Offset(size.width * 0.22, size.height * 0.22),
      Offset(size.width * 0.78, size.height * 0.28),
      Offset(size.width * 0.50, size.height * 0.18),
      Offset(size.width * 0.85, size.height * 0.48),
      Offset(size.width * 0.15, size.height * 0.52),
    ];

    final colorPalettes = [
      [const Color(0xFFFFD700), const Color(0xFFFF8C00), const Color(0xFFFF3D00)], // Gold & Fire
      [const Color(0xFF00E676), const Color(0xFF00B0FF), const Color(0xFFE040FB)], // Neon Violet Green
      [const Color(0xFFFF1744), const Color(0xFFFFEA00), const Color(0xFFFF9100)], // Crimson Yellow
      [const Color(0xFF7C4DFF), const Color(0xFFFF4081), const Color(0xFF00E5FF)], // Pink Purple Cyan
      [const Color(0xFFFFD700), const Color(0xFFFFFFFF), const Color(0xFFFF6D00)], // Bright Gold White
    ];

    for (int b = 0; b < burstLocations.length; b++) {
      final target = burstLocations[b];
      final offsetPhase = (progress + (b * 0.2)) % 1.0;
      final palette = colorPalettes[b % colorPalettes.length];

      // Rocket Ascent Phase (0.0 to 0.35)
      if (offsetPhase < 0.35) {
        final rocketProgress = offsetPhase / 0.35;
        final startY = size.height + 20;
        final currentY = startY - (startY - target.dy) * rocketProgress;
        final currentX = target.dx;

        // Draw Rocket Spark Tail
        final tailPaint = Paint()
          ..color = palette[0].withOpacity(0.9)
          ..strokeWidth = 2.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

        canvas.drawLine(
          Offset(currentX, currentY),
          Offset(currentX, currentY + 30 * (1 - rocketProgress)),
          tailPaint,
        );

        // Rocket head spark
        canvas.drawCircle(Offset(currentX, currentY), 3.0, Paint()..color = Colors.white);
      } else {
        // Explosion Phase (0.35 to 1.0)
        final explodeProgress = (offsetPhase - 0.35) / 0.65;
        final fadeOpacity = (1.0 - explodeProgress).clamp(0.0, 1.0);

        // A. Draw Shockwave Expansion Ring
        final ringRadius = explodeProgress * 90;
        final ringPaint = Paint()
          ..color = palette[0].withOpacity((fadeOpacity * 0.4).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * fadeOpacity
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6);
        canvas.drawCircle(target, ringRadius, ringPaint);

        // B. Draw Starburst Rays / Particles
        const particlesPerBurst = 36;
        for (int p = 0; p < particlesPerBurst; p++) {
          final angle = (p * (2 * pi / particlesPerBurst)) + (b * 0.4);
          final distance = explodeProgress * (90 + (p % 4) * 20);
          final gravity = explodeProgress * explodeProgress * 35; // realistic falling physics

          final px = target.dx + cos(angle) * distance;
          final py = target.dy + sin(angle) * distance + gravity;

          final color = palette[p % palette.length].withOpacity(fadeOpacity);

          // Glowing Core Spark
          final sparkPaint = Paint()
            ..color = color
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

          canvas.drawCircle(Offset(px, py), (1.0 - explodeProgress) * 3.5 + 1.2, sparkPaint);

          // Bright center white dot for extra sparkle
          if (p % 2 == 0) {
            canvas.drawCircle(Offset(px, py), 1.0, Paint()..color = Colors.white.withOpacity(fadeOpacity));
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant PremiumFireworksPainter oldDelegate) => true;
}
