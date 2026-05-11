import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';

class AddInvoicePage extends StatefulWidget {
  const AddInvoicePage({super.key});
  @override State<AddInvoicePage> createState() => _AddInvoicePageState();
}

class _AddInvoicePageState extends State<AddInvoicePage> {
  final _formKey       = GlobalKey<FormState>();
  bool  _loading       = false;
  String _type         = 'receivable';
  String _category     = 'trip';

  final _partyCtrl     = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _subtotalCtrl  = TextEditingController();
  final _issueDateCtrl = TextEditingController();
  final _dueDateCtrl   = TextEditingController();
  final _notesCtrl     = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await sl<ApiClient>().dio.post('/invoices/', data: {
        'invoice_type': _type,
        'category':     _category,
        'party_name':   _partyCtrl.text.trim(),
        'party_email':  _emailCtrl.text.trim(),
        'party_phone':  _phoneCtrl.text.trim(),
        'subtotal':     double.parse(_subtotalCtrl.text),
        'issue_date':   _issueDateCtrl.text.trim(),
        'due_date':     _dueDateCtrl.text.trim(),
        'notes':        _notesCtrl.text.trim(),
        'status':       'draft',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invoice created!'), backgroundColor: AppTheme.success));
        context.go('/invoices');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Invoice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Invoice type'),
                items: const [
                  DropdownMenuItem(value: 'receivable', child: Text('Receivable (Client owes us)')),
                  DropdownMenuItem(value: 'payable',    child: Text('Payable (We owe supplier)')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
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
              const SizedBox(height: 16),
              _field(_partyCtrl,    'Client / Supplier name'),
              _field(_emailCtrl,    'Email',                 required: false),
              _field(_phoneCtrl,    'Phone',                 required: false),
              _field(_subtotalCtrl, 'Subtotal (R)',          isNum: true),
              _field(_issueDateCtrl,'Issue date (YYYY-MM-DD)'),
              _field(_dueDateCtrl,  'Due date (YYYY-MM-DD)'),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Invoice'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool isNum = false, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      ),
    );
  }
}
