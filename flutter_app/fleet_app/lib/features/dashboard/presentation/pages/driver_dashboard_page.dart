import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../driver/presentation/bloc/driver_home_bloc.dart';
import '../../../driver/presentation/bloc/driver_home_event.dart';
import '../../../driver/presentation/bloc/driver_home_state.dart';
import '../widgets/app_shell.dart';

class DriverDashboardPage extends StatelessWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final user = authState.user;

    return BlocProvider(
      create: (_) => sl<DriverHomeBloc>()..add(DriverHomeFetchRequested()),
      child: AppShell(
        title: 'Dashboard',
        child: BlocBuilder<DriverHomeBloc, DriverHomeState>(
          builder: (context, state) {
            final activeTrip = state is DriverHomeLoaded ? state.activeTrip : null;
            final loading    = state is DriverHomeLoading;

            return RefreshIndicator(
              color: AppTheme.accent,
              onRefresh: () async =>
                context.read<DriverHomeBloc>().add(DriverHomeFetchRequested()),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: ListView(
                    padding: Responsive.pagePadding(context),
                    children: [
                  Text('Hello, ${user.firstName}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  const Text("Here's your operational summary",
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 16),

                  _ActiveTripCard(trip: activeTrip, loading: loading),
                  const SizedBox(height: 14),

                  Row(children: [
                    Expanded(child: _ActionButton(
                      label: 'My Trips', icon: Icons.route_outlined,
                      colors: const [AppTheme.primary, AppTheme.accent],
                      onTap: () => context.go('/driver/trips'))),
                    const SizedBox(width: 12),
                    Expanded(child: _ActionButton(
                      label: 'Daily Check', icon: Icons.checklist_outlined,
                      colors: [AppTheme.emerald, const Color(0xFF0E7A3D)],
                      onTap: () => context.go('/driver/checks'))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _ActionButton(
                      label: 'Log Fuel', icon: Icons.local_gas_station_outlined,
                      colors: [AppTheme.amber, const Color(0xFFD4860A)],
                      onTap: () => context.go('/fuel/add'))),
                    const SizedBox(width: 12),
                    Expanded(child: _ActionButton(
                      label: 'Report Issue', icon: Icons.warning_amber_rounded,
                      colors: [AppTheme.rose, const Color(0xFFCC2B2A)],
                      onTap: () => context.go('/repairs/add'))),
                  ]),
                  const SizedBox(height: 16),

                  Container(
                    decoration: AppTheme.cardDecoration,
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Today's stats",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                      const SizedBox(height: 14),
                      const Row(children: [
                        Expanded(child: _StatItem(label: 'Distance',     value: '—')),
                        Expanded(child: _StatItem(label: 'Fuel used',    value: '—')),
                        Expanded(child: _StatItem(label: 'Drive time',   value: '—')),
                        Expanded(child: _StatItem(label: 'Safety score', value: '—',
                          valueColor: AppTheme.emerald)),
                      ]),
                    ]),
                  ),
                ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final Map<String, dynamic>? trip;
  final bool loading;
  const _ActiveTripCard({this.trip, required this.loading});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.darkNavy, AppTheme.primary],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
        color: AppTheme.darkNavy.withValues(alpha: 0.28),
        blurRadius: 20, offset: const Offset(0, 8))],
    ),
    padding: const EdgeInsets.all(18),
    child: loading
      ? const Center(child: SizedBox(height: 20, width: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 8, height: 8,
              decoration: BoxDecoration(
                color: trip != null ? AppTheme.emerald : Colors.white38,
                shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(trip != null ? 'Active trip' : 'No active trip',
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20)),
              child: Text(trip != null ? 'In Progress' : 'Standby',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 14),
          Text(
            trip != null
              ? '${trip!['origin']}  →  ${trip!['destination']}'
              : '—  →  —',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: Colors.white, letterSpacing: -0.2)),
          const SizedBox(height: 4),
          Text(trip != null ? (trip!['client_name'] ?? '') : 'No trip assigned',
            style: const TextStyle(fontSize: 12, color: Colors.white60)),
          if (trip != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: trip!['status'] == 'completed' ? 1.0 : 0.5,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                color: AppTheme.emerald)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Trip #${trip!['id']}',
                style: const TextStyle(fontSize: 10, color: Colors.white54)),
              Text('Cargo: ${trip!['cargo_type'] ?? '—'}',
                style: const TextStyle(fontSize: 10, color: Colors.white54)),
            ]),
          ],
        ]),
  );
}

class _ActionButton extends StatelessWidget {
  final String   label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon,
    required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
          color: colors.first.withValues(alpha: 0.25),
          blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    ),
  );
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color  valueColor;
  const _StatItem({required this.label, required this.value,
    this.valueColor = AppTheme.textPrimary});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(
      fontSize: 17, fontWeight: FontWeight.w700, color: valueColor)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
  ]);
}
