import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Animate gradient color change for parallax feel
  final List<List<Color>> gradients = [
    [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
    [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
    [Color(0xFF4FC3F7), Color(0xFF039BE5)],
    [Color(0xFF0288D1), Color(0xFFB3E5FC)],
  ];

  final List<Map<String, String>> pages = [
    {
      'title': 'Welcome to ToTepAI',
      'desc':
          'An intelligent system designed to classify Bangus by weight and forecast harvest using AI and Arduino-powered technology.',
      'img': 'assets/images/icon.png',
    },
    {
      'title': 'Smart Fish Classification',
      'desc':
          'Using sensors and the Gemini AI model, ToTepAI automatically sorts Bangus based on their weight with high precision.',
      'img': 'assets/images/image1.png',
    },
    {
      'title': 'Accurate Harvest Forecasting',
      'desc':
          'Predict your harvest time and yield efficiently through intelligent forecasting to improve farm productivity.',
      'img': 'assets/images/images2.png',
    },
    {
      'title': 'Empowering Bangus Farmers',
      'desc':
          'Save time, reduce errors, and make data-driven farming decisions with the power of ToTepAI’s smart automation.',
      'img': 'assets/images/image3.png',
    },
  ];

  void _nextPage() {
    if (_currentIndex < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 900),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradients[_currentIndex],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                      horizontal: 30,
                      vertical: 50,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hero image with fade-in and scale
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.7, end: 1.0),
                          duration: Duration(milliseconds: 700),
                          builder: (context, val, child) => Transform.scale(
                            scale: val,
                            child: Opacity(
                              opacity: val,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(
                                        0.12,
                                      ),
                                      blurRadius: 18,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    page['img']!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Animated title with typewriter effect
                        AnimatedTextKit(
                          isRepeatingAnimation: false,
                          animatedTexts: [
                            TypewriterAnimatedText(
                              page['title']!,
                              textStyle: GoogleFonts.rowdies(
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 1.5,
                              ),
                              speed: Duration(milliseconds: 70),
                              cursor: '|',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Description with fade-in effect
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 900),
                          builder: (context, val, child) =>
                              Opacity(opacity: val, child: child),
                          child: Text(
                            page['desc']!,
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w400,
                              fontSize: 17,
                              color: Colors.black.withOpacity(0.78),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dot indicators with scale animation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: Duration(milliseconds: 350),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: _currentIndex == index ? 27 : 10,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? Colors.blueAccent
                        : Colors.grey[350],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // "Next" or "Get Started" button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.94),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 57,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 6,
                ),
                onPressed: _nextPage,
                child: Text(
                  _currentIndex == pages.length - 1 ? 'Get Started' : 'Next',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
