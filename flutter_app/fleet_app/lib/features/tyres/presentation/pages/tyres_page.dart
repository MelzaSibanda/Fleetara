import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/utils/responsive.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';
import 'tyre_form_page.dart';

class TyresPage extends StatefulWidget {
  const TyresPage({super.key});
  @override State<TyresPage> createState() => _TyresPageState();
}

class _TyresPageState extends State<TyresPage> {
  List   _tyres    = [];
  List   _allTyres = [];
  bool   _loading  = true;
  String _filter   = 'all';
  final _fs = sl<FirestoreService>();

  static const _filters = ['all', 'good', 'worn', 'critical', 'replaced'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await _fs.db.collection('tyres').get();
      _allTyres  = _fs.docsToList(snap);
      _applyFilter();
      setState(() => _loading = false);
    } catch (_) { setState(() => _loading = false); }
  }

  void _applyFilter() {
    setState(() {
      _tyres = _filter == 'all'
          ? List.from(_allTyres)
          : _allTyres
              .where((t) => (t['condition'] ?? '') == _filter)
              .toList();
    });
  }

  Future<void> _deleteTyre(Map tyre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete tyre',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        content: Text(
          'Delete ${tyre['brand'] ?? 'this tyre'} at ${_posLabel(tyre['position'] ?? '')}?\n'
          'This cannot be undone.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose, minimumSize: const Size(80, 36)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _fs.db.collection('tyres').doc(tyre['id'] as String).delete();
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tyre deleted', style: TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.emerald, behavior: SnackBarBehavior.floating));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Tyres',
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/tyres/inspect'),
          icon: const Icon(Icons.search, size: 16, color: AppTheme.accent),
          label: const Text('Inspect',
            style: TextStyle(color: AppTheme.accent, fontSize: 12)),
        ),
        TextButton.icon(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
          label: const Text('Add Tyre',
            style: TextStyle(color: AppTheme.primary, fontSize: 12)),
        ),
        const SizedBox(width: 8),
      ],
      child: Column(children: [
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _filters.map((f) {
              final active = _filter == f;
              final color  = _condColor(f);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () { setState(() => _filter = f); _applyFilter(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: active
                        ? (f == 'all' ? AppTheme.primary : color).withValues(alpha: 0.15)
                        : AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                          ? (f == 'all' ? AppTheme.primary : color).withValues(alpha: 0.5)
                          : AppTheme.border,
                        width: 0.5),
                    ),
                    child: Text(_filterLabel(f),
                      style: TextStyle(fontSize: 12,
                        fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                        color: active
                          ? (f == 'all' ? AppTheme.primary : color)
                          : AppTheme.textMuted)),
                  ),
                ),
              );
            }).toList()),
          ),
        ),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: AppTheme.primary, strokeWidth: 2))
            : _tyres.isEmpty
              ? EmptyState(
                  icon: Icons.tire_repair_outlined,
                  title: 'No tyres recorded',
                  subtitle: 'Add tyre records to track condition and lifespan.',
                  action: ElevatedButton(
                    onPressed: () => _openForm(context),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(140, 40)),
                    child: const Text('Add Tyre'),
                  ),
                )
              : RListBody(
                  twoColumn: true,
                  onRefresh: _load,
                  cards: _tyres.map((t) => _TyreCard(
                    tyre:     t,
                    onEdit:   () => _openForm(context, tyre: t),
                    onDelete: () => _deleteTyre(t),
                  )).toList(),
                ),
        ),
      ]),
    );
  }

  void _openForm(BuildContext context, {Map? tyre}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TyreFormPage(tyre: tyre)),
    );
    if (saved == true) _load();
  }

  Color _condColor(String c) {
    switch (c) {
      case 'good':     return AppTheme.emerald;
      case 'worn':     return AppTheme.amber;
      case 'critical': return AppTheme.rose;
      case 'replaced': return AppTheme.textMuted;
      default:         return AppTheme.primary;
    }
  }

  String _filterLabel(String f) =>
    f == 'all' ? 'All' : '${f[0].toUpperCase()}${f.substring(1)}';

  String _posLabel(String p) => p.replaceAll('_', ' ').split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

class _TyreCard extends StatelessWidget {
  final Map          tyre;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TyreCard({required this.tyre, required this.onEdit, required this.onDelete});

  Color get _cc {
    switch (tyre['condition'] ?? 'good') {
      case 'good':     return AppTheme.emerald;
      case 'worn':     return AppTheme.amber;
      case 'critical': return AppTheme.rose;
      case 'replaced': return AppTheme.textMuted;
      default:         return AppTheme.primary;
    }
  }

  String get _condLabel {
    switch (tyre['condition'] ?? 'good') {
      case 'good':     return 'Good';
      case 'worn':     return 'Worn';
      case 'critical': return 'Critical';
      case 'replaced': return 'Replaced';
      default:         return tyre['condition'] ?? '';
    }
  }

  String _posLabel(String p) => p.replaceAll('_', ' ').split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context) {
    final brand       = tyre['brand'] ?? 'Unknown brand';
    final size        = tyre['size']  ?? '—';
    final position    = _posLabel(tyre['position'] ?? '');
    final installedKm = tyre['installed_km'] ?? 0;
    final lifespan    = (tyre['km_lifespan'] ?? 120000) as int;
    final kmUsed      = (tyre['km_used'] ?? 0) as int;
    final progress    = lifespan > 0 ? (kmUsed / lifespan).clamp(0.0, 1.0) : 0.0;
    final vehicleLabel = tyre['vehicle_reg'] ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tyre['condition'] == 'critical'
            ? AppTheme.rose.withValues(alpha: 0.3) : AppTheme.border,
          width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
              color: _cc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.tire_repair, color: _cc, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$brand  ·  $size',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary)),
            Text(position,
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ])),
          StatusPill(label: _condLabel, color: _cc),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textMuted),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onSelected: (v) { if (v == 'edit') { onEdit(); } else { onDelete(); } },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 16, color: AppTheme.primary),
                  SizedBox(width: 10),
                  Text('Edit', style: TextStyle(fontSize: 13)),
                ])),
              const PopupMenuItem(value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 16, color: AppTheme.rose),
                  SizedBox(width: 10),
                  Text('Delete', style: TextStyle(fontSize: 13, color: AppTheme.rose)),
                ])),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 0.5, color: AppTheme.border),
        const SizedBox(height: 10),
        Row(children: [
          _cell(Icons.local_shipping_outlined, 'Vehicle',      vehicleLabel),
          _cell(Icons.speed,                   'Installed at', '$installedKm km'),
          _cell(Icons.route_outlined,          'Life used',
            '${(progress * 100).toStringAsFixed(0)}%'),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Tyre lifespan',
            style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          Text('$kmUsed / $lifespan km',
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        ]),
        const SizedBox(height: 4),
        FleetProgressBar(value: progress),
        if (tyre['serial_number'] != null &&
            (tyre['serial_number'] as String).isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('S/N: ${tyre['serial_number']}',
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        ],
      ]),
    );
  }

  Widget _cell(IconData icon, String label, String value) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      const SizedBox(height: 2),
      Row(children: [
        Icon(icon, size: 12, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Flexible(child: Text(value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary),
          overflow: TextOverflow.ellipsis)),
      ]),
    ]),
  );
}
