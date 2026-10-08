import 'package:flutter/material.dart';
import 'app_colors.dart';

const double _pi = 3.141592653589793;

String _fmt(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

/// ছবির মতো গেজ: বামে সবুজ (UP), ডানে লাল (down), ধূসর কাঁটা,
/// কালো UP/down লেবেল, নিচে গোলাপি Up:30% / down:70% পিল।
class ImageStyleGauge extends StatelessWidget {
  final double up;
  final double down;

  const ImageStyleGauge({super.key, required this.up, required this.down});

  static const _pink = Color(0xFFFCBED4);

  Widget _label(String t, double fs) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fs * 0.6, vertical: fs * 0.2),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(fs * 0.55),
      ),
      child: Text(
        t,
        style: TextStyle(
            fontSize: fs, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }

  Widget _pctPill(String t, double fs) {
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
      child: Stack(
        children: [
          Text(t,
              style: TextStyle(
                  fontSize: fs,
                  fontWeight: FontWeight.w900,
                  foreground: stroke)),
          Text(t,
              style: TextStyle(
                  fontSize: fs,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUp = up > down;
    final tie = up == down;
    final winColor = tie ? AppColors.amber : (isUp ? AppColors.green : AppColors.red);
    final big = tie ? '50%' : '${_fmt(isUp ? up : down)}%';
    final caption = tie ? 'সমান' : (isUp ? 'UP' : 'DOWN');

    return AspectRatio(
      aspectRatio: 1.12,
      child: LayoutBuilder(
        builder: (context, box) {
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
        },
      ),
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
    double rad(double d) => d * _pi / 180;

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
      p.color = AppColors.green;
      final end = downSweep > gap ? gap / 2 : 0.0;
      canvas.drawArc(rect, rad(startDeg), rad(upSweep - end), false, p);
    }
    if (downSweep > gap) {
      p.color = AppColors.red;
      final s = upSweep > gap ? gap / 2 : 0.0;
      canvas.drawArc(
          rect, rad(startDeg + upSweep + s), rad(downSweep - s), false, p);
    }

    final a = rad(startDeg + upSweep);
    final tip = c + Offset.fromDirection(a, r * 0.62);
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

/// অ্যাপের ভেতরে Result দেখানোর কার্ড (গেজ + প্যাটার্ন + সেন্টিমেন্ট + কারণ)।
class ResultPanel extends StatelessWidget {
  final AIResult result;
  const ResultPanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final sc = result.sentiment == 'Bullish'
        ? AppColors.green
        : (result.sentiment == 'Bearish' ? AppColors.red : AppColors.amber);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF100D14),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analysis Result',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lilac)),
          const SizedBox(height: 10),
          ImageStyleGauge(up: result.up, down: result.down),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(result.pattern,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sc.withOpacity(0.4)),
                ),
                child: Text(result.sentiment,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: sc)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(result.reason,
              style: const TextStyle(
                  fontSize: 13, height: 1.5, color: Color(0xFFC8C3CD))),
        ],
      ),
    );
  }
}
