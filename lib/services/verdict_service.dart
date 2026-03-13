import '../models/risk_assessment.dart';

class SecurityVerdict {
  final String titleKey;
  final String summaryKey;
  final String actionKey;
  final RiskLabel label;
  final bool urgent;

  const SecurityVerdict({
    required this.titleKey,
    required this.summaryKey,
    required this.actionKey,
    required this.label,
    required this.urgent,
  });
}

class VerdictService {
  /// Generates a verdict for a specific approval assessment.
  static SecurityVerdict getApprovalVerdict(ApprovalRiskAssessment assessment) {
    // 1. Threat DB Hit (Highest Priority)
    final hasThreat = assessment.reasons.any((r) => r.code == 'threat_db_hit');
    if (hasThreat) {
      return const SecurityVerdict(
        titleKey: 'verdictCriticalThreatTitle',
        summaryKey: 'verdictCriticalThreatSummary',
        actionKey: 'verdictCriticalThreatAction',
        label: RiskLabel.critical,
        urgent: true,
      );
    }

    // 2. Flagged/Suspicious Spender
    final isFlagged = assessment.reasons.any(
      (r) => r.code == 'flagged_spender' || r.code == 'suspicious_spender',
    );
    if (isFlagged) {
      return const SecurityVerdict(
        titleKey: 'verdictSuspiciousSpenderTitle',
        summaryKey: 'verdictSuspiciousSpenderSummary',
        actionKey: 'verdictSuspiciousSpenderAction',
        label: RiskLabel.danger,
        urgent: true,
      );
    }

    // 3. Unlimited + Unknown Spender
    final isUnlimited = assessment.reasons.any(
      (r) => r.code == 'unlimited_allowance',
    );
    final isUnknown = assessment.reasons.any(
      (r) => r.code == 'unknown_spender',
    );
    if (isUnlimited && isUnknown) {
      return const SecurityVerdict(
        titleKey: 'verdictUnlimitedUnknownTitle',
        summaryKey: 'verdictUnlimitedUnknownSummary',
        actionKey: 'verdictUnlimitedUnknownAction',
        label: RiskLabel.danger,
        urgent: true,
      );
    }

    // 4. Caution
    if (assessment.label == RiskLabel.caution) {
      return const SecurityVerdict(
        titleKey: 'verdictCautionTitle',
        summaryKey: 'verdictCautionSummary',
        actionKey: 'verdictCautionAction',
        label: RiskLabel.caution,
        urgent: false,
      );
    }

    // 5. Danger (Not captured by specific rules above, but still high score)
    if (assessment.label == RiskLabel.danger) {
      return const SecurityVerdict(
        titleKey: 'verdictDangerTitle',
        summaryKey: 'verdictDangerSummary',
        actionKey: 'verdictDangerAction',
        label: RiskLabel.danger,
        urgent: true,
      );
    }

    // 6. Safe
    return const SecurityVerdict(
      titleKey: 'verdictSafeTitle',
      summaryKey: 'verdictSafeSummary',
      actionKey: 'verdictSafeAction',
      label: RiskLabel.safe,
      urgent: false,
    );
  }

  /// Generates a verdict for the entire wallet.
  static SecurityVerdict getWalletVerdict(WalletRiskAssessment assessment) {
    if (assessment.label == RiskLabel.critical ||
        assessment.label == RiskLabel.danger) {
      return const SecurityVerdict(
        titleKey: 'verdictWalletHighRiskTitle',
        summaryKey: 'verdictWalletHighRiskSummary',
        actionKey: 'verdictWalletHighRiskAction',
        label: RiskLabel.critical,
        urgent: true,
      );
    }
    if (assessment.label == RiskLabel.caution) {
      return const SecurityVerdict(
        titleKey: 'verdictWalletCautionTitle',
        summaryKey: 'verdictWalletCautionSummary',
        actionKey: 'verdictWalletCautionAction',
        label: RiskLabel.caution,
        urgent: false,
      );
    }
    return const SecurityVerdict(
      titleKey: 'verdictWalletSafeTitle',
      summaryKey: 'verdictWalletSafeSummary',
      actionKey: 'verdictWalletSafeAction',
      label: RiskLabel.safe,
      urgent: false,
    );
  }
}
