import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';
import '../bloc/vehicle_bloc.dart';
import '../../data/vehicle_model.dart';

class VehiclesPage extends StatelessWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VehicleBloc()..add(LoadVehicles()),
      child: AppShell(
        title: 'Vehicles',
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/vehicles/add'),
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Vehicle', style: TextStyle(color: Colors.white)),
        ),
        child: BlocBuilder<VehicleBloc, VehicleState>(
          builder: (context, state) {
            if (state is VehicleLoading) return const Center(child: CircularProgressIndicator());
            if (state is VehicleError)   return Center(child: Text(state.message));
            if (state is VehiclesLoaded) {
              return DefaultTabController(
                length: 2,
                child: Column(children: [
                  const TabBar(
                    labelColor: AppTheme.primary,
                    tabs: [Tab(text: 'Horses (Trucks)'), Tab(text: 'Trailers')],
                  ),
                  Expanded(child: TabBarView(children: [
                    _VehicleList(vehicles: state.horses),
                    _VehicleList(vehicles: state.trailers),
                  ])),
                ]),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _VehicleList extends StatelessWidget {
  final List<VehicleModel> vehicles;
  const _VehicleList({required this.vehicles});

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No vehicles yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Tap the button below to add one.', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vehicles.length,
      itemBuilder: (_, i) => _VehicleCard(vehicle: vehicles[i]),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final statusColor = vehicle.status == 'active'
      ? AppTheme.success
      : vehicle.status == 'maintenance' ? AppTheme.warning : Colors.grey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(vehicle.registrationNumber,
              style: Theme.of(context).textTheme.titleMedium)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(vehicle.status,
                style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          Text('${vehicle.make} ${vehicle.model} (${vehicle.year})',
            style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(children: [
            _InfoChip(icon: Icons.speed,       label: '${vehicle.odometer} km'),
            const SizedBox(width: 8),
            _InfoChip(icon: Icons.build_circle, label: '${vehicle.kmUntilService} km to service'),
            if (vehicle.serviceDue) ...[
              const SizedBox(width: 8),
              const _InfoChip(icon: Icons.warning_amber, label: 'Service due', color: AppTheme.warning),
            ],
          ]),
          const SizedBox(height: 12),
          const Divider(),
          Row(children: [
            const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('License: ${vehicle.licenseExpiry}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 16),
            const Icon(Icons.security, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Insurance: ${vehicle.insuranceExpiry}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _InfoChip({required this.icon, required this.label, this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color)),
    ]);
  }
}
