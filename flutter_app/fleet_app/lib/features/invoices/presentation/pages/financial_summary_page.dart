import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';

class FinancialSummaryPage extends StatefulWidget {
  const FinancialSummaryPage({super.key});
  @override State<FinancialSummaryPage> createState() => _FinancialSummaryPageState();
}

class _FinancialSummaryPageState extends State<FinancialSummaryPage> {
  Map  _data    = {};
  bool _loading = true;
  final _fs = sl<FirestoreService>();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await _fs.db.collection('invoices').get();
      final invoices = _fs.docsToList(snap);

      double totalReceivable = 0;
      double totalPaidIn     = 0;
      double totalPayable    = 0;
      double totalPaidOut    = 0;
      double outstanding     = 0;

      for (final inv in invoices) {
        final total  = (inv['total'] as num?)?.toDouble() ?? 0;
        final status = inv['status'] ?? '';
        if (inv['invoice_type'] == 'receivable') {
          totalReceivable += total;
          if (status == 'paid') {
            totalPaidIn += total;
          } else if (status != 'cancelled') {
            outstanding += total;
          }
        } else if (inv['invoice_type'] == 'payable') {
          totalPayable += total;
          if (status == 'paid') totalPaidOut += total;
        }
      }

      setState(() {
        _data = {
          'net_profit':        totalPaidIn - totalPaidOut,
          'total_receivable':  totalReceivable,
          'total_paid_in':     totalPaidIn,
          'outstanding':       outstanding,
          'total_payable':     totalPayable,
          'total_paid_out':    totalPaidOut,
        };
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Financial Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                    Text('R ${(_data['net_profit'] ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white,
                        fontSize: 36, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 24),
                _SummaryRow(label: 'Total receivable',
                  value: 'R ${(_data['total_receivable'] ?? 0).toStringAsFixed(0)}',
                  color: AppTheme.emerald),
                _SummaryRow(label: 'Total paid in',
                  value: 'R ${(_data['total_paid_in'] ?? 0).toStringAsFixed(0)}',
                  color: AppTheme.emerald),
                _SummaryRow(label: 'Outstanding',
                  value: 'R ${(_data['outstanding'] ?? 0).toStringAsFixed(0)}',
                  color: AppTheme.amber),
                _SummaryRow(label: 'Total payable',
                  value: 'R ${(_data['total_payable'] ?? 0).toStringAsFixed(0)}',
                  color: AppTheme.rose),
                _SummaryRow(label: 'Total paid out',
                  value: 'R ${(_data['total_paid_out'] ?? 0).toStringAsFixed(0)}',
                  color: AppTheme.rose),
              ]),
            ),
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
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
