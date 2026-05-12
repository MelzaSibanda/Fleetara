import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';

class AddFuelPage extends StatefulWidget {
  const AddFuelPage({super.key});
  @override State<AddFuelPage> createState() => _AddFuelPageState();
}

class _AddFuelPageState extends State<AddFuelPage> {
  final _formKey      = GlobalKey<FormState>();
  bool  _loading      = false;
  String _fuelType    = 'diesel';

  final _tripCtrl     = TextEditingController();
  final _horseCtrl    = TextEditingController();
  final _litersCtrl   = TextEditingController();
  final _costCtrl     = TextEditingController();
  final _odomCtrl     = TextEditingController();
  final _stationCtrl  = TextEditingController();
  final _locationCtrl = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await sl<ApiClient>().dio.post('/fuel/', data: {
        'trip':         int.parse(_tripCtrl.text),
        'horse':        int.parse(_horseCtrl.text),
        'fuel_type':    _fuelType,
        'liters':       double.parse(_litersCtrl.text),
        'cost':         double.parse(_costCtrl.text),
        'odometer':     int.parse(_odomCtrl.text),
        'fuel_station': _stationCtrl.text.trim(),
        'location':     _locationCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Fuel entry logged!'), backgroundColor: AppTheme.success));
        context.go('/fuel');
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
      appBar: AppBar(title: const Text('Log Fuel Stop')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _field(_tripCtrl,  'Trip ID',          isNum: true),
              _field(_horseCtrl, 'Horse (Truck) ID', isNum: true),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: _fuelType,
                  decoration: const InputDecoration(labelText: 'Fuel type'),
                  items: const [
                    DropdownMenuItem(value: 'diesel', child: Text('Diesel')),
                    DropdownMenuItem(value: 'petrol', child: Text('Petrol')),
                    DropdownMenuItem(value: 'adblue', child: Text('AdBlue')),
                  ],
                  onChanged: (v) => setState(() => _fuelType = v!),
                ),
              ),
              Row(children: [
                Expanded(child: _field(_litersCtrl, 'Litres',   isNum: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_costCtrl,   'Cost (R)', isNum: true)),
              ]),
              _field(_odomCtrl,    'Odometer (km)',    isNum: true),
              _field(_stationCtrl, 'Fuel station name', required: false),
              _field(_locationCtrl,'Location',          required: false),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Fuel Entry'),
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
