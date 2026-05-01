import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:reown_appkit/reown_appkit.dart';

import '../../models/approval.dart';
import '../wc_service.dart';
import '../localization_service.dart';
import 'solana_revoke_service.dart';

/// Bridge between SolanaRevokeService (tx builder) and WalletConnect signing.
///
/// Flow:
///   1. Validate wallet ownership (connected address == approval address)
///   2. Fetch recent blockhash from Solana RPC
///   3. Build unsigned SPL Revoke transaction
///   4. Send to wallet via WC `solana_signTransaction`
///   5. Extract full signed transaction (NOT just signature)
///   6. Submit signed transaction to Solana RPC
///   7. Return transaction signature
///
/// Does NOT contain Privy signing, EVM logic, or swap routing.
class SolanaSigningBridge {
  static const String _chainId =
      'solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp'; // mainnet

  /// Returns true if the current WalletConnect session supports Solana signing.
  static bool canSign() => WcService().hasSolanaSigning;

  /// Returns true if the connected Solana address matches [walletAddress].
  static bool isOwner(String walletAddress) {
    final connected = WcService().solanaAddress;
    if (connected.isEmpty) return false;
    return connected == walletAddress;
  }

  /// Revokes a single SPL delegate approval.
  ///
  /// Validates:
  /// - Solana signing session exists
  /// - Connected address == approval.walletAddress
  /// - tokenAccountAddress is present
  ///
  /// Throws if wallet mismatch, not connected, or signing is rejected.
  static Future<String> revokeApproval(ApprovalData a) async {
    _assertCanSign();
    _assertOwner(a.walletAddress ?? '');

    final ownerAddress = a.walletAddress!;
    final tokenAccount = a.tokenAccountAddress;
    if (tokenAccount == null || tokenAccount.isEmpty) {
      throw StateError(
        'SolanaSigningBridge: tokenAccountAddress is required for Solana revoke. '
        'Cannot guess the token account — block the operation.',
      );
    }

    // 1. Get recent blockhash
    final blockhash = await SolanaRevokeService.getRecentBlockhash();

    // 2. Build unsigned transaction
    final unsignedTxBytes = SolanaRevokeService.buildRevokeTransaction(
      ownerAddress: ownerAddress,
      tokenAccountAddress: tokenAccount,
      recentBlockhash: blockhash,
    );

    // 3. Sign via WalletConnect — get full signed transaction
    final signedTxBase64 = await _signAndGetFullTx(unsignedTxBytes);

    // 4. Submit to Solana RPC
    final signature =
        await SolanaRevokeService.submitSignedTransaction(signedTxBase64);

    debugPrint('[SolanaSigningBridge] Revoke submitted: $signature');
    return signature;
  }

  /// Revokes multiple SPL delegates in a single batch transaction.
  ///
  /// Limited to 10 accounts per batch (Solana tx size limit).
  static Future<String> revokeBatch(List<ApprovalData> approvals) async {
    _assertCanSign();

    if (approvals.isEmpty) {
      throw StateError('SolanaSigningBridge: no approvals to revoke');
    }

    final ownerAddress = approvals.first.walletAddress;
    if (ownerAddress == null || ownerAddress.isEmpty) {
      throw StateError('SolanaSigningBridge: wallet address is required');
    }
    _assertOwner(ownerAddress);

    final tokenAccounts = <String>[];
    for (final a in approvals) {
      final ta = a.tokenAccountAddress;
      if (ta == null || ta.isEmpty) {
        debugPrint(
            '[SolanaSigningBridge] Skipping ${a.token} — no tokenAccountAddress');
        continue;
      }
      tokenAccounts.add(ta);
    }

    if (tokenAccounts.isEmpty) {
      throw StateError(
          'SolanaSigningBridge: no valid tokenAccountAddresses in batch');
    }

    // 1. Get recent blockhash
    final blockhash = await SolanaRevokeService.getRecentBlockhash();

    // 2. Build batch unsigned transaction
    final unsignedTxBytes = SolanaRevokeService.buildBatchRevokeTransaction(
      ownerAddress: ownerAddress,
      tokenAccountAddresses: tokenAccounts,
      recentBlockhash: blockhash,
    );

    // 3. Sign via WalletConnect
    final signedTxBase64 = await _signAndGetFullTx(unsignedTxBytes);

    // 4. Submit
    final signature =
        await SolanaRevokeService.submitSignedTransaction(signedTxBase64);

    debugPrint(
        '[SolanaSigningBridge] Batch revoke submitted (${tokenAccounts.length} accounts): $signature');
    return signature;
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  static void _assertCanSign() {
    final wc = WcService();
    if (!wc.hasSolanaSigning) {
      throw StateError(
          'SolanaSigningBridge: No Solana signing session available');
    }
    if (wc.modal == null || wc.modal!.session == null) {
      throw StateError('SolanaSigningBridge: WalletConnect session not active');
    }
  }

  /// Asserts that the connected Solana address matches [walletAddress].
  /// Prevents signing with the wrong wallet.
  static void _assertOwner(String walletAddress) {
    if (walletAddress.isEmpty) {
      throw StateError('SolanaSigningBridge: wallet address is required');
    }
    if (!isOwner(walletAddress)) {
      throw LocalizationService.instance.t('revokeWalletMismatch');
    }
  }

  /// Signs an unsigned Solana transaction via WalletConnect
  /// and returns the full signed transaction as base64.
  ///
  /// CRITICAL: `sendRawTransaction` expects a full signed transaction,
  /// NOT just a signature. If the wallet returns only a signature,
  /// we must assemble the full signed tx ourselves.
  static Future<String> _signAndGetFullTx(Uint8List unsignedTxBytes) async {
    final wc = WcService();
    final modal = wc.modal!;
    final session = modal.session!;

    final base64Tx = base64Encode(unsignedTxBytes);

    try {
      final result = await modal.request(
        topic: session.topic,
        chainId: _chainId,
        request: SessionRequestParams(
          method: 'solana_signTransaction',
          params: {
            'transaction': base64Tx,
          },
        ),
      );

      if (result == null) {
        throw StateError('Wallet returned null for solana_signTransaction');
      }

      // Wallet response handling — we need the FULL signed transaction.
      //
      // Case 1: Wallet returns full signed transaction as base64 string
      // Case 2: Wallet returns { transaction: "base64signedTx" }
      // Case 3: Wallet returns { signature: "base64sig" } — only the signature
      //         In this case we must assemble the signed tx ourselves.

      if (result is Map) {
        // Prefer full signed transaction if available
        final signedTx = result['transaction']?.toString();
        if (signedTx != null && signedTx.isNotEmpty) {
          return signedTx;
        }

        // If only signature returned, assemble the full signed tx
        final sigBase64 = result['signature']?.toString();
        if (sigBase64 != null && sigBase64.isNotEmpty) {
          return _assembleSignedTx(unsignedTxBytes, sigBase64);
        }
      }

      // If result is a string, check if it looks like a full transaction
      // (longer than 64 bytes when decoded = likely a full tx, not just sig)
      final resultStr = result.toString();
      try {
        final decoded = base64Decode(resultStr);
        if (decoded.length > 100) {
          // Likely a full signed transaction
          return resultStr;
        }
        // Too short — likely just a signature, assemble full tx
        return _assembleSignedTx(unsignedTxBytes, resultStr);
      } catch (_) {
        // Not valid base64, cannot proceed
        throw StateError(
            'SolanaSigningBridge: wallet returned unrecognizable signing result');
      }
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('user denied') ||
          err.contains('rejected') ||
          err.contains('cancelled')) {
        throw 'Transaction was rejected in the Solana wallet';
      }
      rethrow;
    }
  }

  /// Assembles a full signed Solana transaction from the unsigned tx bytes
  /// and a base64-encoded 64-byte signature.
  ///
  /// Solana wire format: [num_signatures(1)] [signatures(64*N)] [message]
  /// Our unsigned tx already has a 1-byte count + 64-byte zero placeholder.
  /// We replace the zero placeholder with the real signature.
  static String _assembleSignedTx(
      Uint8List unsignedTxBytes, String signatureBase64) {
    // ── Validate unsigned tx format ──────────────────────────────────────────
    // Solana legacy wire format: [num_signatures(1)] [signatures(64*N)] [message]
    // We only support single-signer (num_signatures == 1) with zero placeholder.

    if (unsignedTxBytes.length < 65) {
      throw StateError(
        'SolanaSigningBridge: unsigned tx too short (${unsignedTxBytes.length} bytes). '
        'Expected at least 65 bytes (1 count + 64 signature placeholder).',
      );
    }

    if (unsignedTxBytes[0] != 1) {
      throw StateError(
        'SolanaSigningBridge: unsupported transaction format. '
        'Expected num_signatures=1, got ${unsignedTxBytes[0]}.',
      );
    }

    // Verify the signature slot is a zero placeholder (not already signed)
    final placeholder = unsignedTxBytes.sublist(1, 65);
    if (placeholder.any((b) => b != 0)) {
      throw StateError(
        'SolanaSigningBridge: transaction already contains a non-empty '
        'signature placeholder. Cannot overwrite.',
      );
    }

    // ── Inject signature ─────────────────────────────────────────────────────

    final sigBytes = base64Decode(signatureBase64);
    if (sigBytes.length != 64) {
      throw StateError(
        'SolanaSigningBridge: expected 64-byte signature, '
        'got ${sigBytes.length} bytes. Cannot assemble signed transaction.',
      );
    }

    final signedTx = Uint8List.fromList(unsignedTxBytes);
    signedTx.setRange(1, 65, sigBytes);

    return base64Encode(signedTx);
  }
}
