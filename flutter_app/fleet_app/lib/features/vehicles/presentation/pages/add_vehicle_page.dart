import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/responsive.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});
  @override State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey          = GlobalKey<FormState>();
  String _type            = 'horse';
  bool   _loading         = false;

  final _regCtrl          = TextEditingController();
  final _makeCtrl         = TextEditingController();
  final _modelCtrl        = TextEditingController();
  final _yearCtrl         = TextEditingController();
  final _odomCtrl         = TextEditingController();
  final _licenseCtrl      = TextEditingController();
  final _insuranceCtrl    = TextEditingController();
  final _serviceKmCtrl    = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final endpoint = _type == 'horse' ? '/vehicles/horses/' : '/vehicles/trailers/';
      await sl<ApiClient>().dio.post(endpoint, data: {
        'registration_number': _regCtrl.text.trim(),
        'make':                _makeCtrl.text.trim(),
        'model':               _modelCtrl.text.trim(),
        'year':                int.parse(_yearCtrl.text),
        'odometer':            int.parse(_odomCtrl.text),
        'license_expiry':      _licenseCtrl.text,
        'insurance_expiry':    _insuranceCtrl.text,
        'service_interval_km': int.parse(_serviceKmCtrl.text),
        'next_service_km':     int.parse(_serviceKmCtrl.text),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Vehicle added!'), backgroundColor: AppTheme.success));
        context.go('/vehicles');
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
      appBar: AppBar(title: const Text('Add Vehicle')),
      body: SingleChildScrollView(
        padding: Responsive.pagePadding(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Vehicle type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(children: [
                _TypeButton(label: 'Horse (Truck)', selected: _type == 'horse',
                  onTap: () => setState(() => _type = 'horse')),
                const SizedBox(width: 12),
                _TypeButton(label: 'Trailer', selected: _type == 'trailer',
                  onTap: () => setState(() => _type = 'trailer')),
              ]),
              const SizedBox(height: 24),
              _field(_regCtrl,       'Registration number',   'e.g. ABC123GP'),
              _field(_makeCtrl,      'Make',                  'e.g. Volvo'),
              _field(_modelCtrl,     'Model',                 'e.g. FH16'),
              _field(_yearCtrl,      'Year',                  'e.g. 2021',  isNum: true),
              _field(_odomCtrl,      'Current odometer (km)', 'e.g. 85000', isNum: true),
              _field(_licenseCtrl,   'License expiry',        'YYYY-MM-DD'),
              _field(_insuranceCtrl, 'Insurance expiry',      'YYYY-MM-DD'),
              _field(_serviceKmCtrl, 'Service interval (km)', 'e.g. 20000', isNum: true),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Vehicle'),
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

class _TypeButton extends StatelessWidget {
  final String label;
  final bool   selected;
  final VoidCallback onTap;
  const _TypeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        )),
      ),
    );
  }
}
