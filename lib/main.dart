import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:totepai/pages/authentications/auth_page.dart';
import 'package:totepai/pages/dashboard/home_page.dart';
import 'package:totepai/pages/splash_screen.dart';
import 'package:totepai/pages/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCo02gXEt1xeUGMKYQWQymsgmGgrJTNesE',
        appId: '1:1095142914393:android:5d98a16bc4c4e6a059f448',
        messagingSenderId: '1095142914393',
        projectId: 'totepai-f457c',
        storageBucket: 'totepai-f457c.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
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
