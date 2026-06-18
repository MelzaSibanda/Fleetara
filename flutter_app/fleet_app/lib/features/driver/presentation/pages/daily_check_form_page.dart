import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/web_image_picker.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/widgets/tyre_truck_diagram.dart';
import '../bloc/inspection_bloc.dart';
import '../bloc/inspection_event.dart';
import '../bloc/inspection_state.dart';

const _kTyreConditions = [
  ('good',         'Good',         '🟢', AppTheme.emerald),
  ('worn',         'Worn',         '🟡', AppTheme.amber),
  ('low_pressure', 'Low Pressure', '🟠', Colors.orange),
  ('damaged',      'Damaged',      '🔴', AppTheme.rose),
  ('burst_risk',   'Burst Risk',   '🚨', Color(0xFF7F1D1D)),
];

Color _tyreConditionColor(String? cond) {
  for (final c in _kTyreConditions) {
    if (c.$1 == cond) return c.$4;
  }
  return Colors.grey;
}

class DailyCheckFormPage extends StatefulWidget {
  const DailyCheckFormPage({super.key});
  @override State<DailyCheckFormPage> createState() => _DailyCheckFormPageState();
}

class _DailyCheckFormPageState extends State<DailyCheckFormPage> {
  final _fs       = sl<FirestoreService>();
  final _pageCtrl = PageController();
  final _odomCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  int  _step            = 0;
  bool _loadingVehicles = true;

  // Vehicles
  List<Map<String, dynamic>> _horses   = [];
  List<Map<String, dynamic>> _trailers = [];
  String? _horseId,  _horseReg;
  String? _trailerId, _trailerReg;

  // Fluids & Engine
  String _oilLevel     = 'good';
  String _coolantLevel = 'good';
  String _brakeFluid   = 'good';
  bool   _noLeaks      = true;

  // Tyres — null = pending / not yet inspected
  final Map<String, String?> _tyreCondition = {for (final p in kTyreSlots) p.code: null};
  final Map<String, String?> _tyrePhoto     = {for (final p in kTyreSlots) p.code: null};
  final Set<String> _tyreIncidentLogged     = {};
  bool   _wheelNuts = true;

  // Trailer tyres only apply when a trailer is actually coupled — a horse
  // running solo only has its own steer + drive axles to inspect.
  List<TyreSlot> get _activeTyreSlots =>
      _hasTrailer ? kTyreSlots : kTyreSlots.where((s) => s.axle != 'trailer').toList(growable: false);

  bool get _tyresComplete =>
      _activeTyreSlots.every((p) => _tyreCondition[p.code] != null && _tyrePhoto[p.code] != null);
  int get _tyresInspectedCount =>
      _activeTyreSlots.where((p) => _tyreCondition[p.code] != null && _tyrePhoto[p.code] != null).length;

  // Brakes & Lights
  bool _brakeResponse = true;
  bool _airPressure   = true;
  bool _headlights    = true;
  bool _brakeLights   = true;
  bool _indicators    = true;

  // Safety Equipment
  bool _fireExt    = true;
  bool _triangles  = true;
  bool _seatbelt   = true;

  // Trailer
  bool _couplingLock      = true;
  bool _trailerTyresOk    = true;
  bool _cargoStraps       = true;
  bool _trailerLightsOk   = true;
  bool _trailerSuspension = true;

  bool get _hasTrailer  => _trailerId != null;
  // Steps: 0 Vehicle, 1 Fluids, 2 Tyres, 3 Brakes&Lights, 4 Safety, 5 Odometer, [6 Trailer], 7 Submit
  int  get _totalSteps  => _hasTrailer ? 8 : 7;
  int  get _submitStep  => _hasTrailer ? 7 : 6;

  static const _stepTitles = [
    'Select Vehicle',
    'Fluids & Engine',
    'Tyre Inspection',
    'Brakes & Lights',
    'Safety Equipment',
    'Odometer',
    'Trailer',
    'Review & Submit',
  ];

  @override
  void initState() { super.initState(); _loadVehicles(); }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _odomCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    try {
      final snap = await _fs.db.collection('vehicles').get();
      final all  = _fs.docsToList(snap);
      setState(() {
        _horses   = all.where((v) => (v['type'] ?? v['vehicle_type']) == 'horse').toList();
        _trailers = all.where((v) => (v['type'] ?? v['vehicle_type']) == 'trailer').toList();
        _loadingVehicles = false;
      });
    } catch (_) {
      setState(() => _loadingVehicles = false);
    }
  }

  String _computeStatus() {
    final tyreList = _tyreCondition.values;
    if (tyreList.any((t) => t == 'damaged' || t == 'burst_risk') ||
        _oilLevel == 'critical' || _coolantLevel == 'critical' || _brakeFluid == 'critical' ||
        !_brakeResponse || !_airPressure) {
      return 'critical';
    }
    if (tyreList.any((t) => t == 'worn' || t == 'low_pressure') ||
        _oilLevel == 'low' || _coolantLevel == 'low' || _brakeFluid == 'low' ||
        !_noLeaks || !_wheelNuts || !_headlights || !_brakeLights || !_indicators ||
        !_fireExt || !_triangles || !_seatbelt ||
        (_hasTrailer && (!_couplingLock || !_trailerTyresOk || !_cargoStraps ||
                         !_trailerLightsOk || !_trailerSuspension))) {
      return 'minor_issue';
    }
    return 'pass';
  }

  bool _validateStep() {
    if (_step == 0 && _horseId == null) {
      _showSnack('Please select a horse vehicle to continue', AppTheme.rose);
      return false;
    }
    if (_step == 2 && !_tyresComplete) {
      _showSnack('Tap each tyre, choose its condition and capture a photo to continue',
        AppTheme.rose);
      return false;
    }
    if (_step == 5 && _odomCtrl.text.trim().isEmpty) {
      _showSnack('Please enter the current odometer reading', AppTheme.rose);
      return false;
    }
    return true;
  }

  void _showSnack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color, behavior: SnackBarBehavior.floating));

  void _goTo(int target) {
    setState(() => _step = target);
    _pageCtrl.animateToPage(target,
      duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
  }

  void _next() {
    if (!_validateStep()) return;
    // Skip trailer step (index 6) if no trailer
    final next = (_step == 5 && !_hasTrailer) ? _submitStep : _step + 1;
    if (next < _totalSteps) _goTo(next);
  }

  void _back() {
    // Skip trailer step (index 6) when going back if no trailer
    final prev = (_step == _submitStep && !_hasTrailer) ? 5 : _step - 1;
    if (prev >= 0) _goTo(prev);
  }

  void _submit(InspectionBloc bloc) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final now = DateTime.now();
    bloc.add(InspectionSubmitRequested({
      'driver_id':   uid,
      'horse_id':    _horseId,
      'horse_reg':   _horseReg   ?? '',
      if (_trailerId != null) 'trailer_id':  _trailerId,
      if (_trailerReg != null) 'trailer_reg': _trailerReg,
      'check_date': '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}',
      'odometer':    int.tryParse(_odomCtrl.text.trim()) ?? 0,
      'overall_status': _computeStatus(),
      'oil_level':      _oilLevel,
      'coolant_level':  _coolantLevel,
      'brake_fluid':    _brakeFluid,
      'no_engine_leaks': _noLeaks,
      // Photos are mandatory proof-of-inspection captured per tyre but are not
      // persisted on the check document itself (20 photos would blow well past
      // Firestore's 1 MB document limit) — only the recorded conditions are.
      // Only the slots actually inspected are written (a solo horse has no
      // trailer tyres to report).
      'tyre_positions': {for (final s in _activeTyreSlots) s.code: _tyreCondition[s.code]},
      'wheel_nuts':     _wheelNuts,
      'brake_response': _brakeResponse,
      'air_pressure':   _airPressure,
      'headlights':     _headlights,
      'brake_lights':   _brakeLights,
      'indicators':     _indicators,
      'fire_extinguisher':    _fireExt,
      'reflective_triangles': _triangles,
      'seatbelt':             _seatbelt,
      if (_hasTrailer) ...{
        'coupling_lock':      _couplingLock,
        'trailer_tyres':      _trailerTyresOk,
        'cargo_straps':       _cargoStraps,
        'trailer_lights':     _trailerLightsOk,
        'trailer_suspension': _trailerSuspension,
      },
      'notes': _notesCtrl.text.trim(),
    }));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InspectionBloc>(),
      child: BlocConsumer<InspectionBloc, InspectionState>(
        listener: (context, state) {
          if (state is InspectionSubmitSuccess) {
            _showSnack('Inspection submitted successfully', AppTheme.emerald);
            context.go('/driver/checks');
          }
          if (state is InspectionError) {
            _showSnack(state.message, AppTheme.rose);
          }
        },
        builder: (context, state) {
          final bloc    = context.read<InspectionBloc>();
          final loading = state is InspectionLoading;

          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              title: Text(_stepTitles[_step],
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _step == 0 ? context.go('/driver/checks') : _back(),
              ),
            ),
            body: Column(children: [
              // Progress bar
              _ProgressHeader(step: _step, totalSteps: _totalSteps),
              // Pages
              Expanded(
                child: _loadingVehicles
                  ? const Center(child: CircularProgressIndicator(
                      color: AppTheme.primary, strokeWidth: 2))
                  : PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _stepVehicle(),
                        _stepFluids(),
                        _stepTyres(),
                        _stepBrakesLights(),
                        _stepSafety(),
                        _stepOdometer(),
                        _stepTrailer(),     // always in list; hidden if no trailer
                        _stepSubmit(bloc, loading),
                      ],
                    ),
              ),
              // Bottom navigation
              if (!_loadingVehicles) _BottomNav(
                step:        _step,
                totalSteps:  _totalSteps,
                submitStep:  _submitStep,
                loading:     loading,
                onBack:      _back,
                onNext:      _next,
                onSubmit:    () => _submit(bloc),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ── Step 0: Vehicle Selection ──────────────────────────────────────────────
  Widget _stepVehicle() => _StepScroll(children: [
    _StepHint('Select your assigned horse and, if applicable, your trailer for today\'s inspection.'),
    const SizedBox(height: 8),
    _SectionLabel('Horse (required)'),
    ..._horses.isEmpty
      ? [_EmptyVehicles('No horses found in fleet.')]
      : _horses.map((v) {
          final id  = v['id'] as String;
          final reg = (v['registration_number'] ?? v['reg'] ?? id).toString();
          final sel = _horseId == id;
          return _VehicleOption(
            reg: reg,
            make: '${v['make'] ?? ''} ${v['model'] ?? ''}'.trim(),
            type: 'Horse',
            icon: Icons.local_shipping,
            selected: sel,
            onTap: () => setState(() { _horseId = id; _horseReg = reg; }),
          );
        }),
    const SizedBox(height: 20),
    _SectionLabel('Trailer (optional)'),
    _VehicleOption(
      reg: 'No Trailer',
      make: 'Solo horse only',
      type: '',
      icon: Icons.not_interested,
      selected: _trailerId == null,
      onTap: () => setState(() { _trailerId = null; _trailerReg = null; }),
    ),
    ..._trailers.map((v) {
      final id  = v['id'] as String;
      final reg = (v['registration_number'] ?? v['reg'] ?? id).toString();
      final sel = _trailerId == id;
      return _VehicleOption(
        reg: reg,
        make: (v['trailer_type'] ?? v['type'] ?? '').toString(),
        type: 'Trailer',
        icon: Icons.rv_hookup,
        selected: sel,
        onTap: () => setState(() { _trailerId = id; _trailerReg = reg; }),
      );
    }),
  ]);

  // ── Step 1: Fluids & Engine ────────────────────────────────────────────────
  Widget _stepFluids() => _StepScroll(children: [
    _StepHint('Check all fluid levels and look for any signs of leaks under the vehicle.'),
    const SizedBox(height: 8),
    _SectionLabel('Engine Fluids'),
    _FluidRow(label: 'Engine oil', value: _oilLevel,
      onChanged: (v) => setState(() => _oilLevel = v)),
    _FluidRow(label: 'Coolant', value: _coolantLevel,
      onChanged: (v) => setState(() => _coolantLevel = v)),
    _FluidRow(label: 'Brake fluid', value: _brakeFluid,
      onChanged: (v) => setState(() => _brakeFluid = v)),
    const SizedBox(height: 20),
    _SectionLabel('Visual Engine Check'),
    _ToggleRow(label: 'No visible leaks or drips', value: _noLeaks,
      okLabel: 'Clear', nokLabel: 'Leaking',
      onChanged: (v) => setState(() => _noLeaks = v)),
  ]);

  // ── Step 2: Tyre Inspection ────────────────────────────────────────────────
  Widget _stepTyres() => _StepScroll(children: [
    _StepHint(_hasTrailer
        ? 'Tap each tyre on the diagram, choose the condition you observe, '
          'then capture a photo as proof of inspection.'
        : 'No trailer is coupled — only the horse\'s steer and drive tyres '
          'need inspecting. Tap each one, choose its condition and capture a photo.'),
    const SizedBox(height: 12),
    _TyreProgressTracker(done: _tyresInspectedCount, total: _activeTyreSlots.length),
    const SizedBox(height: 14),
    _TyreDiagram(condition: _tyreCondition, photo: _tyrePhoto,
      showTrailer: _hasTrailer, onTap: _openTyreSheet),
    const SizedBox(height: 12),
    const _TyreLegend(),
    const SizedBox(height: 20),
    _SectionLabel('Wheels'),
    _ToggleRow(label: 'Wheel nuts are tight', value: _wheelNuts,
      okLabel: 'Tight', nokLabel: 'Loose',
      onChanged: (v) => setState(() => _wheelNuts = v)),
  ]);

  void _openTyreSheet(String code) {
    final pos = kTyreSlots.firstWhere((p) => p.code == code);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TyreInspectSheet(
        pos:       pos,
        condition: _tyreCondition[code],
        photo:     _tyrePhoto[code],
        onConditionSet: (cond) => setState(() => _tyreCondition[code] = cond),
        onPhotoSet: (b64) {
          setState(() => _tyrePhoto[code] = b64);
          _maybeRaiseTyreIncident(code);
        },
      ),
    );
  }

  // Stakeholder requirement: Damaged / Burst Risk tyres auto-create an
  // incident and notify the fleet manager + workshop the moment they're
  // confirmed (condition selected + photo captured), not at submission time.
  Future<void> _maybeRaiseTyreIncident(String code) async {
    final cond = _tyreCondition[code];
    if (cond != 'damaged' && cond != 'burst_risk') return;
    if (!_tyreIncidentLogged.add(code)) return;

    final pos     = kTyreSlots.firstWhere((p) => p.code == code);
    final user    = FirebaseAuth.instance.currentUser;
    final isBurst = cond == 'burst_risk';
    final title   = '${isBurst ? "Burst risk" : "Tyre damage"} — ${pos.label}'
                    '${_horseReg != null ? " ($_horseReg)" : ""}';
    try {
      await _fs.db.collection('repairs').add({
        'title':            title,
        'description':      'Automatically reported during the daily inspection: '
                            '${pos.label} tyre flagged as '
                            '${isBurst ? "burst risk" : "damaged"}.',
        'priority':         isBurst ? 'critical' : 'high',
        'status':           'reported',
        'vehicle_id':       _horseId,
        'vehicle_type':     'horse',
        'vehicle_reg':      _horseReg,
        'issue_category':   'tyres',
        'symptoms':         [isBurst ? 'Blowout' : 'Damage'],
        'specialist_type':  'Tyre Specialist',
        'reported_by':      user?.uid,
        'reported_by_name': user?.displayName ?? 'Driver',
        'reported_at':      DateTime.now().toIso8601String(),
        'auto_generated':   true,
        'source':           'daily_check_tyre_inspection',
      });
      unawaited(sl<NotificationService>().sendToManagers(
        'repair',
        isBurst ? 'Burst risk reported' : 'Tyre damage reported',
        '${pos.label} on ${_horseReg ?? "vehicle"} — fleet manager and workshop notified',
        actor: user?.displayName ?? 'Driver',
        data: {
          'priority':       isBurst ? 'critical' : 'high',
          'title':          title,
          'vehicle_reg':    _horseReg,
          'issue_category': 'tyres',
        },
      ));
      if (mounted) {
        _showSnack(
          '${isBurst ? "Burst risk" : "Damage"} on ${pos.label} reported — '
          'fleet manager and workshop notified',
          AppTheme.rose);
      }
    } catch (_) {}
  }

  // ── Step 3: Brakes & Lights ────────────────────────────────────────────────
  Widget _stepBrakesLights() => _StepScroll(children: [
    _StepHint('Test brakes at low speed and visually confirm all lights are working before departure.'),
    const SizedBox(height: 8),
    _SectionLabel('Brakes'),
    _ToggleRow(label: 'Brake response', value: _brakeResponse,
      okLabel: 'OK', nokLabel: 'Issue',
      onChanged: (v) => setState(() => _brakeResponse = v), critical: true),
    _ToggleRow(label: 'Air pressure', value: _airPressure,
      okLabel: 'OK', nokLabel: 'Low',
      onChanged: (v) => setState(() => _airPressure = v), critical: true),
    const SizedBox(height: 20),
    _SectionLabel('Lights'),
    _ToggleRow(label: 'Headlights', value: _headlights,
      okLabel: 'Working', nokLabel: 'Faulty',
      onChanged: (v) => setState(() => _headlights = v)),
    _ToggleRow(label: 'Brake lights', value: _brakeLights,
      okLabel: 'Working', nokLabel: 'Faulty',
      onChanged: (v) => setState(() => _brakeLights = v)),
    _ToggleRow(label: 'Indicators', value: _indicators,
      okLabel: 'Working', nokLabel: 'Faulty',
      onChanged: (v) => setState(() => _indicators = v)),
  ]);

  // ── Step 4: Safety Equipment ───────────────────────────────────────────────
  Widget _stepSafety() => _StepScroll(children: [
    _StepHint('Confirm all mandatory safety equipment is present and in working condition.'),
    const SizedBox(height: 8),
    _SectionLabel('Safety Equipment'),
    _ToggleRow(label: 'Fire extinguisher', value: _fireExt,
      okLabel: 'Present', nokLabel: 'Missing',
      onChanged: (v) => setState(() => _fireExt = v), critical: true),
    _ToggleRow(label: 'Reflective triangles (×2)', value: _triangles,
      okLabel: 'Present', nokLabel: 'Missing',
      onChanged: (v) => setState(() => _triangles = v)),
    _ToggleRow(label: 'Seatbelt', value: _seatbelt,
      okLabel: 'Working', nokLabel: 'Faulty',
      onChanged: (v) => setState(() => _seatbelt = v), critical: true),
  ]);

  // ── Step 5: Odometer ──────────────────────────────────────────────────────
  Widget _stepOdometer() => _StepScroll(children: [
    _StepHint('Enter the exact dashboard reading. Accurate mileage is required for compliance and service scheduling.'),
    const SizedBox(height: 24),
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(children: [
        const Icon(Icons.speed, size: 48, color: AppTheme.primary),
        const SizedBox(height: 16),
        const Text('Current Odometer Reading',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary)),
        const SizedBox(height: 4),
        const Text('Enter the exact reading shown on the dashboard',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          textAlign: TextAlign.center),
        const SizedBox(height: 20),
        TextField(
          controller: _odomCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary, letterSpacing: 2),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: const TextStyle(color: AppTheme.textMuted, letterSpacing: 2),
            suffixText: 'km',
            suffixStyle: const TextStyle(fontSize: 16, color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ]),
    ),
  ]);

  // ── Step 6: Trailer ────────────────────────────────────────────────────────
  Widget _stepTrailer() {
    if (!_hasTrailer) return const SizedBox();
    return _StepScroll(children: [
      _StepHint('Inspect the trailer coupling, tyres, and cargo securing systems before departure.'),
      const SizedBox(height: 8),
      _SectionLabel('Coupling & Structure'),
      _ToggleRow(label: 'Coupling lock', value: _couplingLock,
        okLabel: 'Secure', nokLabel: 'Issue',
        onChanged: (v) => setState(() => _couplingLock = v), critical: true),
      _ToggleRow(label: 'Suspension', value: _trailerSuspension,
        okLabel: 'OK', nokLabel: 'Issue',
        onChanged: (v) => setState(() => _trailerSuspension = v)),
      const SizedBox(height: 20),
      _SectionLabel('Tyres & Cargo'),
      _ToggleRow(label: 'Trailer tyres', value: _trailerTyresOk,
        okLabel: 'OK', nokLabel: 'Issue',
        onChanged: (v) => setState(() => _trailerTyresOk = v)),
      _ToggleRow(label: 'Cargo straps / container locks', value: _cargoStraps,
        okLabel: 'Secure', nokLabel: 'Missing',
        onChanged: (v) => setState(() => _cargoStraps = v)),
      const SizedBox(height: 20),
      _SectionLabel('Trailer Lights'),
      _ToggleRow(label: 'Trailer lights', value: _trailerLightsOk,
        okLabel: 'Working', nokLabel: 'Faulty',
        onChanged: (v) => setState(() => _trailerLightsOk = v)),
    ]);
  }

  // ── Step 7: Review & Submit ────────────────────────────────────────────────
  Widget _stepSubmit(InspectionBloc bloc, bool loading) {
    final status = _computeStatus();
    final statusColor = status == 'pass'
      ? AppTheme.emerald
      : status == 'critical' ? AppTheme.rose : AppTheme.amber;
    final statusLabel = status == 'pass' ? 'Ready to go'
      : status == 'critical' ? 'Critical issues found' : 'Minor issues found';
    final statusIcon  = status == 'pass' ? Icons.check_circle_outline
      : status == 'critical' ? Icons.error_outline : Icons.warning_amber_rounded;

    final tyreList = _tyreCondition.values;
    final issues = <String>[];
    if (tyreList.any((t) => t == 'damaged' || t == 'burst_risk')) issues.add('Critical tyre issue');
    if (tyreList.any((t) => t == 'worn' || t == 'low_pressure')) issues.add('Tyre wear/pressure');
    if (!_brakeResponse || !_airPressure) issues.add('Brake issue');
    if (_oilLevel != 'good' || _coolantLevel != 'good' || _brakeFluid != 'good') issues.add('Fluid level');
    if (!_headlights || !_brakeLights || !_indicators) issues.add('Light fault');
    if (!_fireExt) issues.add('Fire extinguisher missing');
    if (!_seatbelt) issues.add('Seatbelt faulty');
    if (_hasTrailer && !_couplingLock) issues.add('Coupling issue');

    return _StepScroll(children: [
      // Status banner
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(statusIcon, size: 40, color: statusColor),
          const SizedBox(height: 10),
          Text(statusLabel,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: statusColor)),
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(issues.join(' · '),
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              textAlign: TextAlign.center),
          ],
        ]),
      ),
      const SizedBox(height: 20),
      // Summary
      _SummaryRow('Vehicle', _horseReg ?? '—'),
      if (_trailerReg != null) _SummaryRow('Trailer', _trailerReg!),
      _SummaryRow('Odometer', _odomCtrl.text.isEmpty ? '—' : '${_odomCtrl.text} km'),
      const SizedBox(height: 20),
      // Notes
      _SectionLabel('Notes / Issues (optional)'),
      TextField(
        controller: _notesCtrl,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Describe any additional observations…',
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          filled: true, fillColor: AppTheme.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        ),
      ),
      if (status == 'critical') ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.rose.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.rose.withValues(alpha: 0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.warning_rounded, color: AppTheme.rose, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text(
              'Critical issues detected. The fleet manager will be notified. '
              'Do not depart until issues are resolved.',
              style: TextStyle(fontSize: 12, color: AppTheme.rose),
            )),
          ]),
        ),
      ],
    ]);
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _StepScroll extends StatelessWidget {
  final List<Widget> children;
  const _StepScroll({required this.children});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _StepHint extends StatelessWidget {
  final String text;
  const _StepHint(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
        style: const TextStyle(fontSize: 12, color: AppTheme.primary, height: 1.4))),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Text(text, style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: AppTheme.textMuted, letterSpacing: 0.6)),
  );
}

class _VehicleOption extends StatelessWidget {
  final String   reg, make, type;
  final IconData icon;
  final bool     selected;
  final VoidCallback onTap;
  const _VehicleOption({required this.reg, required this.make, required this.type,
    required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary.withValues(alpha: 0.08) : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppTheme.primary : AppTheme.border,
          width: selected ? 1.5 : 0.5),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20,
            color: selected ? AppTheme.primary : AppTheme.textMuted),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reg, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: selected ? AppTheme.primary : AppTheme.textPrimary)),
          if (make.isNotEmpty)
            Text(make, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ])),
        if (selected)
          const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22),
      ]),
    ),
  );
}

class _EmptyVehicles extends StatelessWidget {
  final String msg;
  const _EmptyVehicles(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: Text(msg, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
  );
}

// Fluid level row: Good / Low / Critical
class _FluidRow extends StatelessWidget {
  final String   label, value;
  final void Function(String) onChanged;
  const _FluidRow({required this.label, required this.value, required this.onChanged});

  static const _opts = ['good', 'low', 'critical'];
  static const _labels = ['Good', 'Low', 'Critical'];
  static const _colors = [AppTheme.emerald, AppTheme.amber, AppTheme.rose];

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: Row(children: [
      Expanded(child: Text(label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary))),
      const SizedBox(width: 8),
      Row(children: List.generate(3, (i) {
        final sel = value == _opts[i];
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: GestureDetector(
            onTap: () => onChanged(_opts[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? _colors[i].withValues(alpha: 0.15) : AppTheme.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? _colors[i] : AppTheme.border, width: 0.8),
              ),
              child: Text(_labels[i], style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: sel ? _colors[i] : AppTheme.textMuted)),
            ),
          ),
        );
      })),
    ]),
  );
}

// ── Interactive tyre diagram ───────────────────────────────────────────────
// Tap a tyre on the 20-position truck + trailer rig to open the inspection
// sheet. Colour reflects the recorded condition; a check badge marks tyres
// that have a condition AND a photo, a white dot marks ones still pending.
class _TyreDiagram extends StatelessWidget {
  final Map<String, String?> condition, photo;
  final bool showTrailer;
  final void Function(String code) onTap;
  const _TyreDiagram({required this.condition, required this.photo,
      required this.showTrailer, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border, width: 0.5),
    ),
    child: Center(
      child: TyreTruckDiagram(
        colorFor:    (code) => _tyreConditionColor(condition[code]),
        isDone:      (code) => condition[code] != null && photo[code] != null,
        isAttention: (code) => condition[code] == null,
        showTrailer: showTrailer,
        onTap: onTap,
      ),
    ),
  );
}

class _TyreProgressTracker extends StatelessWidget {
  final int done, total;
  const _TyreProgressTracker({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;
    final fullyDone = done == total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Tyres Inspected', style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          Text('$done / $total complete', style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fullyDone ? AppTheme.emerald : AppTheme.primary)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct, minHeight: 6,
            backgroundColor: AppTheme.border,
            color: fullyDone ? AppTheme.emerald : AppTheme.primary)),
      ]),
    );
  }
}

class _TyreLegend extends StatelessWidget {
  const _TyreLegend();
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 14, runSpacing: 6, alignment: WrapAlignment.center,
    children: [
      _dot(Colors.grey, 'Pending'),
      _dot(AppTheme.emerald, 'Good'),
      _dot(AppTheme.amber, 'Worn'),
      _dot(Colors.orange, 'Low Pressure'),
      _dot(AppTheme.rose, 'Damaged'),
      _dot(const Color(0xFF7F1D1D), 'Burst Risk'),
    ],
  );

  Widget _dot(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
  ]);
}

// ── Tyre inspection sheet: condition picker + mandatory photo ─────────────
class _TyreInspectSheet extends StatefulWidget {
  final TyreSlot pos;
  final String?  condition, photo;
  final void Function(String condition) onConditionSet;
  final void Function(String photoBase64) onPhotoSet;
  const _TyreInspectSheet({required this.pos, required this.condition, required this.photo,
      required this.onConditionSet, required this.onPhotoSet});
  @override State<_TyreInspectSheet> createState() => _TyreInspectSheetState();
}

class _TyreInspectSheetState extends State<_TyreInspectSheet> {
  String? _condition;
  String? _photo;
  bool    _uploading = false;

  @override void initState() {
    super.initState();
    _condition = widget.condition;
    _photo     = widget.photo;
  }

  Future<void> _pickPhoto({required bool useCamera}) async {
    setState(() => _uploading = true);
    try {
      final bytes = await pickImageBytes(useCamera: useCamera);
      if (bytes == null) { setState(() => _uploading = false); return; }
      if (bytes.length > 350000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Image too large — use a photo under 350 KB',
              style: TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
        }
        setState(() => _uploading = false);
        return;
      }
      final b64 = base64Encode(bytes);
      widget.onPhotoSet(b64);
      setState(() { _photo = b64; _uploading = false; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.rose, behavior: SnackBarBehavior.floating));
      }
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color    = _tyreConditionColor(_condition);
    final complete = _condition != null && _photo != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Center(child: Icon(Icons.tire_repair, color: color)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Inspect Tyre', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              Text(widget.pos.label, style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            ])),
            if (complete) const Icon(Icons.check_circle, color: AppTheme.emerald, size: 22),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 16),

          const Text('Condition', style: TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: _kTyreConditions.map((c) {
            final sel = _condition == c.$1;
            return GestureDetector(
              onTap: () { widget.onConditionSet(c.$1); setState(() => _condition = c.$1); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? c.$4.withValues(alpha: 0.14) : AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? c.$4 : AppTheme.border, width: sel ? 1.4 : 0.8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(c.$3, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(c.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: sel ? c.$4 : AppTheme.textPrimary)),
                ]),
              ),
            );
          }).toList()),

          if (_condition != null) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppTheme.border),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.camera_alt_outlined, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              const Text('Photo required', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
              const Spacer(),
              if (_photo != null)
                const Text('✓ Photo verified', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w600, color: AppTheme.emerald)),
            ]),
            const SizedBox(height: 10),
            if (_photo != null && _photo!.isNotEmpty) ...[
              ClipRRect(borderRadius: BorderRadius.circular(10),
                child: Image.memory(base64Decode(_photo!),
                  height: 140, width: double.infinity, fit: BoxFit.cover)),
              const SizedBox(height: 10),
            ],
            Row(children: [
              Expanded(child: _photoBtn(
                label: _uploading ? 'Uploading…' : (_photo == null ? 'Camera' : 'Retake'),
                icon:  Icons.camera_alt,
                onTap: _uploading ? null : () => _pickPhoto(useCamera: true))),
              const SizedBox(width: 10),
              Expanded(child: _photoBtn(
                label: 'Gallery', icon: Icons.photo_library_outlined,
                onTap: _uploading ? null : () => _pickPhoto(useCamera: false))),
            ]),
            if (_photo == null) ...[
              const SizedBox(height: 8),
              const Text('Tyre image required — capture a photo to mark this tyre inspected.',
                style: TextStyle(fontSize: 11, color: AppTheme.rose)),
            ],
          ],

          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: complete ? () => Navigator.pop(context) : null,
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 46)),
            child: Text(
              complete ? 'Done' : 'Choose a condition and capture a photo',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          )),
        ]),
      ),
    );
  }

  Widget _photoBtn({required String label, required IconData icon, required VoidCallback? onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: AppTheme.accent),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600, color: AppTheme.accent)),
        ]),
      ),
    );
}

// Binary toggle row: OK / Not OK
class _ToggleRow extends StatelessWidget {
  final String   label, okLabel, nokLabel;
  final bool     value, critical;
  final void Function(bool) onChanged;
  const _ToggleRow({required this.label, required this.value,
    required this.okLabel, required this.nokLabel,
    required this.onChanged, this.critical = false});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: (!value && critical) ? AppTheme.rose.withValues(alpha: 0.4) : AppTheme.border,
        width: 0.5),
    ),
    child: Row(children: [
      Expanded(child: Row(children: [
        if (critical && !value)
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Icon(Icons.error_outline, size: 14, color: AppTheme.rose),
          ),
        Expanded(child: Text(label, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
      ])),
      const SizedBox(width: 8),
      Row(children: [
        _Pill(label: okLabel, selected: value,
          color: AppTheme.emerald, onTap: () => onChanged(true)),
        const SizedBox(width: 6),
        _Pill(label: nokLabel, selected: !value,
          color: critical ? AppTheme.rose : AppTheme.amber,
          onTap: () => onChanged(false)),
      ]),
    ]),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final bool   selected;
  final Color  color;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected,
    required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.15) : AppTheme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? color : AppTheme.border, width: 0.8),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: selected ? color : AppTheme.textMuted)),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label,
        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
      Expanded(child: Text(value, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary))),
    ]),
  );
}

// ── Progress Header ────────────────────────────────────────────────────────
class _ProgressHeader extends StatelessWidget {
  final int step, totalSteps;
  const _ProgressHeader({required this.step, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final progress = (step + 1) / totalSteps;
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Step ${step + 1} of $totalSteps',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          Text('${(progress * 100).round()}% complete',
            style: const TextStyle(fontSize: 11, color: AppTheme.primary,
              fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppTheme.border,
            color: AppTheme.primary,
          ),
        ),
      ]),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int  step, totalSteps, submitStep;
  final bool loading;
  final VoidCallback onBack, onNext, onSubmit;
  const _BottomNav({
    required this.step, required this.totalSteps, required this.submitStep,
    required this.loading, required this.onBack, required this.onNext, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst  = step == 0;
    final isSubmit = step == submitStep;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(children: [
        if (!isFirst)
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                side: const BorderSide(color: AppTheme.border),
                foregroundColor: AppTheme.textPrimary,
              ),
              child: const Text('Back'),
            ),
          ),
        if (!isFirst) const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: loading ? null : (isSubmit ? onSubmit : onNext),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
            child: loading
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(isSubmit ? 'Submit Inspection' : 'Next',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}
