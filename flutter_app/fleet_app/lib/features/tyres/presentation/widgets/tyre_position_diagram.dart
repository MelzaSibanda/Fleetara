import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// ── Layout constants ─────────────────────────────────────────────────────────
const double kTyreDiagramWidth = 260;
const double _tyreW = 36;
const double _tyreH = 50;
const double _leftX = 10;
const double _rightX = kTyreDiagramWidth - 10 - _tyreW;
const double _cabH = 70;
const double _subGap = 56;
const double _rowGap = 130;
const double _bottomPad = 20;

/// Returns 'outer' | 'inner' for tyres that share a dual-wheel axle position,
/// or null for single tyres (a horse's steer axle, positions 1-2).
/// Axle groups repeat every 4 positions as left-outer, left-inner,
/// right-outer, right-inner — matching the order built in [buildTyreLayout].
String? dualPositionFor(int position, String vehicleType) {
  final isHorse = vehicleType != 'trailer';
  if (isHorse && position <= 2) return null;
  final base = isHorse ? 3 : 1;
  final idx = (position - base) % 4;
  return (idx == 0 || idx == 2) ? 'outer' : 'inner';
}

// ── Slot definition ───────────────────────────────────────────────────────────
// One tyre position on the diagram. `position` matches the numeric string
// stored in Firestore (tyres.position == '1'..'N'); `label` is the HT/TT
// label shown to the user (HT1, TT12, ...).
class TyreSlotDef {
  final int position;
  final String label;
  final String axleLabel;
  final String side; // 'left' | 'right'
  final String? dualPosition; // 'outer' | 'inner' | null (single steer tyre)
  final double cx, cy; // cx = left edge, cy = vertical center
  const TyreSlotDef({
    required this.position,
    required this.label,
    required this.axleLabel,
    required this.side,
    required this.dualPosition,
    required this.cx,
    required this.cy,
  });
}

/// Human-readable description of a slot's location, e.g. "Axle 1 · Left ·
/// Outer" or "Front · Right".
String tyreSlotDescription(TyreSlotDef slot) {
  final side = slot.side[0].toUpperCase() + slot.side.substring(1);
  final parts = [slot.axleLabel, side];
  final dual = slot.dualPosition;
  if (dual != null) parts.add(dual == 'outer' ? 'Outer' : 'Inner');
  return parts.join(' · ');
}

class TyreLayout {
  final List<TyreSlotDef> slots;
  final double height;
  final bool hasCab;
  final double frontY;
  const TyreLayout({
    required this.slots,
    required this.height,
    required this.hasCab,
    required this.frontY,
  });
}

/// Builds the HT/TT tyre layout for a vehicle.
///
/// Horses get a single-tyre front (steer) axle (HT1/HT2) followed by
/// dual-tyre rear axle groups; trailers are made up entirely of dual-tyre
/// axle groups. Each axle group contributes 4 positions, laid out as
/// left-top, left-bottom, right-top, right-bottom — matching the fleet's
/// HT/TT numbering convention.
TyreLayout buildTyreLayout(
    {required String vehicleType, required int tyreCount}) {
  final isHorse = vehicleType != 'trailer';
  final prefix = isHorse ? 'HT' : 'TT';
  final slots = <TyreSlotDef>[];
  var remaining = tyreCount;
  var pos = 1;
  const frontY = _cabH + 40.0;

  if (isHorse) {
    if (remaining >= 1) {
      slots.add(TyreSlotDef(
          position: pos,
          label: '$prefix$pos',
          axleLabel: 'Front',
          side: 'left',
          dualPosition: null,
          cx: _leftX,
          cy: frontY));
      pos++;
      remaining--;
    }
    if (remaining >= 1) {
      slots.add(TyreSlotDef(
          position: pos,
          label: '$prefix$pos',
          axleLabel: 'Front',
          side: 'right',
          dualPosition: null,
          cx: _rightX,
          cy: frontY));
      pos++;
      remaining--;
    }
  }

  var groupIndex = 0;
  while (remaining > 0) {
    groupIndex++;
    final groupY = isHorse
        ? frontY + 110 + (groupIndex - 1) * _rowGap
        : (30 + _subGap / 2 + _tyreH / 2) + (groupIndex - 1) * _rowGap;
    final order = <(String, double)>[
      ('left', -_subGap / 2),
      ('left', _subGap / 2),
      ('right', -_subGap / 2),
      ('right', _subGap / 2),
    ];
    final n = math.min(remaining, 4);
    for (var i = 0; i < n; i++) {
      final (side, dy) = order[i];
      slots.add(TyreSlotDef(
          position: pos,
          label: '$prefix$pos',
          axleLabel: 'Axle $groupIndex',
          side: side,
          dualPosition: dualPositionFor(pos, vehicleType),
          cx: side == 'left' ? _leftX : _rightX,
          cy: groupY + dy));
      pos++;
    }
    remaining -= n;
  }

  final maxCy =
      slots.isEmpty ? frontY : slots.map((s) => s.cy).reduce(math.max);
  final height = maxCy + _tyreH / 2 + _bottomPad;

  return TyreLayout(
      slots: slots, height: height, hasCab: isHorse, frontY: frontY);
}

/// Resolves how many tyre positions a vehicle has, falling back to the
/// `axles` field (and finally a sensible default) for older records that
/// predate the `tyre_count` field.
int resolveTyreCount(Map vehicle) {
  final tc = vehicle['tyre_count'];
  if (tc is int && tc > 0) return tc;
  if (tc is String) {
    final v = int.tryParse(tc);
    if (v != null && v > 0) return v;
  }
  final axles = vehicle['axles'];
  int? axlesInt;
  if (axles is int) axlesInt = axles;
  if (axles is String) axlesInt = int.tryParse(axles);
  if (axlesInt != null && axlesInt > 0) {
    return vehicle['type'] == 'trailer' ? axlesInt * 4 : 2 + axlesInt * 4;
  }
  return vehicle['type'] == 'trailer' ? 12 : 6;
}

/// Returns the HT/TT display label for a tyre document, e.g. 'HT3' / 'TT12
/// (Inner)'. Dual-wheel positions get an Outer/Inner suffix; single tyres
/// (steer axle) do not. Falls back to formatting legacy semantic position
/// codes (e.g. 'steer_left' -> 'Steer Left') for records created before this
/// scheme.
String tyrePositionLabel(Map tyre) {
  final p = tyre['position']?.toString() ?? '';
  final n = int.tryParse(p);
  if (n != null) {
    final vehicleType = tyre['vehicle_type'] ?? 'horse';
    final prefix = vehicleType == 'trailer' ? 'TT' : 'HT';
    final dual = dualPositionFor(n, vehicleType);
    final suffix =
        dual == null ? '' : (dual == 'outer' ? ' (Outer)' : ' (Inner)');
    return '$prefix$n$suffix';
  }
  return p
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ── Diagram widget ─────────────────────────────────────────────────────────────
class TyrePositionDiagram extends StatelessWidget {
  final String vehicleType;
  final int tyreCount;
  final Map<String, dynamic> tyresByPosition; // key: position as string
  final int? selectedPosition;
  final Set<int>? highlightPositions;
  final void Function(TyreSlotDef slot)? onTapSlot;
  final double maxWidth;

  const TyrePositionDiagram({
    super.key,
    required this.vehicleType,
    required this.tyreCount,
    this.tyresByPosition = const {},
    this.selectedPosition,
    this.highlightPositions,
    this.onTapSlot,
    this.maxWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    final layout =
        buildTyreLayout(vehicleType: vehicleType, tyreCount: tyreCount);
    return LayoutBuilder(builder: (_, con) {
      final w = math.min(con.maxWidth, maxWidth);
      final scale = w / kTyreDiagramWidth;
      final h = layout.height * scale;
      return SizedBox(
          width: w,
          height: h,
          child: Stack(children: [
            Positioned.fill(
                child: CustomPaint(painter: _TyreDiagramPainter(layout))),
            ...layout.slots.map((s) {
              final data = tyresByPosition[s.position.toString()];
              final cond = data?['condition']?.toString() ?? '';
              final color = cond == 'good'
                  ? AppTheme.emerald
                  : cond == 'worn'
                      ? AppTheme.amber
                      : cond == 'critical'
                          ? AppTheme.rose
                          : Colors.grey[600]!;
              return Positioned(
                left: s.cx * scale,
                top: (s.cy - _tyreH / 2) * scale,
                width: _tyreW * scale,
                height: _tyreH * scale,
                child: TyreTile(
                  label: s.label,
                  subLabel: s.dualPosition == null
                      ? null
                      : (s.dualPosition == 'outer' ? 'OUT' : 'IN'),
                  color: data != null ? color : Colors.grey[700]!,
                  selected: selectedPosition == s.position ||
                      (highlightPositions?.contains(s.position) ?? false),
                  hasData: data != null,
                  onTap: onTapSlot == null ? null : () => onTapSlot!(s),
                ),
              );
            }),
          ]));
    });
  }
}

// ── Truck / trailer body painter ────────────────────────────────────────────────
class _TyreDiagramPainter extends CustomPainter {
  final TyreLayout layout;
  const _TyreDiagramPainter(this.layout);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / kTyreDiagramWidth;
    final body = Paint()..color = const Color(0xFFD8D8D8);
    final cab = Paint()..color = const Color(0xFFC0C0C0);
    final glass = Paint()
      ..color = const Color(0xFFB3D9F0).withValues(alpha: 0.6);
    final axle = Paint()
      ..color = const Color(0xFF8A8A8A)
      ..strokeWidth = 2.5 * scale
      ..strokeCap = StrokeCap.round;
    final joint = Paint()..color = const Color(0xFF666666);

    Rect r(double x, double y, double w, double h) =>
        Rect.fromLTWH(x * scale, y * scale, w * scale, h * scale);

    // Chassis body
    final bodyTop = layout.hasCab ? layout.frontY - _tyreH / 2 - 6 : 14.0;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            r(_leftX - 6, bodyTop, (_rightX + _tyreW) - (_leftX - 6) + 6,
                layout.height - bodyTop - 10),
            Radius.circular(14 * scale)),
        body);

    // Cab + windscreen (horse only)
    if (layout.hasCab) {
      const cabW = 120.0;
      final cabX = (kTyreDiagramWidth - cabW) / 2;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              r(cabX, 6, cabW, _cabH), Radius.circular(12 * scale)),
          cab);
      canvas.drawRRect(
          RRect.fromRectAndRadius(r(cabX + 16, 18, cabW - 32, _cabH - 36),
              Radius.circular(6 * scale)),
          glass);
    }

    // Axle lines — connect left/right tyres that share a row, with a centre joint
    final byY = <int, List<TyreSlotDef>>{};
    for (final s in layout.slots) {
      byY.putIfAbsent(s.cy.round(), () => []).add(s);
    }
    for (final entry in byY.entries) {
      final list = entry.value;
      if (list.length < 2) continue;
      final xs = list.map((s) => s.cx + _tyreW / 2).toList()..sort();
      final y = entry.key.toDouble();
      canvas.drawLine(Offset(xs.first * scale, y * scale),
          Offset(xs.last * scale, y * scale), axle);
      canvas.drawCircle(
          Offset((kTyreDiagramWidth / 2) * scale, y * scale), 5 * scale, joint);
    }
  }

  @override
  bool shouldRepaint(_TyreDiagramPainter oldDelegate) =>
      oldDelegate.layout.height != layout.height ||
      oldDelegate.layout.slots.length != layout.slots.length;
}

// ── 3-D tyre tile ──────────────────────────────────────────────────────────────
class TyreTile extends StatelessWidget {
  final String label;
  final String? subLabel; // 'OUT' / 'IN' for dual-wheel positions
  final Color color;
  final bool selected;
  final bool hasData;
  final VoidCallback? onTap;
  const TyreTile({
    super.key,
    required this.label,
    this.subLabel,
    required this.color,
    this.selected = false,
    this.hasData = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A4A4A), Color(0xFF111111)]),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: selected ? AppTheme.primary : Colors.transparent,
                width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(2, 3)),
              if (selected)
                BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1),
            ],
          ),
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(
                child: CustomPaint(painter: _TreadPainter(color: color))),
            Padding(
              padding: const EdgeInsets.all(2),
              child: FittedBox(
                child: subLabel == null
                    ? Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 2)
                            ]))
                    : Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 2)
                                ])),
                        Text(subLabel!,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 2)
                                ])),
                      ]),
              ),
            ),
            if (!hasData)
              Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                          color: Colors.white54, shape: BoxShape.circle))),
          ]),
        ),
      );
}

class _TreadPainter extends CustomPainter {
  final Color color;
  const _TreadPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rimR = math.min(w, h) * 0.32;
    final rimC = Offset(w / 2, h / 2);
    final rim = Paint()
      ..shader = RadialGradient(colors: [
        color.withValues(alpha: 0.9),
        color.withValues(alpha: 0.4)
      ]).createShader(Rect.fromCircle(center: rimC, radius: rimR));
    canvas.drawCircle(rimC, rimR, rim);
    final groove = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawOval(Rect.fromLTWH(1, 1, w - 2, h - 2), groove);
  }

  @override
  bool shouldRepaint(_TreadPainter oldDelegate) => oldDelegate.color != color;
}
