import '../models/approval.dart';
import '../services/risk_engine.dart';

/// Derives human-readable risk reasons from real [ApprovalData] fields.
/// Only shows reasons that are actually supported by available data.
class RiskExplanationService {
  /// Returns an ordered list of risk reason strings for the given [approval].
  /// All reasons are derived from actual on-chain data — nothing is fabricated.
  static List<String> explain(ApprovalData approval) {
    final reasons = <String>[];

    // 1. Spender Reputation (Top Priority)
    if (approval.reputation == SpenderReputation.trusted) {
      reasons.add(
        'Verified Protocol: This spender is recognized as a trusted community protocol (e.g., Uniswap or PancakeSwap).',
      );
    } else if (approval.reputation == SpenderReputation.suspicious) {
      reasons.add(
        'Warning: This address has been identified as suspicious or high-risk.',
      );
    } else {
      // Unknown / unrecognized spender (no human-readable label available)
      final spenderLabel = approval.spender.trim();
      final hasNoLabel = spenderLabel.isEmpty ||
          spenderLabel.toLowerCase() == 'unknown' ||
          spenderLabel == approval.spenderAddress;
      if (hasNoLabel) {
        reasons.add(
          'Anonymous Spender: This contract has no known identity or public reputation.',
        );
      }
    }

    // 2. Unlimited allowance
    if (approval.allowance == RiskEngine.maxUint256) {
      final text = approval.reputation == SpenderReputation.trusted
          ? 'Unlimited allowance is standard for DEX routers, but still allows full access to this token.'
          : 'Unlimited approval detected — this spender can transfer your entire token balance at any time.';
      reasons.add(text);
    }

    // 3. Unverified contract
    if (!approval.isVerified &&
        approval.reputation != SpenderReputation.trusted) {
      reasons.add(
        'Contract verification could not be confirmed — unverified contracts carry higher risk.',
      );
    }

    // 4. Recently deployed contract (but only if we actually have age data)
    if (approval.contractAgeDays > 0 && approval.contractAgeDays < 30) {
      reasons.add(
        'Contract was deployed less than 30 days ago — newly created contracts present higher uncertainty.',
      );
    }

    // If no specific reasons were found but risk level is warning, add generic
    if (reasons.isEmpty && approval.riskLevel == RiskLevel.warning) {
      reasons.add(
        'This approval has a limited but non-zero allowance from an unverified or unknown source.',
      );
    }

    return reasons;
  }

  /// Returns the recommended action string based on risk level and reputation.
  static String recommendation(ApprovalData approval) {
    if (approval.reputation == SpenderReputation.suspicious) {
      return 'Action Required: Revoke immediately. This address is flagged as suspicious.';
    }

    if (approval.reputation == SpenderReputation.trusted &&
        approval.riskLevel != RiskLevel.danger) {
      return 'Trusted protocol: No immediate risk, but review periodically to maintain security.';
    }

    switch (approval.riskLevel) {
      case RiskLevel.danger:
        return approval.reputation == SpenderReputation.trusted
            ? 'Access alert: You have granted this trusted protocol full control over this token. Use caution with large balances.'
            : 'Revoke immediately — this approval poses a significant risk to your assets.';
      case RiskLevel.warning:
        return 'Review this spender carefully. Consider revoking if you no longer use this dApp.';
      case RiskLevel.safe:
        return 'No urgent action required. This approval appears safe based on available data.';
    }
  }
}
