import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class StatementGeneratorPage extends StatefulWidget {
  const StatementGeneratorPage({super.key});
  @override State<StatementGeneratorPage> createState() => _StatementGeneratorPageState();
}

class _StatementGeneratorPageState extends State<StatementGeneratorPage> {
  final _formKey       = GlobalKey<FormState>();
  final _clientCtrl    = TextEditingController();
  final _stmtNoCtrl    = TextEditingController();
  final _fromDateCtrl  = TextEditingController();
  final _toDateCtrl    = TextEditingController();

  @override
  void dispose() {
    _clientCtrl.dispose(); _stmtNoCtrl.dispose();
    _fromDateCtrl.dispose(); _toDateCtrl.dispose();
    super.dispose();
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

  void _generate() {
    if (!_formKey.currentState!.validate()) return;
    context.go('/invoices/statement/preview', extra: {
      'client':       _clientCtrl.text.trim(),
      'statement_no': _stmtNoCtrl.text.trim(),
      'from_date':    _fromDateCtrl.text.trim(),
      'to_date':      _toDateCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Generate Statement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/invoices'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _section('Client'),
                TextFormField(
                  controller: _clientCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Client / Company name',
                    hintText: 'e.g. Wisewalls Logistics',
                    prefixIcon: Icon(Icons.business_outlined, size: 18),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                _section('Statement details'),
                TextFormField(
                  controller: _stmtNoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Statement #',
                    hintText: 'e.g. Sep-25',
                    prefixIcon: Icon(Icons.tag_outlined, size: 18),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _datePicker(_fromDateCtrl, 'From date')),
                  const SizedBox(width: 12),
                  Expanded(child: _datePicker(_toDateCtrl,   'To date')),
                ]),
                const SizedBox(height: 28),

                ElevatedButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.description_outlined, color: Colors.white, size: 18),
                  label: const Text('Generate Statement'),
                ),
                const SizedBox(height: 32),
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
      fontSize: 11, fontWeight: FontWeight.w600,
      color: AppTheme.textMuted, letterSpacing: 0.5)),
  );

  Widget _datePicker(TextEditingController ctrl, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: ctrl,
      readOnly: true,
      onTap: () => _pickDate(ctrl),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today, size: 16),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    ),
  );
}
