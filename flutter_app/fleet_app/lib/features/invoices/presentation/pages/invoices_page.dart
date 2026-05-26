import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});
  @override State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  List   _invoices = [];
  bool   _loading  = true;
  String _filter   = 'all';
  double _revenue  = 0;
  double _expenses = 0;
  double _outstanding = 0;

  static const _filters = ['all', 'receivable', 'payable', 'overdue'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await sl<ApiClient>().dio.get('/invoices/');
      final all = List<Map>.from(res.data as List);

      double revenue = 0, expenses = 0, outstanding = 0;
      for (final inv in all) {
        final total = double.tryParse(inv['total']?.toString() ?? '0') ?? 0;
        if (inv['invoice_type'] == 'receivable') {
          if (inv['status'] == 'paid') {
            revenue += total;
          } else if (inv['status'] != 'cancelled') {
            outstanding += total;
          }
        } else if (inv['invoice_type'] == 'payable') {
          if (inv['status'] == 'paid') {
            expenses += total;
          }
        }
      }

      List filtered = all;
      if (_filter == 'receivable') {
        filtered = all.where((i) => i['invoice_type'] == 'receivable').toList();
      } else if (_filter == 'payable') {
        filtered = all.where((i) => i['invoice_type'] == 'payable').toList();
      } else if (_filter == 'overdue') {
        filtered = all.where((i) => i['status'] == 'overdue').toList();
      }

      setState(() {
        _invoices    = filtered;
        _revenue     = revenue;
        _expenses    = expenses;
        _outstanding = outstanding;
        _loading     = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'paid':      return AppTheme.emerald;
      case 'overdue':   return AppTheme.rose;
      case 'sent':      return AppTheme.primary;
      case 'cancelled': return AppTheme.textMuted;
      default:          return AppTheme.amber;
    }
  }

  String _filterLabel(String f) =>
    f == 'all' ? 'All' : '${f[0].toUpperCase()}${f.substring(1)}';

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Finance',
      actions: [
        TextButton(
          onPressed: () => context.go('/invoices/summary'),
          style: TextButton.styleFrom(
            side: const BorderSide(color: AppTheme.border, width: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          child: const Text('Report', style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => context.go('/invoices/add'),
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: const Text('Invoice', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
        const SizedBox(width: 8),
      ],
      child: Column(children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Net profit (MTD)',
              style: TextStyle(fontSize: 11, color: Colors.white70)),
            const SizedBox(height: 4),
            Text('R ${(_revenue - _expenses).toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white)),
            const SizedBox(height: 12),
            Row(children: [
              _HeroStat(label: 'Revenue',     value: 'R ${_revenue.toStringAsFixed(0)}'),
              _HeroStat(label: 'Expenses',    value: 'R ${_expenses.toStringAsFixed(0)}'),
              _HeroStat(label: 'Outstanding', value: 'R ${_outstanding.toStringAsFixed(0)}'),
            ]),
          ]),
        ),
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _filters.map((f) {
              final active = _filter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () { setState(() => _filter = f); _load(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primary.withValues(alpha: 0.18) : AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.border,
                        width: 0.5),
                    ),
                    child: Text(_filterLabel(f),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                        color: active ? AppTheme.primary : AppTheme.textMuted)),
                  ),
                ),
              );
            }).toList()),
          ),
        ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
            : _invoices.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No invoices found',
                  subtitle: 'Invoices will appear here once created.',
                  action: ElevatedButton(
                    onPressed: () => context.go('/invoices/add'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 36)),
                    child: const Text('New invoice'),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _invoices.length,
                    itemBuilder: (_, i) => _InvoiceRow(
                      inv: _invoices[i],
                      statusColor: _statusColor(_invoices[i]['status'] ?? ''),
                      onTap: () => context.go('/invoices/${_invoices[i]['id']}'),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
      Text(label,  style: const TextStyle(fontSize: 10, color: Colors.white70)),
    ]),
  );
}

class _InvoiceRow extends StatelessWidget {
  final Map          inv;
  final Color        statusColor;
  final VoidCallback onTap;
  const _InvoiceRow({required this.inv, required this.statusColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isReceivable = inv['invoice_type'] == 'receivable';
    final arrowColor   = isReceivable ? AppTheme.emerald : AppTheme.rose;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: arrowColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isReceivable ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: arrowColor, size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(inv['invoice_number'] ?? '',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          Text('${inv['party_name'] ?? ''} · ${inv['issue_date'] ?? ''}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('R ${inv['total'] ?? inv['subtotal'] ?? '—'}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(inv['status'] ?? '',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: statusColor)),
          ),
        ]),
      ]),
    ));
  }
}
