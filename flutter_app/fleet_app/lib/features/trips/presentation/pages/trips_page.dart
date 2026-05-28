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
      final snap = _filter == 'all'
          ? await _fs.db.collection('trips').get()
          : await _fs.db.collection('trips')
              .where('status', isEqualTo: _filter).get();
      setState(() {
        _trips = _fs.docsToList(snap)
            .map((j) => TripModel.fromJson(j))
            .toList();
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _deleteTrip(TripModel trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete trip'),
        content: Text('Delete trip to ${trip.destination}?\nThis cannot be undone.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose, minimumSize: const Size(80, 36)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _fs.db.collection('trips').doc(trip.id).delete();
      _loadTrips();
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Trip deleted', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.emerald)); }
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: $e', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.rose)); }
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
        ElevatedButton.icon(
          onPressed: () async { await context.push('/trips/add'); _loadTrips(); },
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text('New trip', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14)),
        ),
        const SizedBox(width: 8),
      ],
      child: Column(children: [
        _FilterBar(filters: _filters, selected: _filter,
          label: _filterLabel,
          onSelect: (f) { setState(() => _filter = f); _loadTrips(); }),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: AppTheme.accent, strokeWidth: 2))
            : _trips.isEmpty
              ? EmptyState(
                  icon: Icons.route_outlined,
                  title: 'No trips found',
                  subtitle: 'Create your first trip to get started.',
                  action: ElevatedButton(
                    onPressed: () => context.go('/trips/add'),
                    child: const Text('New trip')),
                )
              : RListBody(
                  twoColumn: true,
                  onRefresh: _loadTrips,
                  cards: _trips.map((t) => _TripCard(
                    trip: t,
                    onTap: () async {
                      await context.push('/trips/${t.id}');
                      _loadTrips();
                    },
                    onDelete: () => _deleteTrip(t),
                  )).toList(),
                ),
        ),
      ]),
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onTap, onDelete;
  const _TripCard({required this.trip, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(trip.clientName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary))),
            StatusPill(label: trip.statusLabel, color: trip.statusColor),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textMuted),
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
          const SizedBox(height: 12),
          // Route visualisation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Column(children: [
                Container(width: 9, height: 9,
                  decoration: BoxDecoration(
                    color: AppTheme.accent, shape: BoxShape.circle)),
                Container(width: 1.5, height: 16, color: AppTheme.border,
                  margin: const EdgeInsets.symmetric(vertical: 3)),
                const Icon(Icons.location_on, size: 10, color: AppTheme.rose),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.origin, style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary)),
                  const SizedBox(height: 14),
                  Text(trip.destination, style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary)),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 4, children: [
            _meta(Icons.calendar_today_outlined, trip.formattedDate),
            if (trip.driverName.isNotEmpty) _meta(Icons.person_outline, trip.driverName),
            if (trip.horseReg.isNotEmpty)   _meta(Icons.local_shipping_outlined, trip.horseReg),
            _meta(Icons.inventory_2_outlined, trip.cargoType),
          ]),
        ]),
      ),
    ),
  );

  Widget _meta(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: AppTheme.textMuted),
    const SizedBox(width: 4),
    Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
  ]);
}

// Reusable horizontal filter bar
class _FilterBar extends StatelessWidget {
  final List<String>            filters;
  final String                  selected;
  final String Function(String) label;
  final void Function(String)   onSelect;
  const _FilterBar({required this.filters, required this.selected,
    required this.label, required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
    color: AppTheme.surface,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: filters.map((f) {
        final active = selected == f;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active
                  ? AppTheme.accent.withValues(alpha: 0.10)
                  : AppTheme.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                    ? AppTheme.accent.withValues(alpha: 0.4)
                    : AppTheme.border,
                  width: active ? 1.0 : 0.5),
              ),
              child: Text(label(f), style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppTheme.accent : AppTheme.textMuted)),
            ),
          ),
        );
      }).toList()),
    ),
  );
}
