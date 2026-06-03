import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/notification_service.dart';

class AddFuelPage extends StatefulWidget {
  const AddFuelPage({super.key});
  @override State<AddFuelPage> createState() => _AddFuelPageState();
}

class _AddFuelPageState extends State<AddFuelPage> {
  final _formKey    = GlobalKey<FormState>();
  bool  _loading    = false;
  bool  _fetching   = true;
  String _fuelType  = 'diesel';
  final _fs = sl<FirestoreService>();

  List<Map<String, dynamic>> _horses = [];
  String? _selectedHorse;
  String? _selectedHorseReg;

  final _litersCtrl   = TextEditingController();
  final _costCtrl     = TextEditingController();
  final _odomCtrl     = TextEditingController();
  final _stationCtrl  = TextEditingController();
  final _locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  @override
  void dispose() {
    _litersCtrl.dispose(); _costCtrl.dispose(); _odomCtrl.dispose();
    _stationCtrl.dispose(); _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchVehicles() async {
    try {
      final snap = await _fs.db.collection('vehicles')
          .where('type', isEqualTo: 'horse').get();
      setState(() {
        _horses = _fs.docsToList(snap).map<Map<String, dynamic>>((h) => {
          'id':    h['id'],
          'label': '${h['registration_number']} — ${h['make']} ${h['model']}',
          'reg':   h['registration_number'] ?? '',
        }).toList();
        _fetching = false;
      });
    } catch (_) {
      setState(() => _fetching = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final fbUser     = FirebaseAuth.instance.currentUser;
      final driverUid  = fbUser?.uid ?? '';
      String driverName = fbUser?.displayName ?? '';
      if (driverName.isEmpty && driverUid.isNotEmpty) {
        try {
          final doc = await _fs.db.collection('users').doc(driverUid).get();
          if (doc.exists) {
            final d = doc.data() as Map<String, dynamic>;
            driverName = d['full_name'] ?? d['first_name'] ?? '';
          }
        } catch (_) {}
      }

      // Find driver's current active trip
      String activeTripId = '';
      if (driverUid.isNotEmpty) {
        try {
          final tripSnap = await _fs.db.collection('trips')
              .where('driver_id', isEqualTo: driverUid)
              .where('status', isEqualTo: 'in_progress')
              .limit(1).get();
          if (tripSnap.docs.isNotEmpty) {
            activeTripId = tripSnap.docs.first.id;
          }
        } catch (_) {}
      }

      await _fs.db.collection('fuel_entries').add({
        'horse_id':             _selectedHorse,
        'vehicle_registration': _selectedHorseReg ?? '',
        'fuel_type':            _fuelType,
        'liters':               double.parse(_litersCtrl.text),
        'cost':                 double.parse(_costCtrl.text),
        'odometer':             int.parse(_odomCtrl.text),
        'fuel_station':         _stationCtrl.text.trim(),
        'location':             _locationCtrl.text.trim(),
        'driver_id':            driverUid,
        'driver_name':          driverName,
        'trip_id':              activeTripId,
        'created_at':           DateTime.now().toIso8601String(),
      });

      final reg     = _selectedHorseReg ?? '';
      final liters  = _litersCtrl.text;
      final station = _stationCtrl.text.trim();
      final actor   = driverName;
      unawaited(sl<NotificationService>().sendToManagers(
        'fuel', 'Fuel logged',
        '${reg.isNotEmpty ? reg : 'Vehicle'} — ${liters}L'
            '${station.isNotEmpty ? ' at $station' : ''}',
        actor: actor,
        data: {
          'vehicle_reg': reg,
          'liters':      double.tryParse(liters) ?? 0,
          'cost':        double.tryParse(_costCtrl.text) ?? 0,
          'fuel_type':   _fuelType,
          'station':     station,
          'odometer':    int.tryParse(_odomCtrl.text) ?? 0,
        },
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Fuel entry logged!',
            style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald, behavior: SnackBarBehavior.floating));
        context.go('/fuel');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
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
        title: const Text('Log Fuel Stop'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/fuel'),
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedHorse,
                        decoration: const InputDecoration(labelText: 'Horse (Truck)'),
                        hint: Text(
                          _horses.isEmpty ? 'No horses available' : 'Select horse',
                          style: const TextStyle(fontSize: 12)),
                        items: _horses.map((h) => DropdownMenuItem<String>(
                          value: h['id'] as String,
                          child: Text(h['label'] as String, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        isExpanded: true,
                        onChanged: _horses.isEmpty ? null : (v) {
                          final h = _horses.firstWhere((h) => h['id'] == v);
                          setState(() {
                            _selectedHorse    = v;
                            _selectedHorseReg = h['reg'] as String;
                          });
                        },
                        validator: (_) => _selectedHorse == null ? 'Select a vehicle' : null,
                      ),
                    ),
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
                    _field(_odomCtrl,     'Odometer (km)',     isNum: true),
                    _field(_stationCtrl,  'Fuel station name', required: false),
                    _field(_locationCtrl, 'Location',          required: false),
                    const SizedBox(height: 8),
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
