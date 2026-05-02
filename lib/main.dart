import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:totepai/pages/authentications/auth_page.dart';
import 'package:totepai/pages/dashboard/home_page.dart';
import 'package:totepai/pages/splash_screen.dart';
import 'package:totepai/pages/onboarding_screen.dart';
import 'package:totepai/controllers/harvest_data_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  if (Platform.isAndroid) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDOC3iZ_38Vzoir-L4OmkOES5KjYWB1K5M',
        appId: '1:649100271753:android:a8196445bcaaf0f3a82658',
        messagingSenderId: '1095142914393',
        projectId: 'totepai-edd0f',
        storageBucket: 'totepai-edd0f.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(
    const ToTepAI()
    // const MaterialApp(
    //   debugShowCheckedModeBanner: false,
    //   home: HarvestFormPage(),
    // ),
  );
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
