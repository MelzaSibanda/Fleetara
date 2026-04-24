import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';

class FinancialSummaryPage extends StatefulWidget {
  const FinancialSummaryPage({super.key});
  @override State<FinancialSummaryPage> createState() => _FinancialSummaryPageState();
}

class _FinancialSummaryPageState extends State<FinancialSummaryPage> {
  Map  _data    = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await sl<ApiClient>().dio.get('/invoices/summary/');
      setState(() { _data = res.data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial Summary')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  const Text('Net Profit',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('R ${_data['net_profit'] ?? 0}',
                    style: const TextStyle(color: Colors.white,
                      fontSize: 36, fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 24),
              _SummaryRow(label: 'Total receivable',
                value: 'R ${_data['total_receivable'] ?? 0}', color: AppTheme.success),
              _SummaryRow(label: 'Total paid in',
                value: 'R ${_data['total_paid_in'] ?? 0}',    color: AppTheme.success),
              _SummaryRow(label: 'Outstanding',
                value: 'R ${_data['outstanding'] ?? 0}',      color: AppTheme.warning),
              _SummaryRow(label: 'Total payable',
                value: 'R ${_data['total_payable'] ?? 0}',    color: AppTheme.error),
              _SummaryRow(label: 'Total paid out',
                value: 'R ${_data['total_paid_out'] ?? 0}',   color: AppTheme.error),
            ]),
          ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _SummaryRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
