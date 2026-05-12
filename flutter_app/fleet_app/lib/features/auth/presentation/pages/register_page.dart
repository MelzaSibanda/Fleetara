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
          if (state is AuthAuthenticated) context.go('/dashboard');
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
<<<<<<< HEAD
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
                            initialValue: _role,
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
=======
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
>>>>>>> 2077d3f97f38c256ddf48e9491d67a18af7d6f87
                      ),
                      const SizedBox(height: 28),
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
                          v!.length < 6 ? 'Minimum 6 characters' : null,
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
