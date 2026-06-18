import 'dart:convert';
<<<<<<< Updated upstream
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
=======
import 'dart:math' as math;
>>>>>>> Stashed changes

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/utils/web_image_picker.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';
import '../widgets/tyre_position_diagram.dart';

// ── Page ───────────────────────────────────────────────────────────────────────
class TyreInspectionPage extends StatefulWidget {
  const TyreInspectionPage({super.key});
  @override
  State<TyreInspectionPage> createState() => _TyreInspectionPageState();
}

class _TyreInspectionPageState extends State<TyreInspectionPage> {
  final _fs = sl<FirestoreService>();
  List<Map<String, dynamic>> _vehicles = [];
  String? _vehicleId;
  String _vehicleType = 'horse';
  int _tyreCount = 6;
  Map<String, Map<String, dynamic>> _byPos = {};
  bool _loading = false;
  int? _selected;
  int? _rotateFrom;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final snap = await _fs.db.collection('vehicles').get();
      setState(() {
        _vehicles = _fs
            .docsToList(snap)
            .map<Map<String, dynamic>>((v) => {
                  'id': v['id'],
                  'label':
                      '${v['registration_number']} — ${v['make'] ?? ''} ${v['model'] ?? ''}'
                          .trim(),
                  'type': v['type'] ?? 'horse',
                  'tyre_count': resolveTyreCount(v),
                })
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _loadTyres() async {
    if (_vehicleId == null) return;
    setState(() => _loading = true);
    try {
      final snap = await _fs.db
          .collection('tyres')
          .where('vehicle_id', isEqualTo: _vehicleId)
          .get();
      final map = <String, Map<String, dynamic>>{};
      for (final t in _fs.docsToList(snap)) {
        final pos = t['position']?.toString() ?? '';
        if (pos.isNotEmpty) map[pos] = t;
      }
      setState(() {
        _byPos = map;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _onTapSlot(TyreSlotDef slot) {
    if (_rotateFrom != null && _rotateFrom != slot.position) {
      _doRotation(_rotateFrom!, slot.position);
      return;
    }
    setState(() {
      _selected = slot.position;
      _rotateFrom = null;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        slot: slot,
        data: _byPos[slot.position.toString()],
        vehicleId: _vehicleId ?? '',
        vehicleType: _vehicleType,
        fs: _fs,
        onRotate: () {
          Navigator.pop(context);
          setState(() => _rotateFrom = slot.position);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('${slot.label} selected — tap the tyre to swap with'),
              backgroundColor: AppTheme.primary,
              duration: const Duration(seconds: 5)));
        },
        onUpdated: _loadTyres,
      ),
    );
  }

  Future<void> _doRotation(int from, int to) async {
    final layout =
        buildTyreLayout(vehicleType: _vehicleType, tyreCount: _tyreCount);
    final fs = layout.slots.firstWhere((s) => s.position == from);
    final ts = layout.slots.firstWhere((s) => s.position == to);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Record Rotation', style: TextStyle(fontSize: 16)),
        content: Text(
            'Swap ${fs.label} (${tyreSlotDescription(fs)}) ↔ '
            '${ts.label} (${tyreSlotDescription(ts)})?',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    setState(() => _rotateFrom = null);
    if (ok != true) return;
    try {
<<<<<<< Updated upstream
      final fromCode = fs.position.toString();
      final toCode = ts.position.toString();
      final fT = _byPos[fromCode];
      final tT = _byPos[toCode];
      if (fT != null) {
        await _fs.db
            .collection('tyres')
            .doc(fT['id'] as String)
            .update({'position': toCode});
      }
      if (tT != null) {
        await _fs.db
            .collection('tyres')
            .doc(tT['id'] as String)
            .update({'position': fromCode});
=======
      final fT = _byPos[fs.code];
      final tT = _byPos[ts.code];
      if (fT != null) {
        await _fs.db.collection('tyres')
          .doc(fT['id'] as String).update({'position': ts.code});
      }
      if (tT != null) {
        await _fs.db.collection('tyres')
          .doc(tT['id'] as String).update({'position': fs.code});
>>>>>>> Stashed changes
      }
      await _fs.db.collection('tyre_rotations').add({
        'vehicle_id': _vehicleId,
        'from_slot': fs.label,
        'from_position': fromCode,
        'to_slot': ts.label,
        'to_position': toCode,
        'from_tyre_id': fT?['id'],
        'to_tyre_id': tT?['id'],
        'rotated_at': DateTime.now().toIso8601String(),
      });
      await _loadTyres();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
<<<<<<< Updated upstream
            content: Text('Rotation recorded',
                style: TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.emerald,
            behavior: SnackBarBehavior.floating));
=======
        content: Text('Rotation recorded', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.emerald, behavior: SnackBarBehavior.floating));
>>>>>>> Stashed changes
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
<<<<<<< Updated upstream
            content:
                Text('Error: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.rose,
            behavior: SnackBarBehavior.floating));
=======
        content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
>>>>>>> Stashed changes
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Tyre Inspection',
      child: Column(children: [
        // Vehicle selector
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: DropdownButtonFormField<String>(
<<<<<<< Updated upstream
            decoration: const InputDecoration(
                labelText: 'Vehicle',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            initialValue: _vehicleId,
            hint: const Text('Select vehicle to inspect',
                style: TextStyle(fontSize: 12)),
=======
            decoration: const InputDecoration(labelText: 'Vehicle', isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            initialValue: _vehicleId,
            hint: const Text('Select vehicle to inspect', style: TextStyle(fontSize: 12)),
>>>>>>> Stashed changes
            isExpanded: true,
            items: _vehicles
                .map((v) => DropdownMenuItem<String>(
                      value: v['id'] as String,
                      child: Text(v['label'] as String,
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) {
              final vehicle =
                  _vehicles.firstWhere((e) => e['id'] == v, orElse: () => {});
              setState(() {
                _vehicleId = v;
                _vehicleType = vehicle['type'] as String? ?? 'horse';
                _tyreCount = vehicle['tyre_count'] as int? ?? 6;
                _byPos = {};
                _selected = null;
              });
              _loadTyres();
            },
          ),
        ),

        // Legend
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppTheme.background,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _dot(AppTheme.emerald, 'Good'),
            const SizedBox(width: 14),
            _dot(AppTheme.amber, 'Worn'),
            const SizedBox(width: 14),
            _dot(AppTheme.rose, 'Critical'),
            const SizedBox(width: 14),
            _dot(Colors.grey, 'No data'),
          ]),
        ),

        // Rotation banner
        if (_rotateFrom != null)
          Container(
            color: AppTheme.primary.withValues(alpha: 0.10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              const Icon(Icons.swap_horiz, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                  '${_vehicleType == 'trailer' ? 'TT' : 'HT'}$_rotateFrom selected — tap target tyre',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              GestureDetector(
                  onTap: () => setState(() => _rotateFrom = null),
                  child: const Text('Cancel',
                      style: TextStyle(fontSize: 12, color: AppTheme.rose))),
            ]),
          ),

        // Diagram
        Expanded(
            child: _vehicleId == null
                ? const EmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'Select a vehicle',
                    subtitle: 'Choose a vehicle to begin the tyre inspection.')
                : _loading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppTheme.accent))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                            child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TyrePositionDiagram(
                            vehicleType: _vehicleType,
                            tyreCount: _tyreCount,
                            tyresByPosition: _byPos,
                            selectedPosition: _selected,
                            highlightPositions:
                                _rotateFrom == null ? null : {_rotateFrom!},
                            onTapSlot: _onTapSlot,
                          ),
                        )),
                      )),
      ]),
    );
  }

  Widget _dot(Color c, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ]);
}

// ── Detail bottom sheet ────────────────────────────────────────────────────────
class _DetailSheet extends StatefulWidget {
  final TyreSlotDef slot;
  final Map? data;
  final String vehicleId;
  final String vehicleType;
  final FirestoreService fs;
  final VoidCallback onRotate, onUpdated;
  const _DetailSheet(
      {required this.slot,
      required this.data,
      required this.vehicleId,
      required this.vehicleType,
      required this.fs,
      required this.onRotate,
      required this.onUpdated});
  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  bool _uploading = false;
  String? _condition;

  @override
  void initState() {
    super.initState();
    _condition = widget.data?['condition']?.toString();
  }

  Future<void> _uploadPhoto() async {
    setState(() => _uploading = true);
    try {
<<<<<<< Updated upstream
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      final file = await input.onChange.first.then((_) => input.files?.first);
      if (file == null) {
        setState(() => _uploading = false);
        return;
      }
      final reader = html.FileReader()..readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes = reader.result as Uint8List;
=======
      final bytes = await pickImageBytes();
      if (bytes == null) { setState(() => _uploading = false); return; }
>>>>>>> Stashed changes
      // Limit: 700KB in Firestore. Warn if larger.
      if (bytes.length > 700000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
<<<<<<< Updated upstream
              content: Text('Image too large — use a photo under 700 KB',
                  style: TextStyle(color: Colors.white)),
              backgroundColor: AppTheme.rose,
              behavior: SnackBarBehavior.floating));
=======
          content: Text('Image too large — use a photo under 700 KB',
            style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
>>>>>>> Stashed changes
        }
        setState(() => _uploading = false);
        return;
      }
      final b64 = base64Encode(bytes);
      final tyreId = widget.data?['id'] as String?;
      if (tyreId != null) {
        await widget.fs.db.collection('tyres').doc(tyreId).update({
          'inspection_photo': b64,
          'photo_updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Create a new tyre record with the photo
        await widget.fs.db.collection('tyres').add({
          'vehicle_id': widget.vehicleId,
          'vehicle_type': widget.vehicleType,
          'position': widget.slot.position.toString(),
          'condition': 'good',
          'inspection_photo': b64,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      widget.onUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Photo saved', style: TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.emerald,
            behavior: SnackBarBehavior.floating));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
<<<<<<< Updated upstream
            content:
                Text('Error: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.rose,
            behavior: SnackBarBehavior.floating));
      }
    } finally {
      setState(() => _uploading = false);
    }
=======
        content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
      }
    } finally { setState(() => _uploading = false); }
>>>>>>> Stashed changes
  }

  Future<void> _updateCondition(String newCond) async {
    final tyreId = widget.data?['id'] as String?;
    if (tyreId == null) return;
    await widget.fs.db
        .collection('tyres')
        .doc(tyreId)
        .update({'condition': newCond});
    setState(() => _condition = newCond);
    widget.onUpdated();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
<<<<<<< Updated upstream
          content: Text('Condition updated to $newCond',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating));
=======
      content: Text('Condition updated to $newCond',
        style: const TextStyle(color: Colors.white)),
      backgroundColor: AppTheme.emerald, behavior: SnackBarBehavior.floating));
>>>>>>> Stashed changes
    }
  }

  Color get _condColor {
    switch (_condition) {
      case 'good':
        return AppTheme.emerald;
      case 'worn':
        return AppTheme.amber;
      case 'critical':
        return AppTheme.rose;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final photo = data?['inspection_photo'] as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
          color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // Header
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: _condColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(
                  child: Text(widget.slot.label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _condColor))),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(widget.slot.label,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  Text(tyreSlotDescription(widget.slot).toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5)),
                ])),
            if (_condition != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _condColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                    '${_condition![0].toUpperCase()}${_condition!.substring(1)}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _condColor)),
              ),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 14),

          if (data == null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.tire_repair_outlined,
                    size: 18, color: AppTheme.textMuted),
                SizedBox(width: 10),
                Text('No tyre recorded at this position',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              ]),
            ),
          ] else ...[
            _info('Brand', data['brand']?.toString() ?? '—'),
            _info('Size', data['size']?.toString() ?? '—'),
            _info('Serial No.', data['serial_number']?.toString() ?? '—'),
            _info('Installed', '${data['installed_km'] ?? 0} km'),
            _info('Life used',
                '${data['km_used'] ?? 0} / ${data['km_lifespan'] ?? 0} km'),
            if ((data['notes'] ?? '').toString().isNotEmpty)
              _info('Notes', data['notes'].toString()),
          ],

          // Photo preview
          if (photo != null && photo.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(base64Decode(photo),
                    height: 160, width: double.infinity, fit: BoxFit.cover)),
          ],
          const SizedBox(height: 20),

          // Actions
          if (_condition != null) ...[
            const Text('Update condition',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Row(children: [
              _condBtn('good', 'Good', AppTheme.emerald),
              const SizedBox(width: 8),
              _condBtn('worn', 'Worn', AppTheme.amber),
              const SizedBox(width: 8),
              _condBtn('critical', 'Critical', AppTheme.rose),
            ]),
            const SizedBox(height: 14),
          ],

          Row(children: [
            Expanded(
                child: _actionBtn(
                    label: 'Record Rotation',
                    icon: Icons.swap_horiz,
                    color: AppTheme.primary,
                    onTap: widget.onRotate)),
            const SizedBox(width: 10),
            Expanded(
                child: _actionBtn(
                    label: _uploading ? 'Uploading…' : 'Upload Photo',
                    icon: Icons.camera_alt_outlined,
                    color: AppTheme.accent,
                    onTap: _uploading ? () {} : _uploadPhoto)),
          ]),
        ]),
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary))),
        ]),
      );

  Widget _condBtn(String val, String label, Color col) => Expanded(
        child: GestureDetector(
          onTap: () => _updateCondition(val),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 34,
            decoration: BoxDecoration(
                color: _condition == val ? col : col.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: col.withValues(alpha: 0.4))),
            child: Center(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _condition == val ? Colors.white : col))),
          ),
        ),
      );

  Widget _actionBtn(
          {required String label,
          required IconData icon,
          required Color color,
          required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.35))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      );
}
