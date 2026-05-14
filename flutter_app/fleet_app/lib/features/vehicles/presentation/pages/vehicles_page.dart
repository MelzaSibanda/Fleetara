import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';
import '../bloc/vehicle_bloc.dart';
import '../../data/vehicle_model.dart';
import '../../../../core/utils/responsive.dart';

class VehiclesPage extends StatelessWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VehicleBloc()..add(LoadVehicles()),
      child: AppShell(
        title: 'Vehicles',
        actions: [
          ElevatedButton.icon(
            onPressed: () => context.go('/vehicles/add'),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('Add', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
          ),
          const SizedBox(width: 8),
        ],
        child: BlocBuilder<VehicleBloc, VehicleState>(
          builder: (context, state) {
            if (state is VehicleLoading) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2));
            }
            if (state is VehicleError) {
              return Center(child: Text(state.message, style: const TextStyle(color: AppTheme.rose)));
            }
            if (state is VehiclesLoaded) {
              return DefaultTabController(
                length: 3,
                child: Column(children: [
                  Container(
                    color: AppTheme.surface,
                    child: const TabBar(
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: AppTheme.textMuted,
                      labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      indicatorColor: AppTheme.primary,
                      indicatorWeight: 2,
                      tabs: [
                        Tab(text: 'Horses'),
                        Tab(text: 'Trailers'),
                        Tab(text: 'Alerts'),
                      ],
                    ),
                  ),
                  const Divider(height: 0.5, thickness: 0.5, color: AppTheme.border),
                  Expanded(child: TabBarView(children: [
                    _VehicleList(vehicles: state.horses),
                    _VehicleList(vehicles: state.trailers),
                    const _AlertsTab(),
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
      return const EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No vehicles yet',
        subtitle: 'Add your first vehicle to get started.',
      );
    }
    return ListView.builder(
      padding: Responsive.pagePadding(context),
      itemCount: vehicles.length,
      itemBuilder: (_, i) => _VehicleCard(vehicle: vehicles[i]),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  const _VehicleCard({required this.vehicle});

  Color get _statusColor {
    switch (vehicle.status) {
      case 'active':      return AppTheme.primary;
      case 'maintenance': return AppTheme.amber;
      case 'on_trip':     return AppTheme.emerald;
      default:            return AppTheme.textMuted;
    }
  }

  String get _statusLabel {
    switch (vehicle.status) {
      case 'active':      return 'Active';
      case 'maintenance': return 'Maintenance';
      case 'on_trip':     return 'On trip';
      default:            return vehicle.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kmToService = vehicle.kmUntilService;
    final odom        = vehicle.odometer;
    final interval    = 20000;
    final progress    = odom > 0 ? ((interval - kmToService) / interval).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.local_shipping, color: _statusColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(vehicle.registrationNumber,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            Text('${vehicle.make} ${vehicle.model} · ${vehicle.year}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ])),
          _Pill(label: _statusLabel, color: _statusColor),
        ]),
        const SizedBox(height: 12),
        // 3-col data grid
        Row(children: [
          _DataCell(label: 'Odometer',   value: '${vehicle.odometer} km'),
          _DataCell(
            label: 'To service',
            value: '${vehicle.kmUntilService} km',
            valueColor: vehicle.serviceDue ? AppTheme.rose : AppTheme.emerald,
          ),
          const _DataCell(label: 'Driver', value: '—'),
        ]),
        const SizedBox(height: 10),
        // Service progress bar
        FleetProgressBar(value: progress),
        const SizedBox(height: 10),
        // Bottom row
        Row(children: [
          const Icon(Icons.badge_outlined, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text('Licence: ${vehicle.licenseExpiry}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(width: 14),
          const Icon(Icons.security, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text('Insurance: ${vehicle.insuranceExpiry}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          if (vehicle.serviceDue) ...[
            const Spacer(),
            _Pill(label: 'Service due', color: AppTheme.rose),
          ],
        ]),
      ]),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;
  const _DataCell({required this.label, required this.value, this.valueColor = AppTheme.textPrimary});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      const SizedBox(height: 2),
      Text(value,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: valueColor)),
    ]),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color  color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
  );
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context) => const EmptyState(
    icon: Icons.notifications_none_outlined,
    title: 'No vehicle alerts',
    subtitle: 'Licence, insurance, and service alerts will appear here.',
  );
}
