import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/localization_service.dart';

/// Premium animated card for Link Shield on the dashboard.
///
/// Features: glassmorphism, gradient border pulse, shield icon with glow.
/// Tap navigates to the Link Shield scan screen.
class LinkShieldCard extends StatefulWidget {
  final VoidCallback? onTap;

  const LinkShieldCard({super.key, this.onTap});

  @override
  State<LinkShieldCard> createState() => _LinkShieldCardState();
}

class _LinkShieldCardState extends State<LinkShieldCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          final glowOpacity = 0.15 + (_pulseAnim.value * 0.15);
          final borderOpacity = 0.25 + (_pulseAnim.value * 0.20);

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                width: 1.5,
                color: Color.lerp(
                  const Color(0xFF00B8FF),
                  const Color(0xFF8B5CF6),
                  _pulseAnim.value,
                )!
                    .withOpacity(borderOpacity),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.04),
                  Colors.white.withOpacity(0.01),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(
                    const Color(0xFF00B8FF),
                    const Color(0xFF8B5CF6),
                    _pulseAnim.value,
                  )!
                      .withOpacity(glowOpacity),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: child!,
              ),
            ),
          );
        },
        child: Row(
          children: [
            // Shield icon with glow
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00B8FF), Color(0xFF8B5CF6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00B8FF).withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.link_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t('linkShieldTitle'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.t('linkShieldSubtitle'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow indicator
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
