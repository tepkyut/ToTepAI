import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  bool _showText = false;
  bool _fadeOut = false;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _scaleAnimation = Tween(begin: 1.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Logo animation first
    _logoController.forward().whenComplete(() {
      setState(() {
        _showText = true;
      });
    });

    // Go to onboarding
    Timer(const Duration(seconds: 7), () {
      setState(() {
        _fadeOut = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        opacity: _fadeOut ? 0 : 1,
        duration: const Duration(milliseconds: 500),
        child: Stack(
          children: [
            // Gradient + bubbles
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: GradientBubblesPainter(),
            ),

            // Centered content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo zoom animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 180,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Proper Typewriter effect
                  if (_showText)
                    AnimatedTextKit(
                      isRepeatingAnimation: false,
                      animatedTexts: [
                        TypewriterAnimatedText(
                          'ToTepAI',
                          textStyle: GoogleFonts.rowdies(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              const Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          speed: const Duration(milliseconds: 170),
                          cursor: '|',
                        ),
                      ],
                      totalRepeatCount: 1,
                      pause: const Duration(milliseconds: 300),
                      displayFullTextOnTap: true,
                      stopPauseOnTap: true,
                    ),
                ],
              ),
            ),
            // Credits/affiliation at bottom
          ],
        ),
      ),
    );
  }
}

// Custom FadeIn Widget for smooth subtitle animation
class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeIn({Key? key, required this.child, this.delay = Duration.zero})
    : super(key: key);

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

// Enhanced Gradient background with faint bubbles
class GradientBubblesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gradient
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Gradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
    );
    final Paint paint = Paint()..shader = gradient.createShader(rect);

    // Draw gradient curve
    Path bluePath = Path();
    bluePath.lineTo(0, size.height * 0.6);
    bluePath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.8,
      size.width,
      size.height * 0.6,
    );
    bluePath.lineTo(size.width, 0);
    bluePath.close();
    canvas.drawPath(bluePath, paint);

    // Bubbles
    var bubblePaint = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..style = PaintingStyle.fill;
    final random = Random(1); // Fixed seed, consistent pattern

    for (int i = 0; i < 10; i++) {
      final bubbleRadius = random.nextDouble() * 28 + 10;
      final bubbleX = random.nextDouble() * size.width;
      final bubbleY =
          size.height * 0.62 + random.nextDouble() * size.height * 0.27;
      canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleRadius, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
