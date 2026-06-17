import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../tyres/presentation/widgets/tyre_position_diagram.dart';

const _kMakes = [
  'Mercedes-Benz Actros',
  'Scania G Series',
  'Scania R Series',
  'Volvo FH',
  'MAN TGS',
  'UD Quester',
  'UD Quon',
  'FAW JH6',
];
const _kAxleOptions = [1, 2, 3];
const _kTyreCountOptions = [4, 6, 8, 10, 12];
const _kDefaultServiceKm = 30000;
const _kDefaultLifespanKm = 80000;

const _kStepTitles = [
  'Vehicle Type',
  'Vehicle Details',
  'Tyre Configuration',
  'Compliance Information',
  'Review & Save',
];

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});
  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _fs = sl<FirestoreService>();
  final _pageCtrl = PageController();

  int _step = 0;
  bool _saving = false;

  // Step 1 — vehicle type
  String? _type; // 'horse' | 'trailer'

  // Step 2 — vehicle details
  final _regCtrl = TextEditingController();
  String? _make;
  int? _axles;
  int? _tyreCount;
  int? _year;
  final _odomCtrl = TextEditingController();
  final _serviceKmCtrl = TextEditingController(text: '$_kDefaultServiceKm');
  final _descCtrl = TextEditingController();

  // Step 3 — one name + serial-number field per auto-generated tyre position
  List<TextEditingController> _tyreBrandCtrls = [];
  List<TextEditingController> _tyreSerialCtrls = [];
  List<GlobalKey> _tyreSlotKeys = [];
  int? _selectedTyrePosition;

  // Step 2 extra — front-face truck photo (optional)
  String? _vehiclePhotoBase64;
  bool _photoUploading = false;

  // Step 4 — compliance dates
  DateTime? _licenseExpiry;
  DateTime? _insuranceExpiry;

  static final _years = List<int>.generate(
      DateTime.now().year - 1999, (i) => DateTime.now().year - i);

  @override
  void dispose() {
    _regCtrl.dispose();
    _odomCtrl.dispose();
    _serviceKmCtrl.dispose();
    _descCtrl.dispose();
    for (final c in _tyreBrandCtrls) {
      c.dispose();
    }
    for (final c in _tyreSerialCtrls) {
      c.dispose();
    }
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Tyre layout generation engine ───────────────────────────────────────
  // Lays the tyres out as numbered left/right pairs (1-2, 3-4, ...) — the
  // count alone is enough; positions are filled in with serial numbers here
  // and matched against odometer readings during daily inspections later.
  void _regenerateTyreSlots() {
    for (final c in _tyreBrandCtrls) {
      c.dispose();
    }
    for (final c in _tyreSerialCtrls) {
      c.dispose();
    }
    _tyreBrandCtrls =
        List.generate(_tyreCount ?? 0, (_) => TextEditingController());
    _tyreSerialCtrls =
        List.generate(_tyreCount ?? 0, (_) => TextEditingController());
    _tyreSlotKeys = List.generate(_tyreCount ?? 0, (_) => GlobalKey());
    _selectedTyrePosition = null;
  }

  // Tapping a tyre in the diagram selects it and scrolls its entry card
  // into view so the user can fill in its name/serial.
  void _onTapTyreSlot(TyreSlotDef slot) {
    setState(() => _selectedTyrePosition = slot.position);
    final key = _tyreSlotKeys[slot.position - 1];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: 0.5);
      }
    });
  }

  String _fmtDate(DateTime? d) => d == null
      ? ''
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _snack(String msg, [Color color = AppTheme.rose]) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: const TextStyle(color: Colors.white)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating));

  bool _validateStep() {
    switch (_step) {
      case 0:
        if (_type == null) {
          _snack('Select a vehicle type to continue');
          return false;
        }
        return true;
      case 1:
        if (_regCtrl.text.trim().isEmpty ||
            _make == null ||
            _axles == null ||
            _tyreCount == null ||
            _year == null ||
            _odomCtrl.text.trim().isEmpty) {
          _snack('Please complete all the required fields');
          return false;
        }
        if (int.tryParse(_odomCtrl.text.trim()) == null) {
          _snack('Odometer must be a number');
          return false;
        }
        return true;
      case 2:
        return true; // serial numbers are optional — can be captured later
      case 3:
        if (_licenseExpiry == null || _insuranceExpiry == null) {
          _snack('Please set both the licence and insurance expiry dates');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateStep()) return;
    if (_step == 1) _regenerateTyreSlots();
    if (_step < _kStepTitles.length - 1) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    }
  }

  void _back() {
    if (_step == 0) {
      context.go('/vehicles');
      return;
    }
    setState(() => _step--);
    _pageCtrl.animateToPage(_step,
        duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
  }

  Future<void> _pickDate({required bool license}) async {
    final now = DateTime.now();
    final initial = (license ? _licenseExpiry : _insuranceExpiry) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (license) {
        _licenseExpiry = picked;
      } else {
        _insuranceExpiry = picked;
      }
    });
  }

  Future<void> _pickVehiclePhoto() async {
    setState(() => _photoUploading = true);
    try {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      final file = await input.onChange.first.then((_) => input.files?.first);
      if (file == null) {
        setState(() => _photoUploading = false);
        return;
      }
      final reader = html.FileReader()..readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes = reader.result as Uint8List;
      if (bytes.length > 700000) {
        if (mounted) _snack('Photo too large — keep it under 700 KB');
        setState(() => _photoUploading = false);
        return;
      }
      setState(() {
        _vehiclePhotoBase64 = base64Encode(bytes);
        _photoUploading = false;
      });
    } catch (e) {
      if (mounted) _snack('Error: $e');
      setState(() => _photoUploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_validateStep()) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final now = DateTime.now();
      final odometer = int.parse(_odomCtrl.text.trim());
      final serviceKm =
          int.tryParse(_serviceKmCtrl.text.trim()) ?? _kDefaultServiceKm;

      final vehicleRef = await _fs.db.collection('vehicles').add({
        'type': _type,
        'registration_number': _regCtrl.text.trim().toUpperCase(),
        'make': _make,
        'model': '',
        'year': _year,
        'axles': _axles,
        'tyre_count': _tyreCount,
        'odometer': odometer,
        'service_interval_km': serviceKm,
        'next_service_km': odometer + serviceKm,
        'description': _descCtrl.text.trim(),
        'license_expiry': _fmtDate(_licenseExpiry),
        'insurance_expiry': _fmtDate(_insuranceExpiry),
        'status': 'active',
        'created_by': uid,
        'created_at': now.toIso8601String(),
        if (_vehiclePhotoBase64 != null) 'photo': _vehiclePhotoBase64,
      });

      // Pre-populate the tyres collection so daily inspections already know
      // each position's serial number, install odometer and starting status —
      // no manual tyre selection needed once the vehicle is on the road.
      final batch = _fs.db.batch();
      for (var i = 0; i < (_tyreCount ?? 0); i++) {
        final brand = _tyreBrandCtrls[i].text.trim();
        final serial = _tyreSerialCtrls[i].text.trim();
        batch.set(_fs.db.collection('tyres').doc(), {
          'vehicle_id': vehicleRef.id,
          'vehicle_reg': _regCtrl.text.trim().toUpperCase(),
          'vehicle_type': _type,
          'position': '${i + 1}',
          if (brand.isNotEmpty) 'brand': brand,
          if (serial.isNotEmpty) 'serial_number': serial,
          'installed_km': odometer,
          'condition': 'good',
          'km_lifespan': _kDefaultLifespanKm,
          'km_used': 0,
          'created_at': now.toIso8601String(),
        });
      }
      await batch.commit();

      if (mounted) {
        _snack('Vehicle added!', AppTheme.emerald);
        context.go('/vehicles');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_kStepTitles[_step],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        leading:
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
      ),
      body: Column(children: [
        _WizardProgress(step: _step, total: _kStepTitles.length),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _stepType(),
              _stepDetails(),
              _stepTyres(),
              _stepCompliance(),
              _stepReview(),
            ],
          ),
        ),
        _WizardNav(
          step: _step,
          total: _kStepTitles.length,
          saving: _saving,
          onBack: _step == 0 ? null : _back,
          onNext: _step == _kStepTitles.length - 1 ? _submit : _next,
        ),
      ]),
    );
  }

  // ── Step 1: Vehicle Type ────────────────────────────────────────────────
  Widget _stepType() => _WizardScroll(children: [
        const _WizardHint(
            'Choose what you’re adding to the fleet — the rest of the '
            'form adapts to match your choice.'),
        const SizedBox(height: 20),
        _TypeCard(
          icon: Icons.local_shipping_outlined,
          title: 'Horse (Prime Mover)',
          subtitle: 'The powered truck that pulls a trailer',
          selected: _type == 'horse',
          onTap: () => setState(() => _type = 'horse'),
        ),
        const SizedBox(height: 12),
        _TypeCard(
          icon: Icons.rv_hookup_outlined,
          title: 'Trailer',
          subtitle: 'The towed unit coupled to a horse',
          selected: _type == 'trailer',
          onTap: () => setState(() => _type = 'trailer'),
        ),
      ]);

  // ── Step 2: Vehicle Details ─────────────────────────────────────────────
  Widget _stepDetails() => _WizardScroll(children: [
        const _WizardLabel('Registration Number'),
        _textField(_regCtrl,
            hint: 'e.g. HBD332MP',
            textCapitalization: TextCapitalization.characters),
        const SizedBox(height: 16),
        const _WizardLabel('Make'),
        _dropdown<String>(
            value: _make,
            hint: 'Select make',
            items: _kMakes,
            labelOf: (m) => m,
            onChanged: (v) => setState(() => _make = v)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const _WizardLabel('Number of Axles'),
                _dropdown<int>(
                    value: _axles,
                    hint: 'Axles',
                    items: _kAxleOptions,
                    labelOf: (n) => '$n',
                    onChanged: (v) => setState(() => _axles = v)),
              ])),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const _WizardLabel('Number of Tyres'),
                _dropdown<int>(
                    value: _tyreCount,
                    hint: 'Tyres',
                    items: _kTyreCountOptions,
                    labelOf: (n) => '$n',
                    onChanged: (v) => setState(() => _tyreCount = v)),
              ])),
        ]),
        if (_tyreCount != null) ...[
          const SizedBox(height: 6),
          const Text(
              'The tyre layout will be generated automatically in the next step',
              style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 16),
        const _WizardLabel('Year'),
        _dropdown<int>(
            value: _year,
            hint: 'Select year',
            items: _years,
            labelOf: (y) => '$y',
            onChanged: (v) => setState(() => _year = v)),
        const SizedBox(height: 16),
        const _WizardLabel('Current Odometer (km)'),
        _textField(_odomCtrl, hint: 'e.g. 245000', isNum: true),
        const SizedBox(height: 16),
        const _WizardLabel('Service Interval (km)'),
        _textField(_serviceKmCtrl,
            hint: 'Default $_kDefaultServiceKm', isNum: true),
        const SizedBox(height: 16),
        const _WizardLabel('Description'),
        _textField(_descCtrl,
            hint: 'e.g. Cross-border long-haul truck', maxLines: 4),
        const SizedBox(height: 16),
        const _WizardLabel('Front Photo (optional)'),
        _vehiclePhotoBase64 == null
            ? GestureDetector(
                onTap: _photoUploading ? null : _pickVehiclePhoto,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.border,
                          width: 0.8,
                          style: BorderStyle.solid)),
                  child: Center(
                      child: _photoUploading
                          ? const CircularProgressIndicator(
                              color: AppTheme.primary, strokeWidth: 2)
                          : Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.add_a_photo_outlined,
                                  size: 28,
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.6)),
                              const SizedBox(height: 6),
                              const Text('Tap to add front photo',
                                  style: TextStyle(
                                      fontSize: 12, color: AppTheme.textMuted)),
                            ])),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(children: [
                  Image.memory(base64Decode(_vehiclePhotoBase64!),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox()),
                  Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _vehiclePhotoBase64 = null),
                        child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16)),
                      )),
                ]),
              ),
      ]);

  // ── Step 3: Tyre Configuration ──────────────────────────────────────────
  Widget _stepTyres() {
    final count = _tyreCount ?? 0;
    if (count == 0 || _tyreSerialCtrls.length != count) {
      return _WizardScroll(children: const [
        _WizardHint(
            'Set the number of tyres on the previous step to generate the layout.'),
      ]);
    }
    return _WizardScroll(children: [
      _WizardHint('Fleetara generated $count tyre positions across $_axles '
          '${_axles == 1 ? "axle" : "axles"}. Capture the tyre name and serial '
          'number now, or leave them blank to fill in during inspection.'),
      const SizedBox(height: 16),
      Center(
        child: TyrePositionDiagram(
          vehicleType: _type ?? 'horse',
          tyreCount: count,
          selectedPosition: _selectedTyrePosition,
          onTapSlot: _onTapTyreSlot,
        ),
      ),
      const SizedBox(height: 4),
      const _WizardHint(
          'Tap a tyre on the diagram to jump to its entry below.'),
      const SizedBox(height: 16),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _TyreSlotCard(
          key: _tyreSlotKeys[i],
          label: tyrePositionLabel(
              {'position': '${i + 1}', 'vehicle_type': _type}),
          brandController: _tyreBrandCtrls[i],
          serialController: _tyreSerialCtrls[i],
          selected: _selectedTyrePosition == i + 1,
          onTap: () => setState(() => _selectedTyrePosition = i + 1),
        ),
      ),
    ]);
  }

  // ── Step 4: Compliance Information ─────────────────────────────────────
  Widget _stepCompliance() => _WizardScroll(children: [
        const _WizardHint(
            'Fleetara watches these dates automatically and raises a '
            'renewal alert from three months before expiry.'),
        const SizedBox(height: 20),
        _DatePickerField(
            label: 'Licence Expiry',
            icon: Icons.badge_outlined,
            value: _licenseExpiry,
            onTap: () => _pickDate(license: true)),
        const SizedBox(height: 16),
        _DatePickerField(
            label: 'Insurance Expiry',
            icon: Icons.security_outlined,
            value: _insuranceExpiry,
            onTap: () => _pickDate(license: false)),
      ]);

  // ── Step 5: Review & Save ───────────────────────────────────────────────
  Widget _stepReview() => _WizardScroll(children: [
        const _WizardHint(
            'Check everything looks right before saving — you can edit '
            'the vehicle later.'),
        const SizedBox(height: 16),
        if (_vehiclePhotoBase64 != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(base64Decode(_vehiclePhotoBase64!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox()),
          ),
          const SizedBox(height: 14),
        ],
        _ReviewCard(rows: [
          ('Type', _type == 'horse' ? 'Horse (Prime Mover)' : 'Trailer'),
          ('Reg. Number', _regCtrl.text.trim().toUpperCase()),
          ('Make', _make ?? '—'),
          ('Year', _year?.toString() ?? '—'),
          ('Axles', _axles?.toString() ?? '—'),
          ('Tyres', _tyreCount?.toString() ?? '—'),
          ('Odometer', '${_odomCtrl.text.trim()} km'),
          ('Service Interval', '${_serviceKmCtrl.text.trim()} km'),
          (
            'Licence Expiry',
            _licenseExpiry == null ? '—' : _fmtDate(_licenseExpiry)
          ),
          (
            'Insurance Expiry',
            _insuranceExpiry == null ? '—' : _fmtDate(_insuranceExpiry)
          ),
          if (_descCtrl.text.trim().isNotEmpty)
            ('Description', _descCtrl.text.trim()),
        ]),
      ]);

  // ── Field helpers ───────────────────────────────────────────────────────
  Widget _textField(TextEditingController ctrl,
      {required String hint,
      bool isNum = false,
      int maxLines = 1,
      TextCapitalization textCapitalization = TextCapitalization.none}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(hintText: hint),
    );
  }

  Widget _dropdown<T>(
      {required T? value,
      required String hint,
      required List<T> items,
      required String Function(T) labelOf,
      required void Function(T?) onChanged}) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(hintText: hint),
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(labelOf(i))))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Wizard chrome ──────────────────────────────────────────────────────────
class _WizardProgress extends StatelessWidget {
  final int step, total;
  const _WizardProgress({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = (step + 1) / total;
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Step ${step + 1} of $total',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          Text('${(progress * 100).round()}% complete',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppTheme.border,
                color: AppTheme.primary)),
      ]),
    );
  }
}

class _WizardNav extends StatelessWidget {
  final int step, total;
  final bool saving;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  const _WizardNav(
      {required this.step,
      required this.total,
      required this.saving,
      required this.onBack,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isLast = step == total - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border, width: 0.5))),
      child: Row(children: [
        if (onBack != null) ...[
          Expanded(
              flex: 2,
              child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(color: AppTheme.border),
                      foregroundColor: AppTheme.textPrimary),
                  child: const Text('Back'))),
          const SizedBox(width: 12),
        ],
        Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: saving ? null : onNext,
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
              child: saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(isLast ? 'Save Vehicle' : 'Next',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
            )),
      ]),
    );
  }
}

class _WizardScroll extends StatelessWidget {
  final List<Widget> children;
  const _WizardScroll({required this.children});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children)),
      );
}

class _WizardHint extends StatelessWidget {
  final String text;
  const _WizardHint(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.primary, height: 1.4))),
        ]),
      );
}

class _WizardLabel extends StatelessWidget {
  final String text;
  const _WizardLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
      );
}

// ── Step 1 widget: vehicle-type selection card ─────────────────────────────
class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary.withValues(alpha: 0.08)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.border,
                  width: selected ? 1.4 : 0.8)),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: (selected ? AppTheme.primary : AppTheme.border)
                      .withValues(alpha: selected ? 0.15 : 0.5),
                  shape: BoxShape.circle),
              child: Icon(icon,
                  color: selected ? AppTheme.primary : AppTheme.textMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted)),
                ])),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 22),
          ]),
        ),
      );
}

// ── Step 3 widget: one auto-generated tyre slot ────────────────────────────
class _TyreSlotCard extends StatelessWidget {
  final String label;
  final TextEditingController brandController;
  final TextEditingController serialController;
  final bool selected;
  final VoidCallback? onTap;
  const _TyreSlotCard({
    super.key,
    required this.label,
    required this.brandController,
    required this.serialController,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary.withValues(alpha: 0.06)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? AppTheme.primary : AppTheme.border,
                  width: selected ? 1.4 : 0.6)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38,
              height: 32,
              decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: Center(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary))),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(children: [
              TextField(
                controller: brandController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Tyre name / brand',
                    hintStyle: TextStyle(fontSize: 11),
                    border: InputBorder.none),
              ),
              const Divider(height: 10, thickness: 0.4, color: AppTheme.border),
              TextField(
                controller: serialController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'Serial number',
                    hintStyle: TextStyle(fontSize: 11),
                    border: InputBorder.none),
              ),
            ])),
          ]),
        ),
      );
}

// ── Step 4 widget: tappable date field ─────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? value;
  final VoidCallback onTap;
  const _DatePickerField(
      {required this.label,
      required this.icon,
      required this.value,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Select date'
        : '${value!.day.toString().padLeft(2, '0')}/'
            '${value!.month.toString().padLeft(2, '0')}/${value!.year}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border, width: 0.8)),
        child: Row(children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 2),
                Text(text,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: value == null
                            ? AppTheme.textMuted
                            : AppTheme.textPrimary)),
              ])),
          const Icon(Icons.calendar_month_outlined,
              size: 18, color: AppTheme.textMuted),
        ]),
      ),
    );
  }
}

// ── Step 5 widget: read-only summary card ──────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final List<(String, String)> rows;
  const _ReviewCard({required this.rows});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border, width: 0.6)),
        child: Column(
            children: rows
                .map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                width: 130,
                                child: Text(r.$1,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted))),
                            Expanded(
                                child: Text(r.$2,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary))),
                          ]),
                    ))
                .toList()),
      );
}
