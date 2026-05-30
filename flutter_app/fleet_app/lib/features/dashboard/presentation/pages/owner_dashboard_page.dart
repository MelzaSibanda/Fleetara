import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/app_shell.dart';
import '../widgets/stat_card.dart';
import '../widgets/alert_card.dart';

// ── Data snapshot ─────────────────────────────────────────────────────────────

class _Stats {
  final int    activeTrips;
  final int    totalVehicles;
  final int    availableVehicles;
  final int    onTripVehicles;
  final int    maintenanceVehicles;
  final double totalRevenue;
  final double revenueMtd;
  final double totalExpenses;
  final double outstanding;
  final int    openAlerts;
  final List<Map<String, dynamic>> alertItems;

  const _Stats({
    required this.activeTrips,
    required this.totalVehicles,
    required this.availableVehicles,
    required this.onTripVehicles,
    required this.maintenanceVehicles,
    required this.totalRevenue,
    required this.revenueMtd,
    required this.totalExpenses,
    required this.outstanding,
    required this.openAlerts,
    required this.alertItems,
  });
}

// ── Page ──────────────────────────────────────────────────────────────────────

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});
  @override State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  _Stats? _stats;
  bool    _loading = true;
  final   _fs = sl<FirestoreService>();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final now  = DateTime.now();
      final mPfx = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        _fs.db.collection('trips')
            .where('status', isEqualTo: 'in_progress').get(), // 0 active trips
        _fs.db.collection('vehicles').get(),                  // 1 all vehicles
        _fs.db.collection('invoices').get(),                  // 2 all invoices
        _fs.db.collection('fuel_entries').get(),              // 3 all fuel entries
        _fs.db.collection('repairs').get(),                   // 4 all repairs
      ]);

      // ── Trips ──────────────────────────────────────────────────────────────
      final activeTripDocs = results[0].docs;
      final activeTrips    = activeTripDocs.length;
      final onTripIds = activeTripDocs
          .map((d) => (d.data()['horse_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      // ── Vehicles ───────────────────────────────────────────────────────────
      final vehicles      = _fs.docsToList(results[1]);
      final totalVehicles = vehicles.length;
      final mntCount      = vehicles.where((v) => v['status'] == 'maintenance').length;
      final tripCount     = math.min(onTripIds.length, totalVehicles - mntCount).clamp(0, totalVehicles);
      final availCount    = (totalVehicles - mntCount - tripCount).clamp(0, totalVehicles);

      // ── Invoices ───────────────────────────────────────────────────────────
      final invoices = _fs.docsToList(results[2]);
      double totalRev = 0, revMtd = 0, outstanding = 0;
      for (final inv in invoices) {
        final sub    = (inv['subtotal']    as num?)?.toDouble() ?? 0;
        final tax    = (inv['tax_percent'] as num?)?.toDouble() ?? 0;
        final total  = sub * (1 + tax / 100);
        final status = inv['status']?.toString() ?? '';
        final date   = inv['issue_date']?.toString() ?? '';
        if (status == 'paid') {
          totalRev += total;
          if (date.startsWith(mPfx)) revMtd += total;
        } else if (status == 'pending' || status == 'sent' || status == 'overdue') {
          outstanding += total;
        }
      }

      // ── Expenses ───────────────────────────────────────────────────────────
      double fuelExp = 0;
      for (final e in _fs.docsToList(results[3])) {
        fuelExp += (e['cost'] as num?)?.toDouble() ?? 0;
      }

      double repairExp = 0;
      final allRepairs = _fs.docsToList(results[4]);
      for (final r in allRepairs) {
        repairExp += (r['repair_cost'] as num?)?.toDouble() ?? 0;
      }

      // ── Critical open alerts ───────────────────────────────────────────────
      final criticals = allRepairs.where((r) =>
          r['priority'] == 'critical' && r['status'] != 'resolved').toList();

      setState(() {
        _stats = _Stats(
          activeTrips:         activeTrips,
          totalVehicles:       totalVehicles,
          availableVehicles:   availCount,
          onTripVehicles:      tripCount,
          maintenanceVehicles: mntCount,
          totalRevenue:        totalRev,
          revenueMtd:          revMtd,
          totalExpenses:       fuelExp + repairExp,
          outstanding:         outstanding,
          openAlerts:          criticals.length,
          alertItems:          criticals.take(5).toList(),
        );
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // R 12,400 / R 1.2k / R 1.4M
  String _fmt(double v) {
    if (v >= 1000000) return 'R ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'R ${(v / 1000).toStringAsFixed(1)}k';
    return 'R ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final user     = authState.user;
    final now      = DateTime.now();
    final greeting = now.hour < 12 ? 'Good morning'
        : now.hour < 17 ? 'Good afternoon' : 'Good evening';
    final dateStr  = '${_weekday(now.weekday)}, ${_month(now.month)} ${now.day}';
    final s        = _stats;

    return AppShell(
      title: 'Dashboard',
      actions: [
        ElevatedButton.icon(
          onPressed: () => context.go('/trips/add'),
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: Text(Responsive.isMobile(context) ? 'Trip' : 'New Trip',
            style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14)),
        ),
        const SizedBox(width: 8),
      ],
      child: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return RefreshIndicator(
          color: AppTheme.accent,
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: Responsive.pagePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Greeting ─────────────────────────────────────────
                      Row(children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$greeting, ${user.firstName}',
                              style: TextStyle(
                                fontSize: isMobile ? 18 : 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                            const SizedBox(height: 4),
                            Wrap(spacing: 8, children: [
                              Text(dateStr, style: const TextStyle(
                                fontSize: 12, color: AppTheme.textMuted)),
                              if (_loading)
                                _StatusBadge(
                                  label: 'Loading…',
                                  color: AppTheme.textMuted,
                                  bg:    AppTheme.border)
                              else
                                _StatusBadge(
                                  label: (s?.openAlerts ?? 0) > 0
                                      ? '${s!.openAlerts} critical alert${s.openAlerts > 1 ? 's' : ''}'
                                      : 'Fleet operational',
                                  color: (s?.openAlerts ?? 0) > 0
                                      ? AppTheme.amber : AppTheme.emerald,
                                  bg:   ((s?.openAlerts ?? 0) > 0
                                      ? AppTheme.amber : AppTheme.emerald)
                                      .withValues(alpha: 0.12)),
                            ]),
                          ],
                        )),
                      ]),
                      const SizedBox(height: 22),

                      // ── KPI cards ────────────────────────────────────────
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: Responsive.kpiColumns(context),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 170,
                        ),
                        children: [
                          StatCard(
                            label:       'Active trips',
                            value:       _loading ? '…' : '${s?.activeTrips ?? 0}',
                            icon:        Icons.route,
                            color:       AppTheme.accent,
                            trend:       'On road',
                            sparkValues: const [0.3, 0.5, 0.4, 0.7, 0.5, 0.8, 1.0]),
                          StatCard(
                            label:       'Fleet vehicles',
                            value:       _loading ? '…' : '${s?.totalVehicles ?? 0}',
                            icon:        Icons.local_shipping,
                            color:       AppTheme.primary,
                            trend:       'Total',
                            sparkValues: const [0.6, 0.5, 0.7, 0.6, 0.8, 0.7, 1.0]),
                          StatCard(
                            label:       'Revenue (MTD)',
                            value:       _loading ? '…' : _fmt(s?.revenueMtd ?? 0),
                            icon:        Icons.attach_money,
                            color:       AppTheme.emerald,
                            trend:       'This month',
                            sparkValues: const [0.4, 0.6, 0.5, 0.7, 0.6, 0.9, 1.0]),
                          StatCard(
                            label:       'Open alerts',
                            value:       _loading ? '…' : '${s?.openAlerts ?? 0}',
                            icon:        Icons.warning_amber_rounded,
                            color:       (s?.openAlerts ?? 0) > 0
                                            ? AppTheme.rose : AppTheme.amber,
                            trend:       'Critical',
                            sparkValues: const [0.8, 0.6, 0.9, 0.5, 0.7, 0.4, 0.2]),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Finance summary ───────────────────────────────────
                      _FinanceSummaryCard(
                        isMobile:    isMobile,
                        loading:     _loading,
                        revenue:     _fmt(s?.totalRevenue  ?? 0),
                        expenses:    _fmt(s?.totalExpenses ?? 0),
                        outstanding: _fmt(s?.outstanding   ?? 0),
                      ),
                      const SizedBox(height: 16),

                      // ── Fleet health + Alerts ─────────────────────────────
                      isMobile
                        ? Column(children: [
                            _FleetHealthCard(
                              loading:     _loading,
                              total:       s?.totalVehicles       ?? 0,
                              available:   s?.availableVehicles   ?? 0,
                              onTrip:      s?.onTripVehicles      ?? 0,
                              maintenance: s?.maintenanceVehicles ?? 0,
                            ),
                            const SizedBox(height: 14),
                            _AlertsCard(
                              loading:    _loading,
                              alertItems: s?.alertItems ?? [],
                            ),
                          ])
                        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(flex: 5, child: _FleetHealthCard(
                              loading:     _loading,
                              total:       s?.totalVehicles       ?? 0,
                              available:   s?.availableVehicles   ?? 0,
                              onTrip:      s?.onTripVehicles      ?? 0,
                              maintenance: s?.maintenanceVehicles ?? 0,
                            )),
                            const SizedBox(width: 14),
                            Expanded(flex: 7, child: _AlertsCard(
                              loading:    _loading,
                              alertItems: s?.alertItems ?? [],
                            )),
                          ]),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  String _weekday(int d) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d - 1];
  String _month(int m)   =>
      ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color  color, bg;
  const _StatusBadge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );
}

// ── Finance Summary ───────────────────────────────────────────────────────────

class _FinanceSummaryCard extends StatelessWidget {
  final bool   isMobile, loading;
  final String revenue, expenses, outstanding;
  const _FinanceSummaryCard({
    required this.isMobile,
    required this.loading,
    required this.revenue,
    required this.expenses,
    required this.outstanding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.darkNavy, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: AppTheme.darkNavy.withValues(alpha: 0.25),
          blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.account_balance_wallet_outlined,
              color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Finance Overview',
            style: TextStyle(fontSize: 13, color: Colors.white,
              fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/invoices'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('View all', style: TextStyle(
                  fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 12, color: Colors.white70),
              ]),
            ),
          ),
        ]),
        SizedBox(height: isMobile ? 14 : 20),

        // Stats — always 3 equal columns, font shrinks on mobile
        Row(children: [
          Expanded(child: _FinanceStat(
            label: 'Revenue',     value: loading ? '…' : revenue,
            color: AppTheme.emerald, small: isMobile)),
          Expanded(child: _FinanceStat(
            label: 'Expenses',    value: loading ? '…' : expenses,
            color: AppTheme.rose,    small: isMobile)),
          Expanded(child: _FinanceStat(
            label: 'Outstanding', value: loading ? '…' : outstanding,
            color: AppTheme.amber,   small: isMobile)),
        ]),
        SizedBox(height: isMobile ? 16 : 20),

        // Quick actions
        Wrap(spacing: 8, runSpacing: 8, children: [
          _FinanceChip(label: 'New Invoice', icon: Icons.add,
            onTap: () => context.go('/invoices/add')),
          _FinanceChip(label: 'Report',     icon: Icons.bar_chart_outlined,
            onTap: () => context.go('/invoices/summary')),
          _FinanceChip(label: 'Statement',  icon: Icons.description_outlined,
            onTap: () => context.go('/invoices/statement')),
        ]),
      ]),
    );
  }
}

class _FinanceStat extends StatelessWidget {
  final String label, value;
  final Color  color;
  final bool   small;
  const _FinanceStat({required this.label, required this.value,
    required this.color, this.small = false});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: Colors.white60))),
      ]),
      const SizedBox(height: 4),
      Text(value,
        style: TextStyle(
          fontSize: small ? 14 : 18,
          fontWeight: FontWeight.w700,
          color: Colors.white)),
    ],
  );
}

class _FinanceChip extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final VoidCallback onTap;
  const _FinanceChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
          fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

// ── Fleet Health ──────────────────────────────────────────────────────────────

class _FleetHealthCard extends StatelessWidget {
  final bool loading;
  final int  total, available, onTrip, maintenance;
  const _FleetHealthCard({
    required this.loading,
    required this.total,
    required this.available,
    required this.onTrip,
    required this.maintenance,
  });

  @override
  Widget build(BuildContext context) {
    final double a = total > 0 ? available   / total : 0;
    final double t = total > 0 ? onTrip      / total : 0;
    final double m = total > 0 ? maintenance / total : 0;

    return Container(
      padding: const EdgeInsets.all(18),
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
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.local_shipping_outlined,
              color: AppTheme.accent, size: 16),
          ),
          const SizedBox(width: 10),
          const Text('Fleet health',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary)),
        ]),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 120, height: 120,
            child: CustomPaint(
              painter: _DonutPainter(
                segments: loading || total == 0
                    ? [_Segment(AppTheme.border, 1.0)]
                    : [
                        if (a > 0) _Segment(AppTheme.accent,  a),
                        if (t > 0) _Segment(AppTheme.emerald, t),
                        if (m > 0) _Segment(AppTheme.amber,   m),
                      ]),
              child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(loading ? '…' : '$total',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
                  const Text('Total', style: TextStyle(
                    fontSize: 10, color: AppTheme.textMuted)),
                ],
              )),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _LegendRow(color: AppTheme.accent,  label: 'Available',   value: loading ? '…' : '$available'),
        const SizedBox(height: 10),
        _LegendRow(color: AppTheme.emerald, label: 'On trip',     value: loading ? '…' : '$onTrip'),
        const SizedBox(height: 10),
        _LegendRow(color: AppTheme.amber,   label: 'Maintenance', value: loading ? '…' : '$maintenance'),
      ]),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label, value;
  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
    const Spacer(),
    Text(value, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
  ]);
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
    const gap     = 0.03;
    final paint   = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap   = StrokeCap.round;

    // Background ring
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..color = AppTheme.border);

    if (segments.isEmpty) return;

    double start = -math.pi / 2;
    for (final seg in segments) {
      final sweep = (seg.value * 2 * math.pi) - gap;
      if (sweep <= 0) continue;
      paint.color = seg.color;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start, sweep, false, paint);
      start += seg.value * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments.length != segments.length;
}

// ── Alerts ────────────────────────────────────────────────────────────────────

class _AlertsCard extends StatelessWidget {
  final bool   loading;
  final List<Map<String, dynamic>> alertItems;
  const _AlertsCard({required this.loading, required this.alertItems});

  String _alertMessage(Map<String, dynamic> r) {
    final parts = <String>[];
    final vehicle = (r['vehicle_name'] ?? r['vehicle_reg'] ?? '').toString();
    final reporter = (r['reported_by_name'] ?? '').toString();
    if (vehicle.isNotEmpty)  parts.add(vehicle);
    if (reporter.isNotEmpty) parts.add('Reported by $reporter');
    return parts.isNotEmpty ? parts.join(' · ') : 'Critical — needs immediate attention';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
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
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppTheme.amber.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.notifications_outlined,
            color: AppTheme.amber, size: 16),
        ),
        const SizedBox(width: 10),
        const Text('Alerts & Reminders',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary)),
        const Spacer(),
        if (!loading && alertItems.isNotEmpty)
          GestureDetector(
            onTap: () => context.go('/repairs'),
            child: const Text('View all',
              style: TextStyle(fontSize: 12, color: AppTheme.accent,
                fontWeight: FontWeight.w500)),
          ),
      ]),
      const SizedBox(height: 14),

      if (loading)
        const Center(child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(
            color: AppTheme.accent, strokeWidth: 2)))
      else if (alertItems.isEmpty)
        const AlertCard(
          title:   'No active alerts',
          message: 'Vehicle documents and service reminders will appear here.',
          type:    AlertType.info)
      else
        ...alertItems.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AlertCard(
            title:   r['title']?.toString() ?? 'Critical issue',
            message: _alertMessage(r),
            type:    AlertType.danger))),

      const SizedBox(height: 10),
      LayoutBuilder(builder: (ctx, box) {
        // Use Expanded Row on all sizes — each action gets equal space
        return Row(children: [
          _AlertAction(label: 'Vehicles', icon: Icons.local_shipping_outlined,
            onTap: () => context.go('/vehicles')),
          const SizedBox(width: 8),
          _AlertAction(label: 'Repairs',  icon: Icons.handyman_outlined,
            onTap: () => context.go('/repairs')),
          const SizedBox(width: 8),
          _AlertAction(label: 'Invoices', icon: Icons.receipt_long_outlined,
            onTap: () => context.go('/invoices')),
        ]);
      }),
    ]),
  );
}

class _AlertAction extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final VoidCallback onTap;
  const _AlertAction({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border, width: 0.8)),
        child: Column(children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
        ]),
      ),
    ),
  );
}
