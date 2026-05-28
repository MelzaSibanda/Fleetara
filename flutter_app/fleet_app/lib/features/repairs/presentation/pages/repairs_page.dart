import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';
import '../../../../core/utils/responsive.dart';

class RepairsPage extends StatefulWidget {
  const RepairsPage({super.key});
  @override State<RepairsPage> createState() => _RepairsPageState();
}

class _RepairsPageState extends State<RepairsPage> {
  List   _repairs = [];
  bool   _loading = true;
  String _filter  = 'all';
  final _fs = sl<FirestoreService>();

  static const _filters = ['all', 'critical', 'in_progress', 'resolved'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = _filter == 'all'
          ? await _fs.db.collection('repairs')
              .orderBy('reported_at', descending: true).get()
          : await _fs.db.collection('repairs')
              .where('priority', isEqualTo: _filter)
              .orderBy('reported_at', descending: true).get();
      setState(() { _repairs = _fs.docsToList(snap); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'critical': return AppTheme.rose;
      case 'high':     return AppTheme.amber;
      case 'medium':   return AppTheme.accent;
      default:         return AppTheme.textMuted;
    }
  }

  bool _isCritical(Map r) =>
    r['priority'] == 'critical' && r['status'] != 'resolved';

  String _filterLabel(String f) => f == 'all' ? 'All'
    : '${f[0].toUpperCase()}${f.substring(1).replaceAll('_', ' ')}';

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Repairs & Issues',
      actions: [
        ElevatedButton.icon(
          onPressed: () => context.go('/repairs/add'),
          icon: const Icon(Icons.report_problem_outlined, size: 16, color: Colors.white),
          label: const Text('Report issue', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.rose,
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14)),
        ),
        const SizedBox(width: 8),
      ],
      child: Column(children: [
        _FilterChips(
          filters: _filters, selected: _filter,
          label: _filterLabel,
          onSelect: (f) { setState(() => _filter = f); _load(); }),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: AppTheme.accent, strokeWidth: 2))
            : _repairs.isEmpty
              ? EmptyState(
                  icon: Icons.build_outlined,
                  title: 'No repairs reported',
                  subtitle: 'Use "Report issue" to log a breakdown or repair.',
                  action: ElevatedButton(
                    onPressed: () => context.go('/repairs/add'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
                    child: const Text('Report issue')),
                )
              : RListBody(
                  onRefresh: _load,
                  cards: _repairs.map((r) {
                    final pc = _priorityColor(r['priority'] ?? 'low');
                    return _isCritical(r)
                      ? _RepairCardExpanded(repair: r, priorityColor: pc)
                      : _RepairCardCompact(repair: r, priorityColor: pc);
                  }).toList(),
                ),
        ),
      ]),
    );
  }
}

class _RepairCardExpanded extends StatelessWidget {
  final Map   repair;
  final Color priorityColor;
  const _RepairCardExpanded({required this.repair, required this.priorityColor});

  @override
  Widget build(BuildContext context) {
    final reportedAt = (repair['reported_at'] ?? '').toString();
    final dateStr    = reportedAt.length >= 10 ? reportedAt.substring(0, 10) : reportedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: priorityColor.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: priorityColor.withValues(alpha: 0.06),
            blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.warning_amber_rounded, color: priorityColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(repair['title'] ?? '',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20)),
              child: Text((repair['priority'] ?? '').toString().toUpperCase(),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: priorityColor)),
            ),
          ]),
          const SizedBox(height: 10),
          Text(repair['description'] ?? '',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.5),
            maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          _TimelineDot(color: AppTheme.rose, icon: Icons.flag_outlined,
            title: 'Reported by ${repair['reported_by_name'] ?? 'driver'}',
            time: dateStr, isLast: false),
          _TimelineDot(color: AppTheme.amber, icon: Icons.notifications_outlined,
            title: 'Fleet manager notified',
            time: 'Auto-alert sent', isLast: true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 38)),
                child: const Text('Assign workshop'),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.phone_outlined, size: 16),
              label: const Text('Call'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, 38),
                foregroundColor: AppTheme.textPrimary),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final Color  color;
  final IconData icon;
  final String title, time;
  final bool isLast;
  const _TimelineDot({required this.color, required this.icon, required this.title,
    required this.time, required this.isLast});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 12),
        ),
        if (!isLast)
          Expanded(child: Container(width: 1, color: AppTheme.border,
            margin: const EdgeInsets.symmetric(vertical: 2))),
      ]),
      const SizedBox(width: 10),
      Expanded(child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary)),
          Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ]),
      )),
    ]),
  );
}

class _RepairCardCompact extends StatelessWidget {
  final Map   repair;
  final Color priorityColor;
  const _RepairCardCompact({required this.repair, required this.priorityColor});

  @override
  Widget build(BuildContext context) {
    final reportedAt = (repair['reported_at'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.build_outlined, color: priorityColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(repair['title'] ?? '',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
            Text(repair['status'] ?? '',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusPill(
              label: (repair['priority'] ?? '').toString(),
              color: priorityColor),
            const SizedBox(height: 4),
            Text(reportedAt.length >= 10 ? reportedAt.substring(0, 10) : reportedAt,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ]),
        ]),
      ),
    );
  }
}

// Reusable filter chips
class _FilterChips extends StatelessWidget {
  final List<String>            filters;
  final String                  selected;
  final String Function(String) label;
  final void Function(String)   onSelect;
  const _FilterChips({required this.filters, required this.selected,
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
                  width: active ? 1.0 : 0.5)),
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
