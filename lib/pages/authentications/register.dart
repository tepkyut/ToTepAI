import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:totepai/controllers/firebase_auth.dart';
import 'package:totepai/pages/dashboard/home_page.dart';
import 'package:totepai/pages/authentications/auth_page.dart';
import 'package:totepai/utils/responsive.dart';
import 'package:totepai/services/translation_service.dart';
import 'package:totepai/services/language_persistence.dart';

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
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String _selectedLanguage = 'English';

  // Password strength indicator
  String _passwordStrength = '';
  Color _passwordStrengthColor = Colors.grey;

  // Password strength checker
  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = '';
        _passwordStrengthColor = Colors.grey;
      });
      return;
    }

    int strength = 0;
    
    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    
    // Character variety checks
    if (password.contains(RegExp(r'[A-Z]'))) strength++; // Uppercase
    if (password.contains(RegExp(r'[a-z]'))) strength++; // Lowercase
    if (password.contains(RegExp(r'[0-9]'))) strength++; // Numbers
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++; // Special chars

    setState(() {
      if (strength <= 2) {
        _passwordStrength = 'Weak';
        _passwordStrengthColor = Colors.red;
      } else if (strength <= 4) {
        _passwordStrength = 'Medium';
        _passwordStrengthColor = Colors.orange;
      } else {
        _passwordStrength = 'Strong';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  void _registerUser() async {
    // Clear previous errors
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    // Validate inputs
    bool hasError = false;
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = "Username is required");
      hasError = true;
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = "Email is required");
      hasError = true;
    }
    if (_passwordController.text.trim().isEmpty) {
      setState(() => _passwordError = "Password is required");
      hasError = true;
    }
    if (_confirmPasswordController.text.trim().isEmpty) {
      setState(() => _confirmPasswordError = "Please confirm your password");
      hasError = true;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = "Passwords do not match");
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    String result = await _authController.registerNewUser(
      _emailController.text.trim(),
      _nameController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully!"),
          backgroundColor: Colors.green,
        ),
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
    String? errorText,
  }) {
    final bool isFocused = focusNode.hasFocus;
    final bool isFilled = controller.text.isNotEmpty;
    final bool hasError = errorText != null;

    return InputDecoration(
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: hasError
                  ? Colors.red
                  : (isFocused || isFilled ? Color(0xFF0981D1) : Colors.grey),
            )
          : null,
      suffixIcon: suffixIcon,
      labelText: labelText,
      labelStyle: TextStyle(
        color: hasError
            ? Colors.red
            : (isFocused ? Color(0xFF0981D1) : Colors.grey),
        fontSize: 16,
      ),
      floatingLabelStyle: TextStyle(
        color: hasError ? Colors.red : Color(0xFF0981D1),
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: hasError
          ? Colors.red.shade50
          : (isFocused ? Colors.blue.shade50 : Colors.grey.shade100),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: hasError ? Colors.red : Colors.grey,
          width: hasError ? 2 : 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: hasError ? Colors.red : Color(0xFF0981D1),
          width: 2,
        ),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      errorText: errorText,
      errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
    );
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await LanguagePersistence.getLanguage();
    setState(() {
      _selectedLanguage = savedLanguage;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
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
    final EdgeInsets pagePadding = context.responsivePagePadding;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        pagePadding.left,
        32,
        pagePadding.right,
        0,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: ResponsiveConstrainedBox(
        child: Column(
          children: [
            const SizedBox(height: 5),

            // 👤 Full Name
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                decoration: _inputDecoration(
                  labelText: TranslationService.getTranslationSync('username', _selectedLanguage),
                  focusNode: _nameFocus,
                  controller: _nameController,
                  icon: Icons.person_outline,
                  errorText: _nameError,
                ),
                onChanged: (_) {
                  setState(() {});
                  // Clear error when user starts typing
                  if (_nameError != null && _nameController.text.isNotEmpty) {
                    setState(() => _nameError = null);
                  }
                },
              ),
            ),
            const SizedBox(height: 15),

            // 📧 Email
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _emailController,
                focusNode: _emailFocus,
                decoration: _inputDecoration(
                  labelText: TranslationService.getTranslationSync('email', _selectedLanguage),
                  focusNode: _emailFocus,
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  errorText: _emailError,
                ),
                onChanged: (_) {
                  setState(() {});
                  // Clear error when user starts typing
                  if (_emailError != null && _emailController.text.isNotEmpty) {
                    setState(() => _emailError = null);
                  }
                },
              ),
            ),
            const SizedBox(height: 15),

            // 🔒 Password
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  labelText: TranslationService.getTranslationSync('password', _selectedLanguage),
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
                  errorText: _passwordError,
                ),
                onChanged: (_) {
                  setState(() {});
                  _checkPasswordStrength(_passwordController.text);
                  // Clear error when user starts typing
                  if (_passwordError != null && _passwordController.text.isNotEmpty) {
                    setState(() => _passwordError = null);
                  }
                },
              ),
            ),
            // Password strength indicator
            if (_passwordStrength.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                child: Row(
                  children: [
                    Text(
                      TranslationService.getTranslationSync('password_strength', _selectedLanguage),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _passwordStrength,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _passwordStrengthColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Strength indicator dots
                    Row(
                      children: [
                        _buildStrengthDot(Colors.red),
                        const SizedBox(width: 4),
                        _buildStrengthDot(Colors.orange),
                        const SizedBox(width: 4),
                        _buildStrengthDot(Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 15),

            // 🔒 Confirm Password
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _confirmPasswordController,
                focusNode: _confirmFocus,
                obscureText: _obscureConfirm,
                decoration: _inputDecoration(
                  labelText: TranslationService.getTranslationSync('confirm_password', _selectedLanguage),
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
                  errorText: _confirmPasswordError,
                ),
                onChanged: (_) {
                  setState(() {});
                  // Clear error when user starts typing
                  if (_confirmPasswordError != null && _confirmPasswordController.text.isNotEmpty) {
                    setState(() => _confirmPasswordError = null);
                  }
                },
              ),
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
                  : Text(
                      TranslationService.getTranslationSync('signup', _selectedLanguage),
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
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
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  TranslationService.getTranslationSync('already_have_account', _selectedLanguage),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: () {
                    // Find the AuthPage parent and toggle to login
                    final authPageState = context.findAncestorStateOfType<AuthPageState>();
                    if (authPageState != null) {
                      authPageState.setState(() {
                        authPageState.isLoginSelected = true;
                      });
                    } else {
                      // Fallback: navigate to new AuthPage if not found
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AuthPage(showLogin: true, showToggleButtons: false)),
                      );
                    }
                  },
                  child: Text(
                    TranslationService.getTranslationSync('login', _selectedLanguage),
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF0981D1),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthDot(Color color) {
    bool isActive = false;
    if (color == Colors.red && _passwordStrengthColor == Colors.red) {
      isActive = true;
    } else if (color == Colors.orange && _passwordStrengthColor == Colors.orange) {
      isActive = true;
    } else if (color == Colors.green && _passwordStrengthColor == Colors.green) {
      isActive = true;
    }
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey.shade300,
        shape: BoxShape.circle,
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