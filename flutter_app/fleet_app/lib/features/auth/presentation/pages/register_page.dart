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
  final _formKey   = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  String _role     = 'driver';
  bool   _obscure  = true;

  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose();
    _emailCtrl.dispose(); _phoneCtrl.dispose();
    _passCtrl.dispose();  _pass2Ctrl.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(AuthRegisterRequested({
        'first_name': _firstCtrl.text.trim(),
        'last_name':  _lastCtrl.text.trim(),
        'email':      _emailCtrl.text.trim(),
        'phone':      _phoneCtrl.text.trim(),
        'role':       _role,
        'password':   _passCtrl.text,
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/dashboard');
          } else if (state is AuthError) {
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
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: const Row(children: [
                          Icon(Icons.arrow_back, size: 16, color: AppTheme.textMuted),
                          SizedBox(width: 6),
                          Text('Back to login',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ]),
                      ),
                      const SizedBox(height: 28),
                      Row(children: [
                        Image.asset('assets/logos/fleetara_logo.png', width: 30, height: 30),
                        const SizedBox(width: 8),
                        const Text('Fleetara',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary)),
                      ]),
                      const SizedBox(height: 24),
                      const Text('Create account',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary)),
                      const SizedBox(height: 6),
                      const Text('Join your Fleetara workspace',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(height: 24),
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _firstCtrl,
                          decoration: const InputDecoration(labelText: 'First name'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _lastCtrl,
                          decoration: const InputDecoration(labelText: 'Last name'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        )),
                      ]),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined, size: 18),
                        ),
                        validator: (v) {
                          if (v!.isEmpty)       return 'Required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          prefixIcon: Icon(Icons.phone_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _role,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Icons.badge_outlined, size: 18),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'owner',         child: Text('Owner')),
                          DropdownMenuItem(value: 'fleet_manager', child: Text('Fleet Manager')),
                          DropdownMenuItem(value: 'driver',        child: Text('Driver')),
                        ],
                        onChanged: (v) => setState(() => _role = v!),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller:  _passCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined, size: 18),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                          v!.length < 8 ? 'Minimum 8 characters' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller:  _pass2Ctrl,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_outline, size: 18),
                        ),
                        validator: (v) =>
                          v != _passCtrl.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: state is AuthLoading ? null : _register,
                        child: state is AuthLoading
                            ? const SizedBox(height: 18, width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                            : const Text('Create account'),
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
