import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';
import '../../../trips/data/trip_model.dart';

class DriverTripsPage extends StatefulWidget {
  const DriverTripsPage({super.key});
  @override State<DriverTripsPage> createState() => _DriverTripsPageState();
}

class _DriverTripsPageState extends State<DriverTripsPage> {
  List<TripModel> _trips   = [];
  bool            _loading = true;
  String          _filter  = 'all';
  bool            _updating = false;

  static const _filters = ['all', 'scheduled', 'in_progress', 'completed'];

  @override
  void initState() { super.initState(); _loadTrips(); }

  Future<void> _loadTrips() async {
    setState(() => _loading = true);
    try {
      final params = _filter != 'all' ? {'status': _filter} : null;
      final res = await sl<ApiClient>().dio.get('/trips/', queryParameters: params);
      final list = (res.data['results'] ?? res.data) as List;
      setState(() {
        _trips   = list.map<TripModel>((j) => TripModel.fromJson(j)).toList();
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _updateStatus(int tripId, String newStatus) async {
    setState(() => _updating = true);
    try {
      await sl<ApiClient>().dio.patch('/trips/$tripId/status/', data: {'status': newStatus});
      await _loadTrips();
    } catch (_) {} finally {
      setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'My Trips',
      child: Column(children: [
        // Filter bar
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _filters.map((f) {
              final active = _filter == f;
              final label  = f == 'all' ? 'All'
                : f == 'in_progress' ? 'In Progress'
                : f[0].toUpperCase() + f.substring(1);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () { setState(() => _filter = f); _loadTrips(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primary.withValues(alpha: 0.18) : AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.border,
                        width: 0.5,
                      ),
                    ),
                    child: Text(label, style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                      color: active ? AppTheme.primary : AppTheme.textMuted,
                    )),
                  ),
                ),
              );
            }).toList()),
          ),
        ),
        if (_updating)
          const LinearProgressIndicator(color: AppTheme.primary, minHeight: 2),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
            : _trips.isEmpty
              ? const EmptyState(
                  icon: Icons.route_outlined,
                  title: 'No trips found',
                  subtitle: 'Your assigned trips will appear here.',
                )
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _loadTrips,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _trips.length,
                    itemBuilder: (_, i) => _DriverTripCard(
                      trip: _trips[i],
                      onTap: () => context.go('/trips/${_trips[i].id}'),
                      onStatusUpdate: _updateStatus,
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

class _DriverTripCard extends StatelessWidget {
  final TripModel    trip;
  final VoidCallback onTap;
  final Future<void> Function(int, String) onStatusUpdate;
  const _DriverTripCard({required this.trip, required this.onTap, required this.onStatusUpdate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('#${trip.id}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(width: 8),
            Expanded(child: Text(trip.clientName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: trip.statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(trip.statusLabel,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: trip.statusColor)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(trip.origin, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 3.5),
            child: Container(width: 1, height: 10, color: AppTheme.border, margin: const EdgeInsets.symmetric(vertical: 2)),
          ),
          Row(children: [
            const Icon(Icons.location_on, size: 10, color: AppTheme.rose),
            const SizedBox(width: 8),
            Expanded(child: Text(trip.destination, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
          ]),
          const SizedBox(height: 12),
          // Status action buttons
          if (trip.status == 'scheduled')
            _ActionBtn(
              label: 'Start Trip',
              color: AppTheme.primary,
              icon: Icons.play_arrow,
              onTap: () => onStatusUpdate(trip.id, 'in_progress'),
            ),
          if (trip.status == 'in_progress')
            Row(children: [
              Expanded(child: _ActionBtn(
                label: 'Complete',
                color: AppTheme.emerald,
                icon: Icons.check_circle_outline,
                onTap: () => onStatusUpdate(trip.id, 'completed'),
              )),
              const SizedBox(width: 8),
              Expanded(child: _ActionBtn(
                label: 'Log Fuel',
                color: AppTheme.amber,
                icon: Icons.local_gas_station,
                onTap: () => context.go('/fuel/add'),
              )),
            ]),
        ]),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String       label;
  final Color        color;
  final IconData     icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
      ]),
    ),
  );
}
