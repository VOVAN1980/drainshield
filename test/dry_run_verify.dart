import 'package:drainshield_app/services/moralis/moralis_config_service.dart';
import 'package:drainshield_app/services/approval_scan_service.dart';
import 'package:drainshield_app/services/global_approval_scanner.dart';
import 'package:drainshield_app/services/portfolio_service.dart';

// This script runs in pure Dart to verify Moralis connectivity and logic
void main() async {
  print('--- DRAINSHIELD DRY-RUN VERIFICATION ---');

  // 1. Verify Config
  print('\n[1/5] Verifying MoralisConfigService...');
  final config = MoralisConfigService.instance;
  // Initialize via File (pure Dart environment)
  await config.init();
  print(' - API Key detected: ${config.apiKey.isNotEmpty ? "YES" : "NO"}');
  print(' - API Key length: ${config.apiKey.length}');
  print(' - Default Chain: ${config.defaultChain}');

  if (config.apiKey.isEmpty) {
    print(
        ' ! WARNING: Moralis API Key is missing. Scanning will use FAKE mode.');
  }

  const String testWallet = "0xd8da6bf26964af9d7eed9e03e53415d37aa96045";

  // 2. Test ApprovalScanService
  print('\n[2/5] Testing ApprovalScanService.scan()...');
  try {
    final approvals = await ApprovalScanService.scan(testWallet);
    print(' - Success: YES');
    print(' - Count: ${approvals.length}');
    if (approvals.isNotEmpty) {
      print(
          ' - First Approval: ${approvals[0].token} (Spender: ${approvals[0].spender})');
      print(
          ' - Risk Assessment: ${approvals[0].assessment.label.name} (${approvals[0].assessment.score})');
    }
  } catch (e) {
    print(' - Error: $e');
  }

  // 3. Test GlobalApprovalScanner
  print('\n[3/5] Testing GlobalApprovalScanner.scanAllApprovals()...');
  try {
    final globalResults =
        await GlobalApprovalScanner.scanAllApprovals(testWallet);
    print(' - Success: YES');
    print(' - Count: ${globalResults.length}');
  } catch (e) {
    print(' - Error: $e');
  }

  // 4. Test PortfolioService
  print('\n[4/5] Testing PortfolioService.getPortfolio()...');
  try {
    final assets = await PortfolioService().getPortfolio(testWallet);
    print(' - Success: YES');
    print(' - Count: ${assets.length}');
    if (assets.isNotEmpty) {
      print(
          ' - Top Asset: ${assets[0].name} (${assets[0].balance} ${assets[0].symbol})');
      print(' - Value USD: \$${assets[0].valueUsd.toStringAsFixed(2)}');
    }
  } catch (e) {
    print(' - Error: $e');
  }

  // 5. Verification Summary
  print('\n--- VERIFICATION COMPLETE ---');
}
