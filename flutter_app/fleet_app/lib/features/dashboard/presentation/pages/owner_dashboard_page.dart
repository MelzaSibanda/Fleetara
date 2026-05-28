import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/app_shell.dart';
import '../widgets/stat_card.dart';
import '../widgets/alert_card.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final user    = authState.user;
    final now     = DateTime.now();
    final hour    = now.hour;
    final greeting = hour < 12 ? 'Good morning'
        : hour < 17  ? 'Good afternoon' : 'Good evening';
    final dateStr  = '${_weekday(now.weekday)}, ${_month(now.month)} ${now.day}';

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
          onRefresh: () async {},
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
                      // ── Greeting ────────────────────────────────────────
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
                              Text(dateStr,
                                style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.emerald.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20)),
                                child: const Text('Fleet operational',
                                  style: TextStyle(fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.emerald)),
                              ),
                            ]),
                          ],
                        )),
                      ]),
                      const SizedBox(height: 22),

                      // ── KPI cards ────────────────────────────────────────
                      GridView.count(
                        crossAxisCount: Responsive.kpiColumns(context),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isMobile ? 1.45 : 1.25,
                        children: const [
                          StatCard(
                            label: 'Active trips',
                            value: '—',
                            icon:  Icons.route,
                            color: AppTheme.accent,
                            trend: 'On road',
                            sparkValues: [0.3, 0.5, 0.4, 0.7, 0.5, 0.8, 1.0]),
                          StatCard(
                            label: 'Fleet vehicles',
                            value: '—',
                            icon:  Icons.local_shipping,
                            color: AppTheme.primary,
                            trend: 'Total',
                            sparkValues: [0.6, 0.5, 0.7, 0.6, 0.8, 0.7, 1.0]),
                          StatCard(
                            label: 'Revenue (MTD)',
                            value: 'R —',
                            icon:  Icons.attach_money,
                            color: AppTheme.emerald,
                            trend: 'This month',
                            sparkValues: [0.4, 0.6, 0.5, 0.7, 0.6, 0.9, 1.0]),
                          StatCard(
                            label: 'Open alerts',
                            value: '—',
                            icon:  Icons.warning_amber_rounded,
                            color: AppTheme.amber,
                            trend: 'Needs review',
                            sparkValues: [0.8, 0.6, 0.9, 0.5, 0.7, 0.4, 0.2]),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Finance summary card ─────────────────────────────
                      _FinanceSummaryCard(isMobile: isMobile),
                      const SizedBox(height: 16),

                      // ── Fleet health + Alerts ───────────────────────────
                      isMobile
                        ? Column(children: [
                            _FleetHealthCard(),
                            const SizedBox(height: 14),
                            _AlertsCard(),
                          ])
                        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(flex: 5, child: _FleetHealthCard()),
                            const SizedBox(width: 14),
                            Expanded(flex: 7, child: _AlertsCard()),
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

  String _weekday(int d) =>
      ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d - 1];
  String _month(int m) =>
      ['Jan','Feb','Mar','Apr','May','Jun',
       'Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

// ── Finance Summary ──────────────────────────────────────────────────────────

class _FinanceSummaryCard extends StatelessWidget {
  final bool isMobile;
  const _FinanceSummaryCard({required this.isMobile});

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
        // Finance stats row
        isMobile
          ? Wrap(spacing: 0, runSpacing: 12, children: const [
              _FinanceStat(label: 'Revenue',     value: 'R —', color: AppTheme.emerald),
              _FinanceStat(label: 'Expenses',    value: 'R —', color: AppTheme.rose),
              _FinanceStat(label: 'Outstanding', value: 'R —', color: AppTheme.amber),
            ])
          : Row(children: const [
              Expanded(child: _FinanceStat(label: 'Revenue',     value: 'R —', color: AppTheme.emerald)),
              Expanded(child: _FinanceStat(label: 'Expenses',    value: 'R —', color: AppTheme.rose)),
              Expanded(child: _FinanceStat(label: 'Outstanding', value: 'R —', color: AppTheme.amber)),
            ]),
        SizedBox(height: isMobile ? 16 : 20),
        // Quick finance actions
        Wrap(spacing: 8, runSpacing: 8, children: [
          _FinanceChip(label: 'New Invoice', icon: Icons.add,
            onTap: () => context.go('/invoices/add')),
          _FinanceChip(label: 'Report', icon: Icons.bar_chart_outlined,
            onTap: () => context.go('/invoices/summary')),
          _FinanceChip(label: 'Statement', icon: Icons.description_outlined,
            onTap: () => context.go('/invoices/statement')),
        ]),
      ]),
    );
  }
}

class _FinanceStat extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _FinanceStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
      ]),
      const SizedBox(height: 5),
      Text(value, style: const TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
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

// ── Fleet Health ─────────────────────────────────────────────────────────────

class _FleetHealthCard extends StatelessWidget {
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
      Center(child: SizedBox(width: 120, height: 120, child: _DonutChart())),
      const SizedBox(height: 20),
      _LegendRow(color: AppTheme.accent,  label: 'Active',      value: '—'),
      const SizedBox(height: 10),
      _LegendRow(color: AppTheme.emerald, label: 'On trip',     value: '—'),
      const SizedBox(height: 10),
      _LegendRow(color: AppTheme.amber,   label: 'Maintenance', value: '—'),
    ]),
  );
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

class _DonutChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DonutPainter(segments: [
      _Segment(AppTheme.accent,  0.45),
      _Segment(AppTheme.emerald, 0.35),
      _Segment(AppTheme.amber,   0.20),
    ]),
    child: const Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('—', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary)),
        Text('Total', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    )),
  );
}

class _Segment {
  final Color color;
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
    final paint   = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap   = StrokeCap.round;

    // Background ring
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..color = AppTheme.border);

    double start = -math.pi / 2;
    for (final seg in segments) {
      final sweep = (seg.value * 2 * math.pi) - gap;
      paint.color = seg.color;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start, sweep, false, paint);
      start += seg.value * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => false;
}

// ── Alerts card ───────────────────────────────────────────────────────────────

class _AlertsCard extends StatelessWidget {
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
      ]),
      const SizedBox(height: 14),
      const AlertCard(
        title:   'No active alerts',
        message: 'Vehicle documents and service reminders will appear here.',
        type:    AlertType.info),
      const SizedBox(height: 10),
      // Quick links row
      Row(children: [
        _AlertAction(
          label: 'Vehicles', icon: Icons.local_shipping_outlined,
          onTap: () => context.go('/vehicles')),
        const SizedBox(width: 8),
        _AlertAction(
          label: 'Repairs', icon: Icons.handyman_outlined,
          onTap: () => context.go('/repairs')),
        const SizedBox(width: 8),
        _AlertAction(
          label: 'Invoices', icon: Icons.receipt_long_outlined,
          onTap: () => context.go('/invoices')),
      ]),
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
