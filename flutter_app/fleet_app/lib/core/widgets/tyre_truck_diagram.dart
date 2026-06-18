import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One of the 20 tyre positions on a horse + tri-axle trailer rig — shared
/// between the dedicated Tyre Inspection page and the Daily Check diagram so
/// both present the exact same truck layout.
class TyreSlot {
  final int    num;
  final String code, label, axle;
  final double cx, cy, tw, th;
  const TyreSlot(this.num, this.code, this.label, this.axle,
      this.cx, this.cy, this.tw, this.th);
}

const double kTyreDiagramWidth   = 320;
const double kTyreDiagramHeight  = 960; // full horse + tri-axle trailer rig
const double kHorseDiagramHeight = 440; // horse only — no trailer coupled

const List<TyreSlot> kTyreSlots = [
  // Steer axle (single)
  TyreSlot(1,  'steer_left',           'Front Left Steer',      'steer',    36, 190, 28, 44),
  TyreSlot(2,  'steer_right',          'Front Right Steer',     'steer',   284, 190, 28, 44),
  // Drive axle 1 (single)
  TyreSlot(3,  'drive1_left',          'Drive 1 Left',          'drive',    14, 305, 24, 38),
  TyreSlot(4,  'drive1_right',         'Drive 1 Right',         'drive',   306, 305, 24, 38),
  // Drive axle 2 (dual)
  TyreSlot(5,  'drive2_left_outer',    'Drive 2 Left Outer',    'drive',     4, 385, 20, 34),
  TyreSlot(6,  'drive2_left_inner',    'Drive 2 Left Inner',    'drive',    26, 385, 20, 34),
  TyreSlot(7,  'drive2_right_inner',   'Drive 2 Right Inner',   'drive',   294, 385, 20, 34),
  TyreSlot(8,  'drive2_right_outer',   'Drive 2 Right Outer',   'drive',   316, 385, 20, 34),
  // Trailer axle 1 (dual)
  TyreSlot(9,  'trailer1_left_outer',  'Trailer 1 Left Outer',  'trailer',   4, 575, 20, 34),
  TyreSlot(10, 'trailer1_left_inner',  'Trailer 1 Left Inner',  'trailer',  26, 575, 20, 34),
  TyreSlot(11, 'trailer1_right_inner', 'Trailer 1 Right Inner', 'trailer', 294, 575, 20, 34),
  TyreSlot(12, 'trailer1_right_outer', 'Trailer 1 Right Outer', 'trailer', 316, 575, 20, 34),
  // Trailer axle 2 (dual)
  TyreSlot(13, 'trailer2_left_outer',  'Trailer 2 Left Outer',  'trailer',   4, 675, 20, 34),
  TyreSlot(14, 'trailer2_left_inner',  'Trailer 2 Left Inner',  'trailer',  26, 675, 20, 34),
  TyreSlot(15, 'trailer2_right_inner', 'Trailer 2 Right Inner', 'trailer', 294, 675, 20, 34),
  TyreSlot(16, 'trailer2_right_outer', 'Trailer 2 Right Outer', 'trailer', 316, 675, 20, 34),
  // Trailer axle 3 (dual)
  TyreSlot(17, 'trailer3_left_outer',  'Trailer 3 Left Outer',  'trailer',   4, 775, 20, 34),
  TyreSlot(18, 'trailer3_left_inner',  'Trailer 3 Left Inner',  'trailer',  26, 775, 20, 34),
  TyreSlot(19, 'trailer3_right_inner', 'Trailer 3 Right Inner', 'trailer', 294, 775, 20, 34),
  TyreSlot(20, 'trailer3_right_outer', 'Trailer 3 Right Outer', 'trailer', 316, 775, 20, 34),
];

// ── Truck + trailer body silhouette ────────────────────────────────────────
class TruckBodyPainter extends CustomPainter {
  final double scale;
  /// Whether to draw the coupling + trailer body and its axles — false when
  /// the driver is running solo with no trailer coupled.
  final bool showTrailer;
  const TruckBodyPainter({required this.scale, this.showTrailer = true});

  Rect _r(double x, double y, double w, double h) =>
      Rect.fromLTWH(x * scale, y * scale, w * scale, h * scale);

  @override
  void paint(Canvas canvas, Size size) {
    final body  = Paint()..color = const Color(0xFFD8D8D8);
    final cab   = Paint()..color = const Color(0xFFC0C0C0);
    final glass = Paint()..color = const Color(0xFFB3D9F0).withValues(alpha: 0.6);
    final axle  = Paint()..color = const Color(0xFF888888)..strokeWidth = 2 * scale..strokeCap = StrokeCap.round;
    final rrb   = RRect.fromRectAndRadius(_r(110, 8, 100, 76), Radius.circular(14 * scale));

    canvas.drawRRect(rrb, cab);
    canvas.drawRRect(
      RRect.fromRectAndRadius(_r(122, 38, 76, 38), Radius.circular(6 * scale)), glass);
    canvas.drawRect(_r(60, 80, 200, 352), body);

    if (showTrailer) {
      canvas.drawRect(_r(138, 430, 44, 44), cab);   // coupling
      canvas.drawRect(_r(60, 472, 200, 450), body); // trailer body
    }

    void axleLine(double y, double x1, double x2) =>
        canvas.drawLine(Offset(x1 * scale, y * scale), Offset(x2 * scale, y * scale), axle);

    axleLine(190, 36,  284);
    axleLine(305, 14,  306);
    axleLine(385,  4,  316);
    if (showTrailer) {
      axleLine(575,  4,  316);
      axleLine(675,  4,  316);
      axleLine(775,  4,  316);
    }
  }

  @override bool shouldRepaint(TruckBodyPainter o) =>
      o.scale != scale || o.showTrailer != showTrailer;
}

// ── 3-D tyre badge ──────────────────────────────────────────────────────────
class TyreDot extends StatelessWidget {
  final String label;
  final Color  color;
  final bool   selected;
  /// Small white dot in the corner — e.g. "no data" / "not yet inspected".
  final bool   attention;
  /// Small check badge in the corner — e.g. "fully inspected with photo".
  final bool   done;
  const TyreDot({super.key, required this.label, required this.color,
      this.selected = false, this.attention = false, this.done = false});

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
        Positioned.fill(child: CustomPaint(painter: _TreadPainter(color: color))),
        Text(label, style: const TextStyle(
          color: Colors.white, fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        )),
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
        if (done)
          const Positioned(right: 1, top: 1,
            child: Icon(Icons.check_circle, size: 10, color: Colors.white)),
        if (attention && !done)
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
    final rimR  = math.min(w, h) * 0.30;
    final rimC  = Offset(w / 2, h / 2);
    final rim   = Paint()
      ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.4)])
          .createShader(Rect.fromCircle(center: rimC, radius: rimR));
    canvas.drawCircle(rimC, rimR, rim);
    final groove = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawOval(Rect.fromLTWH(1, 1, w - 2, h - 2), groove);
  }

  @override bool shouldRepaint(_TreadPainter o) => o.color != color;
}

/// The full 20-tyre interactive truck + trailer diagram. Presentational only —
/// callers decide each tyre's colour / badges from their own data and handle taps.
class TyreTruckDiagram extends StatelessWidget {
  final Color Function(String code) colorFor;
  final bool  Function(String code) isSelected;
  final bool  Function(String code) isAttention;
  final bool  Function(String code) isDone;
  final void  Function(String code) onTap;
  final double maxWidth;
  /// False hides the trailer body and its 12 tyre positions — for a horse
  /// running solo with no trailer coupled.
  final bool showTrailer;
  const TyreTruckDiagram({
    super.key,
    required this.colorFor,
    required this.onTap,
    this.isSelected  = _never,
    this.isAttention = _never,
    this.isDone      = _never,
    this.maxWidth    = 360,
    this.showTrailer = true,
  });

  static bool _never(String code) => false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, con) {
    final slots = showTrailer
        ? kTyreSlots
        : kTyreSlots.where((s) => s.axle != 'trailer').toList(growable: false);
    final modelHeight = showTrailer ? kTyreDiagramHeight : kHorseDiagramHeight;
    final w     = math.min(con.maxWidth - 32, maxWidth);
    final h     = w * (modelHeight / kTyreDiagramWidth);
    final scale = w / kTyreDiagramWidth;
    return SizedBox(width: w, height: h, child: Stack(children: [
      Positioned.fill(child: CustomPaint(
        painter: TruckBodyPainter(scale: scale, showTrailer: showTrailer))),
      ...slots.map((s) => Positioned(
        left:   (s.cx - s.tw / 2) * scale,
        top:    (s.cy - s.th / 2) * scale,
        width:  s.tw * scale,
        height: s.th * scale,
        child: GestureDetector(
          onTap: () => onTap(s.code),
          child: TyreDot(
            label:     '${s.num}',
            color:     colorFor(s.code),
            selected:  isSelected(s.code),
            attention: isAttention(s.code),
            done:      isDone(s.code),
          ),
        ),
      )),
    ]));
  });
}
