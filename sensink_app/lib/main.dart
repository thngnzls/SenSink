import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SenSinkApp());
}

class SenSinkApp extends StatelessWidget {
  const SenSinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SenSink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0A66C2), // Professional deep blue
        scaffoldBackgroundColor: const Color(0xFFF4F7F9), // Soft premium grey
        useMaterial3: true,
        fontFamily: 'Roboto', // Clean default font
      ),
      home: const SplashScreen(),
    );
  }
}
