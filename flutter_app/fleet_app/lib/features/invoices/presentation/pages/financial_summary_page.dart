import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/services/firestore_service.dart';

class FinancialSummaryPage extends StatefulWidget {
  const FinancialSummaryPage({super.key});
  @override State<FinancialSummaryPage> createState() => _FinancialSummaryPageState();
}

class _FinancialSummaryPageState extends State<FinancialSummaryPage> {
  final _fs = sl<FirestoreService>();

  Map<String, double> _data = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await _fs.db.collection('invoices').get();
      final all  = _fs.docsToList(snap);

      double totalReceivable = 0, totalPaidIn  = 0, outstanding = 0;
      double totalPayable    = 0, totalPaidOut = 0;

      for (final inv in all) {
        final total  = double.tryParse(inv['total']?.toString() ?? '0') ?? 0;
        final status = inv['status'] as String? ?? '';
        final type   = inv['invoice_type'] as String? ?? '';

        if (type == 'receivable') {
          if (status != 'cancelled') totalReceivable += total;
          if (status == 'paid')      totalPaidIn     += total;
          if (status != 'paid' && status != 'cancelled') outstanding += total;
        } else if (type == 'payable') {
          if (status != 'cancelled') totalPayable += total;
          if (status == 'paid')      totalPaidOut += total;
        }
      }

      setState(() {
        _data = {
          'total_receivable': totalReceivable,
          'total_paid_in':    totalPaidIn,
          'outstanding':      outstanding,
          'total_payable':    totalPayable,
          'total_paid_out':   totalPaidOut,
          'net_profit':       totalPaidIn - totalPaidOut,
        };
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  double _val(String key) => _data[key] ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Financial Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/invoices'),
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(
            color: AppTheme.accent, strokeWidth: 2))
        : RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: Responsive.pagePadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Net Profit hero ──────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.darkNavy, AppTheme.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(
                              color: AppTheme.darkNavy.withValues(alpha: 0.25),
                              blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: Column(children: [
                            const Text('Net Profit',
                              style: TextStyle(color: Colors.white60,
                                fontSize: 13, letterSpacing: 0.3)),
                            const SizedBox(height: 10),
                            Text('R ${_val('net_profit').toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Responsive.isMobile(context) ? 28 : 36,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5)),
                            const SizedBox(height: 4),
                            Text(
                              _val('net_profit') >= 0
                                ? '↑ Profitable' : '↓ Operating at a loss',
                              style: TextStyle(
                                color: _val('net_profit') >= 0
                                  ? AppTheme.emerald : AppTheme.rose,
                                fontSize: 12, fontWeight: FontWeight.w500)),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        // ── Summary rows ─────────────────────────────────
                        _SummaryRow(label: 'Total receivable',
                          value: 'R ${_val('total_receivable').toStringAsFixed(0)}',
                          color: AppTheme.emerald),
                        _SummaryRow(label: 'Total paid in',
                          value: 'R ${_val('total_paid_in').toStringAsFixed(0)}',
                          color: AppTheme.emerald),
                        _SummaryRow(label: 'Outstanding',
                          value: 'R ${_val('outstanding').toStringAsFixed(0)}',
                          color: AppTheme.amber),
                        _SummaryRow(label: 'Total payable',
                          value: 'R ${_val('total_payable').toStringAsFixed(0)}',
                          color: AppTheme.rose),
                        _SummaryRow(label: 'Total paid out',
                          value: 'R ${_val('total_paid_out').toStringAsFixed(0)}',
                          color: AppTheme.rose),
                      ],
                    ),
                  ),
                ),
              ),
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
  Widget build(BuildContext context) => Container(
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
