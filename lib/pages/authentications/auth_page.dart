import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:totepai/pages/authentications/login.dart';
import 'package:totepai/pages/authentications/register.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLoginSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 🔵 Top Header
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00AEEF),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(100),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Top-left brand (from onboarding)
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
                          // Centered title and subtitle
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
                    ),

                    const SizedBox(height: 30),

                    // 🔄 Toggle Buttons
                    Container(
                      width: 300,
                      height: 45,
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF00AEEF)),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => isLoginSelected = true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isLoginSelected
                                      ? Color(0xFF00AEEF)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Center(
                                  child: Text(
                                    'Log In',
                                    style: TextStyle(
                                      color: isLoginSelected
                                          ? Colors.white
                                          : Color(0xFF00AEEF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => isLoginSelected = false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !isLoginSelected
                                      ? Color(0xFF00AEEF)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Center(
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: !isLoginSelected
                                          ? Colors.white
                                          : Color(0xFF00AEEF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // 👇 Show Login or SignIn screen
                    if (isLoginSelected)
                      const LoginScreen()
                    else
                      const SignInScreen(),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // 🟢 Privacy and Terms text (BOTTOM)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  children: [
                    const TextSpan(text: "By continuing, you agree to our "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: const TextStyle(
                        color: Color(0xFF00AEEF),
                        fontWeight: FontWeight.w500,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Privacy Policy tapped"),
                            ),
                          );
                        },
                    ),
                    const TextSpan(text: " and "),
                    TextSpan(
                      text: "Terms of Service",
                      style: const TextStyle(
                        color: Color(0xFF00AEEF),
                        fontWeight: FontWeight.w500,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Terms of Service tapped"),
                            ),
                          );
                        },
                    ),
                    const TextSpan(text: "."),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
