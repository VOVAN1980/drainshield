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
    } else {
      // Unknown / unrecognized spender
      final discovered = approval.discoveredName;
      if (discovered != null && discovered.isNotEmpty) {
        reasons.add(
          'Identified Contract: This spender is recognized as "$discovered".',
        );
      } else {
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

    // 5. Behavioral Simulation & Scenarios

    // Centralized Freeze Scenario
    if (approval.hasOwnerPrivileges && approval.canPause) {
      reasons.add(
        'Centralized Freeze Risk: An "owner" or "admin" account has the capability to pause all transfers for this token at any time.',
      );
    } else if (approval.canPause) {
      reasons.add(
          'Automated Freeze: This contract has pause functionality which could be triggered to stop token movement.');
    }

    // Targeted Blacklist Scenario
    if (approval.hasOwnerPrivileges && approval.canBlacklist) {
      reasons.add(
        'Blacklist Control Risk: This contract allows administrators to manually block specific wallets from moving their tokens.',
      );
    } else if (approval.canBlacklist) {
      reasons.add(
          'Blacklist Capability: This contract has logic to restrict specific addresses from transacting.');
    }

    // Supply Manipulation Scenario
    if (approval.hasOwnerPrivileges && approval.canMint) {
      reasons.add(
        'Supply Manipulation Risk: Centralized "minting" power detected. The owner can create new tokens, potentially diluting value or draining liquidity.',
      );
    } else if (approval.canMint) {
      reasons.add(
          'Minting Capability: This contract can create new supply, which is a risk factor for inflation or "rug-pull" scenarios.');
    }

    // Logic Swap / Upgrade Scenario
    if (approval.isProxyContract && approval.hasOwnerPrivileges) {
      reasons.add(
        'Stealth Logic Swap: This is an upgradeable proxy contract controlled by an admin. The underlying logic could be swapped to a malicious version without notice.',
      );
    } else if (approval.isProxyContract) {
      reasons.add(
        'Upgradeable Proxy: This contract uses a proxy pattern. While standard for many dApps, it means the logic can be changed by its maintainers.',
      );
    }

    // Generic Owner Privilege (if not already covered by specific scenarios)
    final hasComplexScenario = (approval.canPause ||
        approval.canMint ||
        approval.canBlacklist ||
        approval.isProxyContract);
    if (approval.hasOwnerPrivileges && !hasComplexScenario) {
      reasons.add(
        'Centralized Control: This contract has an "owner" or "admin" account with elevated privileges over the logic.',
      );
    }

    // 7. Community Trust (Mitigation)
    if (approval.isPopular) {
      final level = approval.popularityScore > 50000 ? 'Very High' : 'High';
      reasons.add(
        'Community Trust: $level on-chain activity detected (${approval.popularityScore}+ transactions). This reduces the risk of an ephemeral scam.',
      );
    }

    // 8. Interaction Trust (Mitigation)
    if (approval.previousInteractions > 0) {
      final text = approval.previousInteractions == 1
          ? 'Established Trust: You have successfully interacted with this contract before.'
          : 'Established Trust: You have successfully interacted with this contract ${approval.previousInteractions} times before.';
      reasons.add(text);
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
