import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/app_shell.dart';
import '../widgets/stat_card.dart';
import '../widgets/alert_card.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});
  @override State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  Map  _stats   = {};
  List _alerts  = [];
  bool _loading = true;
  final _fs = sl<FirestoreService>();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _fs.db.collection('vehicles').get(),
        _fs.db.collection('trips').where('status', isEqualTo: 'in_progress').get(),
        _fs.db.collection('daily_checks')
            .orderBy('check_date', descending: true).limit(50).get(),
        _fs.db.collection('repairs')
            .where('status', isNotEqualTo: 'resolved').get(),
      ]);

      final vehicles    = _fs.docsToList(results[0]);
      final activeTrips = _fs.docsToList(results[1]);
      final checkList   = _fs.docsToList(results[2]);
      final repairList  = _fs.docsToList(results[3]);

      final failedChecks = checkList
          .where((c) => c['overall_status'] == 'critical').length;
      final openRepairs  = repairList.length;

      final alerts = <Map<String, dynamic>>[];
      if (failedChecks > 0) {
        alerts.add({
          'title':    '$failedChecks Critical Check${failedChecks > 1 ? 's' : ''}',
          'subtitle': 'Vehicles with critical issues need immediate attention',
          'type':     'danger',
        });
      }
      if (openRepairs > 0) {
        alerts.add({
          'title':    '$openRepairs Open Repair${openRepairs > 1 ? 's' : ''}',
          'subtitle': 'Unresolved maintenance reports',
          'type':     'warning',
        });
      }

      setState(() {
        _stats  = {
          'vehicles': vehicles.length,
          'trips':    activeTrips.length,
          'checks':   checkList.length,
          'repairs':  openRepairs,
        };
        _alerts  = alerts;
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final user = authState.user;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning'
      : hour < 17 ? 'Good afternoon' : 'Good evening';

    return AppShell(
      title: 'Fleetara',
      child: RefreshIndicator(
        color: AppTheme.accent,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: Responsive.pagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$greeting, ${user.firstName}',
                            style: const TextStyle(fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary)),
                          const SizedBox(height: 2),
                          Text('Fleet Manager  ·  ${_today()}',
                            style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      )),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/trips/add'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16)),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Trip'),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    if (_loading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: AppTheme.accent),
                      ))
                    else ...[
                      // ── KPI cards ──────────────────────────────────────
                      GridView.count(
                        crossAxisCount: Responsive.kpiColumns(context),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: Responsive.isMobile(context) ? 1.5 : 1.7,
                        children: [
                          StatCard(label: 'Total Vehicles',
                            value: '${_stats['vehicles'] ?? 0}',
                            icon: Icons.local_shipping_outlined,
                            color: AppTheme.primary, trend: '↑ Fleet'),
                          StatCard(label: 'Active Trips',
                            value: '${_stats['trips'] ?? 0}',
                            icon: Icons.route_outlined,
                            color: AppTheme.emerald, trend: 'On road'),
                          StatCard(label: 'Daily Checks',
                            value: '${_stats['checks'] ?? 0}',
                            icon: Icons.assignment_turned_in_outlined,
                            color: AppTheme.amber, trend: 'Today'),
                          StatCard(label: 'Open Repairs',
                            value: '${_stats['repairs'] ?? 0}',
                            icon: Icons.handyman_outlined,
                            color: AppTheme.rose, trend: 'Pending'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Quick access ────────────────────────────────────
                      const SectionHeader('Quick access'),
                      GridView.count(
                        crossAxisCount: Responsive.value(context,
                          mobile: 4, tablet: 6, desktop: 8),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: Responsive.isMobile(context) ? 0.9 : 1.1,
                        children: [
                          _QuickTile(icon: Icons.local_shipping_outlined,
                            label: 'Vehicles', color: AppTheme.primary,
                            route: '/vehicles', ctx: context),
                          _QuickTile(icon: Icons.route_outlined,
                            label: 'Trips', color: AppTheme.emerald,
                            route: '/trips', ctx: context),
                          _QuickTile(icon: Icons.assignment_turned_in_outlined,
                            label: 'Checks', color: AppTheme.amber,
                            route: '/daily-checks', ctx: context),
                          _QuickTile(icon: Icons.local_gas_station_outlined,
                            label: 'Fuel', color: AppTheme.accent,
                            route: '/fuel', ctx: context),
                          _QuickTile(icon: Icons.tire_repair_outlined,
                            label: 'Tyres', color: AppTheme.darkNavy,
                            route: '/tyres', ctx: context),
                          _QuickTile(icon: Icons.build_circle_outlined,
                            label: 'Services', color: AppTheme.amber,
                            route: '/services', ctx: context),
                          _QuickTile(icon: Icons.handyman_outlined,
                            label: 'Repairs', color: AppTheme.rose,
                            route: '/repairs', ctx: context),
                          _QuickTile(icon: Icons.location_on_outlined,
                            label: 'GPS', color: AppTheme.emerald,
                            route: '/gps/live', ctx: context),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Alerts ──────────────────────────────────────────
                      const SectionHeader('Alerts'),
                      if (_alerts.isEmpty)
                        const AlertCard(
                          title:   'All clear',
                          message: 'No issues to report. Fleet is running smoothly.',
                          type:    AlertType.success)
                      else
                        ..._alerts.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AlertCard(
                            title:   a['title'],
                            message: a['subtitle'],
                            type:    a['type'] == 'danger'
                              ? AlertType.danger : AlertType.warning),
                        )),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _today() {
    final now = DateTime.now();
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${now.day} ${m[now.month - 1]} ${now.year}';
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String   label, route;
  final Color    color;
  final BuildContext ctx;
  const _QuickTile({required this.icon, required this.label, required this.color,
    required this.route, required this.ctx});

  @override
  Widget build(BuildContext _) => GestureDetector(
    onTap: () => ctx.go(route),
    child: Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 0.8)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: color),
          textAlign: TextAlign.center),
      ]),
    ),
  );
}
