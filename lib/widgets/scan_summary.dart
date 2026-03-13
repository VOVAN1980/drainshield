import 'package:flutter/material.dart';
import '../models/approval.dart';
import '../services/risk_engine.dart';
import '../models/risk_assessment.dart';

class ScanSummary extends StatelessWidget {
  final List<ApprovalData> approvals;
  final int selectedCount;

  const ScanSummary({
    super.key,
    required this.approvals,
    required this.selectedCount,
  });

  int get total => approvals.length;

  int get immediateCount => approvals
      .where(
        (a) =>
            a.assessment.label == RiskLabel.danger ||
            a.assessment.label == RiskLabel.critical,
      )
      .length;

  int get warningCount =>
      approvals.where((a) => a.assessment.label == RiskLabel.caution).length;

  int get unlimitedCount =>
      approvals.where((a) => a.allowance == RiskEngine.maxUint256).length;

  String get _recommendationText {
    if (immediateCount > 0 || unlimitedCount > 0) {
      return "Immediate action recommended: review unlimited and high-risk approvals first.";
    }
    if (warningCount > 0) {
      return "ADVICE: Several contracts have limited permissions. Review spenders you don't recognize.";
    }
    if (total > 0) {
      return "WALLET HEALTHY: All active approvals appear to be within safe parameters.";
    }
    return "No active approvals found.";
  }

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsRow(),
          const SizedBox(height: 16),
          _buildRecommendation(),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _metric(
          "IMMEDIATE",
          "$immediateCount",
          immediateCount > 0 ? const Color(0xFFEF4444) : Colors.white70,
        ),
        _metric(
          "WARNINGS",
          "$warningCount",
          warningCount > 0 ? Colors.orangeAccent : Colors.white70,
        ),
        _metric(
          "UNLIMITED",
          "$unlimitedCount",
          unlimitedCount > 0 ? const Color(0xFF00E5FF) : Colors.white70,
        ),
        _metric(
          "SELECTED",
          "$selectedCount",
          selectedCount > 0 ? const Color(0xFF00FF9D) : Colors.white70,
        ),
      ],
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.white38,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendation() {
    final isUrgent = immediateCount > 0 || unlimitedCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (isUrgent ? Colors.redAccent : const Color(0xFF00FF9D))
            .withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isUrgent ? Icons.security : Icons.info_outline,
            size: 16,
            color: isUrgent ? Colors.redAccent : const Color(0xFF00FF9D),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _recommendationText,
              style: TextStyle(
                color: (isUrgent ? Colors.redAccent : Colors.white70)
                    .withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
