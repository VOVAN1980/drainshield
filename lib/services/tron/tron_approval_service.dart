import 'package:flutter/foundation.dart';
import '../../rpc/tron_rpc.dart';
import '../../models/approval.dart';

/// Scans Tron TRC20 tokens for active allowances (approvals).
///
/// Strategy:
/// 1. Discover spender candidates via TronGrid Approval events
/// 2. For each candidate, verify with `getAllowance(owner, spender, token)`
/// 3. Only `allowance > 0` becomes an active risk in RiskEngine
class TronApprovalService {
  /// Known TRC20 contracts to scan for approvals.
  /// These are the most commonly used tokens on Tron.
  static const List<String> _scanTargetContracts = [
    'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t', // USDT (99% of Tron scams)
    'TEkxiTehnzSmSe2XqrBj4w32RUN966rdz8', // USDC
  ];

  /// Scans Tron wallet for active TRC20 allowances.
  ///
  /// Returns [ApprovalData] for every token+spender pair where allowance > 0.
  static Future<List<ApprovalData>> scan(
    String walletAddress, {
    TronHttpRpcClient? rpcClient,
  }) async {
    final scanStart = DateTime.now();
    debugPrint(
        '[TronScan] ▶ START | addr=${walletAddress.substring(0, 8)}... | targets=${_scanTargetContracts.length}');
    final client = rpcClient ?? TronHttpRpcClient.shared;

    final results = <ApprovalData>[];
    bool hadEventFailure = false;

    // Step 1: Discover spender candidates from Approval events
    final spenderCandidates = <_SpenderCandidate>[];

    for (final contract in _scanTargetContracts) {
      final contractStart = DateTime.now();
      final tokenInfo = TronHttpRpcClient.knownTokens[contract];
      final label = tokenInfo?.symbol ?? contract.substring(0, 8);
      try {
        final eventResult = await client.getApprovalEvents(
          contractAddress: contract,
          ownerAddress: walletAddress,
        );
        final ms = DateTime.now().difference(contractStart).inMilliseconds;

        if (!eventResult.isOk) {
          debugPrint(
              '[TronScan] ⚠️ $label events partial (${ms}ms): ${eventResult.errorMessage}');
          hadEventFailure = true;
          continue;
        }

        debugPrint(
            '[TronScan] ✅ $label events OK (${ms}ms) | events=${eventResult.events.length}');

        for (final event in eventResult.events) {
          final spender = event['spender']?.toString() ?? '';
          if (spender.isEmpty) continue;

          // Deduplicate
          final exists = spenderCandidates.any(
            (c) =>
                c.tokenContract == contract &&
                c.spenderAddress.toLowerCase() == spender.toLowerCase(),
          );
          if (!exists) {
            spenderCandidates.add(_SpenderCandidate(
              tokenContract: contract,
              spenderAddress: spender,
            ));
          }
        }
      } catch (e) {
        final ms = DateTime.now().difference(contractStart).inMilliseconds;
        debugPrint('[TronScan] ❌ $label events FAILED (${ms}ms): $e');
        hadEventFailure = true;
      }
    }

    debugPrint(
        '[TronScan] 📋 Found ${spenderCandidates.length} spender candidates');

    if (hadEventFailure) {
      debugPrint('[TronScan] ⚠️ Partial scan — some event queries failed');
    }

    // Step 2: Verify each candidate with getAllowance()
    for (int i = 0; i < spenderCandidates.length; i++) {
      final candidate = spenderCandidates[i];
      final checkStart = DateTime.now();
      try {
        final allowance = await client.getAllowance(
          ownerAddress: walletAddress,
          spenderAddress: candidate.spenderAddress,
          tokenContract: candidate.tokenContract,
        );
        final ms = DateTime.now().difference(checkStart).inMilliseconds;

        if (allowance > BigInt.zero) {
          debugPrint(
              '[TronScan] 🚨 ACTIVE allowance #${i + 1} (${ms}ms): ${_shortAddress(candidate.spenderAddress)} → allowance=$allowance');
          final tokenInfo =
              TronHttpRpcClient.knownTokens[candidate.tokenContract];

          results.add(ApprovalData(
            chainId: 0,
            chainType: 'tron',
            token: candidate.tokenContract,
            tokenName: tokenInfo?.symbol,
            tokenSymbol: tokenInfo?.symbol,
            spenderAddress: candidate.spenderAddress,
            spender: _shortAddress(candidate.spenderAddress),
            allowance: allowance,
            decimals: tokenInfo?.decimals ?? 18,
            walletAddress: walletAddress,
          ));
        } else {
          debugPrint('[TronScan] ✓ Allowance #${i + 1} clean (${ms}ms)');
        }
      } catch (e) {
        final ms = DateTime.now().difference(checkStart).inMilliseconds;
        debugPrint(
            '[TronScan] ❌ Allowance check #${i + 1} FAILED (${ms}ms): $e');
      }
    }

    final totalMs = DateTime.now().difference(scanStart).inMilliseconds;
    debugPrint(
        '[TronScan] ⏹ DONE in ${totalMs}ms | active_approvals=${results.length}');

    if (hadEventFailure && results.isEmpty) {
      throw StateError(
        'TRON scan incomplete: event discovery failed for one or more '
        'contracts. Cannot confirm wallet is clean.',
      );
    }

    return results;
  }

  static String _shortAddress(String addr) {
    if (addr.length < 10) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }
}

class _SpenderCandidate {
  final String tokenContract;
  final String spenderAddress;

  const _SpenderCandidate({
    required this.tokenContract,
    required this.spenderAddress,
  });
}
