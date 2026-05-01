import "package:flutter/material.dart";
import "dashboard_screen.dart";
import "../services/pro/pro_service.dart";
import "../services/settings/settings_service.dart";
import "../services/wallet/wallet_registry_service.dart";
import "../services/pro/billing_service.dart";
import "../services/alerts/notification_service.dart";
import "../services/alerts/sound_service.dart";
import "../services/alerts/alert_service.dart";
import "../services/security/monitoring_service.dart";
import "../services/threat_intelligence_service.dart";
import "../services/security/system_health_service.dart";
import "package:workmanager/workmanager.dart";
import "../services/security/monitoring_worker.dart";
import "../services/moralis/moralis_config_service.dart";
import "../services/security/security_event_service.dart";
import "package:flutter/foundation.dart";

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _breathController;
  String _statusMessage = "Initializing...";
  double _loadProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _startInitialization();
  }

  Future<void> _startInitialization() async {
    final steps = [
      () => _initStep("Core Security", () => ProService.instance.init()),
      () => _initStep("User Settings", () => SettingsService.instance.init()),
      () => _initStep(
          "Wallet Registry", () => WalletRegistryService.instance.init()),
      () => _initStep("Threat Intelligence",
          () => ThreatIntelligenceService.instance.init()),
      () => _initStep("Billing & PRO", () => BillingService.instance.init()),
      () => _initStep(
          "Notification System", () => NotificationService.instance.init()),
      () => _initStep("Audio Modules", () => SoundService.instance.init()),
      () => _initStep("Alert Engine", () => AlertService.instance.init()),
      () => _initStep(
          "Monitoring Service", () => MonitoringService.instance.init()),
      () => _initStep("Background Tasks", () async {
            await Workmanager()
                .initialize(callbackDispatcher, isInDebugMode: kDebugMode);
          }),
      () => _initStep(
          "Moralis Engine", () => MoralisConfigService.instance.init()),
      () => _initStep(
          "Security Logs", () => SecurityEventService.instance.init()),
      () =>
          _initStep("System Health", () => SystemHealthService.instance.init()),
      () => Future.delayed(const Duration(milliseconds: 500)),
    ];

    for (int i = 0; i < steps.length; i++) {
      await steps[i]();
      if (mounted) {
        setState(() {
          _loadProgress = (i + 1) / steps.length;
        });
        _progressController.animateTo(_loadProgress);
      }
    }

    if (mounted) {
      // Small buffer for smooth transition
      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  Future<void> _initStep(String msg, Future<void> Function() action) async {
    if (mounted) setState(() => _statusMessage = msg);
    debugPrint("[Boot] Starting step: $msg");
    final stopwatch = Stopwatch()..start();

    try {
      await action().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint(
              "[Boot] TIMEOUT on step: $msg (after ${stopwatch.elapsed.inSeconds}s)");
        },
      );
      debugPrint(
          "[Boot] Finished step: $msg (${stopwatch.elapsed.inMilliseconds}ms)");
    } catch (e) {
      debugPrint("[Boot] ERROR on step: $msg: $e");
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070B),
      body: AnimatedBuilder(
        animation: Listenable.merge([_progressController, _breathController]),
        builder: (_, __) {
          final p = _progressController.value;
          final percent = (p * 100).clamp(0, 100).toInt();

          // Плавное дыхание, без дерганий layout
          final t = Curves.easeInOut.transform(_breathController.value);
          final scale = 1.0 + (0.06 * t);

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // щит чуть выше
                Transform.translate(
                  offset: const Offset(0, -110),
                  child: Transform.scale(
                    scale: scale,
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Image.asset(
                        "assets/logo/shield.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // полоса и %
                Transform.translate(
                  offset: const Offset(0, -120),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 380,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Stack(
                            children: [
                              Container(height: 8, color: Colors.white12),
                              FractionallySizedBox(
                                widthFactor: p,
                                child: Container(
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFFB300),
                                        Color(0xFFFFD25A),
                                        Color(0xFFFFF2B0),
                                        Color(0xFFFFC84A),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$percent%",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _statusMessage.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
