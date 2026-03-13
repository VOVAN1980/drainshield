import 'dart:math';
import 'package:flutter/material.dart';

class DsParticle {
  double x, y, dx, dy;
  DsParticle(this.x, this.y, this.dx, this.dy);
}

class DsNetworkPainter extends CustomPainter {
  final List<DsParticle> particles;
  final Color color;

  DsNetworkPainter(this.particles, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paintDot = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    final paintLine = Paint()..strokeWidth = 1.0;

    for (int i = 0; i < particles.length; i++) {
      final p1 = particles[i];
      final pos1 = Offset(p1.x * size.width, p1.y * size.height);
      canvas.drawCircle(pos1, 2, paintDot);

      for (int j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final pos2 = Offset(p2.x * size.width, p2.y * size.height);
        final dist = (pos1 - pos2).distance;
        if (dist < 100) {
          paintLine.color = color.withOpacity((1 - dist / 100) * 0.18);
          canvas.drawLine(pos1, pos2, paintLine);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DsBackground extends StatefulWidget {
  final Widget child;
  final Color accentColor;

  const DsBackground({
    super.key,
    required this.child,
    this.accentColor = const Color(0xFF00FF9D),
  });

  @override
  State<DsBackground> createState() => _DsBackgroundState();
}

class _DsBackgroundState extends State<DsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<DsParticle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 35; i++) {
      _particles.add(
        DsParticle(
          _rnd.nextDouble(),
          _rnd.nextDouble(),
          (_rnd.nextDouble() - 0.5) * 0.002, // Slow, ambient movement
          (_rnd.nextDouble() - 0.5) * 0.002,
        ),
      );
    }
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _ctrl.addListener(() {
      for (var p in _particles) {
        p.x += p.dx;
        p.y += p.dy;
        if (p.x < 0 || p.x > 1) p.dx *= -1;
        if (p.y < 0 || p.y > 1) p.dy *= -1;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark background
        Container(color: const Color(0xFF030509)),

        // Animated particles layer
        Positioned.fill(
          child: CustomPaint(
            painter: DsNetworkPainter(_particles, widget.accentColor),
          ),
        ),

        // Subtle top-right corner glow
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.12),
                  blurRadius: 150,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),

        // Content layer
        SafeArea(child: widget.child),
      ],
    );
  }
}
