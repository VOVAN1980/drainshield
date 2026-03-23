import "dart:convert";
import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "../models/approval.dart";
import "../config/chains.dart";
import "risk_engine.dart";
import "wc_service.dart";
import "moralis_parser.dart";
import "moralis/moralis_config_service.dart";
import "security/blockchain_analysis_service.dart";
import "spender_intelligence_service.dart";

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
        throw "Global approval scan failed: Moralis returned ${res.statusCode}";
      }
    } catch (e) {
      throw e.toString();
    }

    // Evaluate base risks to prioritize deep scan
    RiskEngine.evaluateApprovals(out);

    // Filter for enrichment: Only deep-scan approvals that have some basic risk
    // or are completely unknown, to save time during Panic Mode pipeline
    final toEnrich = out.where((a) =>
        a.assessment.score > 0 ||
        a.reputation == SpenderReputation.unknown ||
        a.reputation == SpenderReputation.suspicious).toList();

    // Enrichment Phase: Deep Analysis
    final analysis = BlockchainAnalysisService.instance;
    await Future.wait(toEnrich.map((item) async {
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
        // This acts as a fallback/timeout failure handler
        debugPrint("Panic Mode Enrichment failed for ${item.spenderAddress}: $e");
      }
    }));

    // Re-evaluate with enriched data to generate final rescue plan
    RiskEngine.evaluateApprovals(out);
    return out;
  }
}
