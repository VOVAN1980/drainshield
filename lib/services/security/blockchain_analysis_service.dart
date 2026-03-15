import 'dart:convert';
import 'package:http/http.dart' as http;
import '../rpc_service.dart';
import '../moralis/moralis_config_service.dart';

class BlockchainAnalysisService {
  static final BlockchainAnalysisService instance =
      BlockchainAnalysisService._internal();
  BlockchainAnalysisService._internal();

  /// Cache to avoid redundant probes for the same address in a session
  final Map<String, AnalysisResult> _cache = {};

  /// EIP-1967 implementation slot: keccak256('eip1967.proxy.implementation') - 1
  static const String eip1967Slot =
      "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc";

  /// owner() function selector
  static const String ownerSelector = "0x8da5cb5b";

  /// Common behavioral selectors
  static const String pausedSelector = "0x5c975abb";
  static const String isPausedSelector = "0xb18a19a0";
  static const String mintSelector = "0x40c10f19";
  static const String blacklistedSelector = "0xfe575a87";
  static const String isBlacklistedSelector = "0xbb57cdcd";

  Future<AnalysisResult> analyze({
    required String walletAddress,
    required String spenderAddress,
    required String chainSlug,
  }) async {
    final cacheKey = "$chainSlug:$spenderAddress";
    if (_cache.containsKey(cacheKey)) {
      // Re-fetch history for the specific wallet if needed,
      // but proxy/owner status is spender-static.
      final cached = _cache[cacheKey]!;
      final historyCount = await _fetchInteractionHistory(
        walletAddress: walletAddress,
        spenderAddress: spenderAddress,
        chainSlug: chainSlug,
      );
      return cached.copyWith(previousInteractions: historyCount);
    }

    // 1. Proxy Detection
    bool isProxy = false;
    try {
      final res = await _rpcCall(
          "eth_getStorageAt", [spenderAddress, eip1967Slot, "latest"]);
      if (res != null &&
          res is String &&
          res !=
              "0x0000000000000000000000000000000000000000000000000000000000000000") {
        isProxy = true;
      }
    } catch (_) {}

    // 2. Owner Privilege Detection
    bool hasOwner = false;
    try {
      final res = await _rpcCall("eth_call", [
        {"to": spenderAddress, "data": ownerSelector},
        "latest"
      ]);
      // If we get back a 32-byte address (64 chars after 0x), it likely supports owner()
      if (res != null &&
          res is String &&
          res.length >= 66 &&
          res != "0x${"0" * 64}") {
        hasOwner = true;
      }
    } catch (_) {}

    // 2.1 Behavioral Capability Probes
    final canPause = await _checkCapability(
        spenderAddress, [pausedSelector, isPausedSelector]);
    final canMint =
        await _checkCapability(spenderAddress, [mintSelector], hasParams: true);
    final canBlacklist = await _checkCapability(
        spenderAddress, [blacklistedSelector, isBlacklistedSelector],
        hasParams: true);

    // 3. Spender Metadata & Discovery
    final metadata = await _fetchSpenderMetadata(spenderAddress, chainSlug);

    // 4. Popularity / Community Trust Signal
    final popularity = await _fetchPopularityScore(spenderAddress, chainSlug);

    // 5. Interaction History
    final historyCount = await _fetchInteractionHistory(
      walletAddress: walletAddress,
      spenderAddress: spenderAddress,
      chainSlug: chainSlug,
    );

    final result = AnalysisResult(
      isProxyContract: isProxy,
      isUpgradeable: isProxy,
      hasOwnerPrivileges: hasOwner,
      canPause: canPause,
      canMint: canMint,
      canBlacklist: canBlacklist,
      previousInteractions: historyCount,
      spenderName: metadata?["name"],
      popularityScore: popularity,
      isPopular: popularity > 5000, // Threshold for "Community Trust"
    );

    _cache[cacheKey] = result;
    return result;
  }

  Future<bool> _checkCapability(String address, List<String> selectors,
      {bool hasParams = false}) async {
    for (final selector in selectors) {
      try {
        final data = hasParams
            ? "${selector}0000000000000000000000000000000000000000000000000000000000000000" // Zero address param
            : selector;
        final res = await _rpcCall("eth_call", [
          {"to": address, "data": data},
          "latest"
        ]);
        // If we get any valid response (not null, not empty 0x),
        // it means the function likely exists and didn't revert.
        if (res != null && res is String && res != "0x") {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Future<int> _fetchInteractionHistory({
    required String walletAddress,
    required String spenderAddress,
    required String chainSlug,
  }) async {
    final apiKey = MoralisConfigService.key;
    if (apiKey.isEmpty) return 0;

    try {
      // Fetch history for the wallet filtered by spender address
      final uri = Uri.parse(
        "https://deep-index.moralis.io/api/v2.2/wallets/$walletAddress/history?chain=$chainSlug&to_address=$spenderAddress&limit=50",
      );
      final res = await http.get(uri, headers: {"X-API-Key": apiKey});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final result = json["result"] as List?;
        return result?.length ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Future<Map<String, dynamic>?> _fetchSpenderMetadata(
    String address,
    String chainSlug,
  ) async {
    final apiKey = MoralisConfigService.key;
    if (apiKey.isEmpty) return null;

    try {
      final uri = Uri.parse(
        "https://deep-index.moralis.io/api/v2.2/erc20/metadata?chain=$chainSlug&addresses=$address",
      );
      final res = await http.get(uri, headers: {"X-API-Key": apiKey});
      if (res.statusCode == 200) {
        final List json = jsonDecode(res.body);
        if (json.isNotEmpty) return json[0] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<int> _fetchPopularityScore(String address, String chainSlug) async {
    final apiKey = MoralisConfigService.key;
    if (apiKey.isEmpty) return 0;

    try {
      // Fetching history for the CONTRACT itself to see total tx count
      final uri = Uri.parse(
        "https://deep-index.moralis.io/api/v2.2/wallets/$address/history?chain=$chainSlug&limit=1",
      );
      final res = await http.get(uri, headers: {"X-API-Key": apiKey});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        // Moralis provides a 'total' field even with limit=1
        return json["total"] as int? ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// Internal RPC wrapper (similar to DsRpc but more flexible for storage/calls)
  Future<dynamic> _rpcCall(String method, List<dynamic> params) async {
    // Note: DsRpc uses a hardcoded BSC URL. In a multi-chain app, we should
    // ideally use a URL based on chainSlug. For now, following project patterns.
    final body = jsonEncode({
      "jsonrpc": "2.0",
      "id": DateTime.now().millisecondsSinceEpoch,
      "method": method,
      "params": params,
    });
    final res = await http.post(
      Uri.parse(DsRpc.rpcUrl),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return json["result"];
    }
    return null;
  }
}

class AnalysisResult {
  final bool isProxyContract;
  final bool isUpgradeable;
  final bool hasOwnerPrivileges;
  final bool canPause;
  final bool canMint;
  final bool canBlacklist;
  final int previousInteractions;
  final String? spenderName;
  final int popularityScore;
  final bool isPopular;

  AnalysisResult({
    required this.isProxyContract,
    required this.isUpgradeable,
    required this.hasOwnerPrivileges,
    this.canPause = false,
    this.canMint = false,
    this.canBlacklist = false,
    required this.previousInteractions,
    this.spenderName,
    this.popularityScore = 0,
    this.isPopular = false,
  });

  AnalysisResult copyWith({int? previousInteractions}) {
    return AnalysisResult(
      isProxyContract: isProxyContract,
      isUpgradeable: isUpgradeable,
      hasOwnerPrivileges: hasOwnerPrivileges,
      canPause: canPause,
      canMint: canMint,
      canBlacklist: canBlacklist,
      spenderName: spenderName,
      popularityScore: popularityScore,
      isPopular: isPopular,
      previousInteractions: previousInteractions ?? this.previousInteractions,
    );
  }
}
