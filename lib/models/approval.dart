import 'risk_assessment.dart';

enum RiskLevel { safe, warning, danger }

enum SpenderReputation {
  trusted,
  unknown,
  suspicious,
  flagged,
  dex,
  bridge,
  safety
}

class ApprovalData {
  final int chainId; // 56
  final String token; // token contract 0x...
  final String? tokenName;
  final String? tokenSymbol;
  final String spenderAddress; // spender 0x...
  final String spender; // label for UI
  BigInt allowance;
  final int decimals; // token decimals

  final bool isKnownDex;
  final bool isVerified;
  final int contractAgeDays;

  RiskLevel riskLevel;
  SpenderReputation reputation;

  // New granular assessment field
  ApprovalRiskAssessment assessment;

  ApprovalData({
    this.chainId = 56,
    required this.token,
    this.tokenName,
    this.tokenSymbol,
    required this.spenderAddress,
    required this.spender,
    required this.allowance,
    this.decimals = 18,
    this.isKnownDex = false,
    this.isVerified = false,
    this.contractAgeDays = 0,
    this.riskLevel = RiskLevel.safe,
    this.reputation = SpenderReputation.unknown,
    ApprovalRiskAssessment? assessment,
  }) : assessment = assessment ?? ApprovalRiskAssessment.safe();
}
