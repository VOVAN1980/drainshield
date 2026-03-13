import '../models/approval.dart';
import 'risk_engine.dart'; // Для константы maxUint256

/// Service providing mock approval data for debug testing of the UI.
/// This isolated service ensures that real scan logic is never tainted.
class MockScanService {
  static List<ApprovalData> getEmpty() => [];

  static List<ApprovalData> getSafe() {
    return [
      ApprovalData(
        token: "0xMockTokenA",
        tokenSymbol: "USDT",
        spenderAddress: "0xPancakeSwap",
        spender: "PancakeSwap Router",
        allowance: BigInt.from(100 * 10e18), // Fixed amount
        riskLevel: RiskLevel.safe,
        reputation: SpenderReputation.trusted,
        isKnownDex: true,
        isVerified: true,
      ),
      ApprovalData(
        token: "0xMockTokenB",
        tokenSymbol: "USDC",
        spenderAddress: "0xUniswap",
        spender: "Uniswap V3",
        allowance: BigInt.from(500 * 10e18),
        riskLevel: RiskLevel.safe,
        reputation: SpenderReputation.trusted,
        isKnownDex: true,
        isVerified: true,
      ),
    ];
  }

  static List<ApprovalData> getWarning() {
    return [
      ApprovalData(
        token: "0xMockTokenC",
        tokenSymbol: "WBNB",
        spenderAddress: "0xUnknownSpender1",
        spender: "Unknown Contract 1",
        allowance: BigInt.from(50 * 10e18),
        riskLevel: RiskLevel.warning,
        reputation: SpenderReputation.unknown,
        isKnownDex: false,
        isVerified: false,
        contractAgeDays: 5,
      ),
      ApprovalData(
        token: "0xMockTokenD",
        tokenSymbol: "BUSD",
        spenderAddress: "0xUnknownSpender2",
        spender: "Unknown Contract 2 (New)",
        allowance: BigInt.from(1000 * 10e18),
        riskLevel: RiskLevel.warning,
        reputation: SpenderReputation.unknown,
        isKnownDex: false,
        isVerified: false,
        contractAgeDays: 1,
      ),
    ];
  }

  static List<ApprovalData> getDanger() {
    return [
      ApprovalData(
        token: "0xMockTokenE",
        tokenSymbol: "DAI",
        spenderAddress: "0xSuspiciousSpender",
        spender: "Phishing Contract",
        allowance: RiskEngine.maxUint256,
        riskLevel: RiskLevel.danger,
        reputation: SpenderReputation.suspicious,
        isKnownDex: false,
        isVerified: false,
        contractAgeDays: 0,
      ),
    ];
  }

  static List<ApprovalData> getUnlimited() {
    return [
      ApprovalData(
        token: "0xMockTokenF",
        tokenSymbol: "ETH",
        spenderAddress: "0xTrustedUnlimited",
        spender: "1inch Router",
        allowance: RiskEngine.maxUint256,
        riskLevel: RiskLevel.warning, // Still warning because unlimited
        reputation: SpenderReputation.trusted,
        isKnownDex: true,
        isVerified: true,
        contractAgeDays: 500,
      ),
    ];
  }

  static List<ApprovalData> getMixed() {
    return [...getDanger(), ...getSafe(), ...getWarning(), ...getUnlimited()];
  }

  static List<ApprovalData> getStress() {
    final List<ApprovalData> stressList = [];
    for (int i = 0; i < 60; i++) {
      final isDanger = i % 10 == 0;
      final isWarning = i % 5 == 0 && !isDanger;

      stressList.add(
        ApprovalData(
          token: "0xStressToken$i",
          tokenSymbol: "TKN$i",
          spenderAddress: "0xSpender$i",
          spender: isDanger
              ? "Malicious $i"
              : (isWarning ? "Unknown $i" : "Trusted $i"),
          allowance: isDanger || i % 3 == 0
              ? RiskEngine.maxUint256
              : BigInt.from((i + 1) * 100 * 10e18),
          riskLevel: isDanger
              ? RiskLevel.danger
              : (isWarning ? RiskLevel.warning : RiskLevel.safe),
          reputation: isDanger
              ? SpenderReputation.suspicious
              : (isWarning
                  ? SpenderReputation.unknown
                  : SpenderReputation.trusted),
          isKnownDex: !isDanger && !isWarning,
          isVerified: !isDanger && !isWarning,
          contractAgeDays: isDanger ? 1 : 100,
        ),
      );
    }
    return stressList;
  }
}
