import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:totepai/pages/authentications/login.dart';
import 'package:totepai/pages/authentications/register.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:totepai/utils/responsive.dart';

class AuthPage extends StatefulWidget {
  final bool showLogin;
  final bool showToggleButtons;
  
  const AuthPage({super.key, this.showLogin = true, this.showToggleButtons = true});

  @override
  AuthPageState createState() => AuthPageState();
}

class AuthPageState extends State<AuthPage> {
  bool isLoginSelected = true;

  @override
  void initState() {
    super.initState();
    isLoginSelected = widget.showLogin;
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
                        const TextSpan(text: "By continuing, you agree to our "),
                        TextSpan(
                          text: "Privacy Policy",
                          style: const TextStyle(
                            color: Color(0xFF0981D1),
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _showPrivacyPolicy(context);
                            },
                        ),
                        const TextSpan(text: " and "),
                        TextSpan(
                          text: "Terms of Service",
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
              title: const Text(
                'Privacy Policy',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0981D1),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPolicySection('Data Collection', 
                      'ToTepAI systematically collects harvest data, fish growth patterns, and environmental information to deliver precise forecasting and comprehensive analytics for your aquaculture operations.'),
                    _buildPolicySection('Data Usage', 
                      'Your data is utilized exclusively for:\n• Generating personalized harvest forecasts\n• Providing weather-based agricultural recommendations\n• Enhancing our artificial intelligence algorithms\n• Creating anonymized industry insights and research'),
                    _buildPolicySection('Data Protection', 
                      'We employ enterprise-grade security protocols including:\n• End-to-end encrypted data transmission and storage\n• Multi-factor secure user authentication\n• Quarterly comprehensive security audits\n• Full compliance with international data protection regulations'),
                    _buildPolicySection('Data Sharing', 
                      'Your personal and operational data is never shared with external parties without your explicit written consent. Only anonymized, statistically aggregated data may be utilized for academic research and industry development.'),
                    _buildPolicySection('Your Rights', 
                      'You retain the following rights regarding your data:\n• Complete access to your stored information at any time\n• Request permanent data deletion and removal\n• Opt-out of ongoing data collection processes\n• Export your complete dataset in industry-standard formats'),
                    const SizedBox(height: 8),
                    const Text(
                      'Last updated: April 2026',
                      style: TextStyle(
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
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Color(0xFF0981D1)),
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
              title: const Text(
                'Terms of Service',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0981D1),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPolicySection('Acceptance of Terms', 
                      'By accessing and utilizing ToTepAI services, you expressly agree to be bound by these terms and conditions. Should you disagree with any provision herein, you must immediately cease all use of our platform.'),
                    _buildPolicySection('Service Description', 
                      'ToTepAI is an advanced artificial intelligence platform designed for aquaculture management, delivering:\n• Sophisticated harvest forecasting and analytical insights\n• Meteorological-based agricultural recommendations\n• Comprehensive growth pattern analysis\n• Continuous real-time monitoring and reporting'),
                    _buildPolicySection('User Responsibilities', 
                      'As a registered user, you hereby commit to:\n• Provide accurate and verifiable harvest data\n• Utilize the service exclusively for legitimate aquaculture operations\n• Refrain from attempting to manipulate or compromise the AI system\n• Respect all intellectual property and proprietary rights'),
                    _buildPolicySection('Service Availability', 
                      'While we maintain a service level objective of 99.9% operational uptime, we cannot guarantee uninterrupted service availability. ToTepAI shall not be held liable for temporary service disruptions or data loss resulting from technical complications beyond our reasonable control.'),
                    _buildPolicySection('Limitation of Liability', 
                      'ToTepAI delivers predictive analytics and recommendations based on available data inputs. These insights are provided for guidance purposes only and must be supplemented with professional agricultural judgment. ToTepAI assumes no liability for operational decisions made in reliance upon our recommendations.'),
                    _buildPolicySection('Account Termination', 
                      'ToTepAI reserves the unilateral right to suspend or terminate user accounts that violate these terms, engage in fraudulent activities, or misuse the platform in any manner deemed detrimental to service integrity.'),
                    _buildPolicySection('Modifications', 
                      'These terms of service may be periodically amended at our discretion. Continued utilization of ToTepAI services following such modifications shall constitute unequivocal acceptance of the revised terms.'),
                    const SizedBox(height: 8),
                    const Text(
                      'Last updated: April 2026',
                      style: TextStyle(
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
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Color(0xFF0981D1)),
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
