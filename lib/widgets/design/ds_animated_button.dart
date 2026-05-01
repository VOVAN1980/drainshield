import 'package:flutter/material.dart';
import 'ds_sheen.dart';

/// A gradient button with:
///   - Moving sheen highlight (DsSheen, ~3s loop)
///   - Tap press-scale: 0.98 → 1.0 (120–150ms)
class DsAnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final BorderRadius borderRadius;
  final List<BoxShadow> boxShadow;
  final Duration sheenDuration;
  final Duration pressDuration;

  const DsAnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.gradient = const LinearGradient(
      colors: [Color(0xFF00FF9D), Color(0xFF00B8FF)],
    ),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.boxShadow = const [],
    this.sheenDuration = const Duration(milliseconds: 3000),
    this.pressDuration = const Duration(milliseconds: 130),
  });

  @override
  State<DsAnimatedButton> createState() => _DsAnimatedButtonState();
}

class _DsAnimatedButtonState extends State<DsAnimatedButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: widget.pressDuration,
      reverseDuration: widget.pressDuration,
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
    );
    // value 1.0 → scale 1.0, value 0.0 → scale 0.98
    _scaleAnim = Tween<double>(
      begin: 0.98,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _pressCtrl.reverse();
  }

  void _onTapUp(TapUpDetails _) {
    _pressCtrl.forward();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _pressCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(minWidth: 80, minHeight: 48),
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: widget.gradient,
            boxShadow: widget.boxShadow,
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: RepaintBoundary(
              child: DsSheen(
                duration: widget.sheenDuration,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
