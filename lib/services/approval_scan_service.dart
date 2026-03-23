import "dart:convert";
import "package:http/http.dart" as http;
import "../models/approval.dart";
import "../config/chains.dart";
import "risk_engine.dart";
import "wc_service.dart";
import "moralis_parser.dart";
import "moralis/moralis_config_service.dart";

class ApprovalScanService {
  static int? lastRiskScore;
  static bool hasRiskyApprovals = false;

  static Future<List<ApprovalData>> scan(
    String wallet, {
    String? targetTokenAddress,
    int? chainId,
  }) async {
    final apiKey = MoralisConfigService.key;

    final activeChainId = chainId ?? WcService().currentChainId;

    final currentChain = ChainConfig.getMoralisChainSlug(activeChainId);
    if (currentChain == null) {
      throw "Cannot scan approvals: Unsupported network (Chain ID: $activeChainId).";
    }

    if (apiKey.isEmpty) {
      throw "Moralis API key is missing";
    }

    final out = <ApprovalData>[];
    try {
      final uri = Uri.parse(
        "https://deep-index.moralis.io/api/v2.2/wallets/$wallet/approvals?chain=$currentChain&limit=100",
      );
      final res = await http.get(uri, headers: {"X-API-Key": apiKey});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final result = (json["result"] as List?) ?? const [];
        for (final it in result) {
          final m = it as Map<String, dynamic>;
          final parsed = MoralisParser.parseApprovalItem(m, currentChain);
          if (parsed.token.isEmpty || parsed.spenderAddress.isEmpty) continue;

          if (targetTokenAddress != null &&
              parsed.token.toLowerCase() != targetTokenAddress.toLowerCase()) {
            continue;
          }
          out.add(parsed);
        }
      } else {
        throw "Approval scan failed: Moralis returned ${res.statusCode}";
      }
    } catch (e) {
      throw e.toString();
    }

    RiskEngine.evaluate(out);
    updateScore(out);
    return out;
  }

  static void updateScore(List<ApprovalData> approvals) {
    if (approvals.isEmpty) {
      lastRiskScore = 100;
      hasRiskyApprovals = false;
      return;
    }

    // Use the new RiskEngine assessment to update global dashboard state
    final walletAssessment = RiskEngine.computeWalletAssessment(approvals);
    lastRiskScore = 100 - walletAssessment.score;

    // Check if any approval requires revocation according to new logic
    hasRiskyApprovals = approvals.any((a) => a.assessment.shouldRevoke);
  }
}
