import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class RepairsPage extends StatefulWidget {
  const RepairsPage({super.key});
  @override State<RepairsPage> createState() => _RepairsPageState();
}

class _RepairsPageState extends State<RepairsPage> {
  List   _repairs = [];
  bool   _loading = true;
  String _filter  = 'all';
  final  _fs      = sl<FirestoreService>();

  static const _filters = ['all', 'critical', 'in_progress', 'resolved'];

  @override
  void initState() { super.initState(); _load(); }

  List   _allRepairs = [];

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap    = await _fs.db.collection('repairs').get();
      final repairs = _fs.docsToList(snap)
        ..sort((a, b) {
          final ra = (a['reported_at'] ?? '').toString();
          final rb = (b['reported_at'] ?? '').toString();
          return rb.compareTo(ra);
        });

      // Back-fill missing reporter names from users collection
      final missingUids = repairs
        .where((r) => (r['reported_by_name'] ?? '').toString().isEmpty
                   && (r['reported_by'] ?? '').toString().isNotEmpty)
        .map((r) => r['reported_by'].toString())
        .toSet();

      if (missingUids.isNotEmpty) {
        final userCache = <String, String>{};
        await Future.wait(missingUids.map((uid) async {
          try {
            final doc = await _fs.db.collection('users').doc(uid).get();
            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>;
              userCache[uid] = data['full_name']?.toString()
                ?? data['first_name']?.toString() ?? '';
            }
          } catch (_) {}
        }));
        for (final r in repairs) {
          final uid = r['reported_by']?.toString() ?? '';
          if ((r['reported_by_name'] ?? '').toString().isEmpty
              && userCache.containsKey(uid)) {
            r['reported_by_name'] = userCache[uid];
          }
        }
      }

      setState(() { _allRepairs = repairs; _applyFilter(); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _applyFilter() {
    setState(() {
      switch (_filter) {
        case 'critical':
          _repairs = _allRepairs
              .where((r) => (r['priority'] ?? '').toString() == 'critical')
              .toList();
          break;
        case 'in_progress':
          _repairs = _allRepairs
              .where((r) => (r['status'] ?? '').toString() == 'in_progress')
              .toList();
          break;
        case 'resolved':
          _repairs = _allRepairs
              .where((r) => (r['status'] ?? '').toString() == 'resolved')
              .toList();
          break;
        default:
          _repairs = List.from(_allRepairs);
      }
    });
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'critical': return AppTheme.rose;
      case 'high':     return AppTheme.amber;
      case 'medium':   return AppTheme.accent;
      default:         return AppTheme.textMuted;
    }
  }

  String _filterLabel(String f) {
    switch (f) {
      case 'all':         return 'All';
      case 'critical':    return 'Critical';
      case 'in_progress': return 'In progress';
      case 'resolved':    return 'Resolved';
      default:            return f;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Repairs & issues',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/repairs/add'),
          icon: const Icon(Icons.flag_outlined, size: 15),
          label: const Text('Report issue', style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 34),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            foregroundColor: AppTheme.textPrimary,
            side: const BorderSide(color: AppTheme.border, width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 8),
      ],
      child: Column(children: [
        // ── Filter tabs ────────────────────────────────────────────────────
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final active = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () { setState(() => _filter = f); _applyFilter(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: active ? AppTheme.primary : AppTheme.border,
                          width: active ? 1.2 : 0.8,
                        ),
                      ),
                      child: Text(_filterLabel(f),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          color: active ? AppTheme.primary : AppTheme.textMuted,
                        )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // ── List ───────────────────────────────────────────────────────────
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: AppTheme.accent, strokeWidth: 2))
            : _repairs.isEmpty
              ? EmptyState(
                  icon: Icons.build_outlined,
                  title: 'No repairs reported',
                  subtitle: 'Use "Report issue" to log a breakdown or repair.',
                  action: OutlinedButton(
                    onPressed: () => context.go('/repairs/add'),
                    child: const Text('Report issue')),
                )
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _repairs.length,
                    itemBuilder: (_, i) => _RepairCard(
                      repair: _repairs[i],
                      priorityColor: _priorityColor(
                        _repairs[i]['priority']?.toString() ?? ''),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

// ── Unified repair card matching the screenshot ─────────────────────────────
class _RepairCard extends StatelessWidget {
  final Map   repair;
  final Color priorityColor;
  const _RepairCard({required this.repair, required this.priorityColor});

  String _dateStr() {
    final raw = (repair['reported_at'] ?? '').toString();
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  String _timeStr() {
    final raw = (repair['reported_at'] ?? '').toString();
    // ISO string: 2026-05-28T09:42:00 or Firestore timestamp string
    if (raw.length >= 16 && raw.contains('T')) return raw.substring(11, 16);
    if (raw.length >= 16 && raw.contains(' ')) return raw.substring(11, 16);
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final priority   = (repair['priority'] ?? 'low').toString();
    final status     = (repair['status']   ?? '').toString();
    final isResolved = status == 'resolved';
    final isCritical = priority == 'critical' && !isResolved;

    // Footer dot color + message
    final Color  dotColor;
    final String statusMsg;
    if (isResolved) {
      dotColor  = AppTheme.emerald;
      statusMsg = 'Resolved';
    } else if (isCritical) {
      dotColor  = AppTheme.emerald;
      statusMsg = 'Fleet manager notified — auto-alert sent';
    } else {
      dotColor  = AppTheme.amber;
      statusMsg = 'Pending fleet manager review';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header: icon + title + priority badge ───────────────────────
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.warning_amber_rounded,
                color: priorityColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(repair['title'] ?? '',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: priorityColor, width: 1),
              ),
              child: Text(
                '${priority[0].toUpperCase()}${priority.substring(1)}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: priorityColor)),
            ),
          ]),
          const SizedBox(height: 10),

          // ── Description ─────────────────────────────────────────────────
          Text(repair['description'] ?? '',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted,
              height: 1.5),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),

          // ── 2×2 detail grid ─────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border, width: 0.8),
            ),
            child: Column(children: [
              IntrinsicHeight(
                child: Row(children: [
                  _DetailCell(
                    label: 'DATE REPORTED',
                    line1: _dateStr(),
                    line2: _timeStr(),
                  ),
                  Container(width: 0.8, color: AppTheme.border),
                  _DetailCell(
                    label: 'DRIVER',
                    line1: repair['reported_by_name']?.toString() ?? '—',
                    line2: (repair['driver_license'] ?? '').toString().isNotEmpty
                      ? 'License: ${repair['driver_license']}'
                      : '',
                  ),
                ]),
              ),
              Container(height: 0.8, color: AppTheme.border),
              IntrinsicHeight(
                child: Row(children: [
                  _DetailCell(
                    label: 'TRUCK / HORSE',
                    line1: repair['vehicle_name']?.toString()
                      ?? repair['vehicle']?.toString() ?? '—',
                    line2: (repair['truck_reg'] ?? repair['vehicle_reg'] ?? '').toString().isNotEmpty
                      ? 'Reg: ${repair['truck_reg'] ?? repair['vehicle_reg']}'
                      : '',
                  ),
                  Container(width: 0.8, color: AppTheme.border),
                  _DetailCell(
                    label: (repair['location'] ?? '').toString().isNotEmpty
                      ? 'LOCATION'
                      : 'STATUS',
                    line1: (repair['location'] ?? '').toString().isNotEmpty
                      ? repair['location'].toString()
                      : '${status[0].toUpperCase()}${status.substring(1).replaceAll('_', ' ')}',
                    line2: (repair['location_detail'] ?? repair['suburb'] ?? '').toString(),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Status footer ────────────────────────────────────────────────
          Row(children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(statusMsg,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _DetailCell extends StatelessWidget {
  final String label, line1, line2;
  const _DetailCell({required this.label, required this.line1, required this.line2});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
            color: AppTheme.textMuted, letterSpacing: 0.4)),
        const SizedBox(height: 4),
        Text(line1,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary)),
        if (line2.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(line2,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ]),
    ),
  );
}
