import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';
import '../../data/trip_model.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});
  @override State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  List<TripModel> _trips   = [];
  bool            _loading = true;
  String          _filter  = 'all';

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
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Trips',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/trips/add'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Trip', style: TextStyle(color: Colors.white)),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppTheme.surface,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final f in ['all', 'scheduled', 'in_progress', 'completed', 'cancelled'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f == 'all' ? 'All' : _capitalize(f)),
                    selected: _filter == f,
                    selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.primary,
                    onSelected: (_) { setState(() => _filter = f); _loadTrips(); },
                  ),
                ),
            ]),
          ),
        ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _trips.isEmpty
              ? const Center(child: Text('No trips found'))
              : RefreshIndicator(
                  onRefresh: _loadTrips,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
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

  String _capitalize(String s) =>
    s.isEmpty ? s : s.replaceAll('_', ' ').split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _TripCard extends StatelessWidget {
  final TripModel    trip;
  final VoidCallback onTap;
  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(trip.clientName,
                style: Theme.of(context).textTheme.titleMedium)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trip.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(trip.statusLabel,
                  style: TextStyle(fontSize: 12,
                    color: trip.statusColor, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.circle, size: 10, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(trip.origin,
                style: Theme.of(context).textTheme.bodyMedium)),
            ]),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Container(width: 2, height: 16,
                color: AppTheme.border,
                margin: const EdgeInsets.symmetric(vertical: 2)),
            ),
            Row(children: [
              const Icon(Icons.location_on, size: 14, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(child: Text(trip.destination,
                style: Theme.of(context).textTheme.bodyMedium)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
              const SizedBox(width: 6),
              Text(trip.scheduledStart.length >= 10
                ? trip.scheduledStart.substring(0, 10) : trip.scheduledStart,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 16),
              const Icon(Icons.inventory_2_outlined, size: 13, color: Colors.grey),
              const SizedBox(width: 6),
              Text(trip.cargoType,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ]),
        ),
      ),
    );
  }
}
