import 'dart:math' as math;
import 'package:flutter/material.dart';

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// ছবির মতো গেজ: বামে সবুজ (UP), ডানে লাল (down), ধূসর কাঁটা,
/// কালো UP/down লেবেল, নিচে গোলাপি Up:30% / down:70% পিল।
class ImageStyleGauge extends StatelessWidget {
  final double up;
  final double down;

  const ImageStyleGauge({super.key, required this.up, required this.down});

  static const _green = Color(0xFF38D996);
  static const _red = Color(0xFFFF6685);
  static const _amber = Color(0xFFFFB45C);
  static const _pink = Color(0xFFFCBED4);

  Widget _label(String t, double fs) => Container(
        padding: EdgeInsets.symmetric(horizontal: fs * 0.6, vertical: fs * 0.2),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(fs * 0.55),
        ),
        child: Text(t,
            style: TextStyle(
                fontSize: fs,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
      );

  Widget _pctPill(String t, double fs) {
    Text build(Paint? fg, Color? color) => Text(
          t,
          style: TextStyle(
            fontSize: fs,
            fontWeight: FontWeight.w900,
            foreground: fg,
            color: color,
          ),
        );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = fs * 0.22
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fs * 0.55, vertical: fs * 0.25),
      decoration: BoxDecoration(
        color: _pink,
        borderRadius: BorderRadius.circular(fs * 0.5),
      ),
      child: Stack(children: [build(stroke, null), build(null, Colors.white)]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUp = up > down;
    final tie = up == down;
    final winColor = tie ? _amber : (isUp ? _green : _red);
    final big = tie ? '50%' : '${_fmt(isUp ? up : down)}%';
    final caption = tie ? 'সমান' : (isUp ? 'UP' : 'DOWN');

    return AspectRatio(
      aspectRatio: 1.12,
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GaugePainter(up))),
            Positioned(left: 2, top: 2, child: _label('UP', w * 0.06)),
            Positioned(right: 2, top: 2, child: _label('down', w * 0.06)),
            Positioned(
                left: 2,
                bottom: 2,
                child: _pctPill('Up:${_fmt(up)}%', w * 0.052)),
            Positioned(
                right: 2,
                bottom: 2,
                child: _pctPill('down:${_fmt(down)}%', w * 0.052)),
            Positioned(
              left: 0,
              right: 0,
              top: w * 0.53,
              child: Column(
                children: [
                  Text(big,
                      style: TextStyle(
                          fontSize: w * 0.10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text(caption,
                      style: TextStyle(
                          fontSize: w * 0.04,
                          fontWeight: FontWeight.w800,
                          color: winColor)),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double up;
  _GaugePainter(this.up);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final r = w * 0.38;
    final stroke = w * 0.08;
    final c = Offset(w / 2, r + stroke / 2 + w * 0.10);
    final rect = Rect.fromCircle(center: c, radius: r);

    const startDeg = 150.0;
    const totalDeg = 240.0;
    double rad(double d) => d * math.pi / 180;

    final upSweep = totalDeg * up / 100;
    final downSweep = totalDeg - upSweep;
    const gap = 2.5;

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    p.color = Colors.white.withOpacity(0.12);
    canvas.drawArc(rect, rad(startDeg), rad(totalDeg), false, p);

    if (upSweep > gap) {
      p.color = const Color(0xFF38D996);
      final end = downSweep > gap ? gap / 2 : 0;
      canvas.drawArc(rect, rad(startDeg), rad(upSweep - end), false, p);
    }
    if (downSweep > gap) {
      p.color = const Color(0xFFFF6685);
      final s = upSweep > gap ? gap / 2 : 0;
      canvas.drawArc(
          rect, rad(startDeg + upSweep + s), rad(downSweep - s), false, p);
    }

    final a = rad(startDeg + upSweep);
    final tip = Offset(c.dx + r * 0.62 * math.cos(a), c.dy + r * 0.62 * math.sin(a));
    final n = Paint()
      ..color = const Color(0xFFCDCDCD)
      ..strokeWidth = w * 0.032
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, tip, n);
    canvas.drawCircle(c, w * 0.024, Paint()..color = const Color(0xFFCDCDCD));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.up != up;
}
