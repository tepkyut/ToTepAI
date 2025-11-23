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

  final List<Map<String, String>> pages = [
    {
      'title': 'Welcome to ToTepAI',
      'desc':
          'An Intelligent system for bangus size classification and harvest forcasting using Gemini model and Arduino-Powered Segregation.',
      'img': 'assets/images/image2.png',
    },
    {
      'title': 'Smart Fish Classification',
      'desc':
          'Using sensors and the Gemini AI model, ToTepAI automatically sorts Bangus based on their weight with high precision.',
      'img': 'assets/images/classification.png',
    },
    {
      'title': 'Accurate Harvest Forecasting',
      'desc':
          'Predict your harvest time and yield efficiently through intelligent forecasting to improve farm productivity.',
      'img': 'assets/images/forecast.png',
    },
    {
      'title': 'Empowering Bangus Farmers',
      'desc':
          'Save time, reduce errors, and make data-driven farming decisions with ToTepAI’s smart automation.',
      'img': 'assets/images/Farmers.png',
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
      backgroundColor: const Color(0xFF0981D1),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 56,
                          height: 56,
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
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
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
                              Container(width: 180, height: 14),
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
            // Dots indicator
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      ),
    );
  }
}
