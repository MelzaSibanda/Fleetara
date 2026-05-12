import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/app_shell.dart';

class DriverDashboardPage extends StatelessWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;

    return AppShell(
      title: 'Fleetara',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hello, ${user.firstName}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),

          // Active trip card — teal bg
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 8, height: 8,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('No active trip', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Standby',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 12),
              const Text('—  →  —',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('No trip assigned yet',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: 0,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0% complete', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  Text('ETA: —',     style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // 2-col action grid
          Row(children: [
            Expanded(
              child: _ActionButton(
                label: 'Complete trip',
                color: AppTheme.primary,
                icon:  Icons.check_circle_outline,
                onTap: () => context.go('/trips'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                label: 'Log fuel stop',
                color: AppTheme.amber,
                icon:  Icons.local_gas_station,
                onTap: () => context.go('/fuel/add'),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // Today's stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Today's stats",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              Row(children: const [
                Expanded(child: _StatItem(label: 'Distance',    value: '0 km')),
                Expanded(child: _StatItem(label: 'Fuel',        value: '0 L')),
                Expanded(child: _StatItem(label: 'Drive time',  value: '0 h')),
                Expanded(child: _StatItem(label: 'Driver score',value: '—',  valueColor: AppTheme.emerald)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // Report breakdown row
          GestureDetector(
            onTap: () => context.go('/repairs/add'),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.rose.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppTheme.rose, size: 16),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Report breakdown',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
                const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String   label;
  final Color    color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
        ]),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String  label;
  final String  value;
  final Color   valueColor;
  const _StatItem({required this.label, required this.value, this.valueColor = AppTheme.textPrimary});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: valueColor)),
    const SizedBox(height: 2),
    Text(label,  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
  ]);
}
