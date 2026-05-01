import 'dart:convert';
import 'package:http/http.dart' as http;

class SolanaRpcException implements Exception {
  final String message;
  const SolanaRpcException(this.message);

  @override
  String toString() => 'SolanaRpcException: $message';
}

/// Minimal Solana JSON-RPC client for DrainShield scanning.
///
/// Supports: balance queries, SPL token account enumeration,
/// transaction submission (for Panic Mode revoke), and blockhash fetching.
///
/// Does NOT include: swap, send, Privy, or execution routing.
class SolanaHttpRpcClient {
  final String rpcUrl;
  final http.Client _http;

  SolanaHttpRpcClient({
    this.rpcUrl = 'https://api.mainnet-beta.solana.com',
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  Future<Map<String, dynamic>> _post(
      String method, List<dynamic> params) async {
    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': 1,
      'method': method,
      'params': params,
    });

    final res = await _http
        .post(
          Uri.parse(rpcUrl),
          headers: const {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw SolanaRpcException('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;

    if (decoded['error'] != null) {
      throw SolanaRpcException(
        'RPC error: ${jsonEncode(decoded["error"])}',
      );
    }

    return decoded;
  }

  /// Returns SOL balance in lamports.
  Future<BigInt> getBalanceLamports(String address) async {
    final json = await _post('getBalance', [
      address,
      {'commitment': 'confirmed'}
    ]);

    final value = json['result']?['value'];
    if (value is! num) {
      throw const SolanaRpcException('Invalid getBalance response');
    }

    return BigInt.from(value);
  }

  /// Returns the latest blockhash (needed for transaction building).
  Future<String> getLatestBlockhash() async {
    final json = await _post('getLatestBlockhash', [
      {'commitment': 'confirmed'}
    ]);

    final blockhash = json['result']?['value']?['blockhash'];
    if (blockhash is! String || blockhash.isEmpty) {
      throw const SolanaRpcException('Invalid getLatestBlockhash response');
    }

    return blockhash;
  }

  /// Sends a signed transaction (base64 encoded) to the network.
  Future<String> sendRawTransaction(String base64Transaction) async {
    final json = await _post('sendTransaction', [
      base64Transaction,
      {
        'encoding': 'base64',
        'skipPreflight': false,
        'preflightCommitment': 'confirmed',
        'maxRetries': 3,
      }
    ]);

    final signature = json['result'];
    if (signature is! String || signature.isEmpty) {
      throw const SolanaRpcException('Invalid sendTransaction response');
    }

    return signature;
  }

  /// Fetches all SPL token accounts owned by [ownerAddress].
  ///
  /// Returns parsed token account data including delegate info
  /// which is critical for DrainShield security scanning.
  Future<List<SplTokenAccount>> getTokenAccountsByOwner(
      String ownerAddress) async {
    final json = await _post('getTokenAccountsByOwner', [
      ownerAddress,
      {'programId': 'TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA'},
      {
        'encoding': 'jsonParsed',
        'commitment': 'confirmed',
      }
    ]);

    final accounts = json['result']?['value'] as List<dynamic>? ?? [];
    final result = <SplTokenAccount>[];

    for (final account in accounts) {
      try {
        final parsed = account['account']?['data']?['parsed']?['info'];
        if (parsed == null) continue;

        final mint = parsed['mint'] as String? ?? '';
        final tokenAmount = parsed['tokenAmount'];
        if (tokenAmount == null || mint.isEmpty) continue;

        final uiAmount = (tokenAmount['uiAmount'] as num?)?.toDouble() ?? 0.0;
        final decimals = (tokenAmount['decimals'] as num?)?.toInt() ?? 0;
        final rawAmount = tokenAmount['amount'] as String? ?? '0';

        // Extract delegate info — this is what DrainShield scans for
        final delegate = parsed['delegate'] as String?;
        final delegatedAmountData = parsed['delegatedAmount'];
        final delegatedAmount = delegatedAmountData != null
            ? (delegatedAmountData['uiAmount'] as num?)?.toDouble() ?? 0.0
            : 0.0;
        final delegatedAmountRaw = delegatedAmountData != null
            ? delegatedAmountData['amount'] as String? ?? '0'
            : '0';

        result.add(SplTokenAccount(
          mint: mint,
          balance: uiAmount,
          rawAmount: BigInt.tryParse(rawAmount) ?? BigInt.zero,
          decimals: decimals,
          accountAddress: account['pubkey'] as String? ?? '',
          delegate: delegate,
          delegatedAmount: delegatedAmount,
          delegatedAmountRaw:
              BigInt.tryParse(delegatedAmountRaw) ?? BigInt.zero,
        ));
      } catch (_) {
        // Skip malformed accounts
      }
    }

    return result;
  }
}

/// Represents a single SPL token account with its balance and delegate info.
class SplTokenAccount {
  final String mint;
  final double balance;
  final BigInt rawAmount;
  final int decimals;
  final String accountAddress;

  /// The delegate address (if any). A non-null delegate = approval risk.
  final String? delegate;

  /// The amount delegated to the delegate.
  final double delegatedAmount;
  final BigInt delegatedAmountRaw;

  SplTokenAccount({
    required this.mint,
    required this.balance,
    required this.rawAmount,
    required this.decimals,
    required this.accountAddress,
    this.delegate,
    this.delegatedAmount = 0.0,
    BigInt? delegatedAmountRaw,
  }) : delegatedAmountRaw = delegatedAmountRaw ?? BigInt.zero;

  /// Returns true if this token account has an active delegate (approval risk).
  bool get hasDelegate => delegate != null && delegate!.isNotEmpty;

  @override
  String toString() =>
      'SplTokenAccount(mint: $mint, balance: $balance, delegate: $delegate)';
}
