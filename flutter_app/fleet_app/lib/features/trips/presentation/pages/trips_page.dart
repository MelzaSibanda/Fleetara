import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';
import '../../data/trip_model.dart';
import '../../../../core/utils/responsive.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});
  @override State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  List<TripModel> _trips   = [];
  bool            _loading = true;
  String          _filter  = 'all';

  static const _filters = ['all', 'scheduled', 'in_progress', 'completed', 'cancelled'];

  @override
  void initState() { super.initState(); _loadTrips(); }

  Future<void> _loadTrips() async {
    setState(() => _loading = true);
    try {
      final res = await sl<ApiClient>().dio.get('/trips/',
        queryParameters: _filter != 'all' ? {'status': _filter} : null);
      final list = (res.data['results'] ?? res.data) as List;
      setState(() {
        _trips   = list.map<TripModel>((j) => TripModel.fromJson(j)).toList();
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  String _filterLabel(String f) {
    if (f == 'all') return 'All';
    return f.replaceAll('_', ' ').split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Trips',
      actions: [
        ElevatedButton.icon(
          onPressed: () => context.go('/trips/add'),
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text('New trip', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
        const SizedBox(width: 8),
      ],
      child: Column(children: [
        // Filter chips
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _filters.map((f) {
              final active = _filter == f;
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
                    child: Text(_filterLabel(f),
                      style: TextStyle(
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
        // List
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
            : _trips.isEmpty
              ? EmptyState(
                  icon: Icons.route_outlined,
                  title: 'No trips found',
                  subtitle: 'Trips will appear here once created.',
                  action: ElevatedButton(
                    onPressed: () => context.go('/trips/add'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36)),
                    child: const Text('New trip'),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _loadTrips,
                  child: ListView.builder(
                    padding: Responsive.pagePadding(context),
                    itemCount: _trips.length,
                    itemBuilder: (_, i) => _TripCard(
                      trip: _trips[i],
                      onTap: () => context.go('/trips/${_trips[i].id}'),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripModel    trip;
  final VoidCallback onTap;
  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
            Expanded(
              child: Text(trip.clientName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
            _StatusPill(status: trip.statusLabel, color: trip.statusColor),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Container(width: 8, height: 8,
              decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(trip.origin,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 3.5),
            child: Container(width: 1, height: 12, color: AppTheme.border, margin: const EdgeInsets.symmetric(vertical: 2)),
          ),
          Row(children: [
            const Icon(Icons.location_on, size: 10, color: AppTheme.rose),
            const SizedBox(width: 8),
            Expanded(child: Text(trip.destination,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(
              trip.scheduledStart.length >= 10 ? trip.scheduledStart.substring(0, 10) : trip.scheduledStart,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(width: 14),
            const Icon(Icons.inventory_2_outlined, size: 12, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(trip.cargoType, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ]),
        ]),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final Color  color;
  const _StatusPill({required this.status, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(status,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
  );
}
