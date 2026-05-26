import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});
  @override State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List   _services = [];
  bool   _loading  = true;
  String _filter   = 'all';
  final _fs = sl<FirestoreService>();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = _filter == 'all'
          ? await _fs.db.collection('vehicle_services')
              .orderBy('scheduled_date', descending: true).get()
          : await _fs.db.collection('vehicle_services')
              .where('status', isEqualTo: _filter)
              .orderBy('scheduled_date', descending: true).get();
      setState(() { _services = _fs.docsToList(snap); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'completed':   return AppTheme.emerald;
      case 'in_progress': return AppTheme.primary;
      case 'scheduled':   return AppTheme.amber;
      default:            return AppTheme.textMuted;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'completed':   return Icons.check_circle_outline;
      case 'in_progress': return Icons.build_circle_outlined;
      default:            return Icons.schedule;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'in_progress': return 'In Progress';
      case 'scheduled':   return 'Scheduled';
      case 'completed':   return 'Completed';
      default:            return s;
    }
  }

  String _typeLabel(String t) => t.replaceAll('_', ' ')
    .split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Services',
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/services/upcoming'),
          icon: const Icon(Icons.schedule, size: 16, color: AppTheme.amber),
          label: const Text('Upcoming', style: TextStyle(color: AppTheme.amber, fontSize: 12)),
        ),
      ],
      child: Column(children: [
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final f in ['all', 'scheduled', 'in_progress', 'completed'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () { setState(() => _filter = f); _load(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _filter == f
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : AppTheme.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _filter == f ? AppTheme.primary : AppTheme.border,
                          width: 0.5),
                      ),
                      child: Text(
                        f == 'all' ? 'All' : _statusLabel(f),
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: _filter == f ? AppTheme.primary : AppTheme.textMuted),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _services.isEmpty
              ? EmptyState(
                  icon: Icons.build_outlined,
                  title: 'No service records',
                  subtitle: 'Vehicle service records will appear here.',
                  action: ElevatedButton(
                    onPressed: () => context.go('/services/add'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(160, 40)),
                    child: const Text('Log Service'),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _services.length,
                    itemBuilder: (_, i) => _ServiceCard(
                      service: Map<String, dynamic>.from(_services[i]),
                      statusColor: _statusColor,
                      statusIcon:  _statusIcon,
                      statusLabel: _statusLabel,
                      typeLabel:   _typeLabel,
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final Color    Function(String) statusColor;
  final IconData Function(String) statusIcon;
  final String   Function(String) statusLabel;
  final String   Function(String) typeLabel;

  const _ServiceCard({
    required this.service,
    required this.statusColor,
    required this.statusIcon,
    required this.statusLabel,
    required this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s        = service['status'] ?? 'scheduled';
    final sc       = statusColor(s);
    final type     = service['service_type'] ?? '';
    final date     = (service['scheduled_date'] ?? '').toString();
    final cost     = service['total_cost'] ?? '0';
    final workshop = service['workshop_name'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: sc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon(s), color: sc, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(typeLabel(type),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary)),
            if (workshop.isNotEmpty)
              Text(workshop,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ])),
          StatusPill(label: statusLabel(s), color: sc),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 0.5, color: AppTheme.border),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.calendar_today, size: 13, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(date.length >= 10 ? date.substring(0, 10) : date,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(width: 16),
          const Icon(Icons.speed, size: 13, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text('${service['odometer_at_service'] ?? 0} km',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const Spacer(),
          Text('R $cost',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary)),
        ]),
      ]),
    );
  }
}
