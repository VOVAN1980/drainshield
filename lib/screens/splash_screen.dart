import "package:flutter/material.dart";
import "../services/localization_service.dart";
import "dashboard_screen.dart";

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _percent;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _percent = StepTween(
      begin: 0,
      end: 100,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));

    _ctrl.forward().then((_) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardScreen(),
          transitionsBuilder: (_, a, __, c) =>
              FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _getBootText(BuildContext context, int p) {
    final loc = LocalizationProvider.of(context);
    if (p < 25) return "SYS.BOOT [ ${loc.t('splashBypass')} ]";
    if (p < 50) return "SYS.BOOT[ ${loc.t('splashConnect')} ]";
    if (p < 85) return "SYS.BOOT[ ${loc.t('splashSecure')} ]";
    return "SYS.BOOT [ ${loc.t('splashReady')} ]";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030509),
      body: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Container(
                width: 150 + (_ctrl.value * 150),
                height: 150 + (_ctrl.value * 150),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF00FF9D,
                      ).withOpacity(0.15 * _ctrl.value),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              );
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 90,
                color: Color(0xFF00FF9D),
              ),
              const SizedBox(height: 24),
              const Text(
                "DrainShield",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 60),
              AnimatedBuilder(
                animation: _percent,
                builder: (_, __) {
                  return Column(
                    children: [
                      Text(
                        "${_percent.value}%",
                        style: const TextStyle(
                          color: Color(0xFF00FF9D),
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getBootText(context, _percent.value),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
