import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/trip_model.dart';

class TripDetailPage extends StatefulWidget {
  final String tripId;
  const TripDetailPage({super.key, required this.tripId});
  @override State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  TripModel? _trip;
  bool       _loading  = true;
  bool       _updating = false;
  final _fs = sl<FirestoreService>();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final doc = await _fs.db.collection('trips').doc(widget.tripId).get();
      if (doc.exists) {
        setState(() { _trip = TripModel.fromJson(_fs.docToMap(doc)); _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _updateStatus(String newStatus) async {
    final labels = {'in_progress': 'Start', 'completed': 'Complete', 'cancelled': 'Cancel'};
    final colors = {'in_progress': AppTheme.primary, 'completed': AppTheme.emerald,
                    'cancelled': AppTheme.rose};

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('${labels[newStatus]} trip?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        content: Text('Mark trip as ${newStatus.replaceAll('_', ' ')}?',
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors[newStatus], minimumSize: const Size(90, 36)),
            child: Text(labels[newStatus]!),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _updating = true);
    try {
      final updates = <String, dynamic>{'status': newStatus};
      if (newStatus == 'in_progress') updates['actual_start'] = DateTime.now().toIso8601String();
      if (newStatus == 'completed')   updates['actual_end']   = DateTime.now().toIso8601String();
      await _fs.db.collection('trips').doc(widget.tripId).update(updates);

      final route = '${_trip!.origin} → ${_trip!.destination}';
      final notifType = newStatus == 'in_progress' ? 'trip_started'
          : newStatus == 'completed' ? 'trip_completed' : 'trip_cancelled';
      final notifTitle = newStatus == 'in_progress' ? 'Trip started'
          : newStatus == 'completed' ? 'Trip completed' : 'Trip cancelled';
      unawaited(sl<NotificationService>().sendToManagers(
        notifType, notifTitle, route,
        actor: _trip!.driverName,
        data: {
          'origin':      _trip!.origin,
          'destination': _trip!.destination,
          'driver':      _trip!.driverName,
          'horse_reg':   _trip!.horseReg,
          'client':      _trip!.clientName,
          'status':      newStatus,
        },
      ));

      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Trip marked as ${newStatus.replaceAll('_', ' ')}',
            style: const TextStyle(color: Colors.white)),
          backgroundColor: colors[newStatus],
          behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
      }
    } finally {
      setState(() => _updating = false);
    }
  }

  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete trip',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        content: const Text('This trip will be permanently deleted.',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
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
      await _fs.db.collection('trips').doc(widget.tripId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trip deleted', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald, behavior: SnackBarBehavior.floating));
        context.go('/trips');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Trip #${widget.tripId.substring(0, 6)}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/trips'),
        ),
        actions: [
          if (_trip != null && _trip!.status != 'completed' && _trip!.status != 'cancelled')
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit trip',
              onPressed: () async {
                await context.push('/trips/${widget.tripId}/edit', extra: _trip);
                _load();
              },
            ),
          if (_trip != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.rose),
              tooltip: 'Delete trip',
              onPressed: _deleteTrip,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _trip == null
            ? const Center(child: Text('Trip not found'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Status banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _trip!.statusColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _trip!.statusColor.withValues(alpha: 0.25), width: 0.5),
                        ),
                        child: Row(children: [
                          Container(width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: _trip!.statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(_trip!.statusLabel,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                              color: _trip!.statusColor)),
                          const Spacer(),
                          Text(_trip!.formattedDate,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      _card(children: [
                        _label('Route'),
                        const SizedBox(height: 10),
                        Row(children: [
                          Container(width: 9, height: 9,
                            decoration: const BoxDecoration(
                              color: AppTheme.primary, shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_trip!.origin,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
                        ]),
                        Padding(padding: const EdgeInsets.only(left: 4),
                          child: Container(width: 1, height: 16, color: AppTheme.border,
                            margin: const EdgeInsets.symmetric(vertical: 3))),
                        Row(children: [
                          const Icon(Icons.location_on, size: 11, color: AppTheme.rose),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_trip!.destination,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
                        ]),
                      ]),
                      const SizedBox(height: 12),

                      _card(children: [
                        _label('Trip details'),
                        const SizedBox(height: 10),
                        _row(Icons.business_outlined,        'Client',   _trip!.clientName),
                        _row(Icons.inventory_2_outlined,     'Cargo',    '${_cargoLabel(_trip!.cargoType)} — ${_trip!.cargoDescription}'),
                        _row(Icons.calendar_today_outlined,  'Scheduled', _trip!.scheduledStart.length >= 16
                          ? _trip!.scheduledStart.substring(0, 16).replaceAll('T', ' ')
                          : _trip!.scheduledStart),
                        if (_trip!.actualStart != null)
                          _row(Icons.play_arrow_outlined, 'Started',
                            _trip!.actualStart!.length >= 16
                              ? _trip!.actualStart!.substring(0, 16).replaceAll('T', ' ')
                              : _trip!.actualStart!),
                        if (_trip!.actualEnd != null)
                          _row(Icons.check_circle_outline, 'Completed',
                            _trip!.actualEnd!.length >= 16
                              ? _trip!.actualEnd!.substring(0, 16).replaceAll('T', ' ')
                              : _trip!.actualEnd!),
                        if (_trip!.notes != null && _trip!.notes!.isNotEmpty)
                          _row(Icons.notes_outlined, 'Notes', _trip!.notes!),
                      ]),
                      const SizedBox(height: 12),

                      _card(children: [
                        _label('Assigned to'),
                        const SizedBox(height: 10),
                        if (_trip!.driverName.isNotEmpty)
                          _row(Icons.person_outline,           'Driver',  _trip!.driverName),
                        if (_trip!.horseReg.isNotEmpty)
                          _row(Icons.local_shipping_outlined,  'Horse',   _trip!.horseReg),
                        if (_trip!.trailerReg.isNotEmpty)
                          _row(Icons.trolley,                  'Trailer', _trip!.trailerReg),
                        if (_trip!.driverName.isEmpty && _trip!.horseReg.isEmpty)
                          const Text('No assignment details',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      ]),
                      const SizedBox(height: 24),

                      if (_updating)
                        const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                      else
                        _buildActions(),
                    ]),
                  ),
                ),
              ),
    );
  }

  Widget _buildActions() {
    final status = _trip?.status ?? '';
    return Column(children: [
      if (status == 'scheduled') ...[
        ElevatedButton.icon(
          onPressed: () => _updateStatus('in_progress'),
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text('Start Trip'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
        ),
        const SizedBox(height: 10),
        _ghostButton('Cancel Trip', Icons.cancel_outlined, AppTheme.rose,
          () => _updateStatus('cancelled')),
      ],
      if (status == 'in_progress') ...[
        ElevatedButton.icon(
          onPressed: () => _updateStatus('completed'),
          icon: const Icon(Icons.check_circle, size: 18),
          label: const Text('Complete Trip'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.emerald,
            minimumSize: const Size(double.infinity, 44)),
        ),
        const SizedBox(height: 10),
        _ghostButton('Cancel Trip', Icons.cancel_outlined, AppTheme.rose,
          () => _updateStatus('cancelled')),
      ],
      if (status == 'completed' || status == 'cancelled')
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border, width: 0.5)),
          child: Row(children: [
            Icon(status == 'completed' ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: AppTheme.textMuted, size: 18),
            const SizedBox(width: 10),
            Text('This trip is ${status.replaceAll('_', ' ')}.',
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          ]),
        ),
    ]);
  }

  Widget _ghostButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
        ]),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _label(String text) => Text(text,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
      color: AppTheme.textMuted, letterSpacing: 0.5));

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 15, color: AppTheme.textMuted),
      const SizedBox(width: 10),
      SizedBox(width: 80,
        child: Text(label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))),
      Expanded(child: Text(value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary))),
    ]),
  );

  String _cargoLabel(String type) {
    const map = {
      'general': 'General Freight', 'perishable': 'Perishable',
      'hazardous': 'Hazardous', 'oversized': 'Oversized',
      'bulk': 'Bulk', 'other': 'Other',
    };
    return map[type] ?? type;
  }
}
