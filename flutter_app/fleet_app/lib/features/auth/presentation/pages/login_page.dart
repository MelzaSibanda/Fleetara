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
  bool _obscure    = true;
  bool _rememberMe = true;

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

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color, behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4)));

  @override
  Widget build(BuildContext context) {
    final width  = MediaQuery.of(context).size.width;
    final isWide = width >= 860;

    return Scaffold(
      backgroundColor: const Color(0xFF060E1E),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) _snack(state.message, AppTheme.rose);
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          if (isWide) {
            return _DesktopView(
              totalWidth:      width,
              formKey:         _formKey,
              emailCtrl:       _emailCtrl,
              passCtrl:        _passCtrl,
              obscure:         _obscure,
              rememberMe:      _rememberMe,
              loading:         loading,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onToggleRemember:() => setState(() => _rememberMe = !_rememberMe),
              onForgot:        _resetPassword,
              onLogin:         _login,
            );
          }
          return _MobileView(
            formKey:         _formKey,
            emailCtrl:       _emailCtrl,
            passCtrl:        _passCtrl,
            obscure:         _obscure,
            rememberMe:      _rememberMe,
            loading:         loading,
            onToggleObscure: () => setState(() => _obscure = !_obscure),
            onToggleRemember:() => setState(() => _rememberMe = !_rememberMe),
            onForgot:        _resetPassword,
            onLogin:         _login,
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MOBILE — dark full-screen design
// ════════════════════════════════════════════════════════════════════════════

class _MobileView extends StatelessWidget {
  final GlobalKey<FormState>  formKey;
  final TextEditingController emailCtrl, passCtrl;
  final bool obscure, rememberMe, loading;
  final VoidCallback onToggleObscure, onToggleRemember, onForgot, onLogin;

  const _MobileView({
    required this.formKey, required this.emailCtrl, required this.passCtrl,
    required this.obscure, required this.rememberMe, required this.loading,
    required this.onToggleObscure, required this.onToggleRemember,
    required this.onForgot, required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final mq     = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final botPad = mq.padding.bottom;

    return Stack(children: [
      // ── Full background image ────────────────────────────────────────────
      Positioned.fill(
        child: Image.asset('assets/logos/bg_image.png', fit: BoxFit.cover),
      ),
      Positioned.fill(
        child: Container(color: const Color(0xEC060E1E)),
      ),

      // ── Content fills entire screen (Positioned.fill gives Column a
      //    constrained height so Expanded works correctly) ──────────────────
      Positioned.fill(
        child: LayoutBuilder(builder: (ctx, constraints) {
          // Brand section = 36 % of screen height, clamped to sane range
          final brandH = (constraints.maxHeight * 0.36).clamp(150.0, 270.0);

          return Column(children: [
            // Top: brand section
            SizedBox(
              height: brandH,
              child: Padding(
                padding: EdgeInsets.fromLTRB(40, topPad + 12, 40, 12),
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Image.asset('assets/logos/fleetara_logo.png',
                    width: 76, height: 76),
                  const SizedBox(height: 14),
                  const Text('Fleetara',
                    style: TextStyle(
                      color: Colors.white, fontSize: 32,
                      fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  const Text(
                    'Smart fleet management,\ndriving your business forward.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54, fontSize: 13, height: 1.5)),
                ]),
              ),
            ),

            // Bottom: dark form card — Expanded fills ALL remaining space
            // so the card always reaches the bottom with no gap.
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF0C1A2E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 28, 24, botPad + 28),
              child: Form(
                key: formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Welcome back',
                    style: TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  const Text('Sign in to continue to your account',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
                  const SizedBox(height: 24),

                  // ── Email ──────────────────────────────────────────────
                  const _DarkLabel('Email address'),
                  const SizedBox(height: 8),
                  _DarkField(
                    controller: emailCtrl,
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your email';
                      if (!v.contains('@'))       return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Password ───────────────────────────────────────────
                  Row(children: [
                    const _DarkLabel('Password'),
                    const Spacer(),
                    GestureDetector(
                      onTap: onForgot,
                      child: const Text('Forgot password?',
                        style: TextStyle(
                          color: AppTheme.accent, fontSize: 12,
                          fontWeight: FontWeight.w500)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  _DarkField(
                    controller: passCtrl,
                    hint: 'Enter your password',
                    icon: Icons.lock_outline,
                    obscureText: obscure,
                    suffix: IconButton(
                      icon: Icon(
                        obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                        color: Colors.white38, size: 18),
                      onPressed: onToggleObscure,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your password' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Remember me ────────────────────────────────────────
                  GestureDetector(
                    onTap: onToggleRemember,
                    behavior: HitTestBehavior.opaque,
                    child: Row(children: [
                      SizedBox(
                        width: 20, height: 20,
                        child: Checkbox(
                          value: rememberMe,
                          onChanged: (_) => onToggleRemember(),
                          checkColor: Colors.white,
                          fillColor: WidgetStateProperty.resolveWith((s) =>
                              s.contains(WidgetState.selected)
                                  ? AppTheme.accent
                                  : Colors.transparent),
                          side: const BorderSide(color: Colors.white38, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('Remember me',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(height: 22),

                  // ── Sign In button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: loading ? null : onLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: loading
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                        : const Text('Sign In',
                            style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── OR divider ─────────────────────────────────────────
                  Row(children: [
                    Expanded(child: Divider(
                      color: Colors.white.withValues(alpha: 0.12), thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('or',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 13))),
                    Expanded(child: Divider(
                      color: Colors.white.withValues(alpha: 0.12), thickness: 1)),
                  ]),
                  const SizedBox(height: 22),

                  // ── Google button ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.22)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _GoogleG(),
                          SizedBox(width: 12),
                          Text('Sign in with Google',
                            style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600,
                              color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // ── Sign up link ───────────────────────────────────────
                  Center(child: Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?",
                        style: TextStyle(color: Colors.white38, fontSize: 13)),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: const Text('Sign up',
                          style: TextStyle(
                            color: AppTheme.accent, fontSize: 13,
                            fontWeight: FontWeight.w600)),
                      ),
                    ],
                  )),
                ]),   // Column(children:[...]) — form fields
              ),     // Form
            ),       // SingleChildScrollView
          ),         // Container
        ),           // Expanded
      ]);            // Column([SizedBox brand, Expanded card])
    }),              // LayoutBuilder builder
  ),                 // Positioned.fill
]);
  }
}

// ── Shared dark-theme helpers ────────────────────────────────────────────────

class _DarkLabel extends StatelessWidget {
  final String text;
  const _DarkLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(
      color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500));
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String   hint;
  final IconData icon;
  final bool     obscureText;
  final Widget?  suffix;
  final TextInputType?            keyboardType;
  final String? Function(String?)? validator;

  const _DarkField({
    required this.controller, required this.hint, required this.icon,
    this.obscureText = false, this.suffix, this.keyboardType, this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:   controller,
    obscureText:  obscureText,
    keyboardType: keyboardType,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    validator: validator,
    decoration: InputDecoration(
      filled:      true,
      fillColor:   const Color(0xFF0A1628),
      hintText:    hint,
      hintStyle:   const TextStyle(color: Colors.white30, fontSize: 14),
      prefixIcon:  Icon(icon, color: Colors.white38, size: 18),
      suffixIcon:  suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.rose)),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.rose, width: 1.5)),
      errorStyle: const TextStyle(color: AppTheme.rose),
    ),
  );
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) => Container(
    width: 22, height: 22,
    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    child: const Center(
      child: Text('G',
        style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4)))),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// DESKTOP — responsive two-panel design
// ════════════════════════════════════════════════════════════════════════════

class _DesktopView extends StatelessWidget {
  final double totalWidth;
  final GlobalKey<FormState>  formKey;
  final TextEditingController emailCtrl, passCtrl;
  final bool obscure, rememberMe, loading;
  final VoidCallback onToggleObscure, onToggleRemember, onForgot, onLogin;

  const _DesktopView({
    required this.totalWidth,
    required this.formKey, required this.emailCtrl, required this.passCtrl,
    required this.obscure, required this.rememberMe, required this.loading,
    required this.onToggleObscure, required this.onToggleRemember,
    required this.onForgot, required this.onLogin,
  });

  // Compute scale helpers based on total screen width
  bool get _narrow  => totalWidth < 1080;
  bool get _compact => totalWidth < 960;

  @override
  Widget build(BuildContext context) {
    final hPad       = _compact ? 24.0 : _narrow ? 36.0 : 52.0;
    final formMax    = _compact ? 300.0 : _narrow ? 340.0 : 390.0;
    final badgePadH  = _compact ? 20.0 : _narrow ? 32.0 : 48.0;

    return Row(children: [
      // ── Left brand panel ──────────────────────────────────────────────
      Expanded(
        flex: 5,
        child: _LeftPanel(narrow: _narrow, compact: _compact),
      ),

      // ── Right form panel ──────────────────────────────────────────────
      Expanded(
        flex: 4,
        child: Container(
          color: AppTheme.surface,
          child: Column(children: [
            const _TopBar(),
            // LayoutBuilder gives SingleChildScrollView a real maxHeight so
            // it can scroll when the form overflows, and Center works when
            // the form is shorter than the available space.
            Expanded(
              child: LayoutBuilder(builder: (ctx, box) =>
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: box.maxHeight - 48),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: formMax),
                        child: _DesktopForm(
                          formKey:          formKey,
                          emailCtrl:        emailCtrl,
                          passCtrl:         passCtrl,
                          obscure:          obscure,
                          rememberMe:       rememberMe,
                          loading:          loading,
                          onToggleObscure:  onToggleObscure,
                          onToggleRemember: onToggleRemember,
                          onForgot:         onForgot,
                          onLogin:          onLogin,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _TrustBadges(hPad: badgePadH),
          ]),
        ),
      ),
    ]);
  }
}

// ── Left panel ───────────────────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  final bool narrow, compact;
  const _LeftPanel({this.narrow = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final pad       = compact ? 28.0 : narrow ? 36.0 : 48.0;
    final titleSize = compact ? 28.0 : narrow ? 32.0 : 38.0;
    final bodySize  = compact ? 12.0 : 14.0;

    return Stack(children: [
      Positioned.fill(
        child: Image.asset('assets/logos/bg_image.png', fit: BoxFit.cover)),
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0D1B3E).withValues(alpha: 0.88),
                const Color(0xFF1E3A72).withValues(alpha: 0.72),
              ],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      Positioned.fill(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Logo
            Row(children: [
              Image.asset('assets/logos/fleetara_logo.png',
                width: compact ? 36 : 44, height: compact ? 36 : 44),
              const SizedBox(width: 12),
              Text('Fleetara',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 17 : 20,
                  fontWeight: FontWeight.w700, letterSpacing: 0.3)),
            ]),
            SizedBox(height: compact ? 20 : 28),

            // Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical:   compact ? 6  : 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22), width: 1)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.smart_toy_outlined,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: compact ? 12 : 14),
                SizedBox(width: compact ? 6 : 8),
                Text('POWERING MODERN FLEETS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: compact ? 9 : 11,
                    fontWeight: FontWeight.w600, letterSpacing: 1.0)),
              ]),
            ),

            SizedBox(height: compact ? 28 : 44),

            // Headline
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: titleSize, fontWeight: FontWeight.w800,
                  height: 1.2, letterSpacing: -0.5),
                children: const [
                  TextSpan(text: 'Your Fleet.\nOur ',
                    style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'Priority.',
                    style: TextStyle(color: Color(0xFF3B82F6))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Manage, track and deliver with complete\nvisibility across your entire fleet.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: bodySize, height: 1.6)),
            SizedBox(height: compact ? 24 : 36),

            // Feature list
            ...[
              ('Real-time GPS tracking',         Icons.location_on_outlined),
              ('Digital vehicle inspections',    Icons.assignment_turned_in_outlined),
              ('Automated trip management',      Icons.route_outlined),
              ('Financial reporting & invoices', Icons.receipt_long_outlined),
            ].map((item) => Padding(
              padding: EdgeInsets.only(bottom: compact ? 7 : 10),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 14,
                  vertical:   compact ? 9  : 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14), width: 0.8)),
                child: Row(children: [
                  Icon(item.$2,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: compact ? 15 : 18),
                  SizedBox(width: compact ? 9 : 12),
                  Expanded(child: Text(item.$1,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis)),
                  Icon(Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.45),
                    size: compact ? 15 : 18),
                ]),
              ),
            )),

            SizedBox(height: compact ? 24 : 36),

            // Trusted banner
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical:   compact ? 9  : 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14), width: 0.8)),
              child: Row(children: [
                Container(
                  width: compact ? 30 : 36, height: compact ? 30 : 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.shield_outlined,
                    color: const Color(0xFF3B82F6), size: compact ? 16 : 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text('Trusted by modern fleets',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: compact ? 11 : 13, fontWeight: FontWeight.w600)),
                    Text('Secure. Reliable. Always on.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: compact ? 10 : 11)),
                  ]),
                ),
                Icon(Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.40),
                  size: compact ? 15 : 18),
              ]),
            ),
            SizedBox(height: compact ? 14 : 20),

            Text('© 2026 Fleetara Trucking Solutions',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: compact ? 10 : 11)),
          ]),           // Column
        ),              // SingleChildScrollView
      ),                // Positioned.fill
    ]);                 // Stack
  }
}

// ── Top bar (right panel header) ─────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border, width: 1),
          borderRadius: BorderRadius.circular(9)),
        child: const Icon(Icons.dark_mode_outlined,
          size: 17, color: AppTheme.textPrimary),
      ),
      const SizedBox(width: 8),
      Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border, width: 1),
          borderRadius: BorderRadius.circular(9)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.language, size: 15, color: AppTheme.textPrimary),
          SizedBox(width: 5),
          Text('EN',
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary)),
          SizedBox(width: 3),
          Icon(Icons.keyboard_arrow_down, size: 15, color: AppTheme.textMuted),
        ]),
      ),
    ]),
  );
}

// ── Trust badges (right panel footer) ────────────────────────────────────────

class _TrustBadges extends StatelessWidget {
  final double hPad;
  const _TrustBadges({this.hPad = 48});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppTheme.border, width: 0.8))),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _TrustBadge(icon: Icons.shield_outlined,
          title: 'Enterprise Grade', subtitle: 'Security'),
        _TrustBadge(icon: Icons.cloud_outlined,
          title: '99.9% Uptime', subtitle: 'Reliable Platform'),
        _TrustBadge(icon: Icons.lock_outline,
          title: 'Your Data', subtitle: 'Always Protected'),
      ],
    ),
  );
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _TrustBadge({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: AppTheme.textMuted),
    const SizedBox(width: 7),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
        style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      Text(subtitle,
        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
    ]),
  ]);
}

// ── Desktop login form (light theme) ─────────────────────────────────────────

class _DesktopForm extends StatelessWidget {
  final GlobalKey<FormState>  formKey;
  final TextEditingController emailCtrl, passCtrl;
  final bool obscure, rememberMe, loading;
  final VoidCallback onToggleObscure, onToggleRemember, onForgot, onLogin;

  const _DesktopForm({
    required this.formKey, required this.emailCtrl, required this.passCtrl,
    required this.obscure, required this.rememberMe, required this.loading,
    required this.onToggleObscure, required this.onToggleRemember,
    required this.onForgot, required this.onLogin,
  });

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Welcome back',
        style: TextStyle(
          fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      const SizedBox(height: 5),
      const Text('Sign in to your Fleetara account',
        style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
      const SizedBox(height: 28),

      // Email
      TextFormField(
        controller: emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          hintText:   'Email address',
          prefixIcon: Icon(Icons.email_outlined, size: 18)),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Enter your email';
          if (!v.contains('@'))       return 'Enter a valid email';
          return null;
        },
      ),
      const SizedBox(height: 12),

      // Password
      TextFormField(
        controller:  passCtrl,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText:   'Password',
          prefixIcon: const Icon(Icons.lock_outline, size: 18),
          suffixIcon: IconButton(
            icon: Icon(
              obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined, size: 18),
            onPressed: onToggleObscure,
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null,
      ),
      const SizedBox(height: 10),

      // Forgot + Remember row
      Row(children: [
        SizedBox(
          width: 18, height: 18,
          child: Checkbox(
            value: rememberMe,
            onChanged: (_) => onToggleRemember(),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: const BorderSide(color: AppTheme.border, width: 1.5),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        const Text('Remember me',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        const Spacer(),
        GestureDetector(
          onTap: onForgot,
          child: const Text('Forgot password?',
            style: TextStyle(
              fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.w500)),
        ),
      ]),
      const SizedBox(height: 22),

      // Sign in button
      ElevatedButton(
        onPressed: loading ? null : onLogin,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: AppTheme.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: loading
          ? const SizedBox(height: 18, width: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Sign in',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 15, color: Colors.white),
            ]),
      ),
      const SizedBox(height: 20),

      // OR divider
      Row(children: [
        const Expanded(child: Divider(color: AppTheme.border, thickness: 0.8)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500))),
        const Expanded(child: Divider(color: AppTheme.border, thickness: 0.8)),
      ]),
      const SizedBox(height: 20),

      // Create account button
      OutlinedButton(
        onPressed: () => context.go('/register'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppTheme.border),
          foregroundColor: AppTheme.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Text('Create a new account',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Spacer(),
            Icon(Icons.person_add_outlined, size: 17, color: AppTheme.textMuted),
          ],
        ),
      ),
    ]),
  );
}
