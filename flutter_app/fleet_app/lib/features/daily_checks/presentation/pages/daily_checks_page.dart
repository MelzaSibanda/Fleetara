import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/responsive.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class DailyChecksPage extends StatefulWidget {
  const DailyChecksPage({super.key});
  @override State<DailyChecksPage> createState() => _DailyChecksPageState();
}

class _DailyChecksPageState extends State<DailyChecksPage> {
  List   _checks    = [];
  List   _allChecks = [];
  bool   _loading   = true;
  String _filter    = 'all';
  final _fs = sl<FirestoreService>();

  static const _filters = ['all', 'pass', 'minor_issue', 'critical'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await _fs.db.collection('daily_checks').get();
      _allChecks = _fs.docsToList(snap)
        ..sort((a, b) {
          final da = (a['check_date'] ?? '').toString();
          final db = (b['check_date'] ?? '').toString();
          return db.compareTo(da);
        });
      _applyFilter();
      setState(() => _loading = false);
    } catch (_) { setState(() => _loading = false); }
  }

  void _applyFilter() {
    setState(() {
      _checks = _filter == 'all'
          ? List.from(_allChecks)
          : _allChecks
              .where((c) => (c['overall_status'] ?? '') == _filter)
              .toList();
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pass':        return AppTheme.emerald;
      case 'minor_issue': return AppTheme.amber;
      case 'critical':    return AppTheme.rose;
      default:            return AppTheme.textMuted;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'pass':        return Icons.check_circle_outline;
      case 'minor_issue': return Icons.warning_amber_outlined;
      case 'critical':    return Icons.cancel_outlined;
      default:            return Icons.help_outline;
    }
  }

  String _filterLabel(String f) {
    switch (f) {
      case 'all':         return 'All';
      case 'pass':        return 'Pass';
      case 'minor_issue': return 'Minor Issue';
      case 'critical':    return 'Critical';
      default:            return f;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Daily Checks',
      actions: [
        ElevatedButton.icon(
          onPressed: () => context.go('/daily-checks/add'),
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text('New Check', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14)),
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
                  onTap: () { setState(() => _filter = f); _applyFilter(); },
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
                        width: active ? 1.0 : 0.5)),
                    child: Text(_filterLabel(f), style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? AppTheme.accent : AppTheme.textMuted)),
                  ),
                ),
              );
            }).toList()),
          ),
        ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: AppTheme.accent, strokeWidth: 2))
            : _checks.isEmpty
              ? EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No daily checks',
                  subtitle: 'Pre-trip vehicle checks will appear here.',
                  action: ElevatedButton(
                    onPressed: () => context.go('/daily-checks/add'),
                    child: const Text('Submit Check')),
                )
              : RListBody(
                  twoColumn: true,
                  onRefresh: _load,
                  cards: _checks.map((c) => _CheckCard(
                    check:       Map<String, dynamic>.from(c),
                    statusColor: _statusColor,
                    statusIcon:  _statusIcon,
                  )).toList(),
                ),
        ),
      ]),
    );
  }
}

class _CheckCard extends StatelessWidget {
  final Map<String, dynamic>        check;
  final Color    Function(String)   statusColor;
  final IconData Function(String)   statusIcon;
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

    final issues = <String>[];
    final tyreList = ['tyre_fl','tyre_fr','tyre_rl','tyre_rr']
        .map((k) => check[k]?.toString() ?? 'good').toList();
    if (tyreList.any((t) => t == 'damaged' || t == 'burst_risk')) {
      issues.add('Critical tyre');
    } else if (tyreList.any((t) => t == 'worn' || t == 'low_pressure')) {
      issues.add('Tyre wear');
    }
    if (check['oil_level'] == 'critical' || check['coolant_level'] == 'critical' ||
        check['brake_fluid'] == 'critical') {
      issues.add('Fluid critical');
    } else if (check['oil_level'] == 'low' || check['coolant_level'] == 'low' ||
        check['brake_fluid'] == 'low') {
      issues.add('Fluid low');
    }
    if (check['brake_response'] == false || check['air_pressure'] == false) {
      issues.add('Brakes');
    }
    if (check['headlights'] == false || check['brake_lights'] == false ||
        check['indicators'] == false) {
      issues.add('Lights');
    }
    if (check['fire_extinguisher'] == false) { issues.add('Fire ext missing'); }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: status == 'critical'
        ? BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.rose.withValues(alpha: 0.25), width: 1),
            boxShadow: [BoxShadow(
              color: AppTheme.rose.withValues(alpha: 0.06),
              blurRadius: 16, offset: const Offset(0, 6))])
        : AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(statusIcon(status), color: sc, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(reg.isNotEmpty ? reg : 'Vehicle',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
              if (driver.isNotEmpty)
                Text(driver, style: const TextStyle(
                  fontSize: 11, color: AppTheme.textMuted)),
            ])),
            StatusPill(
              label: status == 'minor_issue' ? 'Minor Issue'
                : '${status[0].toUpperCase()}${status.substring(1)}',
              color: sc),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5, color: AppTheme.border),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textMuted),
            const SizedBox(width: 5),
            Text(date.length >= 10 ? date.substring(0, 10) : date,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(width: 14),
            const Icon(Icons.speed_outlined, size: 12, color: AppTheme.textMuted),
            const SizedBox(width: 5),
            Text('$odo km',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ]),
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.rose.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 13, color: AppTheme.rose),
                const SizedBox(width: 6),
                Text('Issues: ${issues.join('  ·  ')}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.rose,
                    fontWeight: FontWeight.w500)),
              ]),
            ),
          ],
          if ((check['notes'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(check['notes'].toString(),
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ]),
      ),
    );
  }
}
