import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key});
  @override State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final _formKey     = GlobalKey<FormState>();
  bool  _loading     = false;
  String _cargoType  = 'general';

  final _clientCtrl  = TextEditingController();
  final _originCtrl  = TextEditingController();
  final _destCtrl    = TextEditingController();
  final _cargoCtrl   = TextEditingController();
  final _dateCtrl    = TextEditingController();
  final _horseCtrl   = TextEditingController();
  final _trailerCtrl = TextEditingController();
  final _driverCtrl  = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await sl<ApiClient>().dio.post('/trips/', data: {
        'client_name':       _clientCtrl.text.trim(),
        'origin':            _originCtrl.text.trim(),
        'destination':       _destCtrl.text.trim(),
        'cargo_description': _cargoCtrl.text.trim(),
        'cargo_type':        _cargoType,
        'scheduled_start':   _dateCtrl.text.trim(),
        'horse':             int.tryParse(_horseCtrl.text),
        'trailer':           int.tryParse(_trailerCtrl.text),
        'driver':            int.tryParse(_driverCtrl.text),
        'status':            'scheduled',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trip created!'), backgroundColor: AppTheme.success));
        context.go('/trips');
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
      appBar: AppBar(title: const Text('New Trip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _field(_clientCtrl,  'Client name',        'e.g. Acme Logistics'),
              _field(_originCtrl,  'Origin',             'e.g. Johannesburg'),
              _field(_destCtrl,    'Destination',        'e.g. Cape Town'),
              _field(_cargoCtrl,   'Cargo description',  'What are you transporting?'),
              _field(_dateCtrl,    'Scheduled start',    'YYYY-MM-DDTHH:MM'),
              _field(_horseCtrl,   'Horse ID',           'Vehicle ID', isNum: true),
              _field(_trailerCtrl, 'Trailer ID',         'Trailer ID', isNum: true),
              _field(_driverCtrl,  'Driver ID',          'Driver user ID', isNum: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: _cargoType,
                  decoration: const InputDecoration(labelText: 'Cargo type'),
                  items: const [
                    DropdownMenuItem(value: 'general',    child: Text('General Freight')),
                    DropdownMenuItem(value: 'perishable', child: Text('Perishable')),
                    DropdownMenuItem(value: 'hazardous',  child: Text('Hazardous')),
                    DropdownMenuItem(value: 'oversized',  child: Text('Oversized')),
                    DropdownMenuItem(value: 'bulk',       child: Text('Bulk')),
                  ],
                  onChanged: (v) => setState(() => _cargoType = v!),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Trip'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }
}
