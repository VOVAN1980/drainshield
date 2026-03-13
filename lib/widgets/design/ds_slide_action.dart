import 'package:flutter/material.dart';

class DsSlideAction extends StatefulWidget {
  final VoidCallback? onAction;
  final String label;

  const DsSlideAction({super.key, this.onAction, required this.label});

  @override
  State<DsSlideAction> createState() => _DsSlideActionState();
}

class _DsSlideActionState extends State<DsSlideAction> {
  double _dragValue = 0.0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onAction != null;

    // Premium red tones for urgency
    const Color activeRed = Color(0xFFFF3B30);
    const Color deepRed = Color(0xFFA50000);
    final Color color = isEnabled ? activeRed : Colors.white24;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double containerWidth = constraints.maxWidth;
        const double thumbWidth = 60.0;
        final double maxDrag = containerWidth - thumbWidth - 4;

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(isEnabled ? 0.08 : 0.03),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: color.withOpacity(isEnabled ? 0.15 : 0.05),
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Center label tracking
              Center(
                child: Opacity(
                  opacity: _dragValue > 20 ? 0.2 : 1.0,
                  child: Text(
                    widget.label.toUpperCase(),
                    style: TextStyle(
                      color: isEnabled ? Colors.white70 : Colors.white24,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              // Sliding thumb
              Positioned(
                left: 2 + _dragValue,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (!isEnabled || _completed) return;
                    setState(() {
                      _dragValue += details.delta.dx;
                      if (_dragValue < 0) _dragValue = 0;
                      if (_dragValue >= maxDrag) {
                        _dragValue = maxDrag;
                        _completed = true;
                        widget.onAction?.call();

                        Future.delayed(const Duration(milliseconds: 1000), () {
                          if (mounted) {
                            setState(() {
                              _dragValue = 0;
                              _completed = false;
                            });
                          }
                        });
                      }
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (!isEnabled) return;
                    if (!_completed) {
                      setState(() {
                        _dragValue = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: thumbWidth,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: isEnabled
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [activeRed, deepRed],
                            )
                          : null,
                      color: !isEnabled ? Colors.white10 : null,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: isEnabled
                          ? [
                              BoxShadow(
                                color: activeRed.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: const Icon(
                      Icons.keyboard_double_arrow_right,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
