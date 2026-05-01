import 'package:flutter/foundation.dart';
import '../../rpc/tron_rpc.dart';
import '../../models/approval.dart';

/// Builds TRC20 revoke (approve(spender, 0)) transactions for Tron Panic Mode.
///
/// This service:
/// 1. Builds the unsigned `approve(spender, 0)` transaction via TronGrid
/// 2. Delegates signing to TronLink / WalletConnect-TRON wallet provider
/// 3. Broadcasts the signed transaction via TronGrid
///
/// Does NOT contain Privy/EVM raw signing. The wallet provider handles
/// all cryptographic signing.
class TronRevokeService {
  /// Builds an unsigned revoke transaction for a single TRC20 approval.
  ///
  /// The caller must sign this transaction using TronLink or
  /// WalletConnect-TRON provider, then broadcast via [broadcastSignedTx].
  static Future<TronUnsignedTransaction> buildRevokeTx({
    required ApprovalData approval,
    TronHttpRpcClient? rpcClient,
  }) async {
    if (approval.chainType != 'tron') {
      throw StateError(
          'TronRevokeService: expected chainType=tron, got ${approval.chainType}');
    }

    final ownerAddress = approval.walletAddress;
    if (ownerAddress == null || ownerAddress.isEmpty) {
      throw StateError('TronRevokeService: wallet address is required');
    }

    final client = rpcClient ?? TronHttpRpcClient.shared;

    // Build approve(spender, 0) — resets the allowance to zero
    return client.buildTrc20Approve(
      ownerAddress: ownerAddress,
      tokenContract: approval.token,
      spenderAddress: approval.spenderAddress,
      amount: BigInt.zero,
    );
  }

  /// Broadcasts a signed Tron transaction.
  ///
  /// The transaction must have been signed by the wallet provider
  /// (TronLink / WalletConnect-TRON) before calling this.
  static Future<String> broadcastSignedTx(
    TronSignedTransaction signedTx, {
    TronHttpRpcClient? rpcClient,
  }) async {
    final client = rpcClient ?? TronHttpRpcClient.shared;
    return client.broadcastTransaction(signedTx);
  }

  /// Builds revoke transactions for multiple approvals (Panic Mode batch).
  ///
  /// Returns a list of unsigned transactions, one per approval.
  /// Each must be signed individually by the wallet provider.
  static Future<List<TronUnsignedTransaction>> buildBatchRevokeTxs({
    required List<ApprovalData> approvals,
    TronHttpRpcClient? rpcClient,
  }) async {
    final client = rpcClient ?? TronHttpRpcClient.shared;

    final txs = <TronUnsignedTransaction>[];

    for (final approval in approvals) {
      try {
        final tx = await buildRevokeTx(
          approval: approval,
          rpcClient: client,
        );
        txs.add(tx);
      } catch (e) {
        debugPrint('[TronRevokeService] Failed to build revoke tx for '
            '${approval.token} -> ${approval.spenderAddress}: $e');
        // Continue building other transactions
      }
    }

    return txs;
  }
}
