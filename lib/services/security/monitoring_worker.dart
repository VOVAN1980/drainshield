import 'package:workmanager/workmanager.dart';
import 'package:flutter/material.dart';
import '../pro/pro_service.dart';
import '../settings/settings_service.dart';
import '../wallet/wallet_registry_service.dart';
import 'monitoring_service.dart';
import 'monitoring_state_service.dart';
import '../alerts/notification_service.dart';
import '../alerts/alert_service.dart';
import '../moralis/moralis_config_service.dart';

/// The entry point for the background task.
/// It must be a top-level function and annotated with @pragma('vm:entry-point').
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('[MonitoringWorker] Background task started: $taskName');

    try {
      // 1. Initialize core logic services
      await ProService.instance.init();
      await SettingsService.instance.init();
      await WalletRegistryService.instance.init();
      await MonitoringStateService.instance.init();
      await MoralisConfigService.instance.init();

      // 2. Initialize alert infrastructure (needed to show notifications from background)
      await NotificationService.instance.init();
      await AlertService.instance.init();

      // 3. Run the scan
      // MonitoringService.runMonitoringNow() already contains gating for PRO status
      // and auto-monitoring settings.
      await MonitoringService.instance.runMonitoringNow();

      debugPrint('[MonitoringWorker] Background task completed');
      return Future.value(true);
    } catch (e) {
      debugPrint('[MonitoringWorker] Background task failed: $e');
      return Future.value(false);
    }
  });
}
