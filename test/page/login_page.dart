import 'package:chat_apps/main.dart';
import 'package:chat_apps/page/home_page.dart';
import 'package:chat_apps/page/register_page.dart';
import 'package:chat_apps/provider/auth_provider.dart';
import 'package:chat_apps/provider/error_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    try {
      talker.info('Initializing LoginPage');
      _loadSavedCredentials();
    } catch (e, st) {
      talker.error('Error initializing LoginPage', e, st);
      // Add to visual error tracking
      ref
          .read(errorProvider.notifier)
          .addError(
            'Login page initialization failed',
            details: e.toString(),
            severity: ErrorSeverity.critical,
          );
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      talker.info('Loading saved credentials');
      final prefs = await SharedPreferences.getInstance();
      final savePassword = prefs.getString('password');
      final saveEmail = prefs.getString('email');
      if (saveEmail != null && savePassword != null) {
        setState(() {
          _emailController.text = saveEmail;
          _passwordController.text = savePassword;
        });
        talker.info('Loaded saved credentials for email: $saveEmail');
      }
    } catch (e, st) {
      talker.error('Error loading saved credentials', e, st);
      // Add to visual error tracking
      ref
          .read(errorProvider.notifier)
          .addError(
            'Failed to load saved credentials',
            details: e.toString(),
            severity: ErrorSeverity.warning,
          );
    }
  }

  Future<void> _saveCredentials() async {
    try {
      talker.info('Saving credentials for user: ${_emailController.text}');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('isLoggedIn', true);
      talker.info('Credentials saved successfully');
    } catch (e, st) {
      talker.error('Error saving credentials', e, st);
    }
  }

  @override
  void dispose() {
    try {
      _emailController.dispose();
      _passwordController.dispose();
      super.dispose();
    } catch (e, st) {
      talker.error('Error disposing login page', e, st);
    }
  }

  Future<void> _handleSubmit() async {
    try {
      talker.info('Starting login submission');
      // Validate form
      final formState = _formKey.currentState;
      if (formState == null || !formState.validate()) {
        talker.warning('Form validation failed');
        return;
      }

      // Prevent multiple submissions
      if (_isLoading) {
        talker.warning('Multiple login attempts prevented');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final errorMessage = await ref
          .read(authProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (!mounted) return;

      if (errorMessage == null) {
        await _saveCredentials();
        if (!mounted) return;
        // Navigate to home page only if login was successful
        Navigator.of(context).pushReplacement(
          // Use pushReplacement to prevent going back to login
          MaterialPageRoute(builder: (context) => const ChatHomePage()),
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Show error message from signIn method
        talker.error('Login failedsssssssssss: $errorMessage');
        // Add to visual error tracking
        ref
            .read(errorProvider.notifier)
            .addError(
              'Login failed',
              details: errorMessage,
              severity: ErrorSeverity.error,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
                const Icon(Icons.lock_open, color: Colors.white70),
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
      // Add to visual error tracking
      ref
          .read(errorProvider.notifier)
          .addError(
            'Unexpected login error',
            details: e.toString(),
            severity: ErrorSeverity.critical,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.dangerous, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('An unexpected error occurred during login'),
                ),
                const Icon(Icons.refresh, color: Colors.white70),
              ],
            ),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 8),
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
        setState(() {
          _isLoading = false;
        });
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
          height: double.infinity, // ← ADD THIS
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
                const SizedBox(height: 30), // reduced from 50
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
                const SizedBox(height: 30), // reduced from 50
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                    child: Container(
                      color: Colors.white,
                      child: SingleChildScrollView(
                        // ← KEY FIX
                        padding: const EdgeInsets.all(20.0),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // ← KEY FIX
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
                                      ),
                                    ),
                                  ),
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
                                          return 'Please enter your password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                      controller: _passwordController,
                                      obscureText: true,
                                      textInputAction: TextInputAction.done,
                                      enabled: !_isLoading,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Password',
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
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
                            const SizedBox(height: 30),
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
