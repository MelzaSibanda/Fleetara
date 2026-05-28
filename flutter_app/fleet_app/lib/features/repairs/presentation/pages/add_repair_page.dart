import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/responsive.dart';

class AddRepairPage extends StatefulWidget {
  const AddRepairPage({super.key});
  @override State<AddRepairPage> createState() => _AddRepairPageState();
}

class _AddRepairPageState extends State<AddRepairPage> {
  final _formKey   = GlobalKey<FormState>();
  bool  _loading   = false;
  bool  _fetching  = true;
  String _priority = 'medium';
  final _fs = sl<FirestoreService>();

  List<Map<String, dynamic>> _vehicles = [];
  String? _selectedVehicle;
  String  _selectedVehicleReg = '';

  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _workshopCtrl = TextEditingController();
  final _costCtrl     = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose();
    _workshopCtrl.dispose(); _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchVehicles() async {
    try {
      final snap = await _fs.db.collection('vehicles').get();
      setState(() {
        _vehicles = _fs.docsToList(snap).map<Map<String, dynamic>>((v) => {
          'id':    v['id'],
          'label': '${v['registration_number']} (${v['type'] ?? 'vehicle'})',
          'reg':   v['registration_number'] ?? '',
          'type':  v['type'] ?? 'horse',
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
      final fbUser = FirebaseAuth.instance.currentUser;
      final uid    = fbUser?.uid ?? '';

      // Resolve display name: Firebase Auth → Firestore users doc → fallback
      String reporterName = fbUser?.displayName ?? '';
      if (reporterName.isEmpty && uid.isNotEmpty) {
        try {
          final doc = await _fs.db.collection('users').doc(uid).get();
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            reporterName = data['full_name'] ?? data['first_name'] ?? '';
          }
        } catch (_) {}
      }

      await _fs.db.collection('repairs').add({
        'title':              _titleCtrl.text.trim(),
        'description':        _descCtrl.text.trim(),
        'priority':           _priority,
        'status':             'reported',
        'vehicle_id':         _selectedVehicle,
        'vehicle_reg':        _selectedVehicleReg,
        'workshop_name':      _workshopCtrl.text.trim(),
        'repair_cost':        _costCtrl.text.isEmpty ? null : double.parse(_costCtrl.text),
        'reported_by':        uid,
        'reported_by_name':   reporterName,
        'reported_at':        DateTime.now().toIso8601String(),
      });

      final priorityLabel = '${_priority[0].toUpperCase()}${_priority.substring(1)}';
      unawaited(sl<NotificationService>().sendToManagers(
        'repair', 'Repair reported',
        '$priorityLabel: ${_titleCtrl.text.trim()}',
        actor: reporterName,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Repair reported!', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald, behavior: SnackBarBehavior.floating));
        context.go('/repairs');
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
        title: const Text('Report Repair / Breakdown'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/repairs'),
        ),
      ),
      body: _fetching
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
        : SingleChildScrollView(
            padding: Responsive.pagePadding(context),
            child: Center(
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
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
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedVehicle,
                        decoration: const InputDecoration(labelText: 'Vehicle'),
                        hint: Text(
                          _vehicles.isEmpty ? 'No vehicles available' : 'Select vehicle',
                          style: const TextStyle(fontSize: 12)),
                        items: _vehicles.map((v) => DropdownMenuItem<String>(
                          value: v['id'] as String,
                          child: Text(v['label'] as String, overflow: TextOverflow.ellipsis),
                        )).toList(),
                        isExpanded: true,
                        onChanged: _vehicles.isEmpty ? null : (v) {
                          final vehicle = _vehicles.firstWhere((x) => x['id'] == v);
                          setState(() {
                            _selectedVehicle    = v;
                            _selectedVehicleReg = vehicle['reg'] as String;
                          });
                        },
                        validator: (_) => _selectedVehicle == null ? 'Select a vehicle' : null,
                      ),
                    ),
                    _field(_workshopCtrl, 'Workshop name',       required: false),
                    _field(_costCtrl,     'Estimated cost (R)',  isNum: true, required: false),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
                      child: _loading
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Report Issue'),
                    ),
                  ]),
                ),
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
