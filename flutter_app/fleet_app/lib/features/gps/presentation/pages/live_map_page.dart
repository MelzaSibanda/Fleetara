import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/presentation/widgets/app_shell.dart';

class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key});
  @override State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  List   _liveData    = [];
  bool   _loading     = true;
  bool   _refreshing  = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    setState(() => _refreshing = true);
    try {
      final res = await sl<ApiClient>().dio.get('/gps/live/');
      setState(() { _liveData = res.data is List ? res.data : []; _loading = false; _refreshing = false; });
    } catch (_) {
      setState(() { _loading = false; _refreshing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Live GPS tracking',
      actions: [
        if (_refreshing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20, color: AppTheme.textPrimary),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.emerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${_liveData.length} active',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.emerald)),
        ),
      ],
      child: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2))
        : ListView(padding: const EdgeInsets.all(16), children: [
            // Map card
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(children: [
                  CustomPaint(
                    size: const Size(double.infinity, 240),
                    painter: _MapGridPainter(liveData: _liveData),
                  ),
                  Positioned(
                    top: 12, left: 14,
                    child: Text('Fleet map — live positions',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            // Per-truck cards
            if (_liveData.isEmpty)
              const EmptyState(
                icon: Icons.map_outlined,
                title: 'No active trips',
                subtitle: 'Live driver locations will appear here\nwhen trips are in progress.',
              )
            else
              ..._liveData.asMap().entries.map((entry) =>
                _TrackingCard(data: entry.value, index: entry.key)),
          ]),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final List liveData;
  const _MapGridPainter({required this.liveData});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color       = AppTheme.border
      ..strokeWidth = 0.5;

    // Draw grid
    const cols = 8;
    const rows = 6;
    for (int c = 1; c < cols; c++) {
      final x = size.width * c / cols;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int r = 1; r < rows; r++) {
      final y = size.height * r / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw route polylines and truck pins
    final rng    = math.Random(42);
    final labels = 'ABCDEFGHIJ'.split('');

    for (int i = 0; i < liveData.length && i < 5; i++) {
      final color     = i.isEven ? AppTheme.primary : AppTheme.amber;
      final x1 = size.width  * (0.1 + rng.nextDouble() * 0.3);
      final y1 = size.height * (0.2 + rng.nextDouble() * 0.4);
      final x2 = size.width  * (0.5 + rng.nextDouble() * 0.4);
      final y2 = size.height * (0.2 + rng.nextDouble() * 0.4);

      // Dashed polyline
      final dashPaint = Paint()
        ..color       = color.withValues(alpha: 0.7)
        ..strokeWidth = 1.5
        ..style       = PaintingStyle.stroke;
      _drawDashed(canvas, Offset(x1, y1), Offset(x2, y2), dashPaint);

      // Truck pin
      final pinPaint = Paint()..color = color;
      final ringPaint = Paint()
        ..color       = color.withValues(alpha: 0.4)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(x2, y2), 10, pinPaint);
      canvas.drawCircle(Offset(x2, y2), 15, ringPaint);

      final tp = TextPainter(
        text: TextSpan(text: labels[i % labels.length],
          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x2 - tp.width / 2, y2 - tp.height / 2));
    }
  }

  void _drawDashed(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLen = 6.0;
    const gapLen  = 4.0;
    final dx   = end.dx - start.dx;
    final dy   = end.dy - start.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final ux   = dx / dist;
    final uy   = dy / dist;
    double d   = 0;
    bool drawing = true;
    while (d < dist) {
      final segLen = drawing ? dashLen : gapLen;
      final next   = math.min(d + segLen, dist);
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + ux * d,    start.dy + uy * d),
          Offset(start.dx + ux * next, start.dy + uy * next),
          paint,
        );
      }
      d += segLen;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => old.liveData.length != liveData.length;
}

class _TrackingCard extends StatelessWidget {
  final Map data;
  final int index;
  const _TrackingCard({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final ts = (data['timestamp'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_shipping, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data['driver'] ?? 'Driver',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              Text(data['horse'] ?? '—',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                  decoration: const BoxDecoration(color: AppTheme.emerald, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Live',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.emerald)),
              ]),
            ),
          ]),
        ),
        const Divider(height: 0.5, thickness: 0.5, color: AppTheme.border),
        // 2x2 data grid
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Row(children: [
              _DataCell(label: 'Route',
                value: '${data['origin'] ?? '—'} → ${data['destination'] ?? '—'}'),
              _DataCell(label: 'Speed',
                value: data['speed_kmh'] != null ? '${data['speed_kmh']} km/h' : '—'),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _DataCell(label: 'Coordinates',
                value: data['latitude'] != null
                  ? '${data['latitude']}, ${data['longitude']}' : '—'),
              _DataCell(label: 'Last ping',
                value: ts.length >= 19 ? ts.substring(11, 19) : ts),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String label;
  final String value;
  const _DataCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      const SizedBox(height: 2),
      Text(value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
        overflow: TextOverflow.ellipsis),
    ]),
  );
}
