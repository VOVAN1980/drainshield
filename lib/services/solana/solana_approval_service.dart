import 'package:flutter/foundation.dart';
import '../../rpc/solana_rpc.dart';
import '../../models/approval.dart';

/// Scans Solana SPL token accounts for delegate approvals.
///
/// On Solana, "approval" = delegate authority on an SPL token account.
/// If `delegatedAmount > 0` and `delegate != null`, it's an active permission
/// that a third party can use to transfer tokens on your behalf.
class SolanaApprovalService {
  /// Scans all SPL token accounts for the given wallet address
  /// and returns [ApprovalData] for every account with an active delegate.
  static Future<List<ApprovalData>> scan(
    String walletAddress, {
    SolanaHttpRpcClient? rpcClient,
  }) async {
    final client = rpcClient ??
        SolanaHttpRpcClient(
          rpcUrl: 'https://api.mainnet-beta.solana.com',
        );

    final results = <ApprovalData>[];

    try {
      final tokenAccounts = await client.getTokenAccountsByOwner(walletAddress);

      for (final account in tokenAccounts) {
        if (!account.hasDelegate) continue;

        // Map SPL delegate to ApprovalData
        results.add(ApprovalData(
          chainId: 0, // Non-EVM
          chainType: 'solana',
          token: account.mint,
          tokenName: null, // Will be enriched later if token registry exists
          tokenSymbol: null,
          tokenAccountAddress:
              account.accountAddress, // SPL token account for revoke
          spenderAddress: account.delegate!,
          spender: _shortAddress(account.delegate!),
          allowance: account.delegatedAmountRaw,
          decimals: account.decimals,
          walletAddress: walletAddress,
          // Extra Solana-specific metadata stored for revoke
        ));
      }
    } catch (e) {
      debugPrint('[SolanaApprovalService] Scan error: $e');
      rethrow;
    }

    return results;
  }

  static String _shortAddress(String addr) {
    if (addr.length < 10) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }
}
