import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../driver/presentation/bloc/driver_home_bloc.dart';
import '../../../driver/presentation/bloc/driver_home_event.dart';
import '../../../driver/presentation/bloc/driver_home_state.dart';
import '../widgets/app_shell.dart';

class DriverDashboardPage extends StatelessWidget {
  const DriverDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final user = authState.user;

    return BlocProvider(
      create: (_) => sl<DriverHomeBloc>()..add(DriverHomeFetchRequested()),
      child: AppShell(
        title: 'Dashboard',
        child: BlocBuilder<DriverHomeBloc, DriverHomeState>(
          builder: (context, state) {
            final activeTrip = state is DriverHomeLoaded ? state.activeTrip : null;
            final loading    = state is DriverHomeLoading;
            final isWide     = Responsive.isWide(context);

            return RefreshIndicator(
              color: AppTheme.accent,
              onRefresh: () async =>
                context.read<DriverHomeBloc>().add(DriverHomeFetchRequested()),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: ListView(
                    padding: Responsive.pagePadding(context),
                    children: [
                      // ── Greeting ─────────────────────────────────────────
                      Text('Hello, ${user.firstName}',
                        style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                      const SizedBox(height: 2),
                      const Text("Here's your operational summary",
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      const SizedBox(height: 18),

                      // ── Active trip card ──────────────────────────────────
                      _ActiveTripCard(trip: activeTrip, loading: loading),
                      const SizedBox(height: 14),

                      // ── Action tiles ──────────────────────────────────────
                      Row(children: [
                        Expanded(child: _ActionTile(
                          label:    'My Trips',
                          subtitle: 'View and manage your trips',
                          icon:     Icons.route_outlined,
                          colors:   const [Color(0xFF1A2F6E), AppTheme.accent],
                          onTap:    () => context.go('/driver/trips'),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _ActionTile(
                          label:    'Daily Check',
                          subtitle: 'Complete daily inspections',
                          icon:     Icons.assignment_turned_in_outlined,
                          colors:   const [Color(0xFF1B6B3A), Color(0xFF22C55E)],
                          onTap:    () => context.go('/driver/checks'),
                        )),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _ActionTile(
                          label:    'Log Fuel',
                          subtitle: 'Record fuel transactions',
                          icon:     Icons.local_gas_station_outlined,
                          colors:   const [Color(0xFF92400E), Color(0xFFF59E0B)],
                          onTap:    () => context.go('/fuel/add'),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _ActionTile(
                          label:    'Report Issue',
                          subtitle: 'Report and track issues',
                          icon:     Icons.warning_amber_rounded,
                          colors:   const [Color(0xFF7F1D1D), Color(0xFFEF4444)],
                          onTap:    () => context.go('/repairs/add'),
                        )),
                      ]),
                      const SizedBox(height: 16),

                      // ── Today's stats ────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border, width: 0.5),
                          boxShadow: const [
                            BoxShadow(color: Color(0x081E3A72),
                              blurRadius: 16, offset: Offset(0, 4)),
                          ],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("Today's stats",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: _StatItem(
                              value: '452', unit: 'km', label: 'Distance',
                              icon: Icons.location_on_outlined,
                              color: AppTheme.accent,
                              sparkValues: [0.3, 0.5, 0.4, 0.6, 0.5, 0.7, 0.9],
                            )),
                            _divider(),
                            Expanded(child: _StatItem(
                              value: '128', unit: 'L', label: 'Fuel used',
                              icon: Icons.local_gas_station_outlined,
                              color: const Color(0xFF8B5CF6),
                              sparkValues: [0.5, 0.4, 0.6, 0.5, 0.7, 0.6, 0.8],
                            )),
                            _divider(),
                            Expanded(child: _StatItem(
                              value: '7h 35m', unit: '', label: 'Drive time',
                              icon: Icons.access_time_outlined,
                              color: AppTheme.primary,
                              sparkValues: [0.4, 0.6, 0.5, 0.7, 0.6, 0.8, 0.75],
                            )),
                            _divider(),
                            Expanded(child: _StatItem(
                              value: '96', unit: '', label: 'Safety score',
                              icon: Icons.shield_outlined,
                              color: AppTheme.emerald,
                              trend: '↑ 8%',
                              sparkValues: [0.5, 0.65, 0.7, 0.75, 0.8, 0.85, 0.96],
                            )),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // ── Recent trips + Alerts ────────────────────────────
                      isWide
                        ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(child: _RecentTripsCard(activeTrip: activeTrip)),
                            const SizedBox(width: 14),
                            Expanded(child: _AlertsCard()),
                          ])
                        : Column(children: [
                            _RecentTripsCard(activeTrip: activeTrip),
                            const SizedBox(height: 14),
                            _AlertsCard(),
                          ]),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _divider() => Container(
    width: 0.5, height: 70,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: AppTheme.border,
  );
}

// ── Active trip card ─────────────────────────────────────────────────────────

class _ActiveTripCard extends StatelessWidget {
  final Map<String, dynamic>? trip;
  final bool loading;
  const _ActiveTripCard({this.trip, required this.loading});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: 160,
      child: Stack(children: [
        // Background: gradient + bg image on right
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.darkNavy, AppTheme.primary],
                begin: Alignment.topLeft, end: Alignment.bottomRight)),
          ),
        ),
        // Truck image on the right
        Positioned(
          right: 0, top: 0, bottom: 0,
          width: 220,
          child: Stack(children: [
            Image.asset('assets/logos/bg_image.png',
              fit: BoxFit.cover, alignment: Alignment.centerRight),
            // Left-fade overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.darkNavy, Colors.transparent],
                  begin: Alignment.centerLeft, end: Alignment.centerRight)),
            ),
          ]),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(18),
          child: loading
            ? const Center(child: SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: trip != null ? AppTheme.emerald : Colors.white38,
                      shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(trip != null ? 'Active trip' : 'No active trip',
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(trip != null ? 'In Progress' : 'Standby',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 14),
                Text(
                  trip != null
                    ? '${trip!['origin']}  →  ${trip!['destination']}'
                    : '—  →  —',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: Colors.white, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(trip != null ? (trip!['client_name'] ?? '') : 'No trip assigned',
                  style: const TextStyle(fontSize: 12, color: Colors.white60)),
                const Spacer(),
                if (trip != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: trip!['status'] == 'completed' ? 1.0 : 0.65,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      color: AppTheme.emerald)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text('Trip #${trip!['id']}',
                      style: const TextStyle(fontSize: 10, color: Colors.white54)),
                    const Spacer(),
                    Text('Cargo: ${trip!['cargo_type'] ?? '—'}',
                      style: const TextStyle(fontSize: 10, color: Colors.white54)),
                  ]),
                ],
              ]),
        ),
      ]),
    ),
  );
}

// ── Action tile ──────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final String      label, subtitle;
  final IconData    icon;
  final List<Color> colors;
  final VoidCallback onTap;
  const _ActionTile({
    required this.label, required this.subtitle, required this.icon,
    required this.colors, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
          color: colors.last.withValues(alpha: 0.28),
          blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(
              fontSize: 10, color: Colors.white.withValues(alpha: 0.72)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        )),
        Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.6), size: 18),
      ]),
    ),
  );
}

// ── Stat item ────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String     value, unit, label;
  final IconData   icon;
  final Color      color;
  final String?    trend;
  final List<double> sparkValues;
  const _StatItem({
    required this.value, required this.unit, required this.label,
    required this.icon, required this.color, this.trend,
    this.sparkValues = const [0.4, 0.5, 0.6, 0.45, 0.7, 0.6, 1.0],
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.30), width: 1.5),
          color: color.withValues(alpha: 0.06),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Flexible(child: Text(value,
          style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          overflow: TextOverflow.ellipsis)),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: 2),
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(unit,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))),
        ],
        if (trend != null) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.emerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
            child: Text(trend!,
              style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.emerald)),
          ),
        ],
      ]),
      const SizedBox(height: 2),
      Text(label,
        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      const SizedBox(height: 8),
      SizedBox(
        height: 20,
        child: CustomPaint(
          painter: _MiniSparkPainter(values: sparkValues, color: color),
          size: Size.infinite,
        ),
      ),
    ]),
  );
}

class _MiniSparkPainter extends CustomPainter {
  final List<double> values;
  final Color        color;
  const _MiniSparkPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final stepX = size.width / (values.length - 1);
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - (values[i] * size.height * 0.80) - size.height * 0.05;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevY = size.height - (values[i - 1] * size.height * 0.80) - size.height * 0.05;
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Gradient fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_MiniSparkPainter old) => false;
}

// ── Recent trips card ────────────────────────────────────────────────────────

class _RecentTripsCard extends StatelessWidget {
  final Map<String, dynamic>? activeTrip;
  const _RecentTripsCard({this.activeTrip});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border, width: 0.5),
      boxShadow: const [
        BoxShadow(color: Color(0x081E3A72), blurRadius: 16, offset: Offset(0, 4)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Recent trips',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary)),
        const Spacer(),
        GestureDetector(
          onTap: () => context.go('/driver/trips'),
          child: const Text('View all',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: AppTheme.accent)),
        ),
      ]),
      const SizedBox(height: 14),
      if (activeTrip != null)
        _TripRow(trip: activeTrip!)
      else
        const _EmptySection(
          icon: Icons.route_outlined, label: 'No recent trips'),
    ]),
  );
}

class _TripRow extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _TripRow({required this.trip});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.background,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: Row(children: [
      Container(width: 8, height: 8,
        decoration: const BoxDecoration(color: AppTheme.emerald, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${trip['origin']}  →  ${trip['destination']}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(trip['client_name'] ?? '',
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ])),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20)),
          child: const Text('In Progress',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
              color: AppTheme.accent)),
        ),
        const SizedBox(height: 3),
        const Text('Today',
          style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ]),
      const SizedBox(width: 6),
      const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
    ]),
  );
}

// ── Alerts card ──────────────────────────────────────────────────────────────

class _AlertsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border, width: 0.5),
      boxShadow: const [
        BoxShadow(color: Color(0x081E3A72), blurRadius: 16, offset: Offset(0, 4)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Alerts',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary)),
        const Spacer(),
        GestureDetector(
          onTap: () {},
          child: const Text('View all',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: AppTheme.accent)),
        ),
      ]),
      const SizedBox(height: 14),
      _AlertRow(
        icon: Icons.assignment_late_outlined,
        color: AppTheme.rose,
        title: 'Vehicle inspection due',
        subtitle: 'CA 123-456 – Due in 2 days',
      ),
    ]),
  );
}

class _AlertRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title, subtitle;
  const _AlertRow({required this.icon, required this.color,
    required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 2),
        Text(subtitle,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ])),
      const SizedBox(width: 6),
      Icon(Icons.chevron_right, size: 16, color: color.withValues(alpha: 0.5)),
    ]),
  );
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _EmptySection({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 18, color: AppTheme.textMuted.withValues(alpha: 0.5)),
      const SizedBox(width: 8),
      Text(label,
        style: TextStyle(fontSize: 12,
          color: AppTheme.textMuted.withValues(alpha: 0.7))),
    ]),
  );
}
