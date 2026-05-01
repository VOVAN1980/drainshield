import 'package:flutter/foundation.dart';
import 'package:reown_appkit/reown_appkit.dart';

import '../../models/approval.dart';
import '../../rpc/tron_rpc.dart';
import '../wc_service.dart';
import '../localization_service.dart';
import 'tron_revoke_service.dart';

/// Bridge between TronRevokeService (tx builder) and WalletConnect signing.
///
/// Flow:
///   1. Validate wallet ownership (connected address == approval address)
///   2. Build unsigned TRC20 approve(spender, 0) via TronGrid
///   3. Send unsigned tx to wallet via WC `tron_signTransaction`
///   4. Receive signature from wallet
///   5. Assemble TronSignedTransaction
///   6. Broadcast via TronGrid
///   7. Return txId
///
/// Does NOT contain Privy signing, EVM logic, or swap routing.
class TronSigningBridge {
  static const String _chainId = 'tron:0x2b6653dc'; // Tron Mainnet

  /// Returns true if the current WalletConnect session supports Tron signing.
  static bool canSign() => WcService().hasTronSigning;

  /// Returns true if the connected Tron address matches [walletAddress].
  static bool isOwner(String walletAddress) {
    final connected = WcService().tronAddress;
    if (connected.isEmpty) return false;
    return connected == walletAddress;
  }

  /// Revokes a single TRC20 approval by sending approve(spender, 0).
  ///
  /// Validates:
  /// - Tron signing session exists
  /// - Connected address == approval.walletAddress
  ///
  /// Throws if wallet mismatch, not connected, or signing is rejected.
  static Future<String> revokeApproval(ApprovalData a) async {
    _assertCanSign();
    _assertOwner(a.walletAddress ?? '');

    // 1. Build unsigned transaction via TronGrid
    final unsignedTx = await TronRevokeService.buildRevokeTx(approval: a);

    // 2. Sign via WalletConnect
    final signatureHex = await _signTransaction(unsignedTx);

    // 3. Assemble signed transaction
    final signedTx = TronSignedTransaction(
      rawData: unsignedTx.rawData,
      txId: unsignedTx.txId,
      rawDataHex: unsignedTx.rawDataHex,
      signaturesHex: [signatureHex],
    );

    // 4. Broadcast via TronGrid
    final txId = await TronRevokeService.broadcastSignedTx(signedTx);

    debugPrint('[TronSigningBridge] Revoke broadcast: $txId');
    return txId;
  }

  /// Revokes multiple TRC20 approvals sequentially.
  ///
  /// Unlike Solana, Tron does not support batch transactions.
  /// Each approval requires a separate sign + broadcast cycle.
  /// Returns list of successful txIds.
  static Future<List<String>> revokeBatch(List<ApprovalData> approvals) async {
    _assertCanSign();

    if (approvals.isNotEmpty) {
      _assertOwner(approvals.first.walletAddress ?? '');
    }

    final txIds = <String>[];

    for (final approval in approvals) {
      try {
        final txId = await revokeApproval(approval);
        txIds.add(txId);
      } catch (e) {
        debugPrint(
            '[TronSigningBridge] Batch revoke failed for ${approval.token}: $e');
        // Continue with other approvals — don't break the batch
      }
    }

    return txIds;
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  static void _assertCanSign() {
    final wc = WcService();
    if (!wc.hasTronSigning) {
      throw StateError('TronSigningBridge: No Tron signing session available');
    }
    if (wc.modal == null || wc.modal!.session == null) {
      throw StateError('TronSigningBridge: WalletConnect session not active');
    }
  }

  /// Asserts that the connected Tron address matches [walletAddress].
  /// Prevents signing with the wrong wallet.
  static void _assertOwner(String walletAddress) {
    if (walletAddress.isEmpty) {
      throw StateError('TronSigningBridge: wallet address is required');
    }
    if (!isOwner(walletAddress)) {
      throw LocalizationService.instance.t('revokeWalletMismatch');
    }
  }

  /// Signs an unsigned Tron transaction via WalletConnect.
  ///
  /// Sends the raw_data to the wallet, receives back a hex signature.
  static Future<String> _signTransaction(
      TronUnsignedTransaction unsignedTx) async {
    final wc = WcService();
    final modal = wc.modal!;
    final session = modal.session!;

    try {
      final result = await modal.request(
        topic: session.topic,
        chainId: _chainId,
        request: SessionRequestParams(
          method: 'tron_signTransaction',
          params: {
            'transaction': {
              'txID': unsignedTx.txId,
              'raw_data': unsignedTx.rawData,
              'raw_data_hex': unsignedTx.rawDataHex,
            },
          },
        ),
      );

      if (result == null) {
        throw StateError('Wallet returned null for tron_signTransaction');
      }

      // Extract signature from wallet response.
      // Standard WalletConnect Tron: { signature: ["hexSig"] }
      if (result is Map) {
        final sigList = result['signature'];
        if (sigList is List && sigList.isNotEmpty) {
          return sigList.first.toString();
        }
        if (sigList is String && sigList.isNotEmpty) {
          return sigList;
        }
      }

      // Fallback: treat result as raw signature string
      final sigStr = result.toString();
      if (sigStr.isEmpty) {
        throw StateError(
            'TronSigningBridge: wallet returned empty signing result');
      }
      return sigStr;
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('user denied') ||
          err.contains('rejected') ||
          err.contains('cancelled')) {
        throw 'Transaction was rejected in the Tron wallet';
      }
      rethrow;
    }
  }
}
