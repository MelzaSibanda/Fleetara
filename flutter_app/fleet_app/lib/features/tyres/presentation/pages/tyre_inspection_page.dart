import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

// ── Slot definition ────────────────────────────────────────────────────────────
class _Slot {
  final int    num;
  final String code, label, axle;
  final double cx, cy, tw, th;
  const _Slot(this.num, this.code, this.label, this.axle,
      this.cx, this.cy, this.tw, this.th);
}

const double _kW = 320;
const double _kH = 960;

const List<_Slot> _kSlots = [
  // Steer axle (single)
  _Slot(1,  'steer_left',           'Front Left Steer',      'steer',    36, 190, 28, 44),
  _Slot(2,  'steer_right',          'Front Right Steer',     'steer',   284, 190, 28, 44),
  // Drive axle 1 (single)
  _Slot(3,  'drive1_left',          'Drive 1 Left',          'drive',    14, 305, 24, 38),
  _Slot(4,  'drive1_right',         'Drive 1 Right',         'drive',   306, 305, 24, 38),
  // Drive axle 2 (dual)
  _Slot(5,  'drive2_left_outer',    'Drive 2 Left Outer',    'drive',     4, 385, 20, 34),
  _Slot(6,  'drive2_left_inner',    'Drive 2 Left Inner',    'drive',    26, 385, 20, 34),
  _Slot(7,  'drive2_right_inner',   'Drive 2 Right Inner',   'drive',   294, 385, 20, 34),
  _Slot(8,  'drive2_right_outer',   'Drive 2 Right Outer',   'drive',   316, 385, 20, 34),
  // Trailer axle 1 (dual)
  _Slot(9,  'trailer1_left_outer',  'Trailer 1 Left Outer',  'trailer',   4, 575, 20, 34),
  _Slot(10, 'trailer1_left_inner',  'Trailer 1 Left Inner',  'trailer',  26, 575, 20, 34),
  _Slot(11, 'trailer1_right_inner', 'Trailer 1 Right Inner', 'trailer', 294, 575, 20, 34),
  _Slot(12, 'trailer1_right_outer', 'Trailer 1 Right Outer', 'trailer', 316, 575, 20, 34),
  // Trailer axle 2 (dual)
  _Slot(13, 'trailer2_left_outer',  'Trailer 2 Left Outer',  'trailer',   4, 675, 20, 34),
  _Slot(14, 'trailer2_left_inner',  'Trailer 2 Left Inner',  'trailer',  26, 675, 20, 34),
  _Slot(15, 'trailer2_right_inner', 'Trailer 2 Right Inner', 'trailer', 294, 675, 20, 34),
  _Slot(16, 'trailer2_right_outer', 'Trailer 2 Right Outer', 'trailer', 316, 675, 20, 34),
  // Trailer axle 3 (dual)
  _Slot(17, 'trailer3_left_outer',  'Trailer 3 Left Outer',  'trailer',   4, 775, 20, 34),
  _Slot(18, 'trailer3_left_inner',  'Trailer 3 Left Inner',  'trailer',  26, 775, 20, 34),
  _Slot(19, 'trailer3_right_inner', 'Trailer 3 Right Inner', 'trailer', 294, 775, 20, 34),
  _Slot(20, 'trailer3_right_outer', 'Trailer 3 Right Outer', 'trailer', 316, 775, 20, 34),
];

// ── Page ───────────────────────────────────────────────────────────────────────
class TyreInspectionPage extends StatefulWidget {
  const TyreInspectionPage({super.key});
  @override State<TyreInspectionPage> createState() => _TyreInspectionPageState();
}

class _TyreInspectionPageState extends State<TyreInspectionPage> {
  final _fs = sl<FirestoreService>();
  List<Map<String, dynamic>> _vehicles = [];
  String? _vehicleId;
  Map<String, Map<String, dynamic>> _byPos = {};
  bool _loading = false;
  int? _selected;
  int? _rotateFrom;

  @override void initState() { super.initState(); _loadVehicles(); }

  Future<void> _loadVehicles() async {
    try {
      final snap = await _fs.db.collection('vehicles').get();
      setState(() {
        _vehicles = _fs.docsToList(snap).map<Map<String, dynamic>>((v) => {
          'id':    v['id'],
          'label': '${v['registration_number']} — ${v['make'] ?? ''} ${v['model'] ?? ''}'.trim(),
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadTyres() async {
    if (_vehicleId == null) return;
    setState(() => _loading = true);
    try {
      final snap = await _fs.db.collection('tyres')
          .where('vehicle_id', isEqualTo: _vehicleId).get();
      final map = <String, Map<String, dynamic>>{};
      for (final t in _fs.docsToList(snap)) {
        final pos = t['position']?.toString() ?? '';
        if (pos.isNotEmpty) map[pos] = t;
      }
      setState(() { _byPos = map; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _onTap(int num) {
    if (_rotateFrom != null && _rotateFrom != num) {
      _doRotation(_rotateFrom!, num);
      return;
    }
    setState(() { _selected = num; _rotateFrom = null; });
    final slot = _kSlots.firstWhere((s) => s.num == num);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        slot:     slot,
        data:     _byPos[slot.code],
        vehicleId: _vehicleId ?? '',
        fs:       _fs,
        onRotate: () {
          Navigator.pop(context);
          setState(() => _rotateFrom = num);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('T$num selected — tap the tyre to swap with'),
            backgroundColor: AppTheme.primary,
            duration: const Duration(seconds: 5)));
        },
        onUpdated: _loadTyres,
      ),
    );
  }

  Future<void> _doRotation(int from, int to) async {
    final fs = _kSlots.firstWhere((s) => s.num == from);
    final ts = _kSlots.firstWhere((s) => s.num == to);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Record Rotation', style: TextStyle(fontSize: 16)),
        content: Text('Swap T$from (${fs.label}) ↔ T$to (${ts.label})?',
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm')),
        ],
      ),
    );
    setState(() => _rotateFrom = null);
    if (ok != true) return;
    try {
      final fT = _byPos[fs.code];
      final tT = _byPos[ts.code];
      if (fT != null) await _fs.db.collection('tyres')
          .doc(fT['id'] as String).update({'position': ts.code});
      if (tT != null) await _fs.db.collection('tyres')
          .doc(tT['id'] as String).update({'position': fs.code});
      await _fs.db.collection('tyre_rotations').add({
        'vehicle_id':   _vehicleId,
        'from_slot':    from, 'from_position': fs.code,
        'to_slot':      to,   'to_position':   ts.code,
        'from_tyre_id': fT?['id'], 'to_tyre_id': tT?['id'],
        'rotated_at':   DateTime.now().toIso8601String(),
      });
      await _loadTyres();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Rotation recorded', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.emerald, behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
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
            decoration: const InputDecoration(labelText: 'Vehicle', isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            value: _vehicleId,
            hint: const Text('Select vehicle to inspect', style: TextStyle(fontSize: 12)),
            isExpanded: true,
            items: _vehicles.map((v) => DropdownMenuItem<String>(
              value: v['id'] as String,
              child: Text(v['label'] as String, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (v) {
              setState(() { _vehicleId = v; _byPos = {}; _selected = null; });
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
            _dot(AppTheme.amber,   'Worn'),
            const SizedBox(width: 14),
            _dot(AppTheme.rose,    'Critical'),
            const SizedBox(width: 14),
            _dot(Colors.grey,      'No data'),
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
              Text('T$_rotateFrom selected — tap target tyre',
                style: const TextStyle(fontSize: 12, color: AppTheme.primary,
                  fontWeight: FontWeight.w500)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _rotateFrom = null),
                child: const Text('Cancel',
                  style: TextStyle(fontSize: 12, color: AppTheme.rose))),
            ]),
          ),

        // Diagram
        Expanded(child: _vehicleId == null
          ? const EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'Select a vehicle',
              subtitle: 'Choose a vehicle to begin the tyre inspection.')
          : _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: LayoutBuilder(builder: (_, con) {
                  final w     = math.min(con.maxWidth - 32, 360.0);
                  final h     = w * (_kH / _kW);
                  final scale = w / _kW;
                  return SizedBox(width: w, height: h, child: Stack(children: [
                    Positioned.fill(child: CustomPaint(
                      painter: _BodyPainter(scale: scale))),
                    ..._kSlots.map((s) {
                      final data = _byPos[s.code];
                      final cond = data?['condition']?.toString() ?? '';
                      final col  = cond == 'good'     ? AppTheme.emerald
                                 : cond == 'worn'     ? AppTheme.amber
                                 : cond == 'critical' ? AppTheme.rose
                                 : Colors.grey[500]!;
                      return Positioned(
                        left:   (s.cx - s.tw / 2) * scale,
                        top:    (s.cy - s.th / 2) * scale,
                        width:  s.tw * scale,
                        height: s.th * scale,
                        child: GestureDetector(
                          onTap: () => _onTap(s.num),
                          child: _TyreWidget(
                            num:      s.num,
                            color:    data != null ? col : Colors.grey[600]!,
                            selected: _selected == s.num || _rotateFrom == s.num,
                            hasData:  data != null,
                          ),
                        ),
                      );
                    }),
                  ]));
                })),
              )),
      ]),
    );
  }

  Widget _dot(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
  ]);
}

// ── Truck body painter ─────────────────────────────────────────────────────────
class _BodyPainter extends CustomPainter {
  final double scale;
  const _BodyPainter({required this.scale});

  Rect _r(double x, double y, double w, double h) =>
      Rect.fromLTWH(x * scale, y * scale, w * scale, h * scale);

  @override
  void paint(Canvas canvas, Size size) {
    final body  = Paint()..color = const Color(0xFFD8D8D8);
    final cab   = Paint()..color = const Color(0xFFC0C0C0);
    final glass = Paint()..color = const Color(0xFFB3D9F0).withValues(alpha: 0.6);
    final axle  = Paint()..color = const Color(0xFF888888)..strokeWidth = 2 * scale..strokeCap = StrokeCap.round;
    final rrb   = RRect.fromRectAndRadius(_r(110, 8, 100, 76), Radius.circular(14 * scale));

    // Cab
    canvas.drawRRect(rrb, cab);
    // Windshield
    canvas.drawRRect(
      RRect.fromRectAndRadius(_r(122, 38, 76, 38), Radius.circular(6 * scale)), glass);
    // Horse body
    canvas.drawRect(_r(60, 80, 200, 352), body);
    // Coupling
    canvas.drawRect(_r(138, 430, 44, 44), cab);
    // Trailer
    canvas.drawRect(_r(60, 472, 200, 450), body);

    // Axle lines
    void axleLine(double y, double x1, double x2) =>
        canvas.drawLine(Offset(x1 * scale, y * scale), Offset(x2 * scale, y * scale), axle);

    axleLine(190, 36,  284);   // steer
    axleLine(305, 14,  306);   // drive1
    axleLine(385,  4,  316);   // drive2
    axleLine(575,  4,  316);   // trailer1
    axleLine(675,  4,  316);   // trailer2
    axleLine(775,  4,  316);   // trailer3
  }

  @override bool shouldRepaint(_BodyPainter o) => o.scale != scale;
}

// ── 3-D tyre widget ────────────────────────────────────────────────────────────
class _TyreWidget extends StatelessWidget {
  final int    num;
  final Color  color;
  final bool   selected, hasData;
  const _TyreWidget({required this.num, required this.color,
      required this.selected, required this.hasData});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A4A4A), Color(0xFF111111)],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected ? AppTheme.primary : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4, offset: const Offset(2, 3)),
          if (selected) BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.6),
            blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: Stack(alignment: Alignment.center, children: [
        // Tread ring
        Positioned.fill(child: CustomPaint(painter: _TreadPainter(color: color))),
        // Number
        Text('$num', style: TextStyle(
          color: Colors.white, fontSize: math.max(7, 10.0),
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        )),
        // Shine
        Positioned(
          left: 1, top: 1,
          child: Container(
            width: 8, height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withValues(alpha: 0.35), Colors.transparent],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(3)),
          ),
        ),
        // No-data indicator
        if (!hasData)
          Positioned(
            right: 1, top: 1,
            child: Container(
              width: 5, height: 5,
              decoration: const BoxDecoration(
                color: Colors.white54, shape: BoxShape.circle)),
          ),
      ]),
    );
  }
}

class _TreadPainter extends CustomPainter {
  final Color color;
  const _TreadPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    // Rim circle
    final rimR  = math.min(w, h) * 0.30;
    final rimC  = Offset(w / 2, h / 2);
    final rim   = Paint()
      ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.4)])
          .createShader(Rect.fromCircle(center: rimC, radius: rimR));
    canvas.drawCircle(rimC, rimR, rim);
    // Tread grooves
    final groove = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawOval(Rect.fromLTWH(1, 1, w - 2, h - 2), groove);
  }

  @override bool shouldRepaint(_TreadPainter o) => o.color != color;
}

// ── Detail bottom sheet ────────────────────────────────────────────────────────
class _DetailSheet extends StatefulWidget {
  final _Slot    slot;
  final Map?     data;
  final String   vehicleId;
  final FirestoreService fs;
  final VoidCallback onRotate, onUpdated;
  const _DetailSheet({required this.slot, required this.data,
      required this.vehicleId, required this.fs,
      required this.onRotate, required this.onUpdated});
  @override State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  bool _uploading = false;
  String? _condition;

  @override void initState() {
    super.initState();
    _condition = widget.data?['condition']?.toString();
  }

  Future<void> _uploadPhoto() async {
    setState(() => _uploading = true);
    try {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      final file = await input.onChange.first.then((_) => input.files?.first);
      if (file == null) { setState(() => _uploading = false); return; }
      final reader = html.FileReader()..readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes  = reader.result as Uint8List;
      // Limit: 700KB in Firestore. Warn if larger.
      if (bytes.length > 700000) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Image too large — use a photo under 700 KB',
            style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
        setState(() => _uploading = false);
        return;
      }
      final b64 = base64Encode(bytes);
      final tyreId = widget.data?['id'] as String?;
      if (tyreId != null) {
        await widget.fs.db.collection('tyres').doc(tyreId).update({
          'inspection_photo':    b64,
          'photo_updated_at':    DateTime.now().toIso8601String(),
        });
      } else {
        // Create a new tyre record with the photo
        await widget.fs.db.collection('tyres').add({
          'vehicle_id':       widget.vehicleId,
          'position':         widget.slot.code,
          'condition':        'good',
          'inspection_photo': b64,
          'created_at':       DateTime.now().toIso8601String(),
        });
      }
      widget.onUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Photo saved', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald, behavior: SnackBarBehavior.floating));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
    } finally { setState(() => _uploading = false); }
  }

  Future<void> _updateCondition(String newCond) async {
    final tyreId = widget.data?['id'] as String?;
    if (tyreId == null) return;
    await widget.fs.db.collection('tyres').doc(tyreId).update({'condition': newCond});
    setState(() => _condition = newCond);
    widget.onUpdated();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Condition updated to $newCond',
        style: const TextStyle(color: Colors.white)),
      backgroundColor: AppTheme.emerald, behavior: SnackBarBehavior.floating));
  }

  Color get _condColor {
    switch (_condition) {
      case 'good':     return AppTheme.emerald;
      case 'worn':     return AppTheme.amber;
      case 'critical': return AppTheme.rose;
      default:         return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data   = widget.data;
    final photo  = data?['inspection_photo'] as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // Header
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _condColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text('${widget.slot.num}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  color: _condColor))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.slot.label, style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              Text(widget.slot.axle.toUpperCase(), style: const TextStyle(
                fontSize: 11, color: AppTheme.textMuted, letterSpacing: 0.5)),
            ])),
            if (_condition != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _condColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${_condition![0].toUpperCase()}${_condition!.substring(1)}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
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
                color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.tire_repair_outlined, size: 18, color: AppTheme.textMuted),
                SizedBox(width: 10),
                Text('No tyre recorded at this position',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              ]),
            ),
          ] else ...[
            _info('Brand',       data['brand']?.toString()         ?? '—'),
            _info('Size',        data['size']?.toString()          ?? '—'),
            _info('Serial No.',  data['serial_number']?.toString() ?? '—'),
            _info('Installed',   '${data['installed_km'] ?? 0} km'),
            _info('Life used',   '${data['km_used'] ?? 0} / ${data['km_lifespan'] ?? 0} km'),
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
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            Row(children: [
              _condBtn('good',     'Good',     AppTheme.emerald),
              const SizedBox(width: 8),
              _condBtn('worn',     'Worn',     AppTheme.amber),
              const SizedBox(width: 8),
              _condBtn('critical', 'Critical', AppTheme.rose),
            ]),
            const SizedBox(height: 14),
          ],

          Row(children: [
            Expanded(child: _actionBtn(
              label: 'Record Rotation',
              icon: Icons.swap_horiz,
              color: AppTheme.primary,
              onTap: widget.onRotate)),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn(
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
      SizedBox(width: 90,
        child: Text(label, style: const TextStyle(
          fontSize: 11, color: AppTheme.textMuted))),
      Expanded(child: Text(value, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
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
        child: Center(child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: _condition == val ? Colors.white : col))),
      ),
    ),
  );

  Widget _actionBtn({required String label, required IconData icon,
      required Color color, required VoidCallback onTap}) =>
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
          Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
}
