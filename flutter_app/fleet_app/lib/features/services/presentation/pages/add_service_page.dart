import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';

class AddServicePage extends StatefulWidget {
  const AddServicePage({super.key});
  @override State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final _formKey     = GlobalKey<FormState>();
  final _fs          = sl<FirestoreService>();

  bool   _loading    = false;
  bool   _fetching   = true;

  List<Map<String, dynamic>> _vehicles = [];
  String? _selectedVehicleId;
  String  _selectedVehicleReg = '';

  String _serviceType = 'oil_change';
  String _status      = 'scheduled';

  final _workshopCtrl  = TextEditingController();
  final _odomCtrl      = TextEditingController();
  final _costCtrl      = TextEditingController();
  final _notesCtrl     = TextEditingController();
  final _dateCtrl      = TextEditingController();

  static const _serviceTypes = [
    ('oil_change',     'Oil Change'),
    ('tyre_rotation',  'Tyre Rotation'),
    ('brake_service',  'Brake Service'),
    ('major_service',  'Major Service'),
    ('minor_service',  'Minor Service'),
    ('inspection',     'Inspection'),
    ('other',          'Other'),
  ];

  static const _statuses = [
    ('scheduled',   'Scheduled'),
    ('in_progress', 'In Progress'),
    ('completed',   'Completed'),
  ];

  @override
  void initState() { super.initState(); _fetchVehicles(); }

  @override
  void dispose() {
    _workshopCtrl.dispose(); _odomCtrl.dispose();
    _costCtrl.dispose(); _notesCtrl.dispose(); _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchVehicles() async {
    try {
      final snap = await _fs.db.collection('vehicles')
          .where('status', isEqualTo: 'active').get();
      setState(() {
        _vehicles = _fs.docsToList(snap).map<Map<String, dynamic>>((v) => {
          'id':    v['id'],
          'label': '${v['registration_number']} — ${v['make'] ?? ''} ${v['model'] ?? ''}'.trim(),
          'reg':   v['registration_number'] ?? '',
        }).toList();
        _fetching = false;
      });
    } catch (_) { setState(() => _fetching = false); }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (date == null) return;
    _dateCtrl.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _fs.db.collection('vehicle_services').add({
        'vehicle_id':           _selectedVehicleId,
        'vehicle_reg':          _selectedVehicleReg,
        'service_type':         _serviceType,
        'status':               _status,
        'scheduled_date':       _dateCtrl.text.trim(),
        'workshop_name':        _workshopCtrl.text.trim(),
        'odometer_at_service':  int.tryParse(_odomCtrl.text.trim()) ?? 0,
        'total_cost':           double.tryParse(_costCtrl.text.trim()) ?? 0,
        'notes':                _notesCtrl.text.trim(),
        'created_at':           DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Service logged successfully',
            style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating,
        ));
        context.go('/services');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating,
        ));
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
        title: const Text('Log Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/services'),
        ),
      ),
      body: _fetching
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      _section('Vehicle'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Vehicle'),
                          hint: Text(
                            _vehicles.isEmpty ? 'No active vehicles' : 'Select a vehicle',
                            style: const TextStyle(fontSize: 12)),
                          value: _selectedVehicleId,
                          isExpanded: true,
                          items: _vehicles.map((v) => DropdownMenuItem<String>(
                            value: v['id'] as String,
                            child: Text(v['label'] as String,
                              overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: _vehicles.isEmpty ? null : (v) {
                            final vehicle = _vehicles.firstWhere(
                              (ve) => ve['id'] == v, orElse: () => {});
                            setState(() {
                              _selectedVehicleId  = v;
                              _selectedVehicleReg = vehicle['reg'] ?? '';
                            });
                          },
                          validator: (_) =>
                              _selectedVehicleId == null ? 'Select a vehicle' : null,
                        ),
                      ),

                      _section('Service details'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Service type'),
                          initialValue: _serviceType,
                          isExpanded: true,
                          items: _serviceTypes.map((t) => DropdownMenuItem(
                            value: t.$1, child: Text(t.$2))).toList(),
                          onChanged: (v) => setState(() => _serviceType = v!),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Status'),
                          initialValue: _status,
                          isExpanded: true,
                          items: _statuses.map((s) => DropdownMenuItem(
                            value: s.$1, child: Text(s.$2))).toList(),
                          onChanged: (v) => setState(() => _status = v!),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _dateCtrl,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: const InputDecoration(
                            labelText: 'Service date',
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Select a date' : null,
                        ),
                      ),

                      _textField(_workshopCtrl, 'Workshop / Garage',
                          'e.g. AutoFix Cape Town', required: false),
                      _textField(_odomCtrl, 'Odometer at service (km)',
                          'e.g. 95000', isNum: true),
                      _textField(_costCtrl, 'Total cost (R)',
                          'e.g. 3500', isNum: true),

                      _section('Notes'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            hintText: 'Any additional details about this service',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(height: 18, width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                            : const Text('Save Service'),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 14, top: 4),
    child: Text(title,
      style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
  );

  Widget _textField(TextEditingController ctrl, String label, String hint,
      {bool isNum = false, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: required
            ? (v) => v == null || v.isEmpty ? 'Required' : null
            : null,
      ),
    );
  }
}
