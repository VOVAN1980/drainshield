import "dart:convert";
import "package:http/http.dart" as http;
import "../models/approval.dart";
import "../config/chains.dart";
import "risk_engine.dart";
import "wc_service.dart";
import "moralis_parser.dart";
import "moralis/moralis_config_service.dart";
import "security/blockchain_analysis_service.dart";
import "spender_intelligence_service.dart";

class ApprovalScanService {
  static int? lastRiskScore;
  static bool hasRiskyApprovals = false;

  static Future<List<ApprovalData>> scan(
    String wallet, {
    String? targetTokenAddress,
  }) async {
    final apiKey = MoralisConfigService.key;

    final activeChainId = WcService().currentChainId;

    final currentChain = ChainConfig.getMoralisChainSlug(activeChainId);
    if (currentChain == null) {
      throw "Cannot scan approvals: Unsupported network (Chain ID: $activeChainId). Please switch to a supported network.";
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
          // Initial reputation lookup (local + remote cache)
          final intel = SpenderIntelligenceService.instance;
          parsed.reputation =
              intel.getReputation(activeChainId, parsed.spenderAddress);
          final label =
              intel.getTrustedLabel(activeChainId, parsed.spenderAddress);
          if (label != null) {
            // Use Label from intelligence instead of raw spender address/name if available
            parsed.copyWithEnrichment(discoveredName: label);
          }

          out.add(parsed);
        }
      } else {
        throw "Approval scan failed: Moralis returned ${res.statusCode}";
      }
    } catch (e) {
      throw e.toString();
    }

    // Enrichment Phase: Deep Analysis
    final analysis = BlockchainAnalysisService.instance;
    await Future.wait(out.map((item) async {
      try {
        final result = await analysis.analyze(
          walletAddress: wallet,
          spenderAddress: item.spenderAddress,
          chainSlug: currentChain,
        );

        // Update model with real signals
        item.copyWithEnrichment(
          isProxyContract: result.isProxyContract,
          isUpgradeable: result.isUpgradeable,
          hasOwnerPrivileges: result.hasOwnerPrivileges,
          canPause: result.canPause,
          canMint: result.canMint,
          canBlacklist: result.canBlacklist,
          previousInteractions: result.previousInteractions,
          popularityScore: result.popularityScore,
          isPopular: result.isPopular,
          discoveredName: result.spenderName,
        );
      } catch (e) {
        // Silently skip enrichment for failed probes to avoid blocking entire scan
        print("Enrichment failed for ${item.spenderAddress}: $e");
      }
    }));

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
