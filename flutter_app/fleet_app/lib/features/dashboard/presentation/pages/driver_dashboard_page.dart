import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class DriverDashboardPage extends StatelessWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleetara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, ${user.firstName} 👋', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 4),
            Text('Driver Dashboard', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            Card(
              child: ListTile(
                leading: const Icon(Icons.route, color: AppTheme.primary),
                title: const Text('My Trips'),
                subtitle: const Text('View and manage your trips'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_gas_station, color: AppTheme.accent),
                title: const Text('Log Fuel'),
                subtitle: const Text('Record a fuel stop'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.build_outlined, color: AppTheme.warning),
                title: const Text('Report Repair'),
                subtitle: const Text('Report a breakdown or issue'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
