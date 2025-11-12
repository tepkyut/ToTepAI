import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:totepai/pages/dashboard/home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _loginUser() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login successful!")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Login failed")));
    }

    setState(() => _isLoading = false);
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required FocusNode focusNode,
    required TextEditingController controller,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    final bool isFocused = focusNode.hasFocus;
    final bool isFilled = controller.text.isNotEmpty;

    return InputDecoration(
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: isFocused || isFilled ? Color(0xFF00AEEF) : Colors.grey,
            )
          : null,
      suffixIcon: suffixIcon,
      labelText: labelText,
      labelStyle: TextStyle(
        color: isFocused ? Color(0xFF00AEEF) : Colors.grey,
        fontSize: 16,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF00AEEF),
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: isFocused
          ? Colors.blue.shade50
          : Colors.grey.shade100, // subtle background
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.grey, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF00AEEF), width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _emailController,
            focusNode: _emailFocus,
            decoration: _buildInputDecoration(
              labelText: "Enter your email",
              focusNode: _emailFocus,
              controller: _emailController,
              icon: Icons.email_outlined,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            decoration: _buildInputDecoration(
              labelText: "Enter your password",
              focusNode: _passwordFocus,
              controller: _passwordController,
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _passwordFocus.hasFocus
                      ? Color(0xFF00AEEF)
                      : Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: _isLoading ? null : _loginUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00AEEF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "Log In",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 30),
          Row(
            children: const [
              Expanded(
                child: Divider(color: Colors.grey, thickness: 1, endIndent: 10),
              ),
              Text("or", style: TextStyle(color: Colors.grey, fontSize: 14)),
              Expanded(
                child: Divider(color: Colors.grey, thickness: 1, indent: 10),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildGoogleButton("Continue to login with Google"),
        ],
      ),
    );
  }

  Widget _buildGoogleButton(String text) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Add Google Sign-In logic
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: Colors.black12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon/google.png', width: 24, height: 24),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
