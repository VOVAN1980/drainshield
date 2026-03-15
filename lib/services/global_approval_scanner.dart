import "dart:convert";
import "package:http/http.dart" as http;
import "../models/approval.dart";
import "../config/chains.dart";
import "risk_engine.dart";
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
      throw "Moralis API key is missing";
    }

    final out = <ApprovalData>[];
    try {
      // Moralis v2.2 ERC20 Approval Endpoint
      final uri = Uri.parse(
        "https://deep-index.moralis.io/api/v2.2/wallets/$wallet/approvals?chain=$currentChain&limit=100",
      );

      final res = await http.get(uri, headers: {"X-API-Key": apiKey});

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final result = (json["result"] as List?) ?? const [];
        for (final it in result) {
          final m = it as Map<String, dynamic>;
          final parsed = MoralisParser.parseApprovalItem(
            m,
            currentChain,
            ownerAddress: wallet,
          );
          if (parsed.token.isEmpty || parsed.spenderAddress.isEmpty) continue;
          out.add(parsed);
        }
      } else {
        throw "Global approval scan failed: Moralis returned ${res.statusCode}";
      }
    } catch (e) {
      throw e.toString();
    }

    RiskEngine.evaluateApprovals(out);
    return out;
  }
}
