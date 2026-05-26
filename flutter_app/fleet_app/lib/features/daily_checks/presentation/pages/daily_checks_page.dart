import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class DailyChecksPage extends StatefulWidget {
  const DailyChecksPage({super.key});
  @override State<DailyChecksPage> createState() => _DailyChecksPageState();
}

class _DailyChecksPageState extends State<DailyChecksPage> {
  List   _checks  = [];
  bool   _loading = true;
  String _filter  = 'all';
  final _fs = sl<FirestoreService>();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = _filter == 'all'
          ? await _fs.db.collection('daily_checks')
              .orderBy('check_date', descending: true).get()
          : await _fs.db.collection('daily_checks')
              .where('overall_status', isEqualTo: _filter)
              .orderBy('check_date', descending: true).get();
      setState(() { _checks = _fs.docsToList(snap); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pass':    return AppTheme.emerald;
      case 'warning': return AppTheme.amber;
      case 'fail':    return AppTheme.rose;
      default:        return AppTheme.textMuted;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'pass':    return Icons.check_circle_outline;
      case 'warning': return Icons.warning_amber_outlined;
      case 'fail':    return Icons.cancel_outlined;
      default:        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Daily Checks',
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/daily-checks/add'),
          icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
          label: const Text('New Check',
            style: TextStyle(color: AppTheme.primary, fontSize: 12)),
        ),
      ],
      child: Column(children: [
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final f in ['all', 'pass', 'warning', 'fail'])
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
                        f == 'all' ? 'All' : '${f[0].toUpperCase()}${f.substring(1)}',
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
            : _checks.isEmpty
              ? EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No daily checks',
                  subtitle: 'Pre-trip vehicle checks will appear here.',
                  action: ElevatedButton(
                    onPressed: () => context.go('/daily-checks/add'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(160, 40)),
                    child: const Text('Submit Check'),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _checks.length,
                    itemBuilder: (_, i) => _CheckCard(
                      check:       Map<String, dynamic>.from(_checks[i]),
                      statusColor: _statusColor,
                      statusIcon:  _statusIcon,
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

class _CheckCard extends StatelessWidget {
  final Map<String, dynamic> check;
  final Color    Function(String) statusColor;
  final IconData Function(String) statusIcon;

  const _CheckCard({required this.check, required this.statusColor,
    required this.statusIcon});

  @override
  Widget build(BuildContext context) {
    final status = check['overall_status'] ?? 'pass';
    final sc     = statusColor(status);
    final date   = (check['check_date'] ?? '').toString();
    final driver = check['driver_name'] ?? '';
    final reg    = check['horse_reg']   ?? '';
    final odo    = check['odometer']    ?? 0;
    final fuel   = (check['fuel_level'] ?? '').toString().replaceAll('_', '/');

    final issues = <String>[];
    if (check['oil_ok']           == false) issues.add('Oil');
    if (check['coolant_ok']       == false) issues.add('Coolant');
    if (check['tyre_pressure_ok'] == false) issues.add('Tyres');
    if (check['lights_ok']        == false) issues.add('Lights');
    if (check['brakes_ok']        == false) issues.add('Brakes');
    if (check['wipers_ok']        == false) issues.add('Wipers');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'fail'    ? AppTheme.rose.withValues(alpha: 0.3)
               : status == 'warning' ? AppTheme.amber.withValues(alpha: 0.3)
               : AppTheme.border,
          width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: sc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon(status), color: sc, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reg.isNotEmpty ? reg : 'Vehicle',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary)),
            if (driver.isNotEmpty)
              Text(driver, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ])),
          StatusPill(
            label: '${status[0].toUpperCase()}${status.substring(1)}',
            color: sc,
          ),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 0.5, color: AppTheme.border),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.calendar_today, size: 13, color: AppTheme.textMuted),
          const SizedBox(width: 5),
          Text(date.length >= 10 ? date.substring(0, 10) : date,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(width: 14),
          const Icon(Icons.speed, size: 13, color: AppTheme.textMuted),
          const SizedBox(width: 5),
          Text('$odo km',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(width: 14),
          const Icon(Icons.local_gas_station, size: 13, color: AppTheme.textMuted),
          const SizedBox(width: 5),
          Text(fuel,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ]),
        if (issues.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.warning_amber, size: 13, color: AppTheme.rose),
            const SizedBox(width: 5),
            Text('Issues: ${issues.join(', ')}',
              style: const TextStyle(fontSize: 11, color: AppTheme.rose,
                fontWeight: FontWeight.w500)),
          ]),
        ],
        if ((check['notes'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(check['notes'].toString(),
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ]),
    );
  }
}
