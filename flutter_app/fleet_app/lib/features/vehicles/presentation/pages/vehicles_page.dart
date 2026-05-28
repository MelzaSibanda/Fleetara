import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';
import '../../../../core/utils/responsive.dart';
import '../bloc/vehicle_bloc.dart';
import '../../data/vehicle_model.dart';
import 'edit_vehicle_page.dart';

class VehiclesPage extends StatelessWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VehicleBloc()..add(LoadVehicles()),
      child: BlocConsumer<VehicleBloc, VehicleState>(
        listener: (context, state) {
          if (state is VehicleDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Vehicle deleted', style: TextStyle(color: Colors.white)),
              backgroundColor: AppTheme.emerald));
            context.read<VehicleBloc>().add(LoadVehicles());
          }
          if (state is VehicleError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message, style: const TextStyle(color: Colors.white)),
              backgroundColor: AppTheme.rose));
          }
        },
        builder: (context, state) {
          return AppShell(
            title: 'Vehicles',
            actions: [
              ElevatedButton.icon(
                onPressed: () => context.go('/vehicles/add'),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Add vehicle', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 14)),
              ),
              const SizedBox(width: 8),
            ],
            child: Builder(builder: (ctx) {
              if (state is VehicleLoading || state is VehicleDeleting) {
                return const Center(child: CircularProgressIndicator(
                  color: AppTheme.accent, strokeWidth: 2));
              }
              if (state is VehicleError) {
                return Center(child: Text(state.message,
                  style: const TextStyle(color: AppTheme.rose)));
              }
              if (state is VehiclesLoaded) {
                return DefaultTabController(
                  length: 3,
                  child: Column(children: [
                    Container(
                      color: AppTheme.surface,
                      child: const TabBar(
                        labelColor: AppTheme.accent,
                        unselectedLabelColor: AppTheme.textMuted,
                        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                        indicatorColor: AppTheme.accent,
                        indicatorWeight: 2.5,
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
            }),
          );
        },
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
      return EmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No vehicles yet',
        subtitle: 'Add your first vehicle to get started.',
        action: ElevatedButton(
          onPressed: () => context.go('/vehicles/add'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(140, 40)),
          child: const Text('Add Vehicle'),
        ),
      );
    }
    return RListBody(
      twoColumn: true,
      onRefresh: () async => context.read<VehicleBloc>().add(LoadVehicles()),
      cards: vehicles.map((v) => _VehicleCard(vehicle: v)).toList(),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  const _VehicleCard({required this.vehicle});

  Color get _statusColor {
    switch (vehicle.status) {
      case 'active':      return AppTheme.emerald;
      case 'maintenance': return AppTheme.amber;
      case 'on_trip':     return AppTheme.accent;
      case 'inactive':    return AppTheme.textMuted;
      default:            return AppTheme.textMuted;
    }
  }

  String get _statusLabel {
    switch (vehicle.status) {
      case 'active':      return 'Active';
      case 'maintenance': return 'Maintenance';
      case 'on_trip':     return 'On Trip';
      case 'inactive':    return 'Inactive';
      default:            return vehicle.status;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete vehicle'),
        content: Text('Delete ${vehicle.registrationNumber}? This cannot be undone.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<VehicleBloc>().add(DeleteVehicle(vehicle.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose, minimumSize: const Size(80, 36)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = vehicle.serviceIntervalKm > 0
        ? ((vehicle.serviceIntervalKm - vehicle.kmUntilService) /
            vehicle.serviceIntervalKm).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.local_shipping, color: _statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(vehicle.registrationNumber,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
              Text('${vehicle.make} ${vehicle.model} · ${vehicle.year}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ])),
            StatusPill(label: _statusLabel, color: _statusColor),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textMuted),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (value) {
                if (value == 'edit') {
                  final bloc = context.read<VehicleBloc>();
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => EditVehiclePage(vehicle: vehicle)))
                    .then((_) => bloc.add(LoadVehicles()));
                } else if (value == 'delete') {
                  _confirmDelete(context);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 16, color: AppTheme.accent),
                    const SizedBox(width: 10),
                    const Text('Edit', style: TextStyle(fontSize: 13)),
                  ])),
                const PopupMenuItem(value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 16, color: AppTheme.rose),
                    SizedBox(width: 10),
                    Text('Delete', style: TextStyle(fontSize: 13, color: AppTheme.rose)),
                  ])),
              ],
            ),
          ]),
          const SizedBox(height: 14),
          // Service progress
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              Row(children: [
                _DataCell(label: 'Odometer', value: '${vehicle.odometer} km'),
                _DataCell(
                  label: 'To service',
                  value: '${vehicle.kmUntilService} km',
                  valueColor: vehicle.serviceDue ? AppTheme.rose : AppTheme.emerald),
                _DataCell(label: 'Type',
                  value: vehicle.type == 'horse' ? 'Horse' : 'Trailer'),
              ]),
              const SizedBox(height: 8),
              FleetProgressBar(value: progress),
            ]),
          ),
          const SizedBox(height: 10),
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
              StatusPill(label: 'Service due', color: AppTheme.rose),
            ],
          ]),
        ]),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String label, value;
  final Color  valueColor;
  const _DataCell({required this.label, required this.value,
    this.valueColor = AppTheme.textPrimary});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
        color: valueColor)),
    ]),
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
