import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/notification_service.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ns  = sl<NotificationService>();

    return AppShell(
      title: 'Notifications',
      actions: [
        TextButton(
          onPressed: () => ns.markAllRead(uid),
          child: const Text('Mark all read',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ),
        const SizedBox(width: 4),
      ],
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ns.notificationsStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
              color: AppTheme.accent, strokeWidth: 2));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_outlined,
              title: 'No notifications',
              subtitle: 'Fuel logs, repairs, and trip updates will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) => _NotifTile(
              notif: items[i],
              onTap: () {
                ns.markRead(uid, items[i]['id'] as String);
                _navigateForType(context, items[i]['type']?.toString() ?? '');
              },
            ),
          );
        },
      ),
    );
  }

  void _navigateForType(BuildContext context, String type) {
    switch (type) {
      case 'fuel':            context.go('/fuel');    break;
      case 'repair':          context.go('/repairs'); break;
      case 'trip_started':
      case 'trip_completed':
      case 'trip_assigned':
      case 'trip_cancelled':  context.go('/trips');   break;
    }
  }
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  IconData _icon(String type) {
    switch (type) {
      case 'fuel':            return Icons.local_gas_station_outlined;
      case 'repair':          return Icons.handyman_outlined;
      case 'trip_started':    return Icons.play_arrow_outlined;
      case 'trip_completed':  return Icons.check_circle_outline;
      case 'trip_assigned':   return Icons.route_outlined;
      case 'trip_cancelled':  return Icons.cancel_outlined;
      default:                return Icons.notifications_outlined;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case 'fuel':            return AppTheme.accent;
      case 'repair':          return AppTheme.rose;
      case 'trip_started':    return AppTheme.primary;
      case 'trip_completed':  return AppTheme.emerald;
      case 'trip_assigned':   return AppTheme.amber;
      case 'trip_cancelled':  return AppTheme.textMuted;
      default:                return AppTheme.textMuted;
    }
  }

  String _timeAgo(String iso) {
    final dt   = DateTime.tryParse(iso) ?? DateTime.now();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    <  7) return '${diff.inDays}d ago';
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final type    = notif['type']?.toString()       ?? '';
    final title   = notif['title']?.toString()      ?? '';
    final body    = notif['body']?.toString()       ?? '';
    final isRead  = notif['is_read'] == true;
    final created = notif['created_at']?.toString() ?? '';
    final color   = _iconColor(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? AppTheme.surface : AppTheme.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? AppTheme.border : AppTheme.primary.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon(type), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      color: AppTheme.textPrimary,
                    )),
                ),
                Text(_timeAgo(created),
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ]),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(body,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
          if (!isRead) ...[
            const SizedBox(width: 10),
            Container(
              width: 8, height: 8,
              margin: const EdgeInsets.only(top: 5),
              decoration: const BoxDecoration(
                color: AppTheme.primary, shape: BoxShape.circle),
            ),
          ],
        ]),
      ),
    );
  }
}
