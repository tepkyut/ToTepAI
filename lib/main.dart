import 'package:flutter/material.dart';
import 'package:totepai/pages/authentications/auth_page.dart';
import 'package:totepai/pages/dashboard/home.dart';
import 'package:totepai/pages/splash_screen.dart';
import 'package:totepai/pages/onboarding_screen.dart';

void main() {
  runApp(const ToTepAI());
}

class ToTepAI extends StatelessWidget {
  const ToTepAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToTepAI',
      theme: ThemeData(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'poppins'),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const AuthPage(),
        '/dashboard': (context) => const HomePage(), // ✅ Added this route
      },
    );
  }
}
