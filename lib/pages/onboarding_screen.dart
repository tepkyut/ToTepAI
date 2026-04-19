import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/translation_service.dart';
import '../services/language_persistence.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  String _selectedLanguage = 'Kamayo';

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await LanguagePersistence.getLanguage();
    setState(() {
      _selectedLanguage = savedLanguage;
    });
  }

  Widget _buildCompactLanguageSelector() {
    return OutlinedButton.icon(
      onPressed: () => _showLanguageDialog(),
      icon: const Icon(
        Icons.language_rounded,
        size: 14,
        color: Colors.white,
      ),
      label: Text(
        _selectedLanguage,
        // TranslationService.getTranslationSync('select_language', _selectedLanguage),
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white70),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: const Color(0xFF0981D1),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0981D1),
                const Color(0xFF00AEEF),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                TranslationService.getTranslationSync('select_language', _selectedLanguage),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...TranslationService.getSupportedLanguages().map((language) => 
                _buildLanguageOption(language)
              ).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    final bool isSelected = _selectedLanguage == language;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLanguage = language;
          });
          LanguagePersistence.saveLanguage(language); // Save the language
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? Colors.white.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            language,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: isSelected 
                  ? FontWeight.w700 
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentIndex < 4 - 1) {
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
                      TranslationService.getTranslationSync('skip', _selectedLanguage),
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
                itemCount: 4,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final titles = [
                    TranslationService.getTranslationSync('welcome', _selectedLanguage),
                    TranslationService.getTranslationSync('classification', _selectedLanguage),
                    TranslationService.getTranslationSync('forecasting', _selectedLanguage),
                    TranslationService.getTranslationSync('empowering', _selectedLanguage),
                  ];
                  final descriptions = [
                    TranslationService.getTranslationSync('desc', _selectedLanguage),
                    TranslationService.getTranslationSync('classification_desc', _selectedLanguage),
                    TranslationService.getTranslationSync('forecasting_desc', _selectedLanguage),
                    TranslationService.getTranslationSync('empowering_desc', _selectedLanguage),
                  ];
                  final images = [
                    'assets/images/image2.png',
                    'assets/images/classification.png',
                    'assets/images/forecast.png',
                    'assets/images/Farmers.png',
                  ];
                  
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final Orientation orientation =
                          MediaQuery.of(context).orientation;
                      final bool isLandscape =
                          orientation == Orientation.landscape;
                      final double imageSize = ((isLandscape
                                  ? constraints.maxHeight * 0.95
                                  : constraints.maxWidth * 0.82)
                              .clamp(240.0, 520.0))
                          .toDouble();
                      final EdgeInsets contentPadding = EdgeInsets.symmetric(
                        horizontal: isLandscape ? 24 : 24,
                        vertical: isLandscape ? 8 : 12,
                      );

                      final titleWidget = Text(
                        titles[index],
                        textAlign: isLandscape ? TextAlign.left : TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: isLandscape ? 29 : 28,
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
                      );

                      final descWidget = Text(
                        descriptions[index],
                        textAlign: isLandscape ? TextAlign.left : TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: isLandscape ? 17 : 13,
                          height: 1.65,
                          fontWeight: FontWeight.w500,
                        ),
                      );

                      final descContainer = Align(
                        alignment:
                            isLandscape ? Alignment.centerLeft : Alignment.center,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isLandscape
                                ? constraints.maxWidth * 0.5
                                : constraints.maxWidth * 0.88,
                          ),
                          child: descWidget,
                        ),
                      );

                      final Widget textSection = Column(
                        crossAxisAlignment: isLandscape
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          titleWidget,
                          const SizedBox(height: 18),
                          descContainer,
                        ],
                      );

                      final illustration = Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            duration: const Duration(milliseconds: 600),
                            scale: _currentIndex == index ? 1.0 : 0.96,
                            child: Image.asset(
                              images[index],
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: imageSize * 0.68,
                            height: 16,
                          ),
                        ],
                      );

                      final Widget body = isLandscape
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 32),
                                    child: textSection,
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: illustration,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 12),
                                textSection,
                                const SizedBox(height: 28),
                                illustration,
                              ],
                            );

                      return SingleChildScrollView(
                        padding: contentPadding,
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Align(
                            alignment: isLandscape
                                ? Alignment.centerLeft
                                : Alignment.topCenter,
                            child: body,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 1),
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
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
            const SizedBox(height: 1),
            // Bottom navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  // Language selector (only on first page)
                  if (_currentIndex == 0) ...[
                    _buildCompactLanguageSelector(),
                    const SizedBox(width: 12),
                  ],
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
                      _currentIndex == 4 - 1
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _currentIndex == 4 - 1
                          ? TranslationService.getTranslationSync('get_started', _selectedLanguage)
                          : TranslationService.getTranslationSync('continue', _selectedLanguage),
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
