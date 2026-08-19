import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Login সফল হলে সরাসরি Home Screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _authService.getAuthErrorMessage(error),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // ==================================================
                    // LOGO
                    // ==================================================

                    Center(
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.people_alt_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'বন্ধু সোশ্যাল',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'আপনার অ্যাকাউন্টে লগইন করুন',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ==================================================
                    // EMAIL
                    // ==================================================

                    TextFormField(
                      controller: _emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      textInputAction:
                          TextInputAction.next,
                      autocorrect: false,
                      enabled: !_isLoading,
                      decoration: const InputDecoration(
                        labelText: 'ইমেইল',
                        hintText:
                            'আপনার ইমেইল লিখুন',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                        border:
                            OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final email =
                            value?.trim() ?? '';

                        if (email.isEmpty) {
                          return 'ইমেইল লিখুন';
                        }

                        if (!email.contains('@') ||
                            !email.contains('.')) {
                          return 'সঠিক ইমেইল দিন';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // PASSWORD
                    // ==================================================

                    TextFormField(
                      controller:
                          _passwordController,
                      obscureText:
                          _obscurePassword,
                      textInputAction:
                          TextInputAction.done,
                      enabled: !_isLoading,
                      onFieldSubmitted: (_) {
                        if (!_isLoading) {
                          _login();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'পাসওয়ার্ড',
                        hintText:
                            'আপনার পাসওয়ার্ড লিখুন',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),
                        suffixIcon: IconButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _obscurePassword =
                                        !_obscurePassword;
                                  });
                                },
                          icon: Icon(
                            _obscurePassword
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                          ),
                        ),
                        border:
                            const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'পাসওয়ার্ড লিখুন';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // FORGOT PASSWORD
                    // ==================================================

                    Align(
                      alignment:
                          Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context)
                                    .push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                        child: const Text(
                          'পাসওয়ার্ড ভুলে গেছেন?',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // LOGIN BUTTON
                    // ==================================================

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : _login,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Text(
                                'লগইন',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // OR
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color:
                                Colors.grey.shade400,
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 12,
                          ),
                          child: Text(
                            'অথবা',
                            style: TextStyle(
                              color:
                                  Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color:
                                Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // GOOGLE LOGIN
                    // ==================================================

                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              ScaffoldMessenger
                                      .of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Google Login পরের ধাপে চালু করা হবে।',
                                  ),
                                  behavior:
                                      SnackBarBehavior
                                          .floating,
                                ),
                              );
                            },
                      icon: const Icon(
                        Icons.g_mobiledata_rounded,
                      ),
                      label: const Text(
                        'Google দিয়ে লগইন',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        minimumSize:
                            const Size(
                          double.infinity,
                          52,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // SIGN UP
                    // ==================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          'নতুন ব্যবহারকারী?',
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(
                                    context,
                                  ).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SignupScreen(),
                                    ),
                                  );
                                },
                          child: const Text(
                            'অ্যাকাউন্ট তৈরি করুন',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
