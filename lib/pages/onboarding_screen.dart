import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<List<Color>> gradients = [
    [const Color(0xFFB3E5FC), const Color(0xFFE1F5FE)],
    [const Color(0xFF81D4FA), const Color(0xFFB3E5FC)],
    [const Color(0xFF4FC3F7), const Color(0xFF039BE5)],
    [const Color(0xFF0288D1), const Color(0xFFB3E5FC)],
  ];

  final List<Map<String, String>> pages = [
    {
      'title': 'Welcome to ToTepAI',
      'desc':
          'An Intelligent system for bangus size classification and harvest forcasting using Gemini model and Arduino-Powered Segregation.',
      'img': 'assets/images/logo.png',
    },
    {
      'title': 'Smart Fish Classification',
      'desc':
          'Using sensors and the Gemini AI model, ToTepAI automatically sorts Bangus based on their weight with high precision.',
      'img': 'assets/images/classification1.png',
    },
    {
      'title': 'Accurate Harvest Forecasting',
      'desc':
          'Predict your harvest time and yield efficiently through intelligent forecasting to improve farm productivity.',
      'img': 'assets/images/forecasting1.png',
    },
    {
      'title': 'Empowering Bangus Farmers',
      'desc':
          'Save time, reduce errors, and make data-driven farming decisions with ToTepAI’s smart automation.',
      'img': 'assets/images/forecasting.png',
    },
  ];

  void _nextPage() {
    if (_currentIndex < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00AEEF),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar with Skip
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 26,
                              height: 26,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'ToTepAI',
                            style: GoogleFonts.alfaSlabOne(
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 50),
                            Text(
                              page['title']!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                letterSpacing: 0.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.08),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            Text(
                              page['desc']!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withOpacity(0.91),
                                fontSize: 16,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AnimatedScale(
                                    duration: const Duration(milliseconds: 600),
                                    scale: _currentIndex == index ? 1.0 : 0.96,
                                    child: Image.asset(
                                      page['img']!,
                                      width: 290,
                                      height: 290,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Small base shadow to ground the illustration
                                  Container(
                                    width: 180,
                                    height: 14,
                                    // decoration: BoxDecoration(
                                    //   color: Colors.black.withOpacity(0.12),
                                    //   borderRadius: BorderRadius.circular(999),
                                    //   // boxShadow: [
                                    //   //   BoxShadow(
                                    //   //     color: Colors.black.withOpacity(0.18),
                                    //   //     blurRadius: 16,
                                    //   //     spreadRadius: 0,
                                    //   //     offset: const Offset(0, 3),
                                    //   //   ),
                                    //   // ],
                                    // ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Dots indicator (restored) — progress line remains removed
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: 10,
                      width: _currentIndex == index ? 26 : 10,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Bottom navigation buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _nextPage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          padding: const EdgeInsets.symmetric(
                             horizontal: 18,
                             vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        icon: Icon(
                          _currentIndex == pages.length - 1
                              ? Icons.rocket_launch_rounded
                              : Icons.arrow_forward_rounded,
                           size: 18,
                        ),
                        label: Text(
                          _currentIndex == pages.length - 1
                              ? 'Get Started'
                              : 'Continue',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                             color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _ModernAnimatedBackground extends StatefulWidget {
  const _ModernAnimatedBackground();

  @override
  State<_ModernAnimatedBackground> createState() =>
      _ModernAnimatedBackgroundState();
}

class _ModernAnimatedBackgroundState extends State<_ModernAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final double w = constraints.maxWidth;
              final double h = constraints.maxHeight;
              final double t = _controller.value;
              final double twoPi = 2 * math.pi;

              // Smooth oscillations for blob centers
              final double x1 = w * 0.25 + 40 * math.sin(twoPi * (t + 0.00));
              final double y1 = h * 0.25 + 28 * math.cos(twoPi * (t + 0.10));
              final double x2 = w * 0.80 + 36 * math.cos(twoPi * (t + 0.25));
              final double y2 = h * 0.30 + 30 * math.sin(twoPi * (t + 0.30));
              final double x3 = w * 0.15 + 32 * math.sin(twoPi * (t + 0.55));
              final double y3 = h * 0.75 + 26 * math.cos(twoPi * (t + 0.65));

              return Stack(
                children: [
                  // Blob 1 - cyan/blue
                  Positioned(
                    left: x1 - 180,
                    top: y1 - 180,
                    child: _BlurredRadialBlob(
                      diameter: 360,
                      colors: const [Color(0xFF22D3EE), Color(0xFF3B82F6)],
                      opacity: 0.30,
                    ),
                  ),
                  // Blob 2 - violet/pink
                  Positioned(
                    left: x2 - 140,
                    top: y2 - 140,
                    child: _BlurredRadialBlob(
                      diameter: 280,
                      colors: const [Color(0xFFA78BFA), Color(0xFFF472B6)],
                      opacity: 0.28,
                    ),
                  ),
                  // Blob 3 - teal/green
                  Positioned(
                    left: x3 - 160,
                    top: y3 - 160,
                    child: _BlurredRadialBlob(
                      diameter: 320,
                      colors: const [Color(0xFF34D399), Color(0xFF10B981)],
                      opacity: 0.25,
                    ),
                  ),
                  // Soft vignette and subtle texture overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.10),
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.06),
                            Colors.white.withOpacity(0.10),
                          ],
                          stops: const [0.0, 0.4, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BlurredRadialBlob extends StatelessWidget {
  const _BlurredRadialBlob({
    required this.diameter,
    required this.colors,
    this.opacity = 0.3,
  });

  final double diameter;
  final List<Color> colors;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: colors,
                center: Alignment.center,
                radius: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
