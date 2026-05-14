import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../bloc/inspection_bloc.dart';
import '../bloc/inspection_event.dart';
import '../bloc/inspection_state.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class DailyCheckFormPage extends StatefulWidget {
  const DailyCheckFormPage({super.key});
  @override State<DailyCheckFormPage> createState() => _DailyCheckFormPageState();
}

class _DailyCheckFormPageState extends State<DailyCheckFormPage> {
  final _notesCtrl   = TextEditingController();
  final _odomCtrl    = TextEditingController();
  final _horseCtrl   = TextEditingController();
  final _trailerCtrl = TextEditingController();

  String _overallStatus = 'pass';

  // Checkbox states
  bool oilLevel            = false;
  bool coolantLevel        = false;
  bool noEngineLeaks       = false;
  bool tyrePressure        = false;
  bool tyreCondition       = false;
  bool wheelNuts           = false;
  bool brakeResponse       = false;
  bool airPressure         = false;
  bool headlights          = false;
  bool indicators          = false;
  bool brakeLights         = false;
  bool fireExtinguisher    = false;
  bool reflectiveTriangles = false;
  bool seatbelt            = false;
  bool trailerTyres        = false;
  bool couplingSystem      = false;
  bool trailerLights       = false;
  bool cargoLocking        = false;
  bool trailerSuspension   = false;

  void _computeStatus() {
    final allHorse = oilLevel && coolantLevel && noEngineLeaks &&
        tyrePressure && tyreCondition && wheelNuts &&
        brakeResponse && airPressure &&
        headlights && indicators && brakeLights &&
        fireExtinguisher && reflectiveTriangles && seatbelt;
    final allTrailer = trailerTyres && couplingSystem && trailerLights &&
        cargoLocking && trailerSuspension;
    if (allHorse && allTrailer) {
      _overallStatus = 'pass';
    } else if (!brakeResponse || !airPressure || !seatbelt || !fireExtinguisher) {
      _overallStatus = 'critical';
    } else {
      _overallStatus = 'minor_issue';
    }
  }

  void _submit(InspectionBloc bloc) {
    _computeStatus();
    final horseId   = int.tryParse(_horseCtrl.text);
    final trailerId = int.tryParse(_trailerCtrl.text);
    if (horseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horse ID is required'), backgroundColor: AppTheme.rose));
      return;
    }
    bloc.add(InspectionSubmitRequested({
      'horse':               horseId,
      if (trailerId != null) 'trailer': trailerId,
      'odometer':            int.tryParse(_odomCtrl.text),
      'oil_level':           oilLevel,
      'coolant_level':       coolantLevel,
      'no_engine_leaks':     noEngineLeaks,
      'tyre_pressure':       tyrePressure,
      'tyre_condition':      tyreCondition,
      'wheel_nuts':          wheelNuts,
      'brake_response':      brakeResponse,
      'air_pressure':        airPressure,
      'headlights':          headlights,
      'indicators':          indicators,
      'brake_lights':        brakeLights,
      'fire_extinguisher':   fireExtinguisher,
      'reflective_triangles':reflectiveTriangles,
      'seatbelt':            seatbelt,
      'trailer_tyres':       trailerTyres,
      'coupling_system':     couplingSystem,
      'trailer_lights':      trailerLights,
      'cargo_locking':       cargoLocking,
      'trailer_suspension':  trailerSuspension,
      'overall_status':      _overallStatus,
      'notes':               _notesCtrl.text.trim(),
    }));
  }

  @override
  void dispose() {
    _notesCtrl.dispose(); _odomCtrl.dispose();
    _horseCtrl.dispose(); _trailerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InspectionBloc>(),
      child: BlocConsumer<InspectionBloc, InspectionState>(
        listener: (context, state) {
          if (state is InspectionSubmitSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Inspection submitted successfully'),
              backgroundColor: AppTheme.emerald,
            ));
            context.go('/driver/checks');
          }
          if (state is InspectionError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message), backgroundColor: AppTheme.rose));
          }
        },
        builder: (context, state) {
          final bloc    = context.read<InspectionBloc>();
          final loading = state is InspectionLoading;

          return AppShell(
            title: 'Daily Inspection',
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Vehicle IDs
                Row(children: [
                  Expanded(child: _field(_horseCtrl, 'Horse ID *', isNum: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_trailerCtrl, 'Trailer ID', isNum: true)),
                ]),
                _field(_odomCtrl, 'Current Odometer (km)', isNum: true),
                const SizedBox(height: 20),

                _Section(title: '🚛 Engine & Fluids', children: [
                  _Check('Oil level OK',         oilLevel,      (v) => setState(() { oilLevel = v!; })),
                  _Check('Coolant level OK',      coolantLevel,  (v) => setState(() { coolantLevel = v!; })),
                  _Check('No engine leaks',       noEngineLeaks, (v) => setState(() { noEngineLeaks = v!; })),
                ]),

                _Section(title: '🔵 Wheels & Tyres', children: [
                  _Check('Tyre pressure OK',  tyrePressure,  (v) => setState(() { tyrePressure = v!; })),
                  _Check('Tyre condition OK', tyreCondition, (v) => setState(() { tyreCondition = v!; })),
                  _Check('Wheel nuts tight',  wheelNuts,     (v) => setState(() { wheelNuts = v!; })),
                ]),

                _Section(title: '🔴 Brakes', children: [
                  _Check('Brake response OK', brakeResponse, (v) => setState(() { brakeResponse = v!; })),
                  _Check('Air pressure OK',   airPressure,   (v) => setState(() { airPressure = v!; })),
                ]),

                _Section(title: '💡 Lights', children: [
                  _Check('Headlights working',  headlights,  (v) => setState(() { headlights = v!; })),
                  _Check('Indicators working',  indicators,  (v) => setState(() { indicators = v!; })),
                  _Check('Brake lights working',brakeLights, (v) => setState(() { brakeLights = v!; })),
                ]),

                _Section(title: '🦺 Safety Equipment', children: [
                  _Check('Fire extinguisher present',    fireExtinguisher,    (v) => setState(() { fireExtinguisher = v!; })),
                  _Check('Reflective triangles present', reflectiveTriangles, (v) => setState(() { reflectiveTriangles = v!; })),
                  _Check('Seatbelt working',             seatbelt,            (v) => setState(() { seatbelt = v!; })),
                ]),

                _Section(title: '🔗 Trailer', children: [
                  _Check('Trailer tyres OK',    trailerTyres,      (v) => setState(() { trailerTyres = v!; })),
                  _Check('Coupling secure',     couplingSystem,    (v) => setState(() { couplingSystem = v!; })),
                  _Check('Trailer lights OK',   trailerLights,     (v) => setState(() { trailerLights = v!; })),
                  _Check('Cargo locks secure',  cargoLocking,      (v) => setState(() { cargoLocking = v!; })),
                  _Check('Suspension OK',       trailerSuspension, (v) => setState(() { trailerSuspension = v!; })),
                ]),

                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Issues',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: loading ? null : () => _submit(bloc),
                  child: loading
                    ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Inspection'),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {bool isNum = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(title, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Column(children: children),
      ),
    ],
  );
}

class _Check extends StatelessWidget {
  final String   label;
  final bool     value;
  final Function(bool?) onChanged;
  const _Check(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    title: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
    value: value,
    onChanged: onChanged,
    activeColor: AppTheme.primary,
    dense: true,
    controlAffinity: ListTileControlAffinity.leading,
  );
}
