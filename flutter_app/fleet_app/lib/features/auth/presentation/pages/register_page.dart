import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey      = GlobalKey<FormState>();
  final _firstCtrl    = TextEditingController();
  final _lastCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _pass2Ctrl    = TextEditingController();
  String _role        = 'driver';
  bool   _obscure     = true;

  void _register() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthRegisterRequested({
        'first_name': _firstCtrl.text.trim(),
        'last_name':  _lastCtrl.text.trim(),
        'email':      _emailCtrl.text.trim(),
        'username':   _usernameCtrl.text.trim(),
        'phone':      _phoneCtrl.text.trim(),
        'role':       _role,
        'password':   _passCtrl.text,
        'password2':  _pass2Ctrl.text,
      }));
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
                    TextButton.icon(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to login'),
                    ),
                    const SizedBox(height: 16),
                    Text('Create account', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 8),
                    Text('Join your Fleetara workspace', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstCtrl,
                                  decoration: const InputDecoration(labelText: 'First name'),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastCtrl,
                                  decoration: const InputDecoration(labelText: 'Last name'),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameCtrl,
                            decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneCtrl,
                            decoration: const InputDecoration(labelText: 'Phone number', prefixIcon: Icon(Icons.phone_outlined)),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _role,
                            decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.badge_outlined)),
                            items: const [
                              DropdownMenuItem(value: 'owner',         child: Text('Owner')),
                              DropdownMenuItem(value: 'admin',         child: Text('Admin')),
                              DropdownMenuItem(value: 'fleet_manager', child: Text('Fleet Manager')),
                              DropdownMenuItem(value: 'driver',        child: Text('Driver')),
                            ],
                            onChanged: (v) => setState(() => _role = v!),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller:  _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText:  'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => v!.length < 8 ? 'Min 8 characters' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller:  _pass2Ctrl,
                            obscureText: _obscure,
                            decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline)),
                            validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: state is AuthLoading ? null : _register,
                            child: state is AuthLoading
                              ? const SizedBox(height: 20, width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Create Account'),
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
