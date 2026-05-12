import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';

class AddRepairPage extends StatefulWidget {
  const AddRepairPage({super.key});
  @override State<AddRepairPage> createState() => _AddRepairPageState();
}

class _AddRepairPageState extends State<AddRepairPage> {
  final _formKey       = GlobalKey<FormState>();
  bool  _loading       = false;
  String _priority     = 'medium';
  String _vehicleType  = 'horse';

  final _titleCtrl     = TextEditingController();
  final _descCtrl      = TextEditingController();
  final _vehicleIdCtrl = TextEditingController();
  final _workshopCtrl  = TextEditingController();
  final _costCtrl      = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final id = int.tryParse(_vehicleIdCtrl.text);
      await sl<ApiClient>().dio.post('/repairs/', data: {
        'title':         _titleCtrl.text.trim(),
        'description':   _descCtrl.text.trim(),
        'priority':      _priority,
        'status':        'reported',
        'workshop_name': _workshopCtrl.text.trim(),
        'repair_cost':   _costCtrl.text.isEmpty ? null : double.parse(_costCtrl.text),
        if (_vehicleType == 'horse')   'horse':   id,
        if (_vehicleType == 'trailer') 'trailer': id,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Repair reported!'), backgroundColor: AppTheme.success));
        context.go('/repairs');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
=======
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error))
>>>>>>> 2077d3f97f38c256ddf48e9491d67a18af7d6f87
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Repair / Breakdown')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _field(_titleCtrl, 'Issue title', hint: 'e.g. Engine overheating'),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'low',      child: Text('Low')),
                  DropdownMenuItem(value: 'medium',   child: Text('Medium')),
                  DropdownMenuItem(value: 'high',     child: Text('High')),
                  DropdownMenuItem(value: 'critical', child: Text('Critical — Off Road')),
                ],
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _vehicleType,
                decoration: const InputDecoration(labelText: 'Vehicle type'),
                items: const [
                  DropdownMenuItem(value: 'horse',   child: Text('Horse (Truck)')),
                  DropdownMenuItem(value: 'trailer', child: Text('Trailer')),
                ],
                onChanged: (v) => setState(() => _vehicleType = v!),
              ),
              const SizedBox(height: 16),
              _field(_vehicleIdCtrl, 'Vehicle ID',           isNum: true),
              _field(_workshopCtrl,  'Workshop name',         required: false),
              _field(_costCtrl,      'Estimated cost (R)',    isNum: true, required: false),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Report Issue'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool isNum = false, bool required = true, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      ),
    );
  }
}
