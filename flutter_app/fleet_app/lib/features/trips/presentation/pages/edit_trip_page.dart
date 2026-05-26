import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../data/trip_model.dart';

class EditTripPage extends StatefulWidget {
  final TripModel trip;
  const EditTripPage({super.key, required this.trip});

  @override
  State<EditTripPage> createState() => _EditTripPageState();
}

class _EditTripPageState extends State<EditTripPage> {
  final _formKey  = GlobalKey<FormState>();
  bool  _loading  = false;
  bool  _fetching = true;
  final _fs = sl<FirestoreService>();

  List<Map<String, dynamic>> _horses   = [];
  List<Map<String, dynamic>> _trailers = [];
  List<Map<String, dynamic>> _drivers  = [];

  String? _selectedHorse;
  String? _selectedTrailer;
  String? _selectedDriver;
  String  _cargoType = 'general';

  late final TextEditingController _clientCtrl;
  late final TextEditingController _originCtrl;
  late final TextEditingController _destCtrl;
  late final TextEditingController _cargoCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final t          = widget.trip;
    _cargoType       = t.cargoType;
    _selectedHorse   = t.horseId;
    _selectedTrailer = t.trailerId;
    _selectedDriver  = t.driverId;

    _clientCtrl = TextEditingController(text: t.clientName);
    _originCtrl = TextEditingController(text: t.origin);
    _destCtrl   = TextEditingController(text: t.destination);
    _cargoCtrl  = TextEditingController(text: t.cargoDescription);
    _dateCtrl   = TextEditingController(
      text: t.scheduledStart.length >= 16
        ? t.scheduledStart.substring(0, 16).replaceAll('T', ' ')
        : t.scheduledStart,
    );
    _notesCtrl = TextEditingController(text: t.notes ?? '');
    _fetchDropdownData();
  }

  @override
  void dispose() {
    _clientCtrl.dispose(); _originCtrl.dispose();
    _destCtrl.dispose();   _cargoCtrl.dispose();
    _dateCtrl.dispose();   _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdownData() async {
    try {
      final results = await Future.wait([
        _fs.db.collection('vehicles').where('type', isEqualTo: 'horse').get(),
        _fs.db.collection('vehicles').where('type', isEqualTo: 'trailer').get(),
        _fs.db.collection('users').where('role', isEqualTo: 'driver').get(),
      ]);
      setState(() {
        _horses = _fs.docsToList(results[0]).map<Map<String, dynamic>>((h) => {
          'id':    h['id'],
          'label': '${h['registration_number']} — ${h['make']} ${h['model']}',
          'reg':   h['registration_number'] ?? '',
        }).toList();
        _trailers = _fs.docsToList(results[1]).map<Map<String, dynamic>>((t) => {
          'id':    t['id'],
          'label': '${t['registration_number']} (trailer)',
          'reg':   t['registration_number'] ?? '',
        }).toList();
        _drivers = _fs.docsToList(results[2]).map<Map<String, dynamic>>((d) => {
          'id':    d['id'],
          'label': '${d['first_name']} ${d['last_name']}'.trim().isNotEmpty
              ? '${d['first_name']} ${d['last_name']}'.trim()
              : d['email'] ?? '',
          'name':  '${d['first_name']} ${d['last_name']}'.trim(),
        }).toList();
        _fetching = false;
      });
    } catch (_) {
      setState(() => _fetching = false);
    }
  }

  Future<void> _pickDateTime() async {
    DateTime initial = DateTime.now();
    try {
      final raw = widget.trip.scheduledStart;
      initial = DateTime.parse(raw.contains('T') ? raw : raw.replaceAll(' ', 'T'));
    } catch (_) {}

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _dateCtrl.text = dt.toIso8601String().substring(0, 16).replaceAll('T', ' '));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final rawDate = _dateCtrl.text.trim().replaceAll(' ', 'T');
      final horse   = _horses.firstWhere((h) => h['id'] == _selectedHorse, orElse: () => {});
      final trailer = _trailers.firstWhere((t) => t['id'] == _selectedTrailer, orElse: () => {});
      final driver  = _drivers.firstWhere((d) => d['id'] == _selectedDriver, orElse: () => {});

      await _fs.db.collection('trips').doc(widget.trip.id).update({
        'client_name':       _clientCtrl.text.trim(),
        'origin':            _originCtrl.text.trim(),
        'destination':       _destCtrl.text.trim(),
        'cargo_description': _cargoCtrl.text.trim(),
        'cargo_type':        _cargoType,
        'scheduled_start':   rawDate,
        'horse_id':          _selectedHorse,
        'horse_reg':         horse['reg'] ?? '',
        'trailer_id':        _selectedTrailer,
        'trailer_reg':       trailer['reg'] ?? '',
        'driver_id':         _selectedDriver,
        'driver_name':       driver['name'] ?? '',
        'notes':             _notesCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trip updated', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald, behavior: SnackBarBehavior.floating));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5)));
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
        title: const Text('Edit Trip'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
                    _field(_clientCtrl, 'Client name'),
                    _field(_originCtrl, 'Origin'),
                    _field(_destCtrl,   'Destination'),
                    _field(_cargoCtrl,  'Cargo description'),

                    _dropdown<String>(
                      label:  'Cargo type',
                      value:  _cargoType,
                      items: const [
                        DropdownMenuItem(value: 'general',    child: Text('General Freight')),
                        DropdownMenuItem(value: 'perishable', child: Text('Perishable')),
                        DropdownMenuItem(value: 'hazardous',  child: Text('Hazardous')),
                        DropdownMenuItem(value: 'oversized',  child: Text('Oversized')),
                        DropdownMenuItem(value: 'bulk',       child: Text('Bulk')),
                        DropdownMenuItem(value: 'other',      child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _cargoType = v!),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _dateCtrl,
                        readOnly:   true,
                        onTap:      _pickDateTime,
                        decoration: const InputDecoration(
                          labelText:  'Scheduled departure',
                          suffixIcon: Icon(Icons.calendar_today, size: 18)),
                        validator: (v) =>
                          v == null || v.isEmpty ? 'Select departure date' : null,
                      ),
                    ),

                    _section('Assignment'),

                    _dropdown<String>(
                      label:     'Horse (Truck)',
                      value:     _selectedHorse,
                      hint:      'Select horse',
                      items:     _horses.map((h) => DropdownMenuItem<String>(
                        value: h['id'] as String,
                        child: Text(h['label'] as String, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _selectedHorse = v),
                      validator: (_) => _selectedHorse == null ? 'Select a horse' : null,
                    ),

                    _dropdown<String>(
                      label:     'Trailer',
                      value:     _selectedTrailer,
                      hint:      'Select trailer',
                      items:     _trailers.map((t) => DropdownMenuItem<String>(
                        value: t['id'] as String,
                        child: Text(t['label'] as String, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _selectedTrailer = v),
                      validator: (_) => _selectedTrailer == null ? 'Select a trailer' : null,
                    ),

                    _dropdown<String>(
                      label:     'Driver',
                      value:     _selectedDriver,
                      hint:      'Select driver',
                      items:     _drivers.map((d) => DropdownMenuItem<String>(
                        value: d['id'] as String,
                        child: Text(d['label'] as String, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setState(() => _selectedDriver = v),
                      validator: (_) => _selectedDriver == null ? 'Select a driver' : null,
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: TextFormField(
                        controller: _notesCtrl,
                        maxLines:   3,
                        decoration: const InputDecoration(labelText: 'Notes (optional)'),
                      ),
                    ),

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

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 4),
    child: Text(title, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
  );

  Widget _field(TextEditingController ctrl, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    ),
  );

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    String? hint,
  }) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration:  InputDecoration(labelText: label),
        hint:        hint != null ? Text(hint, style: const TextStyle(fontSize: 12)) : null,
        items:       items,
        isExpanded:  true,
        onChanged:   onChanged,
        validator:   validator,
      ),
    );
}
