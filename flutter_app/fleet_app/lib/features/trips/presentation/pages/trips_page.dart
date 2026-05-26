import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
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
  final _fs = sl<FirestoreService>();

  static const _filters = ['all', 'scheduled', 'in_progress', 'completed', 'cancelled'];

  @override
  void initState() { super.initState(); _loadTrips(); }

  Future<void> _loadTrips() async {
    setState(() => _loading = true);
    try {
      var query = _fs.db.collection('trips') as dynamic;
      if (_filter != 'all') {
        query = _fs.db.collection('trips').where('status', isEqualTo: _filter);
      } else {
        query = _fs.db.collection('trips');
      }
      final snap = await query.get();
      setState(() {
        _trips   = (_fs.docsToList(snap) as List)
            .map((j) => TripModel.fromJson(j as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _deleteTrip(TripModel trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete trip',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        content: Text('Delete trip to ${trip.destination}?\nThis cannot be undone.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose, minimumSize: const Size(80, 36)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _fs.db.collection('trips').doc(trip.id).delete();
      _loadTrips();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trip deleted', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
      }
    }
  }

  String _filterLabel(String f) => f == 'all' ? 'All'
    : f.replaceAll('_', ' ').split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Trips',
      actions: [
        TextButton.icon(
          onPressed: () async { await context.push('/trips/add'); _loadTrips(); },
          icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
          label: const Text('New trip', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
        ),
        const SizedBox(width: 8),
      ],
      child: Column(children: [
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
                        width: 0.5),
                    ),
                    child: Text(_filterLabel(f),
                      style: TextStyle(fontSize: 12,
                        fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                        color: active ? AppTheme.primary : AppTheme.textMuted)),
                  ),
                ),
              );
            }).toList()),
          ),
        ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
            : _trips.isEmpty
              ? EmptyState(
                  icon: Icons.route_outlined,
                  title: 'No trips found',
                  subtitle: 'Trips will appear here once created.',
                  action: TextButton.icon(
                    onPressed: () => context.go('/trips/add'),
                    icon: const Icon(Icons.add, color: AppTheme.primary),
                    label: const Text('New trip', style: TextStyle(color: AppTheme.primary)),
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
                      onTap: () async {
                        await context.push('/trips/${_trips[i].id}');
                        _loadTrips();
                      },
                      onDelete: () => _deleteTrip(_trips[i]),
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
  final VoidCallback onDelete;
  const _TripCard({required this.trip, required this.onTap, required this.onDelete});

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
            Expanded(child: Text(trip.clientName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary))),
            StatusPill(label: trip.statusLabel, color: trip.statusColor),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 16, color: AppTheme.textMuted),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (v) { if (v == 'delete') onDelete(); },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 16, color: AppTheme.rose),
                    SizedBox(width: 10),
                    Text('Delete', style: TextStyle(fontSize: 13, color: AppTheme.rose)),
                  ])),
              ],
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Container(width: 8, height: 8,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(trip.origin,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
          ]),
          Padding(padding: const EdgeInsets.only(left: 3.5),
            child: Container(width: 1, height: 12, color: AppTheme.border,
              margin: const EdgeInsets.symmetric(vertical: 2))),
          Row(children: [
            const Icon(Icons.location_on, size: 10, color: AppTheme.rose),
            const SizedBox(width: 8),
            Expanded(child: Text(trip.destination,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary))),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5, color: AppTheme.border),
          const SizedBox(height: 8),
          Wrap(spacing: 14, runSpacing: 4, children: [
            _meta(Icons.calendar_today_outlined, trip.formattedDate),
            if (trip.driverName.isNotEmpty) _meta(Icons.person_outline, trip.driverName),
            if (trip.horseReg.isNotEmpty)   _meta(Icons.local_shipping_outlined, trip.horseReg),
            _meta(Icons.inventory_2_outlined, trip.cargoType),
          ]),
        ]),
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: AppTheme.textMuted),
    const SizedBox(width: 4),
    Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
  ]);
}
