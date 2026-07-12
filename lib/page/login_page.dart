import 'package:chat_apps/page/home_page.dart';
import 'package:chat_apps/page/register_page.dart';
import 'package:chat_apps/provider/auth_provider.dart';
import 'package:chat_apps/provider/error_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    try {
      talker.info('Initializing LoginPage');
      _loadSavedEmail(); // ✅ Only load email, NOT password
    } catch (e, st) {
      talker.error('Error initializing LoginPage', e, st);
      ref
          .read(errorProvider.notifier)
          .addError(
            'Login page initialization failed',
            details: e.toString(),
            severity: ErrorSeverity.critical,
          );
    }
  }

  // ✅ FIX: Only restore email, never restore password
  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('email');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        setState(() {
          _emailController.text = savedEmail;
        });
        talker.info('Loaded saved email: $savedEmail');
      }
    } catch (e, st) {
      talker.error('Error loading saved email', e, st);
    }
  }

  // ✅ FIX: Never save password in SharedPreferences
  Future<void> _saveEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setBool('isLoggedIn', true);
      // ❌ REMOVED: prefs.setString('password', ...) — never store plain text passwords
      talker.info('Saved email successfully');
    } catch (e, st) {
      talker.error('Error saving email', e, st);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    try {
      // Validate form first
      final formState = _formKey.currentState;
      if (formState == null || !formState.validate()) {
        talker.warning('Form validation failed');
        return;
      }

      // Prevent multiple submissions
      if (_isLoading) return;

      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      talker.info('Attempting login for: $email');

      final errorMessage = await ref
          .read(authProvider.notifier)
          .signIn(email: email, password: password);

      if (!mounted) return;

      // ✅ FIX: Only navigate if errorMessage is explicitly null (success)
      if (errorMessage == null) {
        await _saveEmail();
        if (!mounted) return;

        talker.info('Login successful, navigating to home');

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChatHomePage()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // ✅ FIX: Clear password field on failed login
        _passwordController.clear();

        talker.error('Login failed: $errorMessage');

        ref
            .read(errorProvider.notifier)
            .addError(
              'Login failed',
              details: errorMessage,
              severity: ErrorSeverity.error,
            );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _handleSubmit(),
            ),
          ),
        );
      }
    } catch (e, st) {
      talker.error('Unexpected login error', e, st);

      ref
          .read(errorProvider.notifier)
          .addError(
            'Unexpected login error',
            details: e.toString(),
            severity: ErrorSeverity.critical,
          );

      if (mounted) {
        // ✅ Also clear password on unexpected error
        _passwordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.dangerous, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'An unexpected error occurred. Please try again.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _handleSubmit(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Form(
        key: _formKey,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [Colors.blue[900]!, Colors.blue[800]!, Colors.blue[200]!],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Text(
                    'Welcome to Chat App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                    child: Container(
                      color: Colors.white,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20.0),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Email field
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                    ),
                                    child: TextFormField(
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        final emailRegex = RegExp(
                                          r'^[^@]+@[^@]+\.[^@]+$',
                                        );
                                        if (!emailRegex.hasMatch(
                                          value.trim(),
                                        )) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      enabled: !_isLoading,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Email',
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                        ),
                                        border: InputBorder.none,
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // ✅ Password field with show/hide toggle
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: TextFormField(
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) =>
                                          _isLoading ? null : _handleSubmit(),
                                      enabled: !_isLoading,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Password',
                                        hintStyle: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                        border: InputBorder.none,
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                          color: Colors.grey,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Forgot password feature coming soon!',
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: _isLoading ? null : _navigateToRegister,
                              child: Text(
                                'Register',
                                style: TextStyle(
                                  color: _isLoading ? Colors.grey : Colors.blue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            InkWell(
                              onTap: _isLoading ? null : _handleSubmit,
                              child: Container(
                                height: 50,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                ),
                                decoration: BoxDecoration(
                                  color: _isLoading
                                      ? Colors.grey[400]
                                      : Colors.orange[900],
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
