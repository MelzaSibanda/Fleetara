import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';
import '../../../../core/utils/responsive.dart';

class FuelPage extends StatefulWidget {
  const FuelPage({super.key});
  @override State<FuelPage> createState() => _FuelPageState();
}

class _FuelPageState extends State<FuelPage> {
  List _entries   = [];
  Map  _analytics = {};
  bool _loading   = true;
  final _fs = sl<FirestoreService>();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await _fs.db.collection('fuel_entries')
          .orderBy('created_at', descending: true).get();
      final entries = _fs.docsToList(snap);

      double totalLiters = 0, totalCost = 0;
      for (final e in entries) {
        totalLiters += (e['liters'] as num?)?.toDouble() ?? 0;
        totalCost   += (e['cost']   as num?)?.toDouble() ?? 0;
      }
      setState(() {
        _entries   = entries;
        _analytics = {
          'total_liters':        totalLiters,
          'total_cost':          totalCost,
          'avg_price_per_liter': entries.isEmpty || totalLiters == 0
              ? 0 : totalCost / totalLiters,
          'total_fill_ups':      entries.length,
        };
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Fuel',
      actions: [
        ElevatedButton.icon(
          onPressed: () => context.go('/fuel/add'),
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text('Log fuel', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14)),
        ),
        const SizedBox(width: 8),
      ],
      child: _loading
        ? const Center(child: CircularProgressIndicator(
            color: AppTheme.accent, strokeWidth: 2))
        : RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: _load,
            child: ListView(padding: Responsive.pagePadding(context), children: [
              // ── KPI cards ───────────────────────────────────────────────
              GridView.count(
                crossAxisCount: Responsive.isDesktop(context) ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12, mainAxisSpacing: 12,
                childAspectRatio: Responsive.isDesktop(context) ? 1.5 : 1.6,
                children: [
                  _KpiCard(label: 'Total litres',
                    value: '${(_analytics['total_liters'] ?? 0).toStringAsFixed(0)} L',
                    icon: Icons.local_gas_station, color: AppTheme.accent),
                  _KpiCard(label: 'Total cost',
                    value: 'R ${(_analytics['total_cost'] ?? 0).toStringAsFixed(0)}',
                    icon: Icons.attach_money, color: AppTheme.emerald),
                  _KpiCard(label: 'Avg / litre',
                    value: 'R ${(_analytics['avg_price_per_liter'] ?? 0).toStringAsFixed(2)}',
                    icon: Icons.trending_up, color: AppTheme.amber),
                  _KpiCard(label: 'Fill-ups',
                    value: '${_analytics['total_fill_ups'] ?? 0}',
                    icon: Icons.format_list_numbered, color: AppTheme.primary),
                ],
              ),
              const SizedBox(height: 16),

              // ── Monthly chart ────────────────────────────────────────────
              Container(
                decoration: AppTheme.cardDecorationMd,
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Monthly fuel cost',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  _MonthlyBarChart(),
                ]),
              ),
              const SizedBox(height: 14),

              // ── Top consumers ────────────────────────────────────────────
              Container(
                decoration: AppTheme.cardDecoration,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text('Top consumers',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                  ),
                  if (_entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: EmptyState(
                        icon: Icons.local_gas_station_outlined,
                        title: 'No fuel entries yet',
                        subtitle: 'Log a fuel stop to see analytics.'),
                    )
                  else
                    ...List.generate(_entries.length > 3 ? 3 : _entries.length, (i) {
                      final e   = _entries[i];
                      final l   = (e['liters'] ?? 0).toDouble();
                      final max = (_entries[0]['liters'] ?? 1).toDouble();
                      return _FuelRow(
                        rank:     i + 1,
                        label:    e['vehicle_registration'] ?? 'Vehicle ${i + 1}',
                        sublabel: e['fuel_station'] ?? '',
                        value:    '${l.toStringAsFixed(0)} L',
                        fill:     max > 0 ? l / max : 0,
                      );
                    }),
                  const SizedBox(height: 8),
                ]),
              ),
              const SizedBox(height: 14),

              // ── History ──────────────────────────────────────────────────
              if (_entries.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('Fuel history',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
                ),
                ..._entries.map((e) => _FuelEntryRow(entry: e)),
              ],
            ]),
          ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String   label, value;
  final IconData icon;
  final Color    color;
  const _KpiCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.10), color.withValues(alpha: 0.04)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.18), width: 0.8),
    ),
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 18),
      ),
      const Spacer(),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary)),
    ]),
  );
}

class _MonthlyBarChart extends StatelessWidget {
  final _months  = const ['Jan','Feb','Mar','Apr','May','Jun'];
  final _heights = const [0.4, 0.55, 0.5, 0.7, 0.65, 1.0];

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 80,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(_months.length, (i) {
        final isLast = i == _months.length - 1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(
                height: _heights[i] * 60,
                decoration: BoxDecoration(
                  gradient: isLast
                    ? const LinearGradient(
                        colors: [AppTheme.accent, AppTheme.primary],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter)
                    : null,
                  color: isLast ? null
                    : AppTheme.accent.withValues(alpha: 0.2 + _heights[i] * 0.3),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 4),
              Text(_months[i],
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ]),
          ),
        );
      }),
    ),
  );
}

class _FuelRow extends StatelessWidget {
  final int rank;
  final String label, sublabel, value;
  final double fill;
  const _FuelRow({required this.rank, required this.label, required this.sublabel,
    required this.value, required this.fill});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Column(children: [
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('$rank',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: AppTheme.accent))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary)),
          if (sublabel.isNotEmpty)
            Text(sublabel, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary)),
      ]),
      const SizedBox(height: 8),
      FleetProgressBar(value: fill),
    ]),
  );
}

class _FuelEntryRow extends StatelessWidget {
  final Map entry;
  const _FuelEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = (entry['created_at'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accent, AppTheme.primary],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.local_gas_station, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${entry['liters']} L  ·  R ${entry['cost']}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
            Text('Odometer: ${entry['odometer']} km'
              '${entry['fuel_station'] != null && (entry['fuel_station'] as String).isNotEmpty
                ? ' · ${entry['fuel_station']}' : ''}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ])),
          Text(date.length >= 10 ? date.substring(0, 10) : date,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ]),
      ),
    );
  }
}
