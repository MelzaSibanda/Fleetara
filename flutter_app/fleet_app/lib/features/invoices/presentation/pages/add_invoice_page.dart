import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';

class AddInvoicePage extends StatefulWidget {
  const AddInvoicePage({super.key});
  @override State<AddInvoicePage> createState() => _AddInvoicePageState();
}

class _AddInvoicePageState extends State<AddInvoicePage> {
  final _formKey   = GlobalKey<FormState>();
  bool  _loading   = false;
  String _type     = 'receivable';
  String _category = 'trip';
  final _fs = sl<FirestoreService>();

  final _partyCtrl     = TextEditingController();
  final _partyAddrCtrl = TextEditingController();
  final _partyVatCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _truckRegCtrl  = TextEditingController();
  final _descCtrl      = TextEditingController();
  final _qtyCtrl       = TextEditingController();
  final _rateCtrl      = TextEditingController();
  final _subtotalCtrl  = TextEditingController();
  final _taxPctCtrl    = TextEditingController(text: '0');
  final _issueDateCtrl = TextEditingController();
  final _dueDateCtrl   = TextEditingController();
  final _notesCtrl     = TextEditingController();

  @override
  void dispose() {
    for (final c in [_partyCtrl, _partyAddrCtrl, _partyVatCtrl, _emailCtrl,
        _phoneCtrl, _truckRegCtrl, _descCtrl, _qtyCtrl, _rateCtrl,
        _subtotalCtrl, _taxPctCtrl, _issueDateCtrl, _dueDateCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _recalcSubtotal() {
    final qty  = double.tryParse(_qtyCtrl.text)  ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    if (qty > 0 && rate > 0) {
      _subtotalCtrl.text = (qty * rate).toStringAsFixed(2);
    }
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (d != null) {
      ctrl.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    return 'INV-${now.year}${now.month.toString().padLeft(2,'0')}${now.millisecond}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final subtotal = double.tryParse(_subtotalCtrl.text) ?? 0;
      final taxPct   = double.tryParse(_taxPctCtrl.text)   ?? 0;
      final tax      = subtotal * taxPct / 100;
      final total    = subtotal + tax;
      final qty      = double.tryParse(_qtyCtrl.text);
      final rate     = double.tryParse(_rateCtrl.text);

      await _fs.db.collection('invoices').add({
        'invoice_number':  _generateInvoiceNumber(),
        'invoice_type':    _type,
        'category':        _category,
        'party_name':      _partyCtrl.text.trim(),
        'party_address':   _partyAddrCtrl.text.trim(),
        'party_vat':       _partyVatCtrl.text.trim(),
        'party_email':     _emailCtrl.text.trim(),
        'party_phone':     _phoneCtrl.text.trim(),
        'truck_reg':       _truckRegCtrl.text.trim(),
        'description':     _descCtrl.text.trim(),
        if (qty != null)  'quantity': qty,
        if (rate != null) 'rate': rate,
        'subtotal':        subtotal,
        'tax_percent':     taxPct,
        'tax_amount':      tax,
        'total':           total,
        'issue_date':      _issueDateCtrl.text.trim(),
        'due_date':        _dueDateCtrl.text.trim(),
        'notes':           _notesCtrl.text.trim(),
        'status':          'draft',
        'created_at':      DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invoice created!', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald, behavior: SnackBarBehavior.floating));
        context.go('/invoices');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('New Invoice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/invoices'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _section('Invoice type'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Invoice type'),
                    items: const [
                      DropdownMenuItem(value: 'receivable', child: Text('Receivable (Client owes us)')),
                      DropdownMenuItem(value: 'payable',    child: Text('Payable (We owe supplier)')),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'trip',    child: Text('Trip / Freight')),
                      DropdownMenuItem(value: 'fuel',    child: Text('Fuel')),
                      DropdownMenuItem(value: 'service', child: Text('Vehicle Service')),
                      DropdownMenuItem(value: 'repair',  child: Text('Repair')),
                      DropdownMenuItem(value: 'tyre',    child: Text('Tyres')),
                      DropdownMenuItem(value: 'other',   child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
                const SizedBox(height: 8),

                _section('Bill To'),
                _field(_partyCtrl,     'Client / Company name'),
                _field(_partyAddrCtrl, 'Client address',    required: false, lines: 2),
                _field(_partyVatCtrl,  'Client VAT number', required: false),
                _field(_emailCtrl,     'Email',             required: false),
                _field(_phoneCtrl,     'Phone',             required: false),
                const SizedBox(height: 8),

                _section('Trip details'),
                _field(_truckRegCtrl, 'Truck reg no.',          required: false),
                _field(_descCtrl,     'Line item description',  required: false, lines: 2),
                const SizedBox(height: 8),

                _section('Amounts'),
                Row(children: [
                  Expanded(child: _field(_qtyCtrl,  'Qty (loads)', isNum: true, required: false,
                    onChanged: (_) => setState(_recalcSubtotal))),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_rateCtrl, 'Rate (R)',    isNum: true, required: false,
                    onChanged: (_) => setState(_recalcSubtotal))),
                ]),
                _field(_subtotalCtrl, 'Subtotal (R)', isNum: true),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _taxPctCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'VAT / Tax %',
                      suffixText: '%',
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                _section('Dates'),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _issueDateCtrl,
                    readOnly: true,
                    onTap: () => _pickDate(_issueDateCtrl),
                    decoration: const InputDecoration(
                      labelText: 'Issue date',
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _dueDateCtrl,
                    readOnly: true,
                    onTap: () => _pickDate(_dueDateCtrl),
                    decoration: const InputDecoration(
                      labelText: 'Due date',
                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Invoice'),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 4),
    child: Text(title, style: const TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted,
      letterSpacing: 0.5)),
  );

  Widget _field(TextEditingController ctrl, String label, {
    bool isNum = false, bool required = true, int lines = 1,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller:   ctrl,
        maxLines:     lines,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        onChanged:    onChanged,
        decoration:   InputDecoration(labelText: label),
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      ),
    );
  }
}
