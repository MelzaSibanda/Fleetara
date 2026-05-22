import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../data/vehicle_model.dart';

class EditVehiclePage extends StatefulWidget {
  final VehicleModel vehicle;
  const EditVehiclePage({super.key, required this.vehicle});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final _formKey       = GlobalKey<FormState>();
  bool  _loading       = false;
  late String _status;

  late final TextEditingController _regCtrl;
  late final TextEditingController _makeCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _odomCtrl;
  late final TextEditingController _licenseCtrl;
  late final TextEditingController _insuranceCtrl;
  late final TextEditingController _serviceKmCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _status       = v.status;
    _regCtrl      = TextEditingController(text: v.registrationNumber);
    _makeCtrl     = TextEditingController(text: v.make);
    _modelCtrl    = TextEditingController(text: v.model);
    _yearCtrl     = TextEditingController(text: v.year.toString());
    _odomCtrl     = TextEditingController(text: v.odometer.toString());
    _licenseCtrl  = TextEditingController(text: v.licenseExpiry);
    _insuranceCtrl= TextEditingController(text: v.insuranceExpiry);
    _serviceKmCtrl= TextEditingController(text: v.serviceIntervalKm.toString());
    _notesCtrl    = TextEditingController(text: v.notes ?? '');
  }

  @override
  void dispose() {
    _regCtrl.dispose(); _makeCtrl.dispose(); _modelCtrl.dispose();
    _yearCtrl.dispose(); _odomCtrl.dispose(); _licenseCtrl.dispose();
    _insuranceCtrl.dispose(); _serviceKmCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final endpoint = widget.vehicle.type == 'horse'
          ? '/vehicles/horses/${widget.vehicle.id}/'
          : '/vehicles/trailers/${widget.vehicle.id}/';

      await sl<ApiClient>().dio.patch(endpoint, data: {
        'registration_number': _regCtrl.text.trim(),
        'make':                _makeCtrl.text.trim(),
        'model':               _modelCtrl.text.trim(),
        'year':                int.parse(_yearCtrl.text),
        'odometer':            int.parse(_odomCtrl.text),
        'license_expiry':      _licenseCtrl.text.trim(),
        'insurance_expiry':    _insuranceCtrl.text.trim(),
        'service_interval_km': int.parse(_serviceKmCtrl.text),
        'status':              _status,
        if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Vehicle updated successfully',
            style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e',
            style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHorse = widget.vehicle.type == 'horse';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Edit ${isHorse ? 'Horse' : 'Trailer'}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isHorse ? Icons.local_shipping : Icons.trolley,
                      size: 14, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(isHorse ? 'Horse (Truck)' : 'Trailer',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                        color: AppTheme.primary)),
                  ]),
                ),
                const SizedBox(height: 20),

                _field(_regCtrl,       'Registration number',   required: true),
                _field(_makeCtrl,      'Make',                  required: true),
                _field(_modelCtrl,     'Model',                 required: true),
                _field(_yearCtrl,      'Year',                  isNum: true, required: true),
                _field(_odomCtrl,      'Odometer (km)',         isNum: true, required: true),
                _field(_licenseCtrl,   'License expiry',        hint: 'YYYY-MM-DD', required: true),
                _field(_insuranceCtrl, 'Insurance expiry',      hint: 'YYYY-MM-DD', required: true),
                _field(_serviceKmCtrl, 'Service interval (km)', isNum: true, required: true),

                // Status dropdown
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'active',      child: Text('Active')),
                      DropdownMenuItem(value: 'inactive',    child: Text('Inactive')),
                      DropdownMenuItem(value: 'maintenance', child: Text('In Maintenance')),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),

                _field(_notesCtrl, 'Notes', required: false, maxLines: 3),

                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save changes'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {
    bool isNum = false, bool required = true, String? hint, int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller:  ctrl,
        maxLines:    maxLines,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      ),
    );
  }
}
