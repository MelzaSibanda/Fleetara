import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool  _obscure    = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter your email address first',
          style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.amber,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Password reset email sent to $email',
            style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not send reset email. Check the address.',
            style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthLoginRequested(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
              backgroundColor: AppTheme.rose,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ));
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo row
                      Row(children: [
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.local_shipping, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text('Fleetara',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('2026',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                              color: AppTheme.primary)),
                        ),
                      ]),
                      const SizedBox(height: 40),
                      const Text('Welcome back',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary)),
                      const SizedBox(height: 6),
                      const Text('Sign in with your Fleetara account',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(height: 28),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined, size: 18),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter your email';
                          if (!v.contains('@'))       return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller:  _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText:  'Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined, size: 18),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your password' : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _resetPassword,
                          child: const Text('Forgot password?',
                            style: TextStyle(fontSize: 11, color: AppTheme.primary)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sign in button
                      ElevatedButton(
                        onPressed: state is AuthLoading ? null : _login,
                        child: state is AuthLoading
                            ? const SizedBox(height: 18, width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                            : const Text('Sign in'),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/register'),
                          child: RichText(
                            text: const TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              children: [
                                TextSpan(text: 'Create workspace',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w500)),
                              ],
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
        },
      ),
    );
  }
}
