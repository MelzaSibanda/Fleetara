import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key});
  @override State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading  = false;
  bool _fetching = true;
  final _fs = sl<FirestoreService>();

  List<Map<String, dynamic>> _horses   = [];
  List<Map<String, dynamic>> _trailers = [];
  List<Map<String, dynamic>> _drivers  = [];

  String? _selectedHorse;
  String? _selectedTrailer;
  String? _selectedDriver;
  String  _cargoType = 'general';

  final _clientCtrl = TextEditingController();
  final _originCtrl = TextEditingController();
  final _destCtrl   = TextEditingController();
  final _cargoCtrl  = TextEditingController();
  final _dateCtrl   = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  @override
  void dispose() {
    _clientCtrl.dispose(); _originCtrl.dispose();
    _destCtrl.dispose();   _cargoCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final results = await Future.wait([
        _fs.db.collection('vehicles').where('type', isEqualTo: 'horse').where('status', isEqualTo: 'active').get(),
        _fs.db.collection('vehicles').where('type', isEqualTo: 'trailer').where('status', isEqualTo: 'active').get(),
        _fs.db.collection('users').where('role', isEqualTo: 'driver').get(),
      ]);

      setState(() {
        _horses   = _fs.docsToList(results[0]).map<Map<String, dynamic>>((h) => {
          'id':    h['id'],
          'label': '${h['registration_number']} — ${h['make']} ${h['model']}',
          'reg':   h['registration_number'] ?? '',
        }).toList();
        _trailers = _fs.docsToList(results[1]).map<Map<String, dynamic>>((t) => {
          'id':    t['id'],
          'label': '${t['registration_number']} (trailer)',
          'reg':   t['registration_number'] ?? '',
        }).toList();
        _drivers  = _fs.docsToList(results[2]).map<Map<String, dynamic>>((d) => {
          'id':    d['id'],
          'label': '${d['first_name']} ${d['last_name']}'.trim().isNotEmpty
              ? '${d['first_name']} ${d['last_name']}'.trim()
              : d['email'] ?? '',
          'name':  '${d['first_name']} ${d['last_name']}'.trim(),
        }).toList();
        _fetching = false;
      });
    } catch (e) {
      setState(() => _fetching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to load form data: $e',
            style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    _dateCtrl.text = dt.toIso8601String();
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final horse   = _horses.firstWhere((h) => h['id'] == _selectedHorse,
          orElse: () => {});
      final trailer = _trailers.firstWhere((t) => t['id'] == _selectedTrailer,
          orElse: () => {});
      final driver  = _drivers.firstWhere((d) => d['id'] == _selectedDriver,
          orElse: () => {});

      await _fs.db.collection('trips').add({
        'client_name':        _clientCtrl.text.trim(),
        'origin':             _originCtrl.text.trim(),
        'destination':        _destCtrl.text.trim(),
        'cargo_description':  _cargoCtrl.text.trim(),
        'cargo_type':         _cargoType,
        'scheduled_start':    _dateCtrl.text.trim(),
        'horse_id':           _selectedHorse,
        'horse_reg':          horse['reg'] ?? '',
        'trailer_id':         _selectedTrailer,
        'trailer_reg':        trailer['reg'] ?? '',
        'driver_id':          _selectedDriver,
        'driver_name':        driver['name'] ?? '',
        'status':             'scheduled',
        'created_at':         DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trip created successfully',
            style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald, behavior: SnackBarBehavior.floating,
        ));
        context.go('/trips');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
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
        title: const Text('New Trip'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/trips'),
        ),
      ),
      body: _fetching
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _section('Trip details'),
                      _field(_clientCtrl, 'Client name',       'e.g. Acme Logistics'),
                      _field(_originCtrl, 'Origin',            'e.g. Johannesburg'),
                      _field(_destCtrl,   'Destination',       'e.g. Cape Town'),
                      _field(_cargoCtrl,  'Cargo description', 'What is being transported?'),

                      _dropdownField<String>(
                        label:   'Cargo type',
                        value:   _cargoType,
                        items: const [
                          DropdownMenuItem(value: 'general',    child: Text('General Freight')),
                          DropdownMenuItem(value: 'perishable', child: Text('Perishable')),
                          DropdownMenuItem(value: 'hazardous',  child: Text('Hazardous')),
                          DropdownMenuItem(value: 'oversized',  child: Text('Oversized')),
                          DropdownMenuItem(value: 'bulk',       child: Text('Bulk')),
                          DropdownMenuItem(value: 'other',      child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _cargoType = v!),
                        validator: null,
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller:  _dateCtrl,
                          readOnly:    true,
                          onTap:       _pickDateTime,
                          decoration: const InputDecoration(
                            labelText:   'Scheduled departure',
                            suffixIcon:  Icon(Icons.calendar_today, size: 18),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Select a departure date and time' : null,
                        ),
                      ),

                      const SizedBox(height: 4),
                      _section('Assign vehicle & driver'),

                      _dropdownField<String>(
                        label:   'Horse (Truck)',
                        value:   _selectedHorse,
                        hint:    _horses.isEmpty ? 'No active horses available' : 'Select a horse',
                        items:   _horses.map((h) => DropdownMenuItem<String>(
                          value: h['id'] as String,
                          child: Text(h['label'] as String, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: _horses.isEmpty ? null : (v) => setState(() => _selectedHorse = v),
                        validator: (_) => _selectedHorse == null ? 'Select a horse' : null,
                      ),

                      _dropdownField<String>(
                        label:   'Trailer',
                        value:   _selectedTrailer,
                        hint:    _trailers.isEmpty ? 'No active trailers available' : 'Select a trailer',
                        items:   _trailers.map((t) => DropdownMenuItem<String>(
                          value: t['id'] as String,
                          child: Text(t['label'] as String, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: _trailers.isEmpty ? null : (v) => setState(() => _selectedTrailer = v),
                        validator: (_) => _selectedTrailer == null ? 'Select a trailer' : null,
                      ),

                      _dropdownField<String>(
                        label:   'Driver',
                        value:   _selectedDriver,
                        hint:    _drivers.isEmpty ? 'No drivers available' : 'Select a driver',
                        items:   _drivers.map((d) => DropdownMenuItem<String>(
                          value: d['id'] as String,
                          child: Text(d['label'] as String, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: _drivers.isEmpty ? null : (v) => setState(() => _selectedDriver = v),
                        validator: (_) => _selectedDriver == null ? 'Select a driver' : null,
                      ),

                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(height: 18, width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Create Trip'),
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
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
  );

  Widget _field(TextEditingController ctrl, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    required String? Function(T?)? validator,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration:   InputDecoration(labelText: label),
        hint:        Text(hint ?? 'Select', style: const TextStyle(fontSize: 12)),
        items:       items,
        onChanged:   onChanged,
        validator:   validator,
        isExpanded:  true,
      ),
    );
  }
}
