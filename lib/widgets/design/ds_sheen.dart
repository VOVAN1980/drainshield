import 'package:flutter/material.dart';

/// A moving sheen/shimmer overlay that sweeps diagonally across [child].
/// The animation loops automatically on a [duration] period.
/// Wrap any widget (typically a gradient button) with this to get the
/// subtle moving-highlight effect.
class DsSheen extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const DsSheen({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 3000),
  });

  @override
  State<DsSheen> createState() => _DsSheenState();
}

class _DsSheenState extends State<DsSheen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        // Sweep the highlight from left-off-screen to right-off-screen.
        final t = _anim.value; // 0.0 → 1.0
        final start = Alignment(-2.5 + t * 5.0, -1.0);
        final end = Alignment(-1.5 + t * 5.0, 1.0);

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: start,
            end: end,
            colors: const [
              Color(0x00FFFFFF),
              Color(0x22FFFFFF),
              Color(0x44FFFFFF),
              Color(0x22FFFFFF),
              Color(0x00FFFFFF),
            ],
            stops: const [0.0, 0.35, 0.50, 0.65, 1.0],
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
