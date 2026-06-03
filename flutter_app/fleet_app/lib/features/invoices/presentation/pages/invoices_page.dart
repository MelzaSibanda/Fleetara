import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});
  @override State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final _fs = sl<FirestoreService>();

  List   _invoices    = [];
  bool   _loading     = true;
  String _filter      = 'all';
  double _revenue     = 0;
  double _expenses    = 0;
  double _outstanding = 0;

  static const _filters = ['all', 'receivable', 'payable', 'overdue'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await _fs.db.collection('invoices')
          .orderBy('created_at', descending: true).get();
      final all = _fs.docsToList(snap);

      double revenue = 0, expenses = 0, outstanding = 0;
      for (final inv in all) {
        final total = double.tryParse(inv['total']?.toString() ?? '0') ?? 0;
        if (inv['invoice_type'] == 'receivable') {
          if (inv['status'] == 'paid') { revenue += total; }
          else if (inv['status'] != 'cancelled') { outstanding += total; }
        } else if (inv['invoice_type'] == 'payable') {
          if (inv['status'] == 'paid') { expenses += total; }
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
      case 'paid':             return AppTheme.emerald;
      case 'approved':         return AppTheme.emerald;
      case 'overdue':          return AppTheme.rose;
      case 'sent':             return AppTheme.accent;
      case 'cancelled':        return AppTheme.textMuted;
      case 'pending_approval': return AppTheme.amber;
      default:                 return AppTheme.amber;
    }
  }

  String _filterLabel(String f) =>
    f == 'all' ? 'All' : '${f[0].toUpperCase()}${f.substring(1)}';

  Future<void> _approveInvoice(BuildContext context, String invoiceId) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Approve payment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Type APPROVE to confirm release of funds.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'APPROVE'),
            textCapitalization: TextCapitalization.characters,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim() == 'APPROVE'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (confirmed != true) return;
    try {
      await _fs.db.collection('invoices').doc(invoiceId).update({
        'status':      'approved',
        'approved_at': DateTime.now().toIso8601String(),
      });
      _load();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invoice approved',
            style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating));
      }
    } catch (_) {}
  }

  Future<void> _releasePayment(BuildContext context, String invoiceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Release payment',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        content: const Text('Mark this invoice as paid and release funds?',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Release'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _fs.db.collection('invoices').doc(invoiceId).update({
        'status':      'paid',
        'released_at': DateTime.now().toIso8601String(),
      });
      _load();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment released',
            style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.read<AuthBloc>().state;
    final isOwner   = auth is AuthAuthenticated &&
        (auth.user.role == 'owner' || auth.user.role == 'admin');
    final netProfit = _revenue - _expenses;
    final narrow    = Responsive.isMobile(context);
    return AppShell(
      title: 'Finance',
      actions: [
        // On mobile: collapse Report + Statement into overflow menu
        if (!narrow) ...[
          OutlinedButton(
            onPressed: () => context.go('/invoices/summary'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.border, width: 0.8)),
            child: const Text('Report', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => context.go('/invoices/statement'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: AppTheme.border, width: 0.8)),
            child: const Text('Statement', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ] else ...[
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (v) {
              if (v == 'report')    context.go('/invoices/summary');
              if (v == 'statement') context.go('/invoices/statement');
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report',
                child: Row(children: [
                  Icon(Icons.bar_chart_outlined, size: 16, color: AppTheme.textMuted),
                  SizedBox(width: 10),
                  Text('Report', style: TextStyle(fontSize: 13)),
                ])),
              PopupMenuItem(value: 'statement',
                child: Row(children: [
                  Icon(Icons.description_outlined, size: 16, color: AppTheme.textMuted),
                  SizedBox(width: 10),
                  Text('Statement', style: TextStyle(fontSize: 13)),
                ])),
            ],
          ),
        ],
        ElevatedButton.icon(
          onPressed: () => context.go('/invoices/add'),
          icon: const Icon(Icons.add, size: 16, color: Colors.white),
          label: Text(narrow ? 'New' : 'Invoice',
            style: const TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 14)),
        ),
        const SizedBox(width: 8),
      ],
      child: Column(children: [
        // ── Hero / summary strip ─────────────────────────────────────────
        Container(
          margin: EdgeInsets.fromLTRB(narrow ? 12 : 16, narrow ? 12 : 16,
            narrow ? 12 : 16, 0),
          padding: EdgeInsets.all(narrow ? 14 : 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.darkNavy, AppTheme.primary],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.darkNavy.withValues(alpha: 0.3),
                blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Net Profit (MTD)',
                style: TextStyle(fontSize: 11, color: Colors.white60,
                  letterSpacing: 0.4)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(
                  netProfit >= 0 ? '↑ Profit' : '↓ Loss',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: netProfit >= 0 ? AppTheme.emerald : AppTheme.rose)),
              ),
            ]),
            const SizedBox(height: 6),
            Text('R ${netProfit.abs().toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: narrow ? 22 : 28,
                fontWeight: FontWeight.w700,
                color: Colors.white, letterSpacing: -0.5)),
            SizedBox(height: narrow ? 12 : 16),
            // Stats: flex row on wide, 2+1 wrap on narrow
            narrow
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: _HeroStat(label: 'Revenue',
                      value: 'R ${_revenue.toStringAsFixed(0)}',
                      color: AppTheme.emerald)),
                    Expanded(child: _HeroStat(label: 'Expenses',
                      value: 'R ${_expenses.toStringAsFixed(0)}',
                      color: AppTheme.rose)),
                  ]),
                  const SizedBox(height: 10),
                  _HeroStat(label: 'Outstanding',
                    value: 'R ${_outstanding.toStringAsFixed(0)}',
                    color: AppTheme.amber),
                ])
              : Row(children: [
                  _HeroStat(label: 'Revenue',
                    value: 'R ${_revenue.toStringAsFixed(0)}',
                    color: AppTheme.emerald),
                  _HeroStat(label: 'Expenses',
                    value: 'R ${_expenses.toStringAsFixed(0)}',
                    color: AppTheme.rose),
                  _HeroStat(label: 'Outstanding',
                    value: 'R ${_outstanding.toStringAsFixed(0)}',
                    color: AppTheme.amber),
                ]),
          ]),
        ),
        const SizedBox(height: 4),
        // ── Filters ──────────────────────────────────────────────────────
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active
                        ? AppTheme.accent.withValues(alpha: 0.10)
                        : AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                          ? AppTheme.accent.withValues(alpha: 0.4)
                          : AppTheme.border,
                        width: active ? 1.0 : 0.5)),
                    child: Text(_filterLabel(f), style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? AppTheme.accent : AppTheme.textMuted)),
                  ),
                ),
              );
            }).toList()),
          ),
        ),
        // ── List ─────────────────────────────────────────────────────────
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: AppTheme.accent, strokeWidth: 2))
            : _invoices.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No invoices found',
                  subtitle: 'Invoices will appear here once created.',
                  action: ElevatedButton(
                    onPressed: () => context.go('/invoices/add'),
                    child: const Text('New invoice')),
                )
              : RListBody(
                  onRefresh: _load,
                  cards: _invoices.map((inv) => _InvoiceRow(
                    inv:         inv,
                    statusColor: _statusColor(inv['status'] ?? ''),
                    onTap:       () => context.go('/invoices/${inv['id']}'),
                    onApprove: isOwner &&
                        inv['invoice_type'] == 'payable' &&
                        (inv['status'] == 'sent' || inv['status'] == 'pending')
                        ? () => _approveInvoice(context, inv['id'].toString())
                        : null,
                    onRelease: isOwner &&
                        inv['status'] == 'approved'
                        ? () => _releasePayment(context, inv['id'].toString())
                        : null,
                  )).toList(),
                ),
        ),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _HeroStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
      ]),
      const SizedBox(height: 3),
      Text(value, style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
    ]),
  );
}

class _InvoiceRow extends StatelessWidget {
  final Map              inv;
  final Color            statusColor;
  final VoidCallback     onTap;
  final VoidCallback?    onApprove;
  final VoidCallback?    onRelease;
  const _InvoiceRow({
    required this.inv,
    required this.statusColor,
    required this.onTap,
    this.onApprove,
    this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    final isReceivable = inv['invoice_type'] == 'receivable';
    final arrowColor   = isReceivable ? AppTheme.emerald : AppTheme.rose;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: AppTheme.cardDecoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: arrowColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(
                  isReceivable
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                  color: arrowColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(inv['invoice_number'] ?? '',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
                Text('${inv['party_name'] ?? ''}  ·  ${inv['issue_date'] ?? ''}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('R ${inv['total'] ?? inv['subtotal'] ?? '—'}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                StatusPill(label: inv['status'] ?? '', color: statusColor),
              ]),
            ]),
            // ── Approval actions (owner only) ────────────────────────────
            if (onApprove != null || onRelease != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, thickness: 0.5, color: AppTheme.border),
              const SizedBox(height: 10),
              Row(children: [
                if (onApprove != null)
                  Expanded(child: GestureDetector(
                    onTap: onApprove,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.emerald.withValues(alpha: 0.35))),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                            size: 14, color: AppTheme.emerald),
                          SizedBox(width: 6),
                          Text('Approve', style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.emerald)),
                        ]),
                    ),
                  )),
                if (onRelease != null)
                  Expanded(child: GestureDetector(
                    onTap: onRelease,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.35))),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_outlined,
                            size: 14, color: AppTheme.primary),
                          SizedBox(width: 6),
                          Text('Release Payment', style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: AppTheme.primary)),
                        ]),
                    ),
                  )),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}
