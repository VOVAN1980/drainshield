import 'package:flutter/material.dart';
import '../../services/localization_service.dart';

class DsScanningFlow extends StatelessWidget {
  final String title;
  final List<String> steps;
  final int currentStepIndex; // -1 = not started, steps.length = finished
  final double progress; // 0.0 to 1.0
  final Color accentColor;

  const DsScanningFlow({
    super.key,
    required this.title,
    required this.steps,
    required this.currentStepIndex,
    required this.progress,
    this.accentColor = const Color(0xFF00FF9D),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: progress < 1.0
                      ? CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(accentColor),
                        )
                      : Icon(Icons.check_circle, color: accentColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation(accentColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocalizationProvider.of(context).t('scanProgressPercent', {
                'percent': (progress * 100).toStringAsFixed(0),
              }),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Steps List
            ...List.generate(steps.length, (index) {
              final isCompleted = index < currentStepIndex;
              final isActive = index == currentStepIndex;

              Color iconColor;
              IconData iconData;
              Color textColor;

              if (isCompleted) {
                iconColor = accentColor;
                iconData = Icons.check_circle_rounded;
                textColor = Colors.white;
              } else if (isActive) {
                iconColor = accentColor.withOpacity(0.8);
                iconData = Icons.radio_button_checked;
                textColor = Colors.white;
              } else {
                iconColor = Colors.white24;
                iconData = Icons.radio_button_unchecked;
                textColor = Colors.white38;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    isActive
                        ? Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(right: 12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: iconColor,
                            ),
                          )
                        : Icon(iconData, color: iconColor, size: 20),
                    if (!isActive) const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        steps[index],
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
