import 'package:flutter/material.dart';

class DsHazardStripes extends StatelessWidget {
  final double height;
  final Color baseColor;
  final Color stripeColor;
  final double stripeWidth;
  final double spacing;

  const DsHazardStripes({
    super.key,
    this.height = 14,
    this.baseColor = const Color(0xFFFFD700), // Premium Gold
    this.stripeColor = const Color(0xFF000000), // Pure Black
    this.stripeWidth = 12,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _HazardPainter(
          baseColor: baseColor,
          stripeColor: stripeColor,
          stripeWidth: stripeWidth,
          spacing: spacing,
        ),
      ),
    );
  }
}

class _HazardPainter extends CustomPainter {
  final Color baseColor;
  final Color stripeColor;
  final double stripeWidth;
  final double spacing;

  _HazardPainter({
    required this.baseColor,
    required this.stripeColor,
    required this.stripeWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    paint.color = stripeColor;

    double x = -size.height; // Start before the view to handle diagonal
    while (x < size.width) {
      final Path path = Path();
      path.moveTo(x, size.height);
      path.lineTo(x + stripeWidth, size.height);
      path.lineTo(x + stripeWidth + size.height, 0); // 45 degree angle
      path.lineTo(x + size.height, 0);
      path.close();
      canvas.drawPath(path, paint);
      x += stripeWidth + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
