import 'package:flutter/material.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Smooth fade transition to Auth Screen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const AuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Crisp white background
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Displays your custom logo
            Image.asset(
              'assets/logo.png',
              width: 180, // You can adjust this number to make it bigger or smaller
              height: 180,
            ),
            const SizedBox(height: 24),

            // App Title (Visible on white)
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Intelligent Water Management',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54, // Greyed text for contrast
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 60),

            // Loading indicator (Changed to blue to be visible on white background)
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A66C2)),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}