import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/alert_card.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.local_shipping, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Fleetara'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          PopupMenuButton(
            icon: CircleAvatar(
              backgroundColor: AppTheme.primary,
              radius: 16,
              child: Text(
                user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good day, ${user.firstName} 👋', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            Text('Here\'s your fleet overview', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            Text('Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: const [
                StatCard(label: 'Active Trips',   value: '—', icon: Icons.route,         color: AppTheme.primary),
                StatCard(label: 'Total Vehicles', value: '—', icon: Icons.local_shipping, color: AppTheme.secondary),
                StatCard(label: 'Revenue (ZAR)',  value: '—', icon: Icons.attach_money,   color: AppTheme.success),
                StatCard(label: 'Alerts',         value: '—', icon: Icons.warning_amber,  color: AppTheme.warning),
              ],
            ),
            const SizedBox(height: 32),
            Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _QuickActions(),
            const SizedBox(height: 32),
            Text('Alerts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            const AlertCard(
              title:   'No alerts right now',
              message: 'Vehicle documents and service reminders will appear here.',
              type:    AlertType.info,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      {'icon': Icons.add_road,          'label': 'New Trip',  'color': AppTheme.primary},
      {'icon': Icons.local_gas_station, 'label': 'Log Fuel',  'color': AppTheme.accent},
      {'icon': Icons.build_outlined,    'label': 'Service',   'color': AppTheme.warning},
      {'icon': Icons.receipt_long,      'label': 'Invoice',   'color': AppTheme.success},
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: actions.map((a) {
        return GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: (a['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (a['color'] as Color).withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a['icon'] as IconData, color: a['color'] as Color, size: 28),
                const SizedBox(height: 8),
                Text(a['label'] as String,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: a['color'] as Color),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
