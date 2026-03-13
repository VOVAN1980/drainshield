import "../models/approval.dart";

class WalletService {
  static List<ApprovalData> loadFakeApprovals() {
    final max = BigInt.parse(
      "115792089237316195423570985008687907853269984665640564039457584007913129639935",
    );
    const tokenUSDT = "0x55d398326f99059fF775485246999027B3197955";
    const tokenCAKE = "0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82";
    return [
      ApprovalData(
        token: tokenUSDT,
        spenderAddress: "0x10ED43C718714eb63d5aA57B78B54704E256024E",
        spender: "PancakeSwap Router (known)",
        allowance: max,
        isKnownDex: true,
        isVerified: true,
        contractAgeDays: 1200,
      ),
      ApprovalData(
        token: tokenUSDT,
        spenderAddress: "0x1111111111111111111111111111111111111111",
        spender: "Unknown Spender (unverified + new)",
        allowance: max,
        isKnownDex: false,
        isVerified: false,
        contractAgeDays: 7,
      ),
      ApprovalData(
        token: tokenCAKE,
        spenderAddress: "0x2222222222222222222222222222222222222222",
        spender: "Random Verified (unlimited)",
        allowance: max,
        isKnownDex: false,
        isVerified: true,
        contractAgeDays: 400,
      ),
      ApprovalData(
        token: tokenCAKE,
        spenderAddress: "0x3333333333333333333333333333333333333333",
        spender: "Limited Allowance",
        allowance: BigInt.from(1000000),
        isKnownDex: false,
        isVerified: true,
        contractAgeDays: 500,
      ),
      ApprovalData(
        token: tokenUSDT,
        spenderAddress: "0x4444444444444444444444444444444444444444",
        spender: "Zero Allowance",
        allowance: BigInt.zero,
        isKnownDex: false,
        isVerified: true,
        contractAgeDays: 999,
      ),
      ApprovalData(
        token: tokenUSDT,
        spenderAddress: "0x5555555555555555555555555555555555555555",
        spender: "Verified but Age Unknown (0 days)",
        allowance: max,
        isKnownDex: false,
        isVerified: true,
        contractAgeDays: 0,
      ),
      ApprovalData(
        token: tokenCAKE,
        spenderAddress: "0x6666666666666666666666666666666666666666",
        spender: "Known DEX (limited allowance)",
        allowance: BigInt.from(123),
        isKnownDex: true,
        isVerified: true,
        contractAgeDays: 1200,
      ),
    ];
  }
}
