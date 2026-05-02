import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:totepai/pages/authentications/login.dart';
import 'package:totepai/pages/authentications/register.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:totepai/utils/responsive.dart';
import 'package:totepai/services/translation_service.dart';
import 'package:totepai/services/language_persistence.dart';

class AuthPage extends StatefulWidget {
  final bool showLogin;
  final bool showToggleButtons;
  
  const AuthPage({super.key, this.showLogin = true, this.showToggleButtons = true});

  @override
  AuthPageState createState() => AuthPageState();
}

class AuthPageState extends State<AuthPage> {
  bool isLoginSelected = true;
  String _currentLanguage = 'English';

  @override
  void initState() {
    super.initState();
    isLoginSelected = widget.showLogin;
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final savedLanguage = await LanguagePersistence.getLanguage();
    setState(() {
      _currentLanguage = savedLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pagePadding = context.responsivePagePadding;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool showSideBySide = constraints.maxWidth >= 900;
            const double horizontalPadding = 0;
            final EdgeInsets authHorizontalPadding = EdgeInsets.only(
              left: pagePadding.left,
              right: pagePadding.right,
            );

            Widget headerSection = Container(
              width: double.infinity,
              height: showSideBySide ? 320 : 250,
              decoration: BoxDecoration(
                color: const Color(0xFF0981D1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(showSideBySide ? 80 : 100),
                  bottomRight: showSideBySide ? const Radius.circular(80) : Radius.zero,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          Text(
                            "ToTepAI",
                            style: GoogleFonts.alfaSlabOne(
                              fontSize: 47,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Smart Bangus Farming Assistant",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );

            Widget authContent = Column(
              children: [
                const SizedBox(height: 30),
                // Only show toggle navigation if showToggleButtons is true
                if (widget.showToggleButtons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => isLoginSelected = true),
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            color: isLoginSelected ? const Color(0xFF0981D1) : Colors.grey[600],
                            fontWeight: isLoginSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        '|',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () => setState(() => isLoginSelected = false),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: !isLoginSelected ? const Color(0xFF0981D1) : Colors.grey[600],
                            fontWeight: !isLoginSelected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: isLoginSelected
                      ? const LoginScreen(key: ValueKey('login'))
                      : const SignInScreen(key: ValueKey('register')),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      children: [
                        TextSpan(text: TranslationService.getTranslationSync('by_continuing_agree', _currentLanguage)),
                        TextSpan(
                          text: TranslationService.getTranslationSync('privacy_policy', _currentLanguage),
                          style: const TextStyle(
                            color: Color(0xFF0981D1),
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _showPrivacyPolicy(context);
                            },
                        ),
                        TextSpan(text: TranslationService.getTranslationSync('and', _currentLanguage)),
                        TextSpan(
                          text: TranslationService.getTranslationSync('terms_of_service', _currentLanguage),
                          style: const TextStyle(
                            color: Color(0xFF0981D1),
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _showTermsOfService(context);
                            },
                        ),
                        const TextSpan(text: "."),
                      ],
                    ),
                  ),
                ),
              ],
            );

            Widget content = SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: showSideBySide ? 40 : 0,
                  bottom: pagePadding.bottom + 24,
                ),
                child: ResponsiveConstrainedBox(
                  child: showSideBySide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: headerSection),
                            const SizedBox(width: 32),
                            Expanded(
                              child: Padding(
                                padding: authHorizontalPadding,
                                child: authContent,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            headerSection,
                            Padding(
                              padding: authHorizontalPadding,
                              child: authContent,
                            ),
                          ],
                        ),
                ),
              ),
            );

            return Column(
              children: [
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 500,
              minWidth: 280,
            ),
            child: AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              title: Text(
                TranslationService.getTranslationSync('privacy_title', _currentLanguage),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0981D1),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPolicySection(
                      TranslationService.getTranslationSync('data_collection', _currentLanguage),
                      TranslationService.getTranslationSync('data_collection_content', _currentLanguage)
                    ),
                    _buildPolicySection(
                      TranslationService.getTranslationSync('data_usage', _currentLanguage),
                      TranslationService.getTranslationSync('data_usage_content', _currentLanguage)
                    ),
                    _buildPolicySection(
                      TranslationService.getTranslationSync('data_protection', _currentLanguage),
                      TranslationService.getTranslationSync('data_protection_content', _currentLanguage)
                    ),
                    _buildPolicySection(
                      TranslationService.getTranslationSync('data_sharing', _currentLanguage),
                      TranslationService.getTranslationSync('data_sharing_content', _currentLanguage)
                    ),
                    _buildPolicySection(
                      TranslationService.getTranslationSync('your_rights', _currentLanguage),
                      TranslationService.getTranslationSync('your_rights_content', _currentLanguage)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      TranslationService.getTranslationSync('last_updated', _currentLanguage),
                      style: const TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    TranslationService.getTranslationSync('close', _currentLanguage),
                    style: const TextStyle(color: Color(0xFF0981D1)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 500,
              minWidth: 280,
            ),
            child: AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              title: Text(
                TranslationService.getTranslationSync('terms_title', _currentLanguage),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0981D1),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPolicySection(
                      TranslationService.getTranslationSync('acceptance_of_terms', _currentLanguage),
                      TranslationService.getTranslationSync('acceptance_of_terms_content', _currentLanguage)
                    ),
                    _buildPolicySection(
                      TranslationService.getTranslationSync('service_description', _currentLanguage),
                      TranslationService.getTranslationSync('service_description_content', _currentLanguage)
                    ),
                    _buildPolicySection(
                      TranslationService.getTranslationSync('user_responsibilities', _currentLanguage),
                      TranslationService.getTranslationSync('user_responsibilities_content', _currentLanguage)
                    ),
                    _buildPolicySection(
                      TranslationService.getTranslationSync('service_availability', _currentLanguage),
                      TranslationService.getTranslationSync('service_availability_content', _currentLanguage)
                    ),
                    _buildPolicySection(
                      TranslationService.getTranslationSync('limitation_of_liability', _currentLanguage),
                      TranslationService.getTranslationSync('limitation_of_liability_content', _currentLanguage)
                    ),
                    _buildPolicySection(
                      TranslationService.getTranslationSync('account_termination', _currentLanguage),
                      TranslationService.getTranslationSync('account_termination_content', _currentLanguage)
                    ),
                    _buildPolicySection(
                      TranslationService.getTranslationSync('modifications', _currentLanguage),
                      TranslationService.getTranslationSync('modifications_content', _currentLanguage)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      TranslationService.getTranslationSync('last_updated', _currentLanguage),
                      style: const TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    TranslationService.getTranslationSync('close', _currentLanguage),
                    style: const TextStyle(color: Color(0xFF0981D1)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            height: 1.3,
            wordSpacing: 1,
          ),
          // textAlign: TextAlign.justify,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }
}

class _AuthToggleButton extends StatelessWidget {
  const _AuthToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0981D1) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF0981D1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
