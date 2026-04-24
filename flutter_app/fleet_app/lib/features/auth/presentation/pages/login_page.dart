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
  final _formKey      = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _obscurePass  = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthLoginRequested(
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) context.go('/dashboard');
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.error),
            );
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_shipping, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Text('Fleetara', style: Theme.of(context).textTheme.displayMedium),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Text('Welcome back', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 8),
                    Text('Sign in to your Fleetara account', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _usernameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Enter your username' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller:  _passwordCtrl,
                            obscureText: _obscurePass,
                            decoration: InputDecoration(
                              labelText:  'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: state is AuthLoading ? null : _login,
                            child: state is AuthLoading
                              ? const SizedBox(height: 20, width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Sign In'),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account? ", style: Theme.of(context).textTheme.bodyMedium),
                              GestureDetector(
                                onTap: () => context.go('/register'),
                                child: const Text('Register',
                                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
