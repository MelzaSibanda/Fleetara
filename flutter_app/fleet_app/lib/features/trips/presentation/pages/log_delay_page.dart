import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/notification_service.dart';

class LogDelayPage extends StatefulWidget {
  final String tripId;
  final String tripRoute; // "JHB → Lusaka"
  const LogDelayPage({super.key, required this.tripId, required this.tripRoute});

  @override State<LogDelayPage> createState() => _LogDelayPageState();
}

class _LogDelayPageState extends State<LogDelayPage> {
  final _fs      = sl<FirestoreService>();
  bool  _loading = false;
  String _reason = 'border_delay';
  final _notesCtrl = TextEditingController();

  static const _reasons = [
    ('border_delay',  'Border Delay',   Icons.flag_outlined),
    ('traffic',       'Traffic',        Icons.traffic_outlined),
    ('road_closure',  'Road Closure',   Icons.block_outlined),
    ('breakdown',     'Breakdown',      Icons.car_crash_outlined),
    ('accident',      'Accident',       Icons.warning_amber_rounded),
    ('fuel_stop',     'Fuel Stop',      Icons.local_gas_station_outlined),
    ('other',         'Other',          Icons.more_horiz_outlined),
  ];

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _fs.db.collection('trips').doc(widget.tripId).update({
        'delay_status':      'delayed',
        'delay_reason':      _reason,
        'delay_notes':       _notesCtrl.text.trim(),
        'delay_reported_at': DateTime.now().toIso8601String(),
        'official_reason':   '',
      });

      final label = _reasons
          .firstWhere((r) => r.$1 == _reason,
              orElse: () => (_reason, _reason, Icons.info_outline)).$2;

      unawaited(sl<NotificationService>().sendToManagers(
        'trip_delayed', 'Trip delayed',
        '${widget.tripRoute} — $label',
        data: {
          'trip_id':    widget.tripId,
          'route':      widget.tripRoute,
          'reason':     _reason,
          'reason_label': label,
          'notes':      _notesCtrl.text.trim(),
        },
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Delay reported to fleet manager',
            style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating));
        context.go('/driver/trips');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e',
            style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose,
          behavior: SnackBarBehavior.floating));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Report Trip Delay'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/driver/trips'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Trip banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.amber.withValues(alpha: 0.3))),
                child: Row(children: [
                  const Icon(Icons.route_outlined, size: 16, color: AppTheme.amber),
                  const SizedBox(width: 10),
                  Expanded(child: Text(widget.tripRoute,
                    style: const TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                ]),
              ),
              const SizedBox(height: 24),

              const Text('Select delay reason',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
              const SizedBox(height: 12),

              ...(_reasons.map((r) {
                final sel = _reason == r.$1;
                return GestureDetector(
                  onTap: () => setState(() => _reason = r.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primary.withValues(alpha: 0.10)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? AppTheme.primary : AppTheme.border,
                        width: sel ? 1.2 : 0.6)),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.primary.withValues(alpha: 0.12)
                              : AppTheme.background,
                          borderRadius: BorderRadius.circular(9)),
                        child: Icon(r.$3, size: 18,
                          color: sel ? AppTheme.primary : AppTheme.textMuted),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(r.$2,
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500,
                          color: sel ? AppTheme.primary : AppTheme.textPrimary))),
                      if (sel)
                        const Icon(Icons.check_circle,
                          size: 18, color: AppTheme.primary),
                    ]),
                  ),
                );
              })),

              const SizedBox(height: 20),
              const Text('Additional notes (optional)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe the situation…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.amber,
                  minimumSize: const Size(double.infinity, 48)),
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                    : const Text('Report Delay',
                        style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
