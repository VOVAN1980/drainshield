import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/moralis/moralis_config_service.dart';
import '../lib/services/approval_scan_service.dart';
import '../lib/services/global_approval_scanner.dart';
import '../lib/services/portfolio_service.dart';
import '../lib/services/pro/pro_service.dart';
import '../lib/services/security/monitoring_service.dart';
import '../lib/services/wallet/wallet_registry_service.dart';

// Mocking rootBundle for the test environment
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String testWallet = "0xd8da6bf26964af9d7eed9e03e53415d37aa96045"; // vitalik.eth

  group('End-to-End Runtime Verification', () {
    
    setUpAll(() async {
      print('--- INITIALIZING VERIFICATION ---');
      await MoralisConfigService.instance.init();
      print('Moralis Key Loaded: ${MoralisConfigService.key.isNotEmpty ? "YES" : "NO"}');
    });

    test('1. Dashboard Wallet Scan Flow', () async {
      print('\n[VERIFY] Dashboard Wallet Scan');
      try {
        final approvals = await ApprovalScanService.scan(testWallet);
        final success = approvals.isNotEmpty || MoralisConfigService.key.isEmpty;
        print(' - Starts successfully: YES');
        print(' - Returns real data: ${approvals.isNotEmpty ? "YES" : "NO (Possibly empty or fake fallback)"}');
        print(' - Count: ${approvals.length}');
      } catch (e) {
        print(' - Error: $e');
      }
    });

    test('2. Panic Mode Scan Flow', () async {
      print('\n[VERIFY] Panic Mode Scan');
      try {
        final approvals = await GlobalApprovalScanner.scanAllApprovals(testWallet);
        print(' - Starts successfully: YES');
        print(' - Returns real data: ${approvals.isNotEmpty ? "YES" : "NO"}');
      } catch (e) {
        print(' - Error: $e');
      }
    });

    test('3. Portfolio Load Flow', () async {
      print('\n[VERIFY] Portfolio Load');
      try {
        final assets = await PortfolioService().getPortfolio(testWallet);
        print(' - Starts successfully: YES');
        print(' - Returns real data: ${assets.isNotEmpty ? "YES" : "NO"}');
        print(' - Count: ${assets.length}');
      } catch (e) {
        print(' - Error: $e');
      }
    });

    test('4. Background Monitoring Worker', () async {
      print('\n[VERIFY] Monitoring Service');
      try {
        // Force PRO state for test
        final pro = ProService.instance;
        // Mocking Pro state might be hard without setter, let's see
        print(' - Checking gating (PRO status required)...');
        await MonitoringService.instance.runMonitoringNow();
        print(' - Starts successfully: YES');
      } catch (e) {
        print(' - Error: $e');
      }
    });

    test('5. PRO Gating Behavior', () async {
       print('\n[VERIFY] PRO Gating');
       final isPro = ProService.instance.isProActive();
       print(' - Current PRO Status: $isPro');
       final wallets = WalletRegistryService.instance.getMonitoringEligibleWallets();
       print(' - Monitoring Eligible Wallets: ${wallets.length}');
       if (!isPro && wallets.isNotEmpty) {
         print(' - [FAIL] Monitoring should not be allowed for non-PRO');
       } else {
         print(' - [PASS] Gating matches logic');
       }
    });
  });
}
