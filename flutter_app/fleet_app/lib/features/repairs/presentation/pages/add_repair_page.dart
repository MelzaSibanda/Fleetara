import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/notification_service.dart';

// ── Static taxonomy ────────────────────────────────────────────────────────────

const _kCategories = [
  ('engine',       'Engine',       Icons.settings_outlined),
  ('transmission', 'Transmission', Icons.sync_outlined),
  ('electrical',   'Electrical',   Icons.bolt_outlined),
  ('tyres',        'Tyres',        Icons.tire_repair_outlined),
  ('brakes',       'Brakes',       Icons.remove_circle_outline),
  ('suspension',   'Suspension',   Icons.directions_car_outlined),
  ('cooling',      'Cooling',      Icons.water_drop_outlined),
  ('body',         'Body / Other', Icons.car_repair_outlined),
];

const Map<String, List<String>> _kSymptomMap = {
  'engine':       ['Oil Leak', 'Smoke', 'Overheating', 'Knocking', 'Not Starting', 'Unknown'],
  'transmission': ['Slipping Gears', 'Hard Shifting', 'No Drive', 'Fluid Leak', 'Noise', 'Unknown'],
  'electrical':   ['No Power', 'Lights Out', 'Battery Issue', 'Alternator Fault', 'Wiring', 'Unknown'],
  'tyres':        ['Flat Tyre', 'Blowout', 'Worn Tread', 'Damage', 'Pressure Loss', 'Unknown'],
  'brakes':       ['No Braking', 'Brake Fade', 'Grinding Noise', 'Fluid Leak', 'Binding', 'Unknown'],
  'suspension':   ['Rough Ride', 'Pulling', 'Clunking Noise', 'Leaking', 'Broken Spring', 'Unknown'],
  'cooling':      ['Overheating', 'Coolant Leak', 'Radiator Issue', 'Thermostat', 'Fan Fault', 'Unknown'],
  'body':         ['Accident Damage', 'Door / Panel', 'Windscreen', 'Structural', 'Unknown'],
};

const Map<String, String> _kSpecialists = {
  'engine':       'Diesel Mechanic',
  'transmission': 'Diesel Mechanic',
  'electrical':   'Auto Electrician',
  'tyres':        'Tyre Specialist',
  'brakes':       'Diesel Mechanic',
  'suspension':   'Hydraulics Specialist',
  'cooling':      'Diesel Mechanic',
  'body':         'Panel Beater',
};

// ── Page ───────────────────────────────────────────────────────────────────────

class AddRepairPage extends StatefulWidget {
  const AddRepairPage({super.key});
  @override State<AddRepairPage> createState() => _AddRepairPageState();
}

class _AddRepairPageState extends State<AddRepairPage> {
  final _formKey = GlobalKey<FormState>();
  bool  _loading  = false;
  bool  _fetching = true;
  final _fs = sl<FirestoreService>();

  String       _vehicleType    = 'horse';
  String       _issueCategory  = '';
  final List<String> _pickedSymptoms = [];
  String       _priority       = 'medium';

  List<Map<String, dynamic>> _allVehicles = [];
  String? _selectedVehicleId;
  String  _selectedVehicleReg = '';

  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _costCtrl  = TextEditingController();

  List<Map<String, dynamic>> get _filteredVehicles =>
      _allVehicles.where((v) => v['type'] == _vehicleType).toList();

  @override
  void initState() { super.initState(); _fetchVehicles(); }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchVehicles() async {
    try {
      final snap = await _fs.db.collection('vehicles').get();
      setState(() {
        _allVehicles = _fs.docsToList(snap).map<Map<String, dynamic>>((v) => {
          'id':    v['id'],
          'label': '${v['registration_number']} — ${v['make'] ?? ''} ${v['model'] ?? ''}'.trim(),
          'reg':   v['registration_number'] ?? '',
          'type':  v['type'] ?? 'horse',
        }).toList();
        _fetching = false;
      });
    } catch (_) { setState(() => _fetching = false); }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_issueCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select an issue category',
          style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _loading = true);
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      final uid    = fbUser?.uid ?? '';
      String reporterName = fbUser?.displayName ?? '';
      if (reporterName.isEmpty && uid.isNotEmpty) {
        try {
          final doc = await _fs.db.collection('users').doc(uid).get();
          if (doc.exists) {
            final d = doc.data() as Map<String, dynamic>;
            reporterName = d['full_name'] ?? d['first_name'] ?? '';
          }
        } catch (_) {}
      }

      final specialist = _kSpecialists[_issueCategory] ?? '';
      final catLabel   = _kCategories
          .firstWhere((c) => c.$1 == _issueCategory,
              orElse: () => (_issueCategory, _issueCategory, Icons.build_outlined)).$2;
      final autoTitle  = _titleCtrl.text.trim().isNotEmpty
          ? _titleCtrl.text.trim()
          : '$catLabel issue'
              '${_pickedSymptoms.isNotEmpty ? ': ${_pickedSymptoms.join(', ')}' : ''}';

      await _fs.db.collection('repairs').add({
        'title':            autoTitle,
        'description':      _descCtrl.text.trim(),
        'priority':         _priority,
        'status':           'reported',
        'vehicle_id':       _selectedVehicleId,
        'vehicle_type':     _vehicleType,
        'vehicle_reg':      _selectedVehicleReg,
        'issue_category':   _issueCategory,
        'symptoms':         _pickedSymptoms,
        'specialist_type':  specialist,
        'repair_cost':      _costCtrl.text.isEmpty
            ? null : double.tryParse(_costCtrl.text),
        'reported_by':      uid,
        'reported_by_name': reporterName,
        'reported_at':      DateTime.now().toIso8601String(),
      });

      final priorityLabel =
          '${_priority[0].toUpperCase()}${_priority.substring(1)}';
      unawaited(sl<NotificationService>().sendToManagers(
        'repair', 'Repair reported', '$priorityLabel: $autoTitle',
        actor: reporterName,
        data: {
          'priority':        _priority,
          'title':           autoTitle,
          'description':     _descCtrl.text.trim(),
          'vehicle_reg':     _selectedVehicleReg,
          'vehicle_type':    _vehicleType,
          'issue_category':  _issueCategory,
          'specialist_type': specialist,
        },
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Issue reported!',
            style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating));
        context.go('/repairs');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e',
            style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose,
          behavior: SnackBarBehavior.floating));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final specialist =
        _issueCategory.isNotEmpty ? _kSpecialists[_issueCategory] : null;
    final categorySymptoms = _kSymptomMap[_issueCategory] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Report an Issue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/repairs'),
        ),
      ),
      body: _fetching
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                      // ── 1. Vehicle type ─────────────────────────────────
                      _sectionLabel('Vehicle type'),
                      Row(children: [
                        Expanded(child: _TypeBtn(
                          label: 'Truck / Horse',
                          icon: Icons.local_shipping_outlined,
                          selected: _vehicleType == 'horse',
                          onTap: () => setState(() {
                            _vehicleType = 'horse';
                            _selectedVehicleId  = null;
                            _selectedVehicleReg = '';
                          }),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _TypeBtn(
                          label: 'Trailer',
                          icon: Icons.trolley,
                          selected: _vehicleType == 'trailer',
                          onTap: () => setState(() {
                            _vehicleType = 'trailer';
                            _selectedVehicleId  = null;
                            _selectedVehicleReg = '';
                          }),
                        )),
                      ]),
                      const SizedBox(height: 20),

                      // ── 2. Vehicle ──────────────────────────────────────
                      _sectionLabel('Vehicle'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select vehicle'),
                          hint: Text(
                            _filteredVehicles.isEmpty
                                ? 'No ${_vehicleType == 'horse' ? 'trucks' : 'trailers'} available'
                                : 'Select a vehicle',
                            style: const TextStyle(fontSize: 12)),
                          value: _selectedVehicleId,
                          isExpanded: true,
                          items: _filteredVehicles
                              .map((v) => DropdownMenuItem<String>(
                                    value: v['id'] as String,
                                    child: Text(v['label'] as String,
                                      overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: _filteredVehicles.isEmpty
                              ? null
                              : (v) {
                                  final vehicle = _filteredVehicles
                                      .firstWhere((x) => x['id'] == v);
                                  setState(() {
                                    _selectedVehicleId  = v;
                                    _selectedVehicleReg =
                                        vehicle['reg'] as String;
                                  });
                                },
                          validator: (_) => _selectedVehicleId == null
                              ? 'Select a vehicle' : null,
                        ),
                      ),

                      // ── 3. Issue category ───────────────────────────────
                      _sectionLabel('Issue category'),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _kCategories.map((cat) {
                          final sel = _issueCategory == cat.$1;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _issueCategory = cat.$1;
                              _pickedSymptoms.clear();
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppTheme.primary.withValues(alpha: 0.12)
                                    : AppTheme.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: sel
                                      ? AppTheme.primary : AppTheme.border,
                                  width: sel ? 1.2 : 0.6)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(cat.$3, size: 14,
                                    color: sel
                                        ? AppTheme.primary
                                        : AppTheme.textMuted),
                                  const SizedBox(width: 6),
                                  Text(cat.$2, style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: sel
                                        ? AppTheme.primary
                                        : AppTheme.textMuted)),
                                ]),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // ── 4. Symptoms ─────────────────────────────────────
                      if (_issueCategory.isNotEmpty) ...[
                        _sectionLabel('Symptoms (select all that apply)'),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: categorySymptoms.map((s) {
                            final sel = _pickedSymptoms.contains(s);
                            return FilterChip(
                              label: Text(s, style: TextStyle(
                                fontSize: 12,
                                color: sel
                                    ? AppTheme.primary
                                    : AppTheme.textMuted)),
                              selected: sel,
                              onSelected: (v) => setState(() =>
                                v ? _pickedSymptoms.add(s)
                                  : _pickedSymptoms.remove(s)),
                              selectedColor:
                                  AppTheme.primary.withValues(alpha: 0.12),
                              checkmarkColor: AppTheme.primary,
                              side: BorderSide(
                                color: sel
                                    ? AppTheme.primary.withValues(alpha: 0.5)
                                    : AppTheme.border,
                                width: 0.7),
                              backgroundColor: AppTheme.background,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        if (specialist != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.emerald.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.emerald
                                    .withValues(alpha: 0.25))),
                            child: Row(children: [
                              const Icon(Icons.engineering_outlined,
                                size: 16, color: AppTheme.emerald),
                              const SizedBox(width: 8),
                              const Text('Recommended specialist: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted)),
                              Text(specialist, style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.emerald)),
                            ]),
                          ),
                        const SizedBox(height: 20),
                      ],

                      // ── 5. Details ──────────────────────────────────────
                      _sectionLabel('Details'),
                      _field(_titleCtrl, 'Issue title (optional)',
                          hint: 'Leave blank to auto-generate',
                          required: false),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _descCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Describe the issue in detail',
                            alignLabelWithHint: true,
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Priority'),
                          initialValue: _priority,
                          items: const [
                            DropdownMenuItem(
                              value: 'low', child: Text('Low')),
                            DropdownMenuItem(
                              value: 'medium', child: Text('Medium')),
                            DropdownMenuItem(
                              value: 'high', child: Text('High')),
                            DropdownMenuItem(
                              value: 'critical',
                              child: Text('Critical — Off Road')),
                          ],
                          onChanged: (v) =>
                              setState(() => _priority = v!),
                        ),
                      ),
                      _field(_costCtrl, 'Estimated cost (R)',
                          isNum: true, required: false),

                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.rose),
                        child: _loading
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                            : const Text('Report Issue'),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600,
      color: AppTheme.textPrimary)),
  );

  Widget _field(TextEditingController ctrl, String label,
      {bool isNum = false, bool required = true, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: required
            ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      ),
    );
  }
}

// ── Vehicle type toggle button ─────────────────────────────────────────────────

class _TypeBtn extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     selected;
  final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.icon,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.10)
            : AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppTheme.primary : AppTheme.border,
          width: selected ? 1.5 : 0.8)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 22,
          color: selected ? AppTheme.primary : AppTheme.textMuted),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: selected ? AppTheme.primary : AppTheme.textMuted),
          textAlign: TextAlign.center),
      ]),
    ),
  );
}
