import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../widgets/tyre_position_diagram.dart';

class TyreFormPage extends StatefulWidget {
  final Map? tyre; // null = create, non-null = edit
  const TyreFormPage({super.key, this.tyre});

  @override
  State<TyreFormPage> createState() => _TyreFormPageState();
}

class _TyreFormPageState extends State<TyreFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _fetching = true;
  final _fs = sl<FirestoreService>();

  List<Map<String, dynamic>> _horses = [];
  List<Map<String, dynamic>> _trailers = [];

  String _vehicleType = 'horse';
  String? _selectedHorse;
  String? _selectedTrailer;
  String _position = '1';
  String _condition = 'good';

  late TextEditingController _brandCtrl;
  late TextEditingController _sizeCtrl;
  late TextEditingController _serialCtrl;
  late TextEditingController _installedCtrl;
  late TextEditingController _lifespanCtrl;
  late TextEditingController _notesCtrl;

  bool get _isEdit => widget.tyre != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tyre;
    _vehicleType = t?['vehicle_type'] ?? 'horse';
    _position = t?['position']?.toString() ?? '1';
    _condition = t?['condition'] ?? 'good';
    _selectedHorse =
        (t?['vehicle_type'] == 'horse') ? (t!['vehicle_id'] as String?) : null;
    _selectedTrailer = (t?['vehicle_type'] == 'trailer')
        ? (t!['vehicle_id'] as String?)
        : null;

    _brandCtrl = TextEditingController(text: t?['brand'] ?? '');
    _sizeCtrl = TextEditingController(text: t?['size'] ?? '');
    _serialCtrl = TextEditingController(text: t?['serial_number'] ?? '');
    _installedCtrl = TextEditingController(text: '${t?['installed_km'] ?? ''}');
    _lifespanCtrl =
        TextEditingController(text: '${t?['km_lifespan'] ?? 120000}');
    _notesCtrl = TextEditingController(text: t?['notes'] ?? '');

    _fetchVehicles();
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _sizeCtrl.dispose();
    _serialCtrl.dispose();
    _installedCtrl.dispose();
    _lifespanCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _fetching = true);
    try {
      final results = await Future.wait([
        _fs.db.collection('vehicles').where('type', isEqualTo: 'horse').get(),
        _fs.db.collection('vehicles').where('type', isEqualTo: 'trailer').get(),
      ]);
      setState(() {
        _horses = _fs
            .docsToList(results[0])
            .map<Map<String, dynamic>>((h) => {
                  'id': h['id'],
                  'label':
                      '${h['registration_number']} — ${h['make']} ${h['model']}',
                  'reg': h['registration_number'] ?? '',
                  'tyre_count': resolveTyreCount(h),
                })
            .toList();
        _trailers = _fs
            .docsToList(results[1])
            .map<Map<String, dynamic>>((t) => {
                  'id': t['id'],
                  'label': '${t['registration_number']} (trailer)',
                  'reg': t['registration_number'] ?? '',
                  'tyre_count': resolveTyreCount(t),
                })
            .toList();
        _fetching = false;
      });
    } catch (e) {
      setState(() => _fetching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not load vehicles: $e',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.rose,
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final vehicleId =
          _vehicleType == 'horse' ? _selectedHorse : _selectedTrailer;
      final vehicles = _vehicleType == 'horse' ? _horses : _trailers;
      final vehicle =
          vehicles.firstWhere((v) => v['id'] == vehicleId, orElse: () => {});
      final vehicleReg = vehicle['reg'] ?? '';

      final data = <String, dynamic>{
        'vehicle_type': _vehicleType,
        'vehicle_id': vehicleId,
        'vehicle_reg': vehicleReg,
        'position': _position,
        'condition': _condition,
        'brand': _brandCtrl.text.trim(),
        'size': _sizeCtrl.text.trim(),
        'serial_number': _serialCtrl.text.trim(),
        'installed_km': int.parse(_installedCtrl.text),
        'km_lifespan': int.parse(_lifespanCtrl.text),
        'km_used': 0,
        'notes': _notesCtrl.text.trim(),
      };

      if (_isEdit) {
        await _fs.db
            .collection('tyres')
            .doc(widget.tyre!['id'] as String)
            .update(data);
      } else {
        data['created_at'] = DateTime.now().toIso8601String();
        await _fs.db.collection('tyres').add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isEdit ? 'Tyre updated' : 'Tyre added',
                style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.emerald,
            behavior: SnackBarBehavior.floating));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Error: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.rose,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5)));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Tyre count for the currently selected horse/trailer, falling back to a
  /// sensible default for the chosen vehicle type if nothing is selected yet.
  int _currentTyreCount() {
    final vehicleId =
        _vehicleType == 'horse' ? _selectedHorse : _selectedTrailer;
    final vehicles = _vehicleType == 'horse' ? _horses : _trailers;
    final vehicle =
        vehicles.firstWhere((v) => v['id'] == vehicleId, orElse: () => {});
    final tc = vehicle['tyre_count'] as int?;
    return tc ?? (_vehicleType == 'trailer' ? 12 : 6);
  }

  /// Resets `_position` to the first slot of the current vehicle's layout if
  /// the current value no longer matches one of its HT/TT positions.
  void _resetPositionIfInvalid() {
    final layout = buildTyreLayout(
        vehicleType: _vehicleType, tyreCount: _currentTyreCount());
    if (!layout.slots.any((s) => s.position.toString() == _position)) {
      _position = layout.slots.isNotEmpty
          ? layout.slots.first.position.toString()
          : '1';
    }
  }

  /// Builds the position dropdown items from the HT/TT layout for the
  /// selected vehicle. Preserves a legacy/unrecognised `_position` value
  /// (e.g. an old semantic code from a record created before this scheme)
  /// as an extra item so editing doesn't silently change it.
  List<DropdownMenuItem<String>> _positionItems() {
    final layout = buildTyreLayout(
        vehicleType: _vehicleType, tyreCount: _currentTyreCount());
    final items = layout.slots
        .map((s) => DropdownMenuItem<String>(
              value: s.position.toString(),
              child: Text('${s.label} — ${tyreSlotDescription(s)}'),
            ))
        .toList();
    if (!items.any((i) => i.value == _position)) {
      items.insert(
          0,
          DropdownMenuItem<String>(
            value: _position,
            child: Text(tyrePositionLabel(
                {'position': _position, 'vehicle_type': _vehicleType})),
          ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Tyre' : 'Add Tyre'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
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
                        _sectionLabel('Vehicle type'),
                        Row(children: [
                          _typeBtn('horse', 'Horse', Icons.local_shipping),
                          const SizedBox(width: 12),
                          _typeBtn('trailer', 'Trailer', Icons.trolley),
                        ]),
                        const SizedBox(height: 20),
                        _sectionLabel(_vehicleType == 'horse'
                            ? 'Select horse'
                            : 'Select trailer'),
                        if (_vehicleType == 'horse') ...[
                          if (_horses.isEmpty)
                            _noVehiclesHint(
                                'No active horses found. Add a horse first.')
                          else
                            _dropdown<String>(
                              label: 'Horse',
                              value: _selectedHorse,
                              hint: 'Select horse',
                              items: _horses
                                  .map((h) => DropdownMenuItem<String>(
                                      value: h['id'] as String,
                                      child: Text(h['label'] as String,
                                          overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _selectedHorse = v;
                                _resetPositionIfInvalid();
                              }),
                              validator: (_) => _selectedHorse == null
                                  ? 'Select a horse'
                                  : null,
                            ),
                        ] else ...[
                          if (_trailers.isEmpty)
                            _noVehiclesHint(
                                'No active trailers found. Add a trailer first.')
                          else
                            _dropdown<String>(
                              label: 'Trailer',
                              value: _selectedTrailer,
                              hint: 'Select trailer',
                              items: _trailers
                                  .map((t) => DropdownMenuItem<String>(
                                      value: t['id'] as String,
                                      child: Text(t['label'] as String,
                                          overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _selectedTrailer = v;
                                _resetPositionIfInvalid();
                              }),
                              validator: (_) => _selectedTrailer == null
                                  ? 'Select a trailer'
                                  : null,
                            ),
                        ],
                        const SizedBox(height: 4),
                        _sectionLabel('Position on vehicle'),
                        _dropdown<String>(
                          label: 'Position',
                          value: _position,
                          items: _positionItems(),
                          onChanged: (v) => setState(() => _position = v!),
                        ),
                        const SizedBox(height: 4),
                        _sectionLabel('Tyre details'),
                        Row(children: [
                          Expanded(
                              child: _field(_brandCtrl, 'Brand',
                                  hint: 'e.g. Michelin')),
                          const SizedBox(width: 14),
                          Expanded(
                              child: _field(_sizeCtrl, 'Size',
                                  hint: 'e.g. 295/80R22.5')),
                        ]),
                        _field(_serialCtrl, 'Serial number',
                            required: false, hint: 'Optional'),
                        Row(children: [
                          Expanded(
                              child: _field(_installedCtrl, 'Installed at (km)',
                                  isNum: true)),
                          const SizedBox(width: 14),
                          Expanded(
                              child: _field(_lifespanCtrl, 'Lifespan (km)',
                                  isNum: true)),
                        ]),
                        _dropdown<String>(
                          label: 'Condition',
                          value: _condition,
                          items: const [
                            DropdownMenuItem(
                                value: 'good', child: Text('Good')),
                            DropdownMenuItem(
                                value: 'worn', child: Text('Worn')),
                            DropdownMenuItem(
                                value: 'critical',
                                child: Text('Critical — Replace Soon')),
                            DropdownMenuItem(
                                value: 'replaced', child: Text('Replaced')),
                          ],
                          onChanged: (v) => setState(() => _condition = v!),
                        ),
                        const SizedBox(height: 4),
                        _field(_notesCtrl, 'Notes',
                            required: false, maxLines: 3),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loading ? null : _save,
                          child: _loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(_isEdit ? 'Save changes' : 'Add Tyre'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted)),
      );

  Widget _noVehiclesHint(String msg) => Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: AppTheme.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppTheme.amber.withValues(alpha: 0.3), width: 0.5)),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 16, color: AppTheme.amber),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: const TextStyle(fontSize: 12, color: AppTheme.amber))),
        ]),
      );

  Widget _typeBtn(String value, String label, IconData icon) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _vehicleType = value;
            _selectedHorse = null;
            _selectedTrailer = null;
            _position = '1';
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: _vehicleType == value
                    ? AppTheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _vehicleType == value
                        ? AppTheme.primary
                        : AppTheme.border)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon,
                  size: 16,
                  color: _vehicleType == value
                      ? Colors.white
                      : AppTheme.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _vehicleType == value
                          ? Colors.white
                          : AppTheme.textPrimary)),
            ]),
          ),
        ),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool isNum = false,
    bool required = true,
    String? hint,
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label, hintText: hint),
          validator: required
              ? (v) => v == null || v.isEmpty ? 'Required' : null
              : null,
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
          decoration: InputDecoration(labelText: label),
          hint: hint != null
              ? Text(hint, style: const TextStyle(fontSize: 12))
              : null,
          items: items,
          isExpanded: true,
          onChanged: onChanged,
          validator: validator,
        ),
      );
}
