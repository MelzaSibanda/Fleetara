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
  String _type     = 'all';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final params = _type != 'all' ? {'type': _type} : null;
      final res = await sl<ApiClient>().dio.get('/invoices/', queryParameters: params);
      setState(() { _invoices = res.data['results'] ?? res.data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':      return AppTheme.success;
      case 'overdue':   return AppTheme.error;
      case 'sent':      return AppTheme.primary;
      case 'cancelled': return Colors.grey;
      default:          return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Invoices',
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart),
          tooltip: 'Financial summary',
          onPressed: () => context.go('/invoices/summary'),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/invoices/add'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Invoice', style: TextStyle(color: Colors.white)),
      ),
      child: Column(children: [
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            for (final t in ['all', 'receivable', 'payable'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(t == 'all' ? 'All'
                    : '${t[0].toUpperCase()}${t.substring(1)}'),
                  selected: _type == t,
                  selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppTheme.primary,
                  onSelected: (_) { setState(() => _type = t); _load(); },
                ),
              ),
          ]),
        ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _invoices.isEmpty
              ? const Center(child: Text('No invoices found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _invoices.length,
                    itemBuilder: (_, i) {
                      final inv = _invoices[i];
                      final isReceivable = inv['invoice_type'] == 'receivable';
                      final statusCol = _statusColor(inv['status'] ?? '');
                      return Card(
                        child: ListTile(
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: (isReceivable ? AppTheme.success : AppTheme.error)
                                .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isReceivable ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isReceivable ? AppTheme.success : AppTheme.error,
                            ),
                          ),
                          title: Text(inv['invoice_number'] ?? ''),
                          subtitle: Text('${inv['party_name']} • ${inv['issue_date']}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('R ${inv['total']}',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusCol.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(inv['status'] ?? '',
                                  style: TextStyle(fontSize: 10, color: statusCol)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }
}
