import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/notification_service.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _filter = 'all';

  static const _filters = ['all', 'fuel', 'repair', 'trips'];
  static const _labels  = {'all': 'All', 'fuel': 'Fuel', 'repair': 'Repairs', 'trips': 'Trips'};

  bool _matches(String type) {
    if (_filter == 'all')    return true;
    if (_filter == 'fuel')   return type == 'fuel';
    if (_filter == 'repair') return type == 'repair';
    if (_filter == 'trips')  return type.startsWith('trip_');
    return true;
  }

  String _formatDate(String iso) {
    final dt  = DateTime.tryParse(iso) ?? DateTime.now();
    final now = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dtDay     = DateTime(dt.year, dt.month, dt.day);
    final hhmm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (dtDay == today)     return 'Today $hhmm';
    if (dtDay == yesterday) return 'Yesterday $hhmm';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, $hhmm';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ns  = sl<NotificationService>();

    return AppShell(
      title: 'Notification History',
      actions: [
        TextButton(
          onPressed: () => ns.markAllRead(uid),
          child: const Text('Mark all read',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textMuted),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onSelected: (v) {
            if (v == 'clear') _confirmClear(context, uid, ns);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'clear',
              child: Row(children: [
                Icon(Icons.delete_sweep_outlined, size: 16, color: AppTheme.rose),
                SizedBox(width: 10),
                Text('Clear all', style: TextStyle(fontSize: 13, color: AppTheme.rose)),
              ])),
          ],
        ),
        const SizedBox(width: 4),
      ],
      child: Column(children: [
        // ── Filter tabs ─────────────────────────────────────────────────────
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final active = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? AppTheme.primary : AppTheme.border,
                          width: active ? 1.2 : 0.8,
                        ),
                      ),
                      child: Text(_labels[f]!,
                        style: TextStyle(
                          fontSize: 12,
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

        // ── List ────────────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: ns.notificationsStream(uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(
                  color: AppTheme.accent, strokeWidth: 2));
              }
              final all   = snap.data ?? [];
              final items = all
                  .where((n) => _matches(n['type']?.toString() ?? ''))
                  .toList();

              if (items.isEmpty) {
                return EmptyState(
                  icon: _filter == 'fuel'   ? Icons.local_gas_station_outlined
                      : _filter == 'repair' ? Icons.handyman_outlined
                      : _filter == 'trips'  ? Icons.route_outlined
                      : Icons.notifications_outlined,
                  title: 'No ${_labels[_filter]!.toLowerCase()} notifications',
                  subtitle: 'Nothing to show here yet.',
                );
              }

              return RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () async {},
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final n = items[i];
                    return _NotifCard(
                      notif:     n,
                      dateLabel: _formatDate(n['created_at']?.toString() ?? ''),
                      onTap: () {
                        ns.markRead(uid, n['id'] as String);
                        _navigate(context, n['type']?.toString() ?? '');
                      },
                      onDelete: () => ns.deleteNotification(uid, n['id'] as String),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  void _navigate(BuildContext context, String type) {
    if (type == 'fuel')               { context.go('/fuel');    return; }
    if (type == 'repair')             { context.go('/repairs'); return; }
    if (type.startsWith('trip_'))     { context.go('/trips');   return; }
  }

  void _confirmClear(BuildContext context, String uid, NotificationService ns) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Clear all notifications'),
        content: const Text('This will permanently delete your notification history.',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); ns.clearAll(uid); },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose, minimumSize: const Size(90, 36)),
            child: const Text('Clear all')),
        ],
      ),
    );
  }
}

// ── Notification card ──────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> notif;
  final String       dateLabel;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _NotifCard({required this.notif, required this.dateLabel,
    required this.onTap, required this.onDelete});

  IconData _icon(String t) {
    switch (t) {
      case 'fuel':           return Icons.local_gas_station_outlined;
      case 'repair':         return Icons.handyman_outlined;
      case 'trip_started':   return Icons.play_arrow_outlined;
      case 'trip_completed': return Icons.check_circle_outline;
      case 'trip_assigned':  return Icons.route_outlined;
      case 'trip_cancelled': return Icons.cancel_outlined;
      default:               return Icons.notifications_outlined;
    }
  }

  Color _color(String t) {
    switch (t) {
      case 'fuel':           return AppTheme.accent;
      case 'repair':         return AppTheme.rose;
      case 'trip_started':   return AppTheme.primary;
      case 'trip_completed': return AppTheme.emerald;
      case 'trip_assigned':  return AppTheme.amber;
      default:               return AppTheme.textMuted;
    }
  }

  List<String> _chips(String type, Map<String, dynamic> d) {
    String s(String k) => d[k]?.toString() ?? '';
    String cap(String v) => v.isEmpty ? v : '${v[0].toUpperCase()}${v.substring(1)}';

    switch (type) {
      case 'fuel':
        return [
          if (s('vehicle_reg').isNotEmpty) s('vehicle_reg'),
          if (d['liters'] != null) '${d['liters']}L',
          if (d['cost'] != null) 'R ${d['cost']}',
          if (s('fuel_type').isNotEmpty) cap(s('fuel_type')),
        ];
      case 'repair':
        return [
          if (s('priority').isNotEmpty) cap(s('priority')),
          if (s('vehicle_reg').isNotEmpty) s('vehicle_reg'),
        ];
      case 'trip_started':
      case 'trip_completed':
      case 'trip_assigned':
      case 'trip_cancelled':
        return [
          if (s('driver').isNotEmpty) s('driver'),
          if (s('horse_reg').isNotEmpty) s('horse_reg'),
          if (s('client').isNotEmpty) s('client'),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final type   = notif['type']?.toString()  ?? '';
    final title  = notif['title']?.toString() ?? '';
    final body   = notif['body']?.toString()  ?? '';
    final actor  = notif['actor']?.toString() ?? '';
    final isRead = notif['is_read'] == true;
    final data   = Map<String, dynamic>.from(
        (notif['data'] is Map) ? notif['data'] as Map : {});
    final chips  = _chips(type, data);
    final color  = _color(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isRead
              ? AppTheme.surface
              : AppTheme.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? AppTheme.border
                : AppTheme.primary.withValues(alpha: 0.18),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Icon box
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon(type), color: color, size: 19),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Title + date
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Text(title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                        color: AppTheme.textPrimary,
                      )),
                  ),
                  const SizedBox(width: 6),
                  Text(dateLabel,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ]),

                // Body
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(body,
                    style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted, height: 1.4)),
                ],

                // Actor
                if (actor.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('by $actor',
                    style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted,
                      fontStyle: FontStyle.italic)),
                ],

                // Contextual chips
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: chips.map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: color.withValues(alpha: 0.20), width: 0.6),
                      ),
                      child: Text(c, style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                    )).toList(),
                  ),
                ],
              ]),
            ),

            // Unread dot + delete
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isRead)
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary, shape: BoxShape.circle),
                  ),
                SizedBox(height: isRead ? 0 : 6),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.close, size: 15, color: AppTheme.textMuted),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
