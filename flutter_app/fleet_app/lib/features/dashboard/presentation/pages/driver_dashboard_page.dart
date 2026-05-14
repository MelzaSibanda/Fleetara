import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
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
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;

    return BlocProvider(
      create: (_) => sl<DriverHomeBloc>()..add(DriverHomeFetchRequested()),
      child: AppShell(
        title: 'Fleetara',
        child: BlocBuilder<DriverHomeBloc, DriverHomeState>(
          builder: (context, state) {
            final activeTrip = state is DriverHomeLoaded ? state.activeTrip : null;
            final vehicle    = state is DriverHomeLoaded ? state.vehicle    : null;
            final loading    = state is DriverHomeLoading;

            return RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async =>
                context.read<DriverHomeBloc>().add(DriverHomeFetchRequested()),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Greeting
                  Text('Hello, ${user.firstName}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  const Text("Here's your operational summary",
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 16),

                  // Active trip card
                  _ActiveTripCard(trip: activeTrip, loading: loading),
                  const SizedBox(height: 16),

                  // Vehicle card
                  if (vehicle != null && vehicle['horse'] != null)
                    _VehicleCard(vehicle: vehicle),
                  if (vehicle != null && vehicle['horse'] != null)
                    const SizedBox(height: 16),

                  // Quick actions
                  Row(children: [
                    Expanded(child: _ActionButton(
                      label: 'My Trips',
                      color: AppTheme.primary,
                      icon:  Icons.route_outlined,
                      onTap: () => context.go('/driver/trips'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _ActionButton(
                      label: 'Daily Check',
                      color: AppTheme.emerald,
                      icon:  Icons.checklist_outlined,
                      onTap: () => context.go('/driver/checks'),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _ActionButton(
                      label: 'Log Fuel',
                      color: AppTheme.amber,
                      icon:  Icons.local_gas_station,
                      onTap: () => context.go('/fuel/add'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _ActionButton(
                      label: 'Report Issue',
                      color: AppTheme.rose,
                      icon:  Icons.warning_amber_rounded,
                      onTap: () => context.go('/repairs/add'),
                    )),
                  ]),
                  const SizedBox(height: 16),

                  // Today's stats (static for now)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border, width: 0.5),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Today's stats",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary)),
                      const SizedBox(height: 12),
                      Row(children: const [
                        Expanded(child: _StatItem(label: 'Distance',     value: '—')),
                        Expanded(child: _StatItem(label: 'Fuel',         value: '—')),
                        Expanded(child: _StatItem(label: 'Drive time',   value: '—')),
                        Expanded(child: _StatItem(label: 'Safety score', value: '—',
                          valueColor: AppTheme.emerald)),
                      ]),
                    ]),
                  ),
                ],
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
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: loading
        ? const Center(child: SizedBox(height: 18, width: 18,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 8, height: 8,
                decoration: BoxDecoration(
                  color: trip != null ? Colors.white : Colors.white54,
                  shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(trip != null ? 'Active trip' : 'No active trip',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(trip != null ? 'In Progress' : 'Standby',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                    color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              trip != null
                ? '${trip!['origin']} → ${trip!['destination']}'
                : '—  →  —',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              trip != null ? (trip!['client_name'] ?? '') : 'No trip assigned',
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
            if (trip != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: trip!['status'] == 'completed' ? 1.0 : 0.5,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Trip #${trip!['id']}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
                Text('Cargo: ${trip!['cargo_type'] ?? '—'}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ]),
            ],
          ]),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final horse   = vehicle['horse']   as Map<String, dynamic>? ?? {};
    final trailer = vehicle['trailer'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Assigned Vehicle',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _VehicleItem(
            icon: Icons.local_shipping,
            label: 'Horse',
            value: horse['registration_number'] ?? '—',
            sub: '${horse['make'] ?? ''} ${horse['model'] ?? ''}'.trim(),
          )),
          const SizedBox(width: 12),
          Expanded(child: _VehicleItem(
            icon: Icons.rv_hookup,
            label: 'Trailer',
            value: trailer['registration_number'] ?? '—',
            sub: trailer['trailer_type'] ?? '—',
          )),
        ]),
      ]),
    );
  }
}

class _VehicleItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final String   sub;
  const _VehicleItem({required this.icon, required this.label,
    required this.value, required this.sub});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppTheme.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 14, color: AppTheme.primary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ]),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary)),
      Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
    ]),
  );
}

class _ActionButton extends StatelessWidget {
  final String   label;
  final Color    color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color,
    required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(11)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
          color: Colors.white)),
      ]),
    ),
  );
}

class _StatItem extends StatelessWidget {
  final String  label;
  final String  value;
  final Color   valueColor;
  const _StatItem({required this.label, required this.value,
    this.valueColor = AppTheme.textPrimary});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
      color: valueColor)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
  ]);
}
