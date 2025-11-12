import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Single-tone accent color for minimalist look
  static const Color _mono = Color(0xFF111827); // near-black slate
  static const Color _background = Color(0xFF00AEEF);

  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  bool _showText = false;
  bool _fadeOut = false;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _scaleAnimation = Tween(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Logo animation first
    _logoController.forward().whenComplete(() {
      if (!mounted) return;
      setState(() {
        _showText = true;
      });
    });

    // Go to onboarding
    _navigationTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _fadeOut = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/onboarding');
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: AnimatedOpacity(
        opacity: _fadeOut ? 0 : 1,
        duration: const Duration(milliseconds: 600),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo: original, no circle, no tint
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 220,
                          height: 220,
                          alignment: Alignment.center,
                          color: Colors.white,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: _mono.withOpacity(0.4),
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Wordmark only (tagline removed for minimal look)
                  if (_showText)
                    FadeIn(
                      child: Text(
                        'ToTepAI',
                        style: GoogleFonts.alfaSlabOne(
                          color: Colors.white,
                          fontSize: 46,
                          letterSpacing: 0.6,
                          height: 1.05,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.08),
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      delay: const Duration(milliseconds: 50),
                    ),
                ],
              ),
            ),
          ),
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
      duration: const Duration(milliseconds: 600),
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

// End of file
