import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
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

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final client = sl<ApiClient>();
      final res    = await client.dio.get('/fuel/');
      final analy  = await client.dio.get('/fuel/analytics/');
      setState(() {
        _entries   = res.data['results'] ?? res.data;
        _analytics = analy.data is Map ? analy.data : {};
        _loading   = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Fuel analytics',
      actions: [
        ElevatedButton.icon(
          onPressed: () => context.go('/fuel/add'),
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text('Log fuel', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
        const SizedBox(width: 8),
      ],
      child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
        : RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: _load,
            child: ListView(padding: Responsive.pagePadding(context), children: [
              // 4 KPI cards
              GridView.count(
                crossAxisCount: Responsive.isDesktop(context) ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: Responsive.isDesktop(context) ? 1.4 : 1.6,
                children: [
                  _KpiCard(
                    label: 'Total litres',
                    value: '${(_analytics['total_liters'] ?? 0).toStringAsFixed(0)} L',
                    icon: Icons.local_gas_station,
                    color: AppTheme.primary,
                  ),
                  _KpiCard(
                    label: 'Total cost',
                    value: 'R ${(_analytics['total_cost'] ?? 0).toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    color: AppTheme.emerald,
                  ),
                  _KpiCard(
                    label: 'Avg per litre',
                    value: 'R ${(_analytics['avg_price_per_liter'] ?? 0).toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: AppTheme.amber,
                  ),
                  _KpiCard(
                    label: 'Fill-ups',
                    value: '${_analytics['total_fill_ups'] ?? 0}',
                    icon: Icons.format_list_numbered,
                    color: AppTheme.darkNavy,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Monthly bar chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Monthly fuel cost',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  _MonthlyBarChart(),
                ]),
              ),
              const SizedBox(height: 16),

              // Fuel history
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 0.5),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 14, 14, 0),
                    child: Text('Top fuel consumers',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                  ),
                  if (_entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: EmptyState(
                        icon: Icons.local_gas_station_outlined,
                        title: 'No fuel entries yet',
                        subtitle: 'Log a fuel stop to see analytics.',
                      )),
                    )
                  else
                    ...List.generate(_entries.length > 3 ? 3 : _entries.length, (i) {
                      final e = _entries[i];
                      final litres = (e['liters'] ?? 0).toDouble();
                      final max    = (_entries[0]['liters'] ?? 1).toDouble();
                      return _FuelRow(
                        rank:    i + 1,
                        label:   e['vehicle_registration'] ?? 'Vehicle ${i + 1}',
                        sublabel: e['fuel_station'] ?? '',
                        value:   '${litres.toStringAsFixed(0)} L',
                        fill:    max > 0 ? litres / max : 0,
                      );
                    }),
                ]),
              ),
              const SizedBox(height: 16),

              // All entries
              if (_entries.isNotEmpty) ...[
                const Text('Fuel history',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                const SizedBox(height: 10),
                ..._entries.map((e) => _FuelEntryRow(entry: e)),
              ],
            ]),
          ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
      const Spacer(),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
    ]),
  );
}

class _MonthlyBarChart extends StatelessWidget {
  final _months  = const ['Jan','Feb','Mar','Apr','May','Jun'];
  final _heights = const [0.4, 0.55, 0.5, 0.7, 0.65, 1.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                    color: isLast ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.25 + _heights[i] * 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(_months[i], style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

class _FuelRow extends StatelessWidget {
  final int    rank;
  final String label;
  final String sublabel;
  final String value;
  final double fill;
  const _FuelRow({required this.rank, required this.label, required this.sublabel,
    required this.value, required this.fill});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
    child: Column(children: [
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text('$rank',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primary))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          if (sublabel.isNotEmpty)
            Text(sublabel, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      ]),
      const SizedBox(height: 6),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.local_gas_station, color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${entry['liters']} L — R ${entry['cost']}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          Text('Odometer: ${entry['odometer']} km'
            '${entry['fuel_station'] != null && (entry['fuel_station'] as String).isNotEmpty
              ? ' · ${entry['fuel_station']}' : ''}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        Text(date.length >= 10 ? date.substring(0, 10) : date,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ]),
    );
  }
}
