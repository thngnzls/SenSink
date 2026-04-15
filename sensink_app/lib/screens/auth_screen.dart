import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isPasswordVisible = false;
  bool _isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController =
      TextEditingController(); // NEW: Username controller

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  // --- FIREBASE EMAIL/PASSWORD LOGIC ---
  Future<void> _submitAuth() async {
    // 1. Basic Validation
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showMessage("Please fill in all required fields.", isError: true);
      return;
    }

    if (!isLogin && usernameController.text.trim().isEmpty) {
      _showMessage("Please provide a username.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        // --- LOG IN FLOW ---
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );

        // Check if the email is verified before letting them in
        if (!userCredential.user!.emailVerified) {
          await FirebaseAuth.instance.signOut(); // Force sign out
          _showMessage(
            "Please verify your email before logging in. Check your inbox.",
            isError: true,
          );
          setState(() => _isLoading = false);
          return;
        }

        _goToHome();
      } else {
        // --- SIGN UP FLOW ---
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );

        // Save the username to the Firebase profile
        await userCredential.user!.updateDisplayName(
          usernameController.text.trim(),
        );

        // Send the verification email
        await userCredential.user!.sendEmailVerification();

        // Sign them out immediately so they have to verify before entering
        await FirebaseAuth.instance.signOut();

        _showMessage(
          "Account created! A verification email has been sent. Please verify before logging in.",
          isError: false,
        );

        // Switch the UI back to the Login tab automatically
        setState(() {
          isLogin = true;
          passwordController.clear();
        });
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(
        e.message ?? "An authentication error occurred.",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FIREBASE GOOGLE SIGN-IN LOGIC ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      _goToHome();
    } catch (e) {
      print("GOOGLE SIGN IN ERROR: $e");
      _showMessage(
        "Google Sign-In failed. Did you add your SHA-1 key to Firebase?",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper method to navigate to Dashboard
  void _goToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // Helper method to show dynamic snackbars (Error vs Success)
  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: Stack(
        children: [
          // Background Design
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A66C2), Color(0xFF003C8F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),
          Positioned(
            top: 150,
            left: -80,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: Colors.white.withOpacity(0.05),
            ),
          ),

          // Floating Form Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Icon(Icons.water_drop, size: 60, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'SenSink',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),

                    Container(
                      padding: const EdgeInsets.all(28.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTab("Login", isLogin, () {
                                setState(() => isLogin = true);
                              }, primaryColor),
                              _buildTab("Sign Up", !isLogin, () {
                                setState(() => isLogin = false);
                              }, primaryColor),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // NEW: Username Field (Only visible during Sign Up)
                          if (!isLogin) ...[
                            _buildInputLabel("Username"),
                            _buildTextField(
                              controller: usernameController,
                              icon: Icons.person_outline,
                              hintText: "Choose a username",
                            ),
                            const SizedBox(height: 20),
                          ],

                          _buildInputLabel("Email Address"),
                          _buildTextField(
                            controller: emailController,
                            icon: Icons.email_outlined,
                            hintText: "Enter your email",
                          ),
                          const SizedBox(height: 20),

                          _buildInputLabel("Password"),
                          _buildTextField(
                            controller: passwordController,
                            icon: Icons.lock_outline,
                            hintText: "Enter your password",
                            isPassword: true,
                          ),

                          if (isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 24),

                          // MAIN ACTION BUTTON
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isLogin ? "Log In" : "Create Account",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  "or",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // GOOGLE BUTTON
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            icon: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                              height: 20,
                            ),
                            label: const Text(
                              "Continue with Google",
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    String title,
    bool isActive,
    VoidCallback onTap,
    Color activeColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? activeColor : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 60,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[400],
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}
