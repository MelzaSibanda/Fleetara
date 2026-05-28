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
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool  _obscure   = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Enter your email address first', AppTheme.amber); return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _snack('Reset email sent to $email', AppTheme.emerald);
    } catch (_) {
      if (mounted) _snack('Could not send reset email', AppTheme.rose);
    }
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthLoginRequested(
        email: _emailCtrl.text.trim(), password: _passCtrl.text));
    }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4)));

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 860;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) _snack(state.message, AppTheme.rose);
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          if (isWide) {
            return Row(children: [
              // ── Left brand panel ──────────────────────────────────────────
              Expanded(
                flex: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.darkNavy, AppTheme.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Row(children: [
                          Image.asset('assets/logos/fleetara_logo.png',
                            width: 44, height: 44),
                          const SizedBox(width: 12),
                          const Text('Fleetara',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20, fontWeight: FontWeight.w700,
                              letterSpacing: 0.3)),
                        ]),
                        const Spacer(),
                        // Headline
                        const Text('Your Fleet.\nOur Priority.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36, fontWeight: FontWeight.w800,
                            height: 1.2, letterSpacing: -0.5)),
                        const SizedBox(height: 16),
                        Text('Manage, track and deliver with complete\nvisibility across your entire fleet.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 14, height: 1.6)),
                        const SizedBox(height: 48),
                        // Feature list
                        ...[
                          ('Real-time GPS tracking',        Icons.location_on_outlined),
                          ('Digital vehicle inspections',   Icons.assignment_turned_in_outlined),
                          ('Automated trip management',     Icons.route_outlined),
                          ('Financial reporting & invoices',Icons.receipt_long_outlined),
                        ].map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(item.$2, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text(item.$1, style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13, fontWeight: FontWeight.w500)),
                          ]),
                        )),
                        const Spacer(),
                        Text('© 2026 Fleetara Trucking Solutions',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Right form panel ──────────────────────────────────────────
              Expanded(
                flex: 4,
                child: Container(
                  color: AppTheme.surface,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: _LoginForm(
                          formKey:   _formKey,
                          emailCtrl: _emailCtrl,
                          passCtrl:  _passCtrl,
                          obscure:   _obscure,
                          loading:   loading,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                          onForgot:  _resetPassword,
                          onLogin:   _login,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]);
          }

          // ── Mobile: single column ─────────────────────────────────────────
          return Container(
            color: AppTheme.surface,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(children: [
                    const SizedBox(height: 24),
                    Row(children: [
                      Image.asset('assets/logos/fleetara_logo.png',
                        width: 36, height: 36),
                      const SizedBox(width: 10),
                      const Text('Fleetara',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                    ]),
                    const SizedBox(height: 32),
                    _LoginForm(
                      formKey:   _formKey,
                      emailCtrl: _emailCtrl,
                      passCtrl:  _passCtrl,
                      obscure:   _obscure,
                      loading:   loading,
                      onToggleObscure: () => setState(() => _obscure = !_obscure),
                      onForgot:  _resetPassword,
                      onLogin:   _login,
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState>    formKey;
  final TextEditingController   emailCtrl, passCtrl;
  final bool    obscure, loading;
  final VoidCallback onToggleObscure, onForgot, onLogin;
  const _LoginForm({
    required this.formKey, required this.emailCtrl, required this.passCtrl,
    required this.obscure, required this.loading,
    required this.onToggleObscure, required this.onForgot, required this.onLogin,
  });

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Welcome back',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary)),
      const SizedBox(height: 6),
      const Text('Sign in to your Fleetara account',
        style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
      const SizedBox(height: 32),

      // Email
      TextFormField(
        controller: emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'Email address',
          prefixIcon: Icon(Icons.email_outlined, size: 18)),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Enter your email';
          if (!v.contains('@'))       return 'Enter a valid email';
          return null;
        },
      ),
      const SizedBox(height: 14),

      // Password
      TextFormField(
        controller:  passCtrl,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText:  'Password',
          prefixIcon: const Icon(Icons.lock_outline, size: 18),
          suffixIcon: IconButton(
            icon: Icon(obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined, size: 18),
            onPressed: onToggleObscure,
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null,
      ),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: onForgot,
          child: const Text('Forgot password?',
            style: TextStyle(fontSize: 12, color: AppTheme.accent,
              fontWeight: FontWeight.w500)),
        ),
      ),
      const SizedBox(height: 24),

      // Sign in button
      ElevatedButton(
        onPressed: loading ? null : onLogin,
        child: loading
          ? const SizedBox(height: 18, width: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('Sign in'),
      ),
      const SizedBox(height: 24),

      // Divider
      Row(children: [
        Expanded(child: Divider(color: AppTheme.border, thickness: 0.8)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: TextStyle(
            fontSize: 11, color: AppTheme.textMuted.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500))),
        Expanded(child: Divider(color: AppTheme.border, thickness: 0.8)),
      ]),
      const SizedBox(height: 24),

      // Create account
      OutlinedButton(
        onPressed: () => context.go('/register'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
          side: const BorderSide(color: AppTheme.border),
          foregroundColor: AppTheme.textPrimary,
        ),
        child: const Text('Create a new account'),
      ),
    ]),
  );
}
