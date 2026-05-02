import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:totepai/controllers/firebase_auth.dart';
import 'package:totepai/pages/dashboard/home_page.dart';
import 'package:totepai/pages/authentications/auth_page.dart';
import 'package:totepai/utils/responsive.dart';
import 'package:totepai/services/translation_service.dart';
import 'package:totepai/services/language_persistence.dart';
import 'dart:convert';
import 'dart:io';

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
  final AuthController _authController = AuthController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _emailError;
  String? _passwordError;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _testFileStorage(); // Test file storage first
    _loadRememberMe();
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await LanguagePersistence.getLanguage();
    setState(() {
      _selectedLanguage = savedLanguage;
    });
  }

  void _loginUser() async {
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validate inputs
    bool hasError = false;
    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = TranslationService.getTranslationSync('email_required', _selectedLanguage));
      hasError = true;
    }
    if (_passwordController.text.trim().isEmpty) {
      setState(() => _passwordError = TranslationService.getTranslationSync('password_required', _selectedLanguage));
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save remember me preference
      try {
        await _saveRememberMe();
      } catch (e) {
        print('Error saving remember me preference: $e');
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(TranslationService.getTranslationSync('login_successful', _selectedLanguage)),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login failed";
      
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No account found with this email address";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password. Please try again";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address format";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled";
          break;
        case 'too-many-requests':
          errorMessage = "Too many failed attempts. Please try again later";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Please check your connection";
          break;
        case 'invalid-credential':
          errorMessage = "Incorrect password. Please try again";
          break;
        default:
          // Also check the message for specific patterns
          if (e.message?.contains('incorrect') == true || 
              e.message?.contains('malformed') == true ||
              e.message?.contains('expired') == true) {
            errorMessage = "Incorrect password. Please try again";
          } else {
            errorMessage = e.message ?? "Login failed";
          }
          break;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Catch any other unexpected errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An unexpected error occurred. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    final String result = await _authController.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result == "success") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: const Text("Signed in with Google"),
          backgroundColor: Colors.green,
        ),
      );
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

  InputDecoration _buildInputDecoration({
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
          : (isFocused
              ? Colors.blue.shade50
              : Colors.grey.shade100),
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

  // Load remember me preferences
  Future<void> _loadRememberMe() async {
    try {
      print('Loading preferences from file...');
      final file = File('${Directory.systemTemp.path}/remember_me.json');
      
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        
        final rememberMe = data['rememberMe'] ?? false;
        final savedEmail = data['savedEmail'] ?? '';
        final savedPassword = data['savedPassword'] ?? '';
        
        print('Loaded - rememberMe: $rememberMe, email: $savedEmail, password: ${savedPassword.isNotEmpty ? '[loaded]' : '[empty]'}');
        
        setState(() {
          _rememberMe = rememberMe;
          if (_rememberMe) {
            _emailController.text = savedEmail;
            _passwordController.text = savedPassword;
          }
        });
        
        print('Preferences loaded and applied successfully');
      } else {
        print('No saved preferences file found');
        setState(() {
          _rememberMe = false;
        });
      }
    } catch (e) {
      print('Error loading preferences: $e');
      setState(() {
        _rememberMe = false;
      });
    }
  }

  // Save remember me preferences
  Future<void> _saveRememberMe() async {
    try {
      print('Saving remember me: $_rememberMe');
      print('Saving email: ${_emailController.text.trim()}');
      if (_rememberMe) {
        print('Saving password: ${_passwordController.text.trim()}');
      }
      
      final file = File('${Directory.systemTemp.path}/remember_me.json');
      final data = {
        'rememberMe': _rememberMe,
        'savedEmail': _emailController.text.trim(),
        'savedPassword': _rememberMe ? _passwordController.text.trim() : '',
      };
      
      await file.writeAsString(jsonEncode(data));
      print('Preferences saved successfully to file');
      
      // Verify it was saved
      if (await file.exists()) {
        final content = await file.readAsString();
        final savedData = jsonDecode(content);
        print('Verification - rememberMe: ${savedData['rememberMe']}, email: ${savedData['savedEmail']}, password: ${_rememberMe ? '[saved]' : '[not saved]'}');
      }
      
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }

  // Test file storage functionality
  Future<void> _testFileStorage() async {
    try {
      print('Testing file storage...');
      final file = File('${Directory.systemTemp.path}/test.json');
      
      // Test saving
      await file.writeAsString(jsonEncode({'test': 'hello'}));
      print('Test save successful');
      
      // Test loading
      final content = await file.readAsString();
      final data = jsonDecode(content);
      print('Test load: ${data['test']}');
      
      // Clean up
      if (await file.exists()) {
        await file.delete();
        print('Test cleanup successful');
      }
      
    } catch (e) {
      print('File storage test failed: $e');
    }
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _emailController,
                focusNode: _emailFocus,
                decoration: _buildInputDecoration(
                  labelText: TranslationService.getTranslationSync('enter_email', _selectedLanguage),
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                decoration: _buildInputDecoration(
                  labelText: TranslationService.getTranslationSync('enter_password', _selectedLanguage),
                  focusNode: _passwordFocus,
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _passwordFocus.hasFocus
                          ? const Color(0xFF0981D1)
                          : Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  errorText: _passwordError,
                ),
                onChanged: (_) {
                  setState(() {});
                  // Clear error when user starts typing
                  if (_passwordError != null && _passwordController.text.isNotEmpty) {
                    setState(() => _passwordError = null);
                  }
                },
              ),
            ),
            const SizedBox(height: 15),
            
            // Remember Me Checkbox
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF0981D1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Text(
                  TranslationService.getTranslationSync('remember_me', _selectedLanguage),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _isLoading ? null : _loginUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0981D1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      TranslationService.getTranslationSync('login', _selectedLanguage),
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 30),
            Row(
              children: const [
                Expanded(
                  child:
                      Divider(color: Colors.grey, thickness: 1, endIndent: 10),
                ),
                Text("or", style: TextStyle(color: Colors.grey, fontSize: 14)),
                Expanded(
                  child: Divider(color: Colors.grey, thickness: 1, indent: 10),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildGoogleButton("Login with Google"),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  TranslationService.getTranslationSync('dont_have_account', _selectedLanguage),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: () {
                    // Find the AuthPage parent and toggle to register
                    final authPageState = context.findAncestorStateOfType<AuthPageState>();
                    if (authPageState != null) {
                      authPageState.setState(() {
                        authPageState.isLoginSelected = false;
                      });
                    } else {
                      // Fallback: navigate to new AuthPage if not found
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AuthPage(showLogin: false, showToggleButtons: false)),
                      );
                    }
                  },
                  child: Text(
                    TranslationService.getTranslationSync('signup', _selectedLanguage),
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

  Widget _buildGoogleButton(String text) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
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
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
