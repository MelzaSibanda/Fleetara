import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';

@JS('window.print')
external void _windowPrint();

class InvoicePreviewPage extends StatefulWidget {
  final String invoiceId;
  const InvoicePreviewPage({super.key, required this.invoiceId});
  @override State<InvoicePreviewPage> createState() => _InvoicePreviewPageState();
}

class _InvoicePreviewPageState extends State<InvoicePreviewPage> {
  final _fs = sl<FirestoreService>();
  Map  _inv     = {};
  Map  _company = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final invDoc     = await _fs.db.collection('invoices').doc(widget.invoiceId).get();
      final companyDoc = await _fs.db.collection('settings').doc('company_profile').get();
      setState(() {
        _inv     = invDoc.exists     ? _fs.docToMap(invDoc)     : {};
        _company = companyDoc.exists ? _fs.docToMap(companyDoc) : {};
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  String _fmt(dynamic v) {
    if (v == null || v.toString().isEmpty) return '—';
    final d = double.tryParse(v.toString());
    if (d != null) {
      final parts = d.toStringAsFixed(2).split('.');
      final whole = parts[0].replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
      return 'R$whole.${parts[1]}';
    }
    return v.toString();
  }

  String _fmtNum(dynamic v) {
    if (v == null) return '—';
    final d = double.tryParse(v.toString());
    return d != null ? d.toStringAsFixed(2) : v.toString();
  }

  void _print() => _windowPrint();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EAED),
      appBar: AppBar(
        backgroundColor: AppTheme.darkNavy,
        foregroundColor: Colors.white,
        title: Text('Invoice ${_inv['invoice_number'] ?? ''}',
          style: const TextStyle(color: Colors.white, fontSize: 14)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/invoices'),
        ),
        actions: [
          TextButton.icon(
            onPressed: _print,
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
                    const SizedBox(height: 24),
                    _buildBillToRow(),
                    const SizedBox(height: 24),
                    _buildItemsTable(),
                    const SizedBox(height: 0),
                    _buildTotalsRow(),
                    const SizedBox(height: 32),
                    _buildBankDetails(),
                  ]),
                ),
              ),
            ),
          ),
    );
  }

  // ── Header: logo left, "Tax Invoice" right ──────────────────────────────
  Widget _buildHeader() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Logo / company mark
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Image.asset('assets/logos/fleetara_logo.png', width: 56, height: 56),
        const SizedBox(height: 8),
        Text(_company['name'] ?? 'Fleet Company',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: Color(0xFF1E2A3A))),
      ]),
      const Spacer(),
      // "Tax Invoice" title
      const Text('Tax Invoice',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
          color: Color(0xFF1E2A3A), letterSpacing: -0.5)),
    ]);
  }

  // ── Bill To (left) | Invoice details (right) ────────────────────────────
  Widget _buildBillToRow() {
    final companyAddr = (_company['address'] ?? '').toString();
    final regNo  = (_company['reg_no']  ?? '').toString();
    final vatNo  = (_company['vat_no']  ?? '').toString();

    return Column(children: [
      // Thin top border
      Container(height: 0.5, color: Colors.black38),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // LEFT — Bill To
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Bill To:'),
          const SizedBox(height: 8),
          Text(_inv['party_name'] ?? '',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
              color: Colors.black87)),
          if ((_inv['party_address'] ?? '').toString().isNotEmpty)
            ...[const SizedBox(height: 4),
              Text(_inv['party_address'].toString(),
                style: const TextStyle(fontSize: 11, color: Colors.black54,
                  height: 1.5))],
          if ((_inv['party_vat'] ?? '').toString().isNotEmpty)
            ...[const SizedBox(height: 8),
              _detail('Vat Registration:', _inv['party_vat'])],
        ])),
        const SizedBox(width: 40),
        // RIGHT — Invoice details
        SizedBox(width: 240, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _detail('Date:',        _inv['issue_date']),
          _detail('Invoice #:',   _inv['invoice_number']),
          if ((_inv['truck_reg'] ?? '').toString().isNotEmpty)
            _detail('Truck Reg No.:', _inv['truck_reg']),
          const SizedBox(height: 12),
          Text(_company['name'] ?? '',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.black87)),
          if (regNo.isNotEmpty) ...[
            const SizedBox(height: 4),
            _detail('Reg No.', regNo),
          ],
          if (vatNo.isNotEmpty)
            _detail('VAT No.', vatNo),
          if (companyAddr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(companyAddr, style: const TextStyle(fontSize: 10, color: Colors.black54, height: 1.4)),
          ],
        ])),
      ]),
      const SizedBox(height: 16),
      Container(height: 0.5, color: Colors.black38),
    ]);
  }

  // ── Line items table ─────────────────────────────────────────────────────
  Widget _buildItemsTable() {
    final desc = (_inv['description'] ?? '').toString();
    final qty  = _fmtNum(_inv['quantity']);
    final rate = _fmt(_inv['rate']);
    final amt  = _fmt(_inv['subtotal']);

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(50),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(70),
        3: FixedColumnWidth(100),
        4: FixedColumnWidth(110),
      },
      children: [
        // Header row
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade400, width: 0.5),
              top:    BorderSide(color: Colors.grey.shade400, width: 0.5),
            ),
          ),
          children: [
            _th('Item #'),
            _th('Description'),
            _th('Qty',    align: TextAlign.right),
            _th('Rate',   align: TextAlign.right),
            _th('Amount', align: TextAlign.right),
          ],
        ),
        // Data row
        TableRow(children: [
          _td('1', top: 12),
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12, right: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Truck Loads',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: Colors.black87)),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ]),
          ),
          _td(qty == '—' ? '' : qty, align: TextAlign.right, top: 12),
          _td(rate == 'R—' ? '' : rate, align: TextAlign.right, top: 12),
          _td(amt,  align: TextAlign.right, top: 12, bold: true),
        ]),
        // Empty spacer rows
        for (int i = 0; i < 6; i++)
          TableRow(children: [
            _td('', top: 8), _td('', top: 8), _td('', top: 8), _td('', top: 8), _td('', top: 8),
          ]),
      ],
    );
  }

  // ── Totals + special notes ───────────────────────────────────────────────
  Widget _buildTotalsRow() {
    final notes     = (_inv['notes'] ?? '').toString();
    final subtotal  = _fmt(_inv['subtotal']);
    final taxAmt    = _fmt(_inv['tax_amount']);
    final total     = _fmt(_inv['total']);
    final taxPct    = double.tryParse((_inv['tax_percent'] ?? '0').toString()) ?? 0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 0.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Left: special notes
        Expanded(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Special Notes and Instructions'),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(notes, style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ] else const SizedBox(height: 48),
          ]),
        )),
        // Right: subtotal / vat / total
        SizedBox(width: 220, child: Column(children: [
          _totalRow('Subtotal', subtotal),
          _totalRow('VAT (${taxPct.toStringAsFixed(0)}%)',
            taxPct > 0 ? taxAmt : ''),
          Container(
            color: const Color(0xFFF0F4F8),
            child: _totalRow('Total', total, bold: true),
          ),
        ])),
      ]),
    );
  }

  // ── Bank details footer ──────────────────────────────────────────────────
  Widget _buildBankDetails() {
    final bankName   = (_company['bank_name']   ?? '').toString();
    final bankAcc    = (_company['bank_acc']    ?? '').toString();
    final bankBranch = (_company['bank_branch'] ?? '').toString();
    final addr       = (_company['address']     ?? '').toString();

    if (bankName.isEmpty && bankAcc.isEmpty) return const SizedBox();

    return Center(
      child: Column(children: [
        Container(height: 0.5, color: Colors.black26),
        const SizedBox(height: 12),
        const Text('Bank Details:',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 4),
        if ((_company['name'] ?? '').toString().isNotEmpty)
          Text(_company['name'].toString(),
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
        if (bankName.isNotEmpty)
          Text(bankName, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        if (bankAcc.isNotEmpty)
          Text('Acc No: $bankAcc', style: const TextStyle(fontSize: 11, color: Colors.black54)),
        if (bankBranch.isNotEmpty)
          Text('Branch: $bankBranch', style: const TextStyle(fontSize: 11, color: Colors.black54)),
        if (addr.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(addr, style: const TextStyle(fontSize: 10, color: Colors.black45),
            textAlign: TextAlign.center),
        ],
        const SizedBox(height: 12),
        Container(height: 0.5, color: Colors.black26),
      ]),
    );
  }

  // ── Helper widgets ───────────────────────────────────────────────────────
  Widget _label(String text) => Text(text,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
      color: Color(0xFF1E2A3A)));

  Widget _detail(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label,
        style: const TextStyle(fontSize: 11, color: Colors.black54))),
      Expanded(child: Text(value?.toString() ?? '—',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
          color: Colors.black87))),
    ]),
  );

  Widget _th(String text, {TextAlign align = TextAlign.left}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Text(text, textAlign: align,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
        color: Color(0xFF1E2A3A))),
  );

  Widget _td(String text, {TextAlign align = TextAlign.left,
      double top = 8, bool bold = false}) => Padding(
    padding: EdgeInsets.fromLTRB(4, top, 4, top),
    child: Text(text, textAlign: align,
      style: TextStyle(fontSize: 11,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: Colors.black87)),
  );

  Widget _totalRow(String label, String value, {bool bold = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 11,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: Colors.black54)),
      Text(value, style: TextStyle(fontSize: 11,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: bold ? Colors.black87 : Colors.black54)),
    ]),
  );
}
