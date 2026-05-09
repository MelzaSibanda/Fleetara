import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class RepairsPage extends StatefulWidget {
  const RepairsPage({super.key});
  @override State<RepairsPage> createState() => _RepairsPageState();
}

class _RepairsPageState extends State<RepairsPage> {
  List   _repairs = [];
  bool   _loading = true;
  String _filter  = 'all';

  static const _filters = ['all', 'critical', 'in_progress', 'resolved'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final params = _filter != 'all' ? {'priority': _filter} : null;
      final res = await sl<ApiClient>().dio.get('/repairs/', queryParameters: params);
      setState(() { _repairs = res.data['results'] ?? res.data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'critical': return AppTheme.rose;
      case 'high':     return AppTheme.amber;
      case 'medium':   return AppTheme.primary;
      default:         return AppTheme.textMuted;
    }
  }

  bool _isCritical(Map r) =>
    r['priority'] == 'critical' && r['status'] != 'resolved';

  String _filterLabel(String f) {
    if (f == 'all') return 'All';
    return '${f[0].toUpperCase()}${f.substring(1).replaceAll('_', ' ')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Repairs & issues',
      actions: [
        ElevatedButton.icon(
          onPressed: () => context.go('/repairs/add'),
          icon: const Icon(Icons.report_problem_outlined, size: 16, color: Colors.white),
          label: const Text('Report issue', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.rose,
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
                  onTap: () { setState(() => _filter = f); _load(); },
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
            : _repairs.isEmpty
              ? EmptyState(
                  icon: Icons.build_outlined,
                  title: 'No repairs reported',
                  subtitle: 'Use "Report issue" to log a breakdown or repair.',
                  action: ElevatedButton(
                    onPressed: () => context.go('/repairs/add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.rose,
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Report issue'),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _repairs.length,
                    itemBuilder: (_, i) {
                      final r = _repairs[i];
                      return _isCritical(r)
                        ? _RepairCardExpanded(repair: r, priorityColor: _priorityColor(r['priority'] ?? 'low'))
                        : _RepairCardCompact(repair: r, priorityColor: _priorityColor(r['priority'] ?? 'low'));
                    },
                  ),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.warning_amber_rounded, color: priorityColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(repair['title'] ?? '',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(repair['priority'] ?? '',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: priorityColor)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(repair['description'] ?? '',
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 14),
        // Timeline
        _TimelineDot(
          color: AppTheme.rose,
          icon:  Icons.flag_outlined,
          title: 'Reported by ${repair['reported_by_name'] ?? 'driver'}',
          time:  dateStr,
          isLast: false,
        ),
        _TimelineDot(
          color: AppTheme.amber,
          icon:  Icons.notifications_outlined,
          title: 'Fleet manager notified',
          time:  'Auto-alert sent',
          isLast: true,
        ),
        const SizedBox(height: 12),
        // Actions
        Row(children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Assign workshop'),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border, width: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textPrimary),
              label: const Text('Call', style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final Color  color;
  final IconData icon;
  final String title;
  final String time;
  final bool   isLast;
  const _TimelineDot({required this.color, required this.icon, required this.title,
    required this.time, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 12),
          ),
          if (!isLast)
            Expanded(child: Container(width: 1, color: AppTheme.border, margin: const EdgeInsets.symmetric(vertical: 2))),
        ]),
        const SizedBox(width: 10),
        Expanded(child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            Text(time,  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ]),
        )),
      ]),
    );
  }
}

class _RepairCardCompact extends StatelessWidget {
  final Map   repair;
  final Color priorityColor;
  const _RepairCardCompact({required this.repair, required this.priorityColor});

  @override
  Widget build(BuildContext context) {
    final reportedAt = (repair['reported_at'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.build_outlined, color: priorityColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(repair['title'] ?? '',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          Text(repair['status'] ?? '',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        Text(reportedAt.length >= 10 ? reportedAt.substring(0, 10) : reportedAt,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ]),
    );
  }
}
