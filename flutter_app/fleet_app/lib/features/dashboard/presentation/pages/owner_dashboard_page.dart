import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/stat_card.dart';
import '../widgets/alert_card.dart';
class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    final now  = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final dateStr  = '${_weekday(now.weekday)}, ${_month(now.month)} ${now.day}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 56,
        title: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.local_shipping, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Text('Fleetara',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ]),
        actions: [
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 22, color: AppTheme.textPrimary),
              onPressed: () {},
            ),
            Positioned(right: 10, top: 10,
              child: Container(width: 7, height: 7,
                decoration: const BoxDecoration(color: AppTheme.rose, shape: BoxShape.circle))),
          ]),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: AppTheme.primary, radius: 16,
              child: Text(
                user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text(user.roleLabel, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ]),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 16, color: AppTheme.rose),
                  SizedBox(width: 8),
                  Text('Sign out', style: TextStyle(fontSize: 13, color: AppTheme.rose)),
                ]),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthBloc>().add(AuthLogoutRequested());
                context.go('/login');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(children: [
        // Sidebar
        Container(
          width: 200,
          color: AppTheme.surface,
          child: Column(children: [
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                children: [
                  _SidebarItem(icon: Icons.home_outlined,         label: 'Home',    route: '/dashboard', active: true),
                  _SidebarItem(icon: Icons.local_shipping_outlined,label: 'Fleet',   route: '/vehicles'),
                  _SidebarItem(icon: Icons.route_outlined,         label: 'Trips',   route: '/trips'),
                  _SidebarItem(icon: Icons.local_gas_station,      label: 'Fuel',    route: '/fuel'),
                  _SidebarItem(icon: Icons.receipt_long_outlined,  label: 'Finance', route: '/invoices'),
                  _SidebarItem(icon: Icons.map_outlined,           label: 'GPS',     route: '/gps/live'),
                ],
              ),
            ),
            const Divider(height: 0.5, thickness: 0.5, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.all(8),
              child: _SidebarItem(icon: Icons.settings_outlined, label: 'Settings', route: '/settings'),
            ),
          ]),
        ),
        const VerticalDivider(width: 0.5, thickness: 0.5, color: AppTheme.border),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Greeting row
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$greeting, ${user.firstName}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(dateStr, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Fleet operational',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.emerald)),
                    ),
                  ]),
                ])),
                ElevatedButton.icon(
                  onPressed: () => context.go('/trips/add'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New trip'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              // KPI 2x2 grid
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: const [
                  StatCard(label: 'Active trips',     value: '—', icon: Icons.route,              color: AppTheme.primary,  sparkValues: [0.3,0.5,0.4,0.7,0.5,0.8,1.0]),
                  StatCard(label: 'Vehicles active',  value: '—', icon: Icons.local_shipping,      color: AppTheme.darkNavy, sparkValues: [0.6,0.5,0.7,0.6,0.8,0.7,1.0]),
                  StatCard(label: 'Revenue (MTD)',    value: '—', icon: Icons.attach_money,        color: AppTheme.emerald,  sparkValues: [0.4,0.6,0.5,0.7,0.6,0.9,1.0]),
                  StatCard(label: 'Alerts',           value: '—', icon: Icons.warning_amber_rounded,color: AppTheme.amber,   sparkValues: [0.8,0.6,0.9,0.5,0.7,0.4,1.0]),
                ],
              ),
              const SizedBox(height: 24),
              // Fleet health + Alerts row
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _FleetHealthCard()),
                const SizedBox(width: 16),
                Expanded(child: _AlertsCard()),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  String _weekday(int d) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d - 1];
  String _month(int m)   => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   route;
  final bool     active;
  const _SidebarItem({required this.icon, required this.label, required this.route, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: active ? AppTheme.primary : AppTheme.textMuted),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: active ? AppTheme.primary : AppTheme.textMuted)),
        ]),
      ),
    );
  }
}

class _FleetHealthCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Fleet health', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        Center(child: SizedBox(width: 120, height: 120, child: _DonutChart())),
        const SizedBox(height: 16),
        _LegendRow(color: AppTheme.primary,  label: 'Active',      value: '—'),
        const SizedBox(height: 6),
        _LegendRow(color: AppTheme.emerald,  label: 'On trip',     value: '—'),
        const SizedBox(height: 6),
        _LegendRow(color: AppTheme.amber,    label: 'Maintenance', value: '—'),
      ]),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color  color;
  final String label;
  final String value;
  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
    const Spacer(),
    Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
  ]);
}

class _DonutChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(
        segments: [
          _Segment(AppTheme.primary, 0.45),
          _Segment(AppTheme.emerald, 0.35),
          _Segment(AppTheme.amber,   0.20),
        ],
      ),
      child: const Center(
        child: Text('—', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      ),
    );
  }
}

class _Segment {
  final Color  color;
  final double value;
  const _Segment(this.color, this.value);
}

class _DonutPainter extends CustomPainter {
  final List<_Segment> segments;
  const _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = math.min(cx, cy) - 6;
    const strokeW = 14.0;
    const gap     = 0.04;

    final paint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap   = StrokeCap.round;

    double start = -math.pi / 2;
    for (final seg in segments) {
      final sweep = (seg.value * 2 * math.pi) - gap;
      paint.color = seg.color;
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          start, sweep, false, paint);
      start += seg.value * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => false;
}

class _AlertsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        const AlertCard(
          title:   'No active alerts',
          message: 'Vehicle documents and service reminders will appear here.',
          type:    AlertType.info,
        ),
      ]),
    );
  }
}
