import "dart:convert";
import "package:http/http.dart" as http;

/// Minimal JSON-RPC client for BNB Chain (chainId 56)
class DsRpc {
  /// Public BSC RPC (stable). You can swap later to your own endpoint.
  static const String rpcUrl = "https://bsc-dataseed.binance.org/";
  static Future<dynamic> _rpc(String method, List<dynamic> params) async {
    final body = jsonEncode({
      "jsonrpc": "2.0",
      "id": 1,
      "method": method,
      "params": params,
    });
    final res = await http.post(
      Uri.parse(rpcUrl),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    if (res.statusCode != 200) {
      throw Exception("RPC HTTP ${res.statusCode}: ${res.body}");
    }
    final json = jsonDecode(res.body);
    if (json is Map && json["error"] != null) {
      throw Exception("RPC error: ${json["error"]}");
    }
    return json["result"];
  }

  static Future<int> getChainId() async {
    final hex = await _rpc("eth_chainId", []);
    return int.parse((hex as String).substring(2), radix: 16);
  }

  static Future<BigInt> getBalanceWei(String address) async {
    final hex = await _rpc("eth_getBalance", [address, "latest"]);
    return _hexToBigInt(hex as String);
  }

  static BigInt _hexToBigInt(String hex) {
    final clean = hex.startsWith("0x") ? hex.substring(2) : hex;
    if (clean.isEmpty) return BigInt.zero;
    return BigInt.parse(clean, radix: 16);
  }

  /// Converts wei -> BNB (18 decimals) as string with fixed decimals (no rounding magic)
  static String weiToBnb(BigInt wei, {int decimals = 6}) {
    const int scale = 18;
    final base = BigInt.from(10).pow(scale);
    final whole = wei ~/ base;
    final frac = wei % base;
    final fracStr = frac.toString().padLeft(scale, "0");
    final cut = fracStr.substring(0, decimals);
    return "${whole.toString()}.$cut";
  }
}
