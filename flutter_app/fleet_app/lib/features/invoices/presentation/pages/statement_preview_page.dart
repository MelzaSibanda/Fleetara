import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';

@JS('window.print')
external void _windowPrint();

class StatementPreviewPage extends StatefulWidget {
  final String client;
  final String statementNo;
  final String fromDate;
  final String toDate;

  const StatementPreviewPage({
    super.key,
    required this.client,
    required this.statementNo,
    required this.fromDate,
    required this.toDate,
  });

  @override State<StatementPreviewPage> createState() => _StatementPreviewPageState();
}

class _StatementPreviewPageState extends State<StatementPreviewPage> {
  final _fs = sl<FirestoreService>();
  Map<String, dynamic> _data    = {};
  bool _loading = true;

  static const _navy = Color(0xFF1A2F5E);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final snap = await _fs.db.collection('invoices')
          .where('party_name',   isEqualTo: widget.client)
          .where('invoice_type', isEqualTo: 'receivable')
          .get();
      final companyDoc = await _fs.db.collection('settings').doc('company_profile').get();

      final all = _fs.docsToList(snap);
      final invoices = all.where((inv) {
        final date = inv['issue_date'] as String? ?? '';
        if (widget.fromDate.isNotEmpty && date.compareTo(widget.fromDate) < 0) return false;
        if (widget.toDate.isNotEmpty   && date.compareTo(widget.toDate)   > 0) return false;
        return true;
      }).toList()
        ..sort((a, b) => (a['issue_date'] as String? ?? '')
            .compareTo(b['issue_date'] as String? ?? ''));

      double totalCharges = 0, totalCredits = 0;
      final lines = invoices.map((inv) {
        final total  = double.tryParse(inv['total']?.toString() ?? '0') ?? 0;
        final isPaid = inv['status'] == 'paid';
        totalCharges += total;
        if (isPaid) totalCredits += total;
        return <String, dynamic>{
          'date':           inv['issue_date']     ?? '',
          'invoice_number': inv['invoice_number'] ?? '',
          'description':    inv['description']    ?? '',
          'charges':        isPaid ? null : total,
          'credits':        isPaid ? total : null,
          'type':           isPaid ? 'payment' : 'invoice',
        };
      }).toList();

      final firstInv = invoices.isNotEmpty ? invoices.first : <String, dynamic>{};

      setState(() {
        _data = {
          'company': companyDoc.exists ? _fs.docToMap(companyDoc) : <String, dynamic>{},
          'client': {
            'name':    firstInv['party_name']    ?? widget.client,
            'address': firstInv['party_address'] ?? '',
          },
          'totals': {
            'total_charges': totalCharges,
            'total_credits': totalCredits,
            'balance_due':   totalCharges - totalCredits,
          },
          'lines': lines,
        };
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  String _fmt(dynamic v, {bool showDash = true}) {
    if (v == null || v.toString().isEmpty) return showDash ? '-' : '';
    final d = double.tryParse(v.toString());
    if (d == null) return v.toString();
    if (d == 0)    return showDash ? '-' : '';
    final parts = d.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return 'R $whole.${parts[1]}';
  }

  String _fmtCell(String? v) {
    if (v == null || v.trim().isEmpty) return '';
    return _fmt(v, showDash: false);
  }

  String _today() {
    final n = DateTime.now();
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[n.month - 1]} ${n.day}, ${n.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EAED),
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text('Statement — ${widget.statementNo}',
          style: const TextStyle(color: Colors.white, fontSize: 14)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/invoices/statement'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _windowPrint(),
            icon: const Icon(Icons.print, color: Colors.white, size: 18),
            label: const Text('Print / Save PDF',
              style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 794),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(40),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildInfoBox(),
                    const SizedBox(height: 20),
                    _buildBillToAndSummary(),
                    const SizedBox(height: 16),
                    _buildTable(),
                    _buildBalanceFooter(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                  ]),
                ),
              ),
            ),
          ),
    );
  }

  // ── Header: logo left | "Statement" right ──────────────────────────────────
  Widget _buildHeader() {
    final company = (_data['company'] ?? {}) as Map;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Image.asset('assets/logos/fleetara_logo.png', width: 60, height: 60),
        const SizedBox(height: 6),
        Text(company['name']?.toString() ?? '',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _navy)),
        if ((company['address'] ?? '').toString().isNotEmpty)
          Text(company['address'].toString(),
            style: const TextStyle(fontSize: 9, color: Colors.black54, height: 1.4)),
      ]),
      const Spacer(),
      const Text('Statement',
        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800,
          color: _navy, letterSpacing: -0.5)),
    ]);
  }

  // ── Info box top-right: Date, Statement #, Customer ID, Page ───────────────
  Widget _buildInfoBox() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 310,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5)),
        child: Table(
          columnWidths: const {0: FixedColumnWidth(100), 1: FlexColumnWidth()},
          children: [
            _infoRow('Date:',         _today()),
            _infoRow('Statement #',   widget.statementNo),
            _infoRow('Customer ID:',  widget.client),
            _infoRow('Page',          '1 of 1'),
          ],
        ),
      ),
    );
  }

  TableRow _infoRow(String label, String value) => TableRow(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
    ),
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(value, style: const TextStyle(fontSize: 10, color: Colors.black87)),
      ),
    ],
  );

  // ── Bill To (left) | Account Summary (right) ───────────────────────────────
  Widget _buildBillToAndSummary() {
    final client = (_data['client'] ?? {}) as Map;
    final totals = (_data['totals'] ?? {}) as Map;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Bill To
      Expanded(child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            color: _navy,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: const Text('Bill To:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(client['name']?.toString() ?? '',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.black87)),
              if ((client['address'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(client['address'].toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.black54, height: 1.5)),
              ],
            ]),
          ),
        ]),
      )),
      const SizedBox(width: 12),
      // Account Summary
      Expanded(child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            color: _navy,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: const Text('Account Summary',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          _summaryRow('Previous Balance', '-'),
          _summaryRow('Total Credits',    _fmt(totals['total_credits'])),
          _summaryRow('Total Charges',    _fmt(totals['total_charges'])),
          _summaryRowBold('Total Balance Due', _fmt(totals['balance_due'])),
        ]),
      )),
    ]);
  }

  Widget _summaryRow(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      Text(value, style: const TextStyle(fontSize: 10, color: Colors.black87)),
    ]),
  );

  Widget _summaryRowBold(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: Colors.black87)),
      Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: Colors.black87)),
    ]),
  );

  // ── Line items table ────────────────────────────────────────────────────────
  Widget _buildTable() {
    final lines = List<Map>.from((_data['lines'] ?? []) as List);

    // Calculate running balance for Line Total column
    double balance = 0;
    final rows = lines.map((line) {
      final charge = double.tryParse(line['charges']?.toString() ?? '') ?? 0;
      final credit = double.tryParse(line['credits']?.toString() ?? '') ?? 0;
      balance += charge - credit;
      return {...line, '_balance': balance};
    }).toList();

    const emptyCount = 6;

    return Table(
      border: TableBorder(
        top:              BorderSide(color: Colors.grey.shade400, width: 0.5),
        bottom:           BorderSide(color: Colors.grey.shade400, width: 0.5),
        horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.5),
        verticalInside:   BorderSide(color: Colors.grey.shade300, width: 0.5),
      ),
      columnWidths: const {
        0: FixedColumnWidth(72),
        1: FixedColumnWidth(76),
        2: FlexColumnWidth(),
        3: FixedColumnWidth(88),
        4: FixedColumnWidth(88),
        5: FixedColumnWidth(88),
      },
      children: [
        // Header
        TableRow(
          decoration: const BoxDecoration(color: _navy),
          children: [
            _th('Date'),
            _th('Invoice #'),
            _th('Description'),
            _th('Charges',    align: TextAlign.right),
            _th('Credits',    align: TextAlign.right),
            _th('Line Total', align: TextAlign.right),
          ],
        ),
        // Data rows
        ...rows.map((line) {
          final isPayment = line['type'] == 'payment';
          return TableRow(
            decoration: BoxDecoration(
              color: isPayment ? const Color(0xFFF0F4FB) : Colors.white,
            ),
            children: [
              _td(line['date']?.toString()           ?? ''),
              _td(line['invoice_number']?.toString() ?? ''),
              _td(line['description']?.toString()    ?? '', italic: isPayment),
              _td(_fmtCell(line['charges']?.toString()), align: TextAlign.right),
              _td(_fmtCell(line['credits']?.toString()), align: TextAlign.right),
              _td(_fmt(line['_balance']), align: TextAlign.right),
            ],
          );
        }),
        // Empty spacer rows to fill the page
        for (int i = 0; i < emptyCount; i++)
          TableRow(
            decoration: const BoxDecoration(color: Colors.white),
            children: List.generate(6, (_) => _td('', pad: 10)),
          ),
      ],
    );
  }

  // ── Account Current Balance footer bar ─────────────────────────────────────
  Widget _buildBalanceFooter() {
    final totals  = (_data['totals'] ?? {}) as Map;
    final balance = _fmt(totals['balance_due']);
    return Container(
      color: _navy,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(children: [
        const Expanded(
          child: Text('Account Current Balance',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        Text(balance,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(width: 6),
      ]),
    );
  }

  // ── Footer: payment instructions + contact ─────────────────────────────────
  Widget _buildFooter() {
    final company       = (_data['company'] ?? {}) as Map;
    final name          = company['name']?.toString()           ?? '';
    final addr          = company['address']?.toString()        ?? '';
    final phone         = company['phone']?.toString()          ?? '';
    final email         = company['email']?.toString()          ?? '';
    final contactPerson = company['contact_person']?.toString() ?? '';

    return Center(
      child: Column(children: [
        Container(height: 0.5, color: Colors.black26),
        const SizedBox(height: 14),
        if (name.isNotEmpty) ...[
          Text('Make all transfers payable to $name',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: Colors.black87),
            textAlign: TextAlign.center),
          const SizedBox(height: 10),
        ],
        const Text('Thank you for your business!',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
        const SizedBox(height: 10),
        Text(
          'Should you have any enquiries concerning this statement, please contact'
          '${contactPerson.isNotEmpty ? ' $contactPerson' : ' us'}'
          '${phone.isNotEmpty ? ' on $phone' : ''}'
          '.',
          style: const TextStyle(fontSize: 10, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        if (addr.isNotEmpty)
          Text(addr,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
            textAlign: TextAlign.center),
        if (phone.isNotEmpty || email.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text([
            if (phone.isNotEmpty) 'Tel: $phone',
            if (email.isNotEmpty) 'E-mail: $email',
          ].join('   '),
          style: const TextStyle(fontSize: 10, color: Colors.black54),
          textAlign: TextAlign.center),
        ],
        const SizedBox(height: 14),
        Container(height: 0.5, color: Colors.black26),
      ]),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _th(String text, {TextAlign align = TextAlign.left}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
    child: Text(text, textAlign: align,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
        color: Colors.white)),
  );

  Widget _td(String text, {TextAlign align = TextAlign.left,
      bool italic = false, double pad = 6}) => Padding(
    padding: EdgeInsets.symmetric(vertical: pad, horizontal: 6),
    child: Text(text, textAlign: align,
      style: TextStyle(fontSize: 10,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: Colors.black87)),
  );
}
