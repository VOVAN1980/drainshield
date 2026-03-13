import 'package:flutter/material.dart';

enum MascotState { safe, scan, warning, panic, portfolio, settings, pro }

class MascotImage extends StatelessWidget {
  final MascotState mascotState;
  final double width;
  final double height;

  const MascotImage({
    super.key,
    required this.mascotState,
    this.width = 160,
    this.height = 160,
  });

  String get _assetPath {
    switch (mascotState) {
      case MascotState.safe:
        return 'assets/mascot/lion_safe.png';
      case MascotState.scan:
        return 'assets/mascot/lion_scan.png';
      case MascotState.warning:
        return 'assets/mascot/lion_warning.png';
      case MascotState.panic:
        return 'assets/mascot/lion_panic.png';
      case MascotState.portfolio:
        return 'assets/mascot/lion_portfolio.png';
      case MascotState.settings:
        return 'assets/mascot/lion_settings.png';
      case MascotState.pro:
        return 'assets/mascot/lion_pro.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        _assetPath,
        fit: BoxFit.contain,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.white10,
            child: const Icon(Icons.pets, color: Colors.white54),
          );
        },
      ),
    );
  }
}
