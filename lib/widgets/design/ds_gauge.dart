import 'dart:math' as math;
import 'package:flutter/material.dart';

class DsGauge extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color accentColor;
  final String? label;

  const DsGauge({
    super.key,
    required this.value,
    this.accentColor = const Color(0xFF00FF9D),
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(180, 110),
            painter: _GaugePainter(value: value, accentColor: accentColor),
          ),
          Positioned(
            bottom: 10,
            child: Column(
              children: [
                Text(
                  "${(value * 100).round()}%",
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(
                        color: accentColor.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                if (label != null && label!.isNotEmpty)
                  Text(
                    label!.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                if (label == null)
                  Text(
                    "LOADING",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color accentColor;

  _GaugePainter({required this.value, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = math.min(size.width / 2, size.height - 10) - 10;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // Draw background
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Draw glow
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * value,
        false,
        glowPaint,
      );

      // Draw progress
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * value,
        false,
        progressPaint,
      );
    }

    // Draw ticks
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2;

    for (var i = 0; i <= 10; i++) {
      final angle = startAngle + (sweepAngle * i / 10);
      final innerPos = Offset(
        center.dx + (radius - 15) * math.cos(angle),
        center.dy + (radius - 15) * math.sin(angle),
      );
      final outerPos = Offset(
        center.dx + (radius - 25) * math.cos(angle),
        center.dy + (radius - 25) * math.sin(angle),
      );
      canvas.drawLine(innerPos, outerPos, tickPaint);
    }

    // Draw indicator needle/glowing point at the tip
    if (value > 0) {
      final tipAngle = startAngle + (sweepAngle * value);
      final tipPos = Offset(
        center.dx + radius * math.cos(tipAngle),
        center.dy + radius * math.sin(tipAngle),
      );

      final needlePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(tipPos, 4, needlePaint);
      canvas.drawCircle(
        tipPos,
        8,
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value;
}
