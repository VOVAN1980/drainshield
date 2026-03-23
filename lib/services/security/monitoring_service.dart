import 'package:flutter/foundation.dart';
import '../../models/security_event.dart';

import '../settings/settings_service.dart';
import '../pro/pro_service.dart';
import '../wallet/wallet_registry_service.dart';
import '../approval_scan_service.dart';
import 'security_event_service.dart';
import 'monitoring_state_service.dart';
import '../../config/chains.dart';

import 'package:workmanager/workmanager.dart';

class MonitoringService {
  static final MonitoringService instance = MonitoringService._internal();
  MonitoringService._internal();

  static const String _backgroundTaskName = 'drainshield_background_monitoring';
  bool _isInitialized = false;
  bool _isChecking = false;

  // No longer needed here as it's persisted in MonitoringStateService
  // final Map<String, Set<String>> _lastRisks = {};

  Future<void> init() async {
    if (_isInitialized) return;
    await MonitoringStateService.instance.init();
    _isInitialized = true;

    // Schedule background tasks on init
    await scheduleBackgroundTask();

    // Re-schedule when PRO status or settings change
    ProService.instance.addListener(() => scheduleBackgroundTask());
    SettingsService.instance.addListener(() => scheduleBackgroundTask());
  }

  Future<void> scheduleBackgroundTask() async {
    bool isPro = true; // Bypassed for review
    final settings = SettingsService.instance.settings;

    if (!isPro || !settings.autoMonitoringEnabled) {
      await Workmanager().cancelByUniqueName(_backgroundTaskName);
      debugPrint('[MonitoringService] Background tasks cancelled');
      return;
    }

    // WorkManager minimum periodic frequency is 15 minutes
    final interval =
        Duration(minutes: settings.monitoringIntervalMinutes.clamp(15, 1440));

    await Workmanager().registerPeriodicTask(
      _backgroundTaskName,
      'periodic_check',
      frequency: interval,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    // Update next scan time (rough estimate based on now + interval)
    await MonitoringStateService.instance.updateScanTimestamps(
      MonitoringStateService.instance.lastScanTime ?? DateTime.now(),
      DateTime.now().add(interval),
    );

    debugPrint(
        '[MonitoringService] Background tasks scheduled every ${interval.inMinutes} mins');
  }

  Future<void> runMonitoringNow() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      /*
      if (!ProService.instance.isProActive()) {
        debugPrint(
            '[MonitoringService] Skip: Subscription not active (PRO-only feature)');
        return;
      }
      */

      final settings = SettingsService.instance.settings;
      if (!settings.autoMonitoringEnabled && !kDebugMode) {
        debugPrint('[MonitoringService] Skip: Auto-monitoring disabled');
        return;
      }

      final wallets =
          WalletRegistryService.instance.getMonitoringEligibleWallets();
      if (wallets.isEmpty) {
        debugPrint(
            '[MonitoringService] Skip: No monitoring-eligible wallets found');
        return;
      }

      debugPrint(
          '[MonitoringService] Starting check for ${wallets.length} wallets');

      for (final wallet in wallets) {
        await _runWalletCheck(wallet.address);
      }

      // Update last scan time after successful run
      final nextScan = DateTime.now().add(Duration(
          minutes: SettingsService.instance.settings.monitoringIntervalMinutes
              .clamp(15, 1440)));
      await MonitoringStateService.instance
          .updateScanTimestamps(DateTime.now(), nextScan);
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _runWalletCheck(String address) async {
    final allRiskyKeys = <String>{};
    final supportedChains = [1, 56, 137, 42161, 10, 8453];

    for (final chainId in supportedChains) {
      try {
        final chainName = ChainConfig.getChainName(chainId);
        // debugPrint('[Monitoring] Checking $address on $chainName...');

        final approvals =
            await ApprovalScanService.scan(address, chainId: chainId);

        // Filter risky ones
        final riskyApprovals =
            approvals.where((a) => a.assessment.shouldRevoke).toList();

        for (final a in riskyApprovals) {
          allRiskyKeys.add("${chainId}_${a.spenderAddress}_${a.token}");
        }

        // Detect NEW risks using persisted state
        final newRisks = riskyApprovals.where((a) {
          return MonitoringStateService.instance.isNewRisk(
            address,
            a.spenderAddress,
            a.token,
            chainId,
          );
        }).toList();

        if (newRisks.isNotEmpty) {
          for (final risk in newRisks) {
            final title = 'High Risk Detected ($chainName)';
            final message =
                'Suspicious approval for ${risk.tokenSymbol} found on $chainName.';

            SecurityEventService.instance.emit(
              SecurityEvent(
                type: SecurityEventType.highRiskApproval,
                severity: risk.assessment.score >= 90 ? 'critical' : 'high',
                timestamp: DateTime.now(),
                walletAddress: address,
                title: title,
                message: message,
                metadata: {
                  'spender': risk.spenderAddress,
                  'token': risk.token,
                  'symbol': risk.tokenSymbol,
                  'chainId': chainId,
                  'chainName': chainName,
                  'riskScore': risk.assessment.score,
                },
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('[MonitoringService] Error check on chain $chainId: $e');
      }
    }

    // Update state with CURRENT keys to detect NEW ones in next run
    await MonitoringStateService.instance.updateRisks(address, allRiskyKeys);
  }

  void stop() {
    // Cleanup logic
  }
}
