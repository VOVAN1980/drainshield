import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// Exception
// ─────────────────────────────────────────────────────────────────────────────

class TronRpcException implements Exception {
  final String message;
  const TronRpcException(this.message);

  @override
  String toString() => 'TronRpcException: $message';
}

// ─────────────────────────────────────────────────────────────────────────────
// Transaction models
// ─────────────────────────────────────────────────────────────────────────────

/// Unsigned Tron transaction ready for wallet signing.
class TronUnsignedTransaction {
  final Map<String, dynamic> rawData;
  final String txId;
  final String rawDataHex;

  const TronUnsignedTransaction({
    required this.rawData,
    required this.txId,
    required this.rawDataHex,
  });
}

/// Signed Tron transaction ready for broadcast.
class TronSignedTransaction {
  final Map<String, dynamic> rawData;
  final String txId;
  final String rawDataHex;
  final List<String> signaturesHex;
  final bool visible;

  const TronSignedTransaction({
    required this.rawData,
    required this.txId,
    required this.rawDataHex,
    required this.signaturesHex,
    this.visible = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'txID': txId,
      'raw_data': rawData,
      'raw_data_hex': rawDataHex,
      'signature': signaturesHex,
      'visible': visible,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TronHttpRpcClient — production-grade with queue, dedup, retry, config
// ─────────────────────────────────────────────────────────────────────────────

/// TronGrid HTTP RPC client for DrainShield scanning and Panic revoke.
///
/// Architecture:
/// - **Global serial queue**: all HTTP requests go through `_enqueue()`.
///   No two Tron HTTP requests ever fly in parallel, regardless of how many
///   services/screens call concurrently.
/// - **In-flight deduplication**: identical read-only requests (same key)
///   while in-flight return the same Future instead of making a duplicate call.
/// - **429 retry with backoff**: on HTTP 429, waits the server-specified
///   suspension time (or 6s default) and retries up to 2 times.
/// - **Provider config**: base URL and API key via `--dart-define`.
///
/// Signing is handled by TronLink / WalletConnect-TRON wallet provider.
class TronHttpRpcClient {
  final String baseUrl;
  final String? apiKey;
  final http.Client _http;

  // ── Rate limiting ────────────────────────────────────────────────────────
  /// Minimum gap between HTTP requests.
  /// Custom provider (Chainstack etc): 50ms (25+ rps).
  /// TronGrid with API key: 200ms (~5 rps).
  /// TronGrid free tier: 500ms (~2 rps safe).
  bool get _isCustomProvider =>
      _envProviderUrl.isNotEmpty && !baseUrl.contains('trongrid.io');

  Duration get _minRequestInterval {
    if (_isCustomProvider) return const Duration(milliseconds: 50);
    if (apiKey != null && apiKey!.isNotEmpty) {
      return const Duration(milliseconds: 200);
    }
    return const Duration(milliseconds: 500);
  }

  static const int _maxRetries = 2;

  TronHttpRpcClient({
    this.baseUrl = 'https://api.trongrid.io',
    this.apiKey,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  // ── Singleton with dart-define config ────────────────────────────────────
  // flutter run --dart-define=TRONGRID_API_KEY=xxx
  // flutter run --dart-define=TRON_PROVIDER_URL=https://your-rpc.example.com
  static const String _envApiKey =
      String.fromEnvironment('TRONGRID_API_KEY', defaultValue: '');
  static const String _envProviderUrl =
      String.fromEnvironment('TRON_PROVIDER_URL', defaultValue: '');

  static TronHttpRpcClient? _shared;
  static TronHttpRpcClient get shared {
    _shared ??= TronHttpRpcClient(
      baseUrl: _envProviderUrl.isNotEmpty
          ? _envProviderUrl
          : 'https://api.trongrid.io',
      apiKey: _envApiKey.isNotEmpty ? _envApiKey : null,
    );
    return _shared!;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (apiKey != null && apiKey!.isNotEmpty) {
      headers['TRON-PRO-API-KEY'] = apiKey!;
    }
    return headers;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GLOBAL SERIAL QUEUE — one request at a time, ever
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _queueTail = Future.value();

  /// Enqueues an HTTP action onto the global serial queue.
  /// Every Tron HTTP request must go through here.
  /// Simple Future chain — no Completer, no microtask ambiguity.
  Future<T> _enqueue<T>(Future<T> Function() action) {
    final run = _queueTail.then((_) async {
      await Future.delayed(_minRequestInterval);
      return action();
    });
    _queueTail = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // IN-FLIGHT DEDUPLICATION
  // ══════════════════════════════════════════════════════════════════════════

  final Map<String, Future<dynamic>> _inFlight = {};

  /// Deduplicates read-only requests: same key while in-flight → same Future.
  /// Write requests (broadcast, build tx) must NOT use this.
  Future<T> _deduplicated<T>(String key, Future<T> Function() factory) {
    if (_inFlight.containsKey(key)) {
      return _inFlight[key]! as Future<T>;
    }
    final future = factory().whenComplete(() => _inFlight.remove(key));
    _inFlight[key] = future;
    return future;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PER-SESSION CACHE — cleared between refresh cycles
  // ══════════════════════════════════════════════════════════════════════════

  final Map<String, dynamic> _sessionCache = {};

  /// Call at the start of a portfolio refresh or scan cycle to avoid
  /// redundant requests within one refresh.
  void clearSessionCache() => _sessionCache.clear();

  // ══════════════════════════════════════════════════════════════════════════
  // LOW-LEVEL HTTP — with 429 retry
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _enqueue(() => _rawPostWithRetry(path, body));
  }

  Future<Map<String, dynamic>> _rawPostWithRetry(
    String path,
    Map<String, dynamic> body, {
    int attempt = 0,
  }) async {
    debugPrint('[TronRpc] POST $baseUrl$path');
    final res = await _http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    debugPrint('[TronRpc] POST $path → ${res.statusCode}');

    if (res.statusCode == 429) {
      if (attempt >= _maxRetries) {
        throw TronRpcException(
            'HTTP 429: rate limit after $_maxRetries retries');
      }
      final wait = _parse429Wait(res.body);
      debugPrint('[TronRpc] 429 on $path — waiting ${wait.inSeconds}s '
          '(retry ${attempt + 1}/$_maxRetries)');
      await Future.delayed(wait);
      return _rawPostWithRetry(path, body, attempt: attempt + 1);
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw TronRpcException('HTTP ${res.statusCode}: ${res.body}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    debugPrint(
        '[TronRpc] POST decoded path=$path keys=${decoded.keys.take(5)}');
    return decoded;
  }

  /// Throttled + queued GET for TronGrid event/v1 endpoints.
  Future<Map<String, dynamic>> _get(String url) async {
    return _enqueue(() => _rawGetWithRetry(url));
  }

  Future<Map<String, dynamic>> _rawGetWithRetry(
    String url, {
    int attempt = 0,
  }) async {
    final res = await _http
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 429) {
      if (attempt >= _maxRetries) {
        throw TronRpcException(
            'HTTP 429: rate limit after $_maxRetries retries');
      }
      final wait = _parse429Wait(res.body);
      debugPrint('[TronRpc] 429 on GET — waiting ${wait.inSeconds}s '
          '(retry ${attempt + 1}/$_maxRetries)');
      await Future.delayed(wait);
      return _rawGetWithRetry(url, attempt: attempt + 1);
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw TronRpcException('HTTP ${res.statusCode}: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Parses TronGrid 429 response to extract suspension seconds.
  Duration _parse429Wait(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['Error']?.toString() ?? '';
      // Pattern: "suspended for 5 s"
      final match = RegExp(r'suspended for (\d+) s').firstMatch(error);
      if (match != null) {
        final seconds = int.parse(match.group(1)!);
        return Duration(seconds: seconds + 1); // +1s safety margin
      }
    } catch (_) {}
    return const Duration(seconds: 6); // Default fallback
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BALANCE QUERIES
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns TRX balance in SUN (1 TRX = 1,000,000 SUN).
  Future<BigInt> getBalanceSun(String address) {
    final cacheKey = 'balance:$address';
    if (_sessionCache.containsKey(cacheKey)) {
      return Future.value(_sessionCache[cacheKey] as BigInt);
    }

    return _deduplicated(cacheKey, () async {
      final json = await _post('/wallet/getaccount', {
        'address': address,
        'visible': true,
      });
      debugPrint('[TronRpc] getBalanceSun post returned');

      final balance = json['balance'];
      if (balance == null) return BigInt.zero;
      if (balance is! num) {
        throw const TronRpcException('Invalid getaccount balance response');
      }
      final result = BigInt.from(balance);
      _sessionCache[cacheKey] = result;
      debugPrint('[TronRpc] getBalanceSun return raw=$result');
      return result;
    });
  }

  /// Fetches the entire account portfolio (native TRX and TRC20 tokens) via TronGrid v1 API.
  /// This bypasses standard RPC nodes to retrieve all balances in a single request.
  Future<Map<String, dynamic>> getAccountPortfolio(String address) async {
    final eventBaseUrl = _isCustomProvider ? _tronGridBase : baseUrl;
    final url = '$eventBaseUrl/v1/accounts/$address';
    final json = await _eventGet(url);
    final data = json['data'] as List<dynamic>?;
    if (data == null || data.isEmpty) {
      return {};
    }
    return data.first as Map<String, dynamic>;
  }

  /// Reads a TRC20 token balance via `balanceOf(address)`.
  Future<BigInt> getTrc20Balance(String ownerAddress, String contractAddress) {
    final cacheKey = 'trc20bal:$ownerAddress:$contractAddress';
    if (_sessionCache.containsKey(cacheKey)) {
      return Future.value(_sessionCache[cacheKey] as BigInt);
    }

    return _deduplicated(cacheKey, () async {
      final paramHex = abiEncodeAddress(ownerAddress);

      final json = await _post('/wallet/triggerconstantcontract', {
        'owner_address': ownerAddress,
        'contract_address': contractAddress,
        'function_selector': 'balanceOf(address)',
        'parameter': paramHex,
        'visible': true,
      });

      final result = json['result'] as Map<String, dynamic>?;
      if (result != null && result['result'] == false) {
        final msg = result['message']?.toString() ?? 'unknown';
        throw TronRpcException('balanceOf failed: $msg');
      }

      final constantResult = json['constant_result'] as List<dynamic>?;
      if (constantResult == null || constantResult.isEmpty) {
        return BigInt.zero;
      }

      final hex = constantResult[0].toString();
      if (hex.isEmpty || hex == '0' * 64) return BigInt.zero;
      final value = BigInt.parse(hex, radix: 16);
      _sessionCache[cacheKey] = value;
      return value;
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ALLOWANCE CHECK (Critical for DrainShield scanning)
  // ══════════════════════════════════════════════════════════════════════════

  /// Reads current TRC20 allowance via `allowance(owner, spender)`.
  /// Returns raw token amount the spender is allowed to transfer.
  Future<BigInt> getAllowance({
    required String ownerAddress,
    required String spenderAddress,
    required String tokenContract,
  }) {
    final cacheKey = 'allowance:$ownerAddress:$spenderAddress:$tokenContract';
    if (_sessionCache.containsKey(cacheKey)) {
      return Future.value(_sessionCache[cacheKey] as BigInt);
    }

    return _deduplicated(cacheKey, () async {
      final paramHex =
          '${abiEncodeAddress(ownerAddress)}${abiEncodeAddress(spenderAddress)}';

      final results = await _triggerConstantContractRaw(
        ownerAddress: ownerAddress,
        contractAddress: tokenContract,
        functionSelector: 'allowance(address,address)',
        parameter: paramHex,
      );

      if (results.isEmpty || results.first.isEmpty) {
        return BigInt.zero;
      }

      final hex = results.first.replaceAll(RegExp(r'^0+'), '');
      if (hex.isEmpty) return BigInt.zero;
      final value = BigInt.parse(hex, radix: 16);
      _sessionCache[cacheKey] = value;
      return value;
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // APPROVE TRANSACTION BUILDER (for Panic revoke)
  // ══════════════════════════════════════════════════════════════════════════

  /// Default fee_limit for TRC20 approve: 10 TRX (10,000,000 sun).
  static const int defaultApproveFeeLimit = 10000000;

  /// Builds an unsigned TRC20 `approve(spender, amount)` transaction.
  ///
  /// For Panic Mode revoke, call with `amount = BigInt.zero` to reset allowance.
  /// The returned [TronUnsignedTransaction] must be signed by the wallet provider
  /// (TronLink or WalletConnect-TRON), NOT by Privy.
  Future<TronUnsignedTransaction> buildTrc20Approve({
    required String ownerAddress,
    required String tokenContract,
    required String spenderAddress,
    required BigInt amount,
    int feeLimit = defaultApproveFeeLimit,
  }) async {
    final paramHex =
        '${abiEncodeAddress(spenderAddress)}${abiEncodeUint256(amount)}';

    return _buildSmartContractCall(
      ownerAddress: ownerAddress,
      contractAddress: tokenContract,
      functionSelector: 'approve(address,uint256)',
      parameter: paramHex,
      feeLimit: feeLimit,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TRANSACTION BROADCAST
  // ══════════════════════════════════════════════════════════════════════════

  /// Broadcasts a signed transaction to the Tron network.
  /// NOT deduplicated — each broadcast is unique.
  Future<String> broadcastTransaction(TronSignedTransaction signedTx) async {
    final json = await _post('/wallet/broadcasttransaction', signedTx.toJson());

    final success = json['result'] == true;
    if (!success) {
      final message = json['message']?.toString() ?? jsonEncode(json);
      throw TronRpcException('Broadcast failed: $message');
    }

    final txId = json['txid']?.toString() ?? signedTx.txId;
    if (txId.isEmpty) {
      throw const TronRpcException('Broadcast succeeded but txid missing');
    }

    return txId;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TRONGRID EVENT API — separate queue + throttle
  // ══════════════════════════════════════════════════════════════════════════

  /// TronGrid event API base URL.
  /// /v1/contracts/*/events is TronGrid-only — Chainstack doesn't support it.
  static const String _tronGridBase = 'https://api.trongrid.io';

  /// Separate serial queue for TronGrid event requests.
  /// Keeps TronGrid throttle independent from Chainstack primary queue.
  Future<void> _eventQueueTail = Future.value();

  /// TronGrid event throttle: conservative to avoid 429.
  /// Without TRONGRID_API_KEY: 1200ms (~0.8 rps, well under 3 rps limit).
  /// With TRONGRID_API_KEY: 250ms (~4 rps).
  Duration get _eventRequestInterval => (_envApiKey.isNotEmpty)
      ? const Duration(milliseconds: 250)
      : const Duration(milliseconds: 1200);

  /// Enqueues onto the separate TronGrid event queue.
  /// Simple Future chain — no Completer, no microtask ambiguity.
  Future<T> _eventEnqueue<T>(Future<T> Function() action) {
    final run = _eventQueueTail.then((_) async {
      await Future.delayed(_eventRequestInterval);
      return action();
    });
    _eventQueueTail = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  /// TronGrid event GET — uses separate event queue, NOT the primary queue.
  Future<Map<String, dynamic>> _eventGet(String url) {
    return _eventEnqueue(() => _rawEventGetWithRetry(url));
  }

  Future<Map<String, dynamic>> _rawEventGetWithRetry(
    String url, {
    int attempt = 0,
  }) async {
    // Event requests always use TronGrid headers (API key if available)
    final eventHeaders = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_envApiKey.isNotEmpty) {
      eventHeaders['TRON-PRO-API-KEY'] = _envApiKey;
    }

    final res = await _http
        .get(Uri.parse(url), headers: eventHeaders)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 429) {
      if (attempt >= _maxRetries) {
        throw TronRpcException(
            'TronGrid event 429: rate limit after $_maxRetries retries');
      }
      final wait = _parse429Wait(res.body);
      debugPrint('[TronRpc] Event 429 — waiting ${wait.inSeconds}s '
          '(retry ${attempt + 1}/$_maxRetries)');
      await Future.delayed(wait);
      return _rawEventGetWithRetry(url, attempt: attempt + 1);
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw TronRpcException(
          'TronGrid event HTTP ${res.statusCode}: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Fetches Approval events for a TRC20 contract filtered by owner.
  ///
  /// Uses TronGrid event API with its own throttle, independent of the
  /// primary Chainstack queue. Throws [TronRpcException] on failure —
  /// callers must NOT treat exceptions as "no approvals found".
  Future<TronEventResult> getApprovalEvents({
    required String contractAddress,
    required String ownerAddress,
    int limit = 200,
  }) async {
    // Always use TronGrid for event API
    final eventBaseUrl = _isCustomProvider ? _tronGridBase : baseUrl;
    final url = '$eventBaseUrl/v1/contracts/$contractAddress/events'
        '?event_name=Approval'
        '&only_confirmed=true'
        '&limit=$limit';

    final Map<String, dynamic> decoded;
    try {
      decoded = await _eventGet(url);
    } catch (e) {
      debugPrint('[TronRpc] Event discovery failed for $contractAddress: $e');
      return TronEventResult.error(
        'Event discovery failed: $e',
      );
    }

    final data = decoded['data'] as List<dynamic>? ?? [];
    final ownerLower = ownerAddress.toLowerCase();
    final results = <Map<String, dynamic>>[];

    for (final event in data) {
      final eventResult = event['result'] as Map<String, dynamic>?;
      if (eventResult == null) continue;

      // Match owner address (field name varies: 'owner', '0', '_owner')
      final eventOwner = (eventResult['owner'] ??
              eventResult['0'] ??
              eventResult['_owner'] ??
              '')
          .toString()
          .toLowerCase();

      if (eventOwner == ownerLower ||
          eventOwner.endsWith(ownerLower.replaceFirst('0x', ''))) {
        results.add({
          'spender': eventResult['spender'] ??
              eventResult['1'] ??
              eventResult['_spender'] ??
              '',
          'value': eventResult['value'] ??
              eventResult['2'] ??
              eventResult['_value'] ??
              '0',
          'contract': contractAddress,
          'block': event['block_number'],
          'timestamp': event['block_timestamp'],
        });
      }
    }

    return TronEventResult.ok(results);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<String>> _triggerConstantContractRaw({
    required String ownerAddress,
    required String contractAddress,
    required String functionSelector,
    required String parameter,
  }) async {
    final json = await _post('/wallet/triggerconstantcontract', {
      'owner_address': ownerAddress,
      'contract_address': contractAddress,
      'function_selector': functionSelector,
      'parameter': parameter,
      'visible': true,
    });

    final result = json['result'] as Map<String, dynamic>?;
    if (result != null && result['result'] == false) {
      final msg = result['message']?.toString() ?? 'unknown';
      throw TronRpcException('triggerConstantContract failed: $msg');
    }

    final constantResult = json['constant_result'] as List<dynamic>?;
    if (constantResult == null || constantResult.isEmpty) {
      return [];
    }

    return constantResult.map((e) => e.toString()).toList();
  }

  Future<TronUnsignedTransaction> _buildSmartContractCall({
    required String ownerAddress,
    required String contractAddress,
    required String functionSelector,
    required String parameter,
    int feeLimit = 50000000,
    BigInt? callValue,
  }) async {
    final body = <String, dynamic>{
      'owner_address': ownerAddress,
      'contract_address': contractAddress,
      'function_selector': functionSelector,
      'parameter': parameter,
      'fee_limit': feeLimit,
      'visible': true,
    };

    if (callValue != null && callValue > BigInt.zero) {
      body['call_value'] = callValue.toInt();
    }

    final json = await _post('/wallet/triggersmartcontract', body);

    final result = json['result'] as Map<String, dynamic>?;
    if (result == null || result['result'] != true) {
      final msg = result?['message']?.toString() ?? jsonEncode(json);
      throw TronRpcException('triggerSmartContract failed: $msg');
    }

    final tx = json['transaction'] as Map<String, dynamic>?;
    if (tx == null) {
      throw const TronRpcException(
          'triggerSmartContract: missing transaction in response');
    }

    final txId = tx['txID']?.toString() ?? '';
    final rawData = tx['raw_data'] as Map<String, dynamic>?;
    final rawDataHex = tx['raw_data_hex']?.toString() ?? '';

    if (txId.isEmpty || rawData == null || rawDataHex.isEmpty) {
      throw const TronRpcException(
          'triggerSmartContract: invalid transaction structure');
    }

    return TronUnsignedTransaction(
      rawData: rawData,
      txId: txId,
      rawDataHex: rawDataHex,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ABI ENCODING HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// ABI-encodes a Tron base58check address as a 32-byte hex string.
  static String abiEncodeAddress(String tronBase58Address) {
    final decoded = _tronBase58Decode(tronBase58Address);
    _validateTronAddress(decoded, tronBase58Address);
    final addressBytes = decoded.sublist(1, 21);
    final hex =
        addressBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return hex.padLeft(64, '0');
  }

  /// ABI-encodes a uint256 value as a 32-byte hex string.
  static String abiEncodeUint256(BigInt value) {
    return value.toRadixString(16).padLeft(64, '0');
  }

  /// Validates a Tron base58check address.
  /// Returns true if valid, throws [TronRpcException] otherwise.
  static bool validateTronAddress(String tronBase58Address) {
    final decoded = _tronBase58Decode(tronBase58Address);
    _validateTronAddress(decoded, tronBase58Address);
    return true;
  }

  static void _validateTronAddress(List<int> decoded, String original) {
    if (decoded.length != 25) {
      throw TronRpcException(
        'Invalid Tron address "$original": '
        'expected 25 bytes, got ${decoded.length}',
      );
    }

    if (decoded[0] != 0x41) {
      throw TronRpcException(
        'Invalid Tron address "$original": '
        'prefix byte is 0x${decoded[0].toRadixString(16)}, expected 0x41',
      );
    }

    final payload = Uint8List.fromList(decoded.sublist(0, 21));
    final hash1 = sha256.convert(payload).bytes;
    final hash2 = sha256.convert(hash1).bytes;
    final expectedChecksum = hash2.sublist(0, 4);
    final actualChecksum = decoded.sublist(21, 25);

    for (int i = 0; i < 4; i++) {
      if (expectedChecksum[i] != actualChecksum[i]) {
        throw TronRpcException(
          'Invalid Tron address "$original": checksum mismatch',
        );
      }
    }
  }

  static List<int> _tronBase58Decode(String input) {
    const alphabet =
        '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    BigInt value = BigInt.zero;
    for (int i = 0; i < input.length; i++) {
      final charIndex = alphabet.indexOf(input[i]);
      if (charIndex < 0) {
        throw TronRpcException('Invalid base58 character: ${input[i]}');
      }
      value = (value * BigInt.from(58)) + BigInt.from(charIndex);
    }
    final bytes = <int>[];
    while (value > BigInt.zero) {
      bytes.add((value % BigInt.from(256)).toInt());
      value = value ~/ BigInt.from(256);
    }
    int leadingZeros = 0;
    while (leadingZeros < input.length && input[leadingZeros] == '1') {
      leadingZeros++;
    }
    final result = List<int>.filled(leadingZeros, 0) + bytes.reversed.toList();
    return result;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WELL-KNOWN TRC20 CONTRACTS
  // ══════════════════════════════════════════════════════════════════════════

  /// Known TRC20 tokens for scanning.
  static const Map<String, TronTokenInfo> knownTokens = {
    'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t': TronTokenInfo('USDT', 6),
    'TEkxiTehnzSmSe2XqrBj4w32RUN966rdz8': TronTokenInfo('USDC', 6),
    'TNUC9Qb1rRpS5CbWLmNMxXBjyFoydXjWFR': TronTokenInfo('WTRX', 6),
    'TAFjULxiVgT4qWk6UZwjqwZXTSaGaqnVp4': TronTokenInfo('BTT', 18),
    'TCFLL5dx5ZJdKnWuesXxi1VPwjLVmWZZy9': TronTokenInfo('JST', 18),
    'TSSMHYeV2uE9qYH95DqyoCuNCzEL1NvU3S': TronTokenInfo('SUN', 18),
    'TLa2f6VPqDgRE67v1736s7bJ8Ray5wYjU7': TronTokenInfo('WIN', 6),
  };
}

/// Metadata for a known TRC20 token.
class TronTokenInfo {
  final String symbol;
  final int decimals;
  const TronTokenInfo(this.symbol, this.decimals);
}

/// Result of a TronGrid event query.
/// Distinguishes "no approvals found" (ok + empty) from
/// "event discovery failed" (error).
/// Callers must check [isOk] before treating data as authoritative.
class TronEventResult {
  final bool isOk;
  final List<Map<String, dynamic>> events;
  final String? errorMessage;

  const TronEventResult._({
    required this.isOk,
    required this.events,
    this.errorMessage,
  });

  factory TronEventResult.ok(List<Map<String, dynamic>> events) =>
      TronEventResult._(isOk: true, events: events);

  factory TronEventResult.error(String message) =>
      TronEventResult._(isOk: false, events: const [], errorMessage: message);
}
