import "dart:convert";
import "package:http/http.dart" as http;
import "../models/approval.dart";
import "../config/chains.dart";
import "risk_engine.dart";
import "wallet_service.dart";
import "wc_service.dart";
import "moralis_parser.dart";
import "moralis/moralis_config_service.dart";

class GlobalApprovalScanner {

  static Future<List<ApprovalData>> scanAllApprovals(String wallet) async {
    final apiKey = MoralisConfigService.key;

    final activeChainId = WcService().currentChainId;

    final currentChain = ChainConfig.getMoralisChainSlug(activeChainId);
    if (currentChain == null) {
      throw "Cannot scan global approvals: Unsupported network (Chain ID: $activeChainId). Please switch to a supported network.";
    }

    if (apiKey.isEmpty) {
      // In demo mode, load all fake approvals to simulate a global scan
      final fake = WalletService.loadFakeApprovals();
      RiskEngine.evaluateApprovals(fake);
      return fake;
    }

    final out = <ApprovalData>[];
    try {
      // Moralis v2.2 ERC20 Approval Endpoint
      final uri = Uri.parse(
        "https://deep-index.moralis.io/api/v2.2/wallets/$wallet/erc20/approvals?chain=$currentChain&limit=100",
      );

      final res = await http.get(uri, headers: {"X-API-Key": apiKey});

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final result = (json["result"] as List?) ?? const [];
        for (final it in result) {
          final m = it as Map<String, dynamic>;
          final parsed = MoralisParser.parseApprovalItem(m, currentChain);
          if (parsed.token.isEmpty || parsed.spenderAddress.isEmpty) continue;
          out.add(parsed);
        }
      } else {
        print("[GlobalScanner] Moralis Error: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("[GlobalScanner] Exception: $e");
    }

    RiskEngine.evaluateApprovals(out);
    return out;
  }
}
