import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

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
        _analytics = analy.data;
        _loading   = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Fuel',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/fuel/add'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log Fuel', style: TextStyle(color: Colors.white)),
      ),
      child: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Row(children: [
                Expanded(child: _AnalyticCard(
                  label: 'Total Litres',
                  value: '${(_analytics['total_liters'] ?? 0).toStringAsFixed(0)} L',
                  icon: Icons.local_gas_station,
                  color: AppTheme.primary,
                )),
                const SizedBox(width: 12),
                Expanded(child: _AnalyticCard(
                  label: 'Total Cost',
                  value: 'R ${(_analytics['total_cost'] ?? 0).toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  color: AppTheme.success,
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _AnalyticCard(
                  label: 'Avg Price/L',
                  value: 'R ${(_analytics['avg_price_per_liter'] ?? 0).toStringAsFixed(2)}',
                  icon: Icons.trending_up,
                  color: AppTheme.accent,
                )),
                const SizedBox(width: 12),
                Expanded(child: _AnalyticCard(
                  label: 'Fill-ups',
                  value: '${_analytics['total_fill_ups'] ?? 0}',
                  icon: Icons.format_list_numbered,
                  color: AppTheme.secondary,
                )),
              ]),
              const SizedBox(height: 24),
              Text('Fuel history', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ..._entries.map((e) => Card(
                child: ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_gas_station, color: AppTheme.primary),
                  ),
                  title: Text('${e['liters']} L — R ${e['cost']}'),
                  subtitle: Text('Odometer: ${e['odometer']} km'
                    '${e['fuel_station'] != null && (e['fuel_station'] as String).isNotEmpty
                      ? ' • ${e['fuel_station']}' : ''}'),
                  trailing: Text(
                    (e['created_at'] ?? '').toString().length >= 10
                      ? (e['created_at'] ?? '').toString().substring(0, 10) : '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              )),
              if (_entries.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Text('No fuel entries yet'),
                )),
            ]),
          ),
    );
  }
}

class _AnalyticCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color    color;
  const _AnalyticCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    );
  }
}
