import 'dart:typed_data';
import '../../utils/base58.dart';
import '../../rpc/solana_rpc.dart';

// ── Well-known Solana program addresses ──────────────────────────────────────

/// SPL Token Program
final Uint8List _tokenProgramId =
    Base58.decode('TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA');

/// SPL Token Revoke instruction discriminator
const int _splRevokeDiscriminator = 5;

/// Compact-u16 encoder for Solana binary format.
Uint8List _encodeLength(int len) {
  if (len < 0x80) return Uint8List.fromList([len]);
  if (len < 0x4000) return Uint8List.fromList([len | 0x80, len >> 7]);
  return Uint8List.fromList([len | 0x80, (len >> 7) | 0x80, len >> 14]);
}

/// Builds and submits SPL Token revoke transactions for Panic Mode.
///
/// On Solana, revoking a delegate = calling the SPL Token Program's `Revoke`
/// instruction on the token account. This removes the delegate's authority
/// to transfer tokens on behalf of the owner.
///
/// Signing is done via WalletConnect `solana_signTransaction`.
/// This service does NOT use Privy or any internal signing.
class SolanaRevokeService {
  /// Builds a serialized Solana transaction that revokes the delegate
  /// on the specified SPL token account.
  ///
  /// The returned bytes are an unsigned transaction in Solana wire format.
  /// Must be signed by the wallet via WalletConnect `solana:*` namespace
  /// before submission.
  static Uint8List buildRevokeTransaction({
    required String ownerAddress,
    required String tokenAccountAddress,
    required String recentBlockhash,
  }) {
    final ownerPubkey = Base58.decode(ownerAddress);
    final tokenAccount = Base58.decode(tokenAccountAddress);
    final recentHash = Base58.decode(recentBlockhash);

    // Header: 1 signer, 0 readonly signed, 1 readonly unsigned (tokenProgram)
    final header = Uint8List.fromList([1, 0, 1]);

    // Account keys (3 total):
    // 0: owner (signer, writable)
    // 1: token account (writable)
    // 2: token program (readonly)
    const numAccounts = 3;
    final accountKeys = Uint8List(32 * numAccounts);
    accountKeys.setAll(0, ownerPubkey); // 0: owner
    accountKeys.setAll(32, tokenAccount); // 1: token account
    accountKeys.setAll(64, _tokenProgramId); // 2: token program

    // Revoke instruction data: just the discriminator byte (5)
    final instrData = Uint8List.fromList([_splRevokeDiscriminator]);

    final messageBuilder = BytesBuilder();
    messageBuilder.add(header);
    messageBuilder.add(_encodeLength(numAccounts));
    messageBuilder.add(accountKeys);
    messageBuilder.add(recentHash);
    messageBuilder.add(_encodeLength(1)); // 1 instruction

    // SPL Revoke instruction
    messageBuilder.addByte(2); // Program ID index (tokenProgram)
    messageBuilder.add(_encodeLength(2)); // 2 account indices
    messageBuilder.addByte(1); // token account (writable)
    messageBuilder.addByte(0); // owner (signer)
    messageBuilder.add(_encodeLength(instrData.length));
    messageBuilder.add(instrData);

    final messageBytes = messageBuilder.toBytes();
    final txBuilder = BytesBuilder();
    txBuilder.addByte(1); // 1 signature slot
    txBuilder.add(Uint8List(64)); // placeholder for signature
    txBuilder.add(messageBytes);
    return txBuilder.toBytes();
  }

  /// Builds a batch revoke transaction for multiple token accounts.
  ///
  /// This is used in Panic Mode to revoke all delegates in a single transaction.
  /// Limited to ~10 accounts per batch to stay within Solana tx size limits.
  static Uint8List buildBatchRevokeTransaction({
    required String ownerAddress,
    required List<String> tokenAccountAddresses,
    required String recentBlockhash,
  }) {
    if (tokenAccountAddresses.isEmpty) {
      throw StateError('No token accounts to revoke');
    }

    // Solana tx limit: ~1232 bytes. Each revoke instruction is small,
    // but we cap at 10 to be safe.
    final batch = tokenAccountAddresses.take(10).toList();

    final ownerPubkey = Base58.decode(ownerAddress);
    final recentHash = Base58.decode(recentBlockhash);

    // Account keys: owner + all token accounts + token program
    final numAccounts = 1 + batch.length + 1;

    // Header: 1 signer, 0 readonly signed, 1 readonly unsigned (tokenProgram)
    final header = Uint8List.fromList([1, 0, 1]);

    final accountKeys = Uint8List(32 * numAccounts);
    accountKeys.setAll(0, ownerPubkey); // 0: owner (signer)
    for (int i = 0; i < batch.length; i++) {
      accountKeys.setAll(32 * (1 + i), Base58.decode(batch[i]));
    }
    accountKeys.setAll(
        32 * (1 + batch.length), _tokenProgramId); // last: token program

    final tokenProgramIdx = 1 + batch.length; // index of token program

    final instrData = Uint8List.fromList([_splRevokeDiscriminator]);

    final messageBuilder = BytesBuilder();
    messageBuilder.add(header);
    messageBuilder.add(_encodeLength(numAccounts));
    messageBuilder.add(accountKeys);
    messageBuilder.add(recentHash);
    messageBuilder.add(_encodeLength(batch.length)); // N instructions

    for (int i = 0; i < batch.length; i++) {
      messageBuilder.addByte(tokenProgramIdx); // Program ID index
      messageBuilder.add(_encodeLength(2)); // 2 account indices
      messageBuilder.addByte(1 + i); // token account (writable)
      messageBuilder.addByte(0); // owner (signer)
      messageBuilder.add(_encodeLength(instrData.length));
      messageBuilder.add(instrData);
    }

    final messageBytes = messageBuilder.toBytes();
    final txBuilder = BytesBuilder();
    txBuilder.addByte(1); // 1 signature slot
    txBuilder.add(Uint8List(64)); // placeholder
    txBuilder.add(messageBytes);
    return txBuilder.toBytes();
  }

  /// Sends a signed revoke transaction and returns the signature.
  static Future<String> submitSignedTransaction(
    String base64SignedTx, {
    SolanaHttpRpcClient? rpcClient,
  }) async {
    final client = rpcClient ??
        SolanaHttpRpcClient(
          rpcUrl: 'https://api.mainnet-beta.solana.com',
        );
    return client.sendRawTransaction(base64SignedTx);
  }

  /// Gets a fresh blockhash for transaction building.
  static Future<String> getRecentBlockhash({
    SolanaHttpRpcClient? rpcClient,
  }) async {
    final client = rpcClient ??
        SolanaHttpRpcClient(
          rpcUrl: 'https://api.mainnet-beta.solana.com',
        );
    return client.getLatestBlockhash();
  }
}
