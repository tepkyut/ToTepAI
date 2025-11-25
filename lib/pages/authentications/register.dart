import 'package:flutter/material.dart';
import 'package:totepai/controllers/firebase_auth.dart';
import 'package:totepai/pages/dashboard/home_page.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  final AuthController _authController = AuthController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isGoogleLoading = false;

  void _registerUser() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _isLoading = true);

    String result = await _authController.registerNewUser(
      _emailController.text.trim(),
      _nameController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    final String result = await _authController.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result == "success") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Signed in with Google")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (result != "cancelled") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  InputDecoration _inputDecoration({
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
              color: isFocused || isFilled ? Color(0xFF0981D1) : Colors.grey,
            )
          : null,
      suffixIcon: suffixIcon,
      labelText: labelText,
      labelStyle: TextStyle(
        color: isFocused ? Color(0xFF0981D1) : Colors.grey,
        fontSize: 16,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF0981D1),
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: isFocused ? Colors.blue.shade50 : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.grey, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF0981D1), width: 2),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
    );
  }

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),

            // 👤 Full Name
            TextField(
              controller: _nameController,
              focusNode: _nameFocus,
              decoration: _inputDecoration(
                labelText: "Full Name",
                focusNode: _nameFocus,
                controller: _nameController,
                icon: Icons.person_outline,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),

            // 📧 Email
            TextField(
              controller: _emailController,
              focusNode: _emailFocus,
              decoration: _inputDecoration(
                labelText: "Email",
                focusNode: _emailFocus,
                controller: _emailController,
                icon: Icons.email_outlined,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),

            // 🔒 Password
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              decoration: _inputDecoration(
                labelText: "Password",
                focusNode: _passwordFocus,
                controller: _passwordController,
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _passwordFocus.hasFocus
                        ? Color(0xFF0981D1)
                        : Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),

            // 🔒 Confirm Password
            TextField(
              controller: _confirmPasswordController,
              focusNode: _confirmFocus,
              obscureText: _obscureConfirm,
              decoration: _inputDecoration(
                labelText: "Confirm Password",
                focusNode: _confirmFocus,
                controller: _confirmPasswordController,
                icon: Icons.lock_person_outlined,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _confirmFocus.hasFocus
                        ? Color(0xFF0981D1)
                        : Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 25),

            // 🚀 Sign Up Button
            ElevatedButton(
              onPressed: _isLoading ? null : _registerUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0981D1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Expanded(
                  child: Divider(
                    color: Colors.grey,
                    thickness: 1,
                    endIndent: 10,
                  ),
                ),
                Text("or", style: TextStyle(color: Colors.grey, fontSize: 14)),
                Expanded(
                  child: Divider(color: Colors.grey, thickness: 1, indent: 10),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildGoogleButton("Sign up with Google"),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton(String text) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGoogleLoading ? null : _signUpWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.black12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: _isGoogleLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
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
