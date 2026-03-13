import 'package:flutter/material.dart';

/// A one-shot entrance animation: fade-in + slight upward slide.
/// Runs once on mount (not looping). Supports [delay] for stagger effects.
class DsFadeSlide extends StatefulWidget {
  final Widget child;

  /// Delay before the animation starts.
  final Duration delay;

  /// Total animation duration (180–220ms recommended).
  final Duration duration;

  /// Vertical slide start offset (0.0–1.0 fraction of widget height).
  final double slideOffset;

  const DsFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 200),
    this.slideOffset = 0.04,
  });

  @override
  State<DsFadeSlide> createState() => _DsFadeSlideState();
}

class _DsFadeSlideState extends State<DsFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
