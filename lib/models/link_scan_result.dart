// Data models for Link Shield URL scanning results.

enum LinkVerdict {
  trusted, // 🟢 Only for verified allowlisted domains
  lowData, // 🟡 Unknown link, no data either way
  checkLimited, // 🟡 Incomplete check (API timeout, offline)
  suspicious, // 🟠 Suspicious patterns or single reports
  highRisk, // 🔴 Dangerous patterns, not yet confirmed
  confirmedScam, // 🔴 Confirmed by external sources + reports
}

enum LinkConfidence { low, high }

enum DomainAge { newDomain, unknown, established }

enum DomainReputation { clean, suspicious, listed, notVerified }

enum Web3SignalType {
  walletConnectUri,
  walletDeepLink,
  contractAddress,
  connectWalletFlow,
  claimAirdrop,
  fakeApproval,
}

class Web3Signal {
  final Web3SignalType type;
  final String value;
  final String descriptionKey; // localization key

  const Web3Signal({
    required this.type,
    required this.value,
    required this.descriptionKey,
  });
}

class DomainInfo {
  final String domain;
  final DomainAge age;
  final DomainReputation reputation;

  const DomainInfo({
    required this.domain,
    required this.age,
    required this.reputation,
  });
}

class RedirectInfo {
  final String originalUrl;
  final String finalUrl;
  final int redirectCount;
  final bool isSuspicious;

  const RedirectInfo({
    required this.originalUrl,
    required this.finalUrl,
    required this.redirectCount,
    required this.isSuspicious,
  });
}

class LinkScanResult {
  final String originalUrl;
  final String? finalUrl;
  final LinkVerdict verdict;
  final LinkConfidence confidence;
  final int riskScore; // 0-100
  final DomainInfo? domainInfo;
  final RedirectInfo? redirectInfo;
  final List<Web3Signal> web3Signals;
  final List<String> riskFactors; // localization keys
  final DateTime scannedAt;
  final bool isOfflineResult;

  const LinkScanResult({
    required this.originalUrl,
    this.finalUrl,
    required this.verdict,
    required this.confidence,
    required this.riskScore,
    this.domainInfo,
    this.redirectInfo,
    this.web3Signals = const [],
    this.riskFactors = const [],
    required this.scannedAt,
    this.isOfflineResult = false,
  });

  /// Whether the "Open Link" button should be hidden completely
  /// (SUSPICIOUS / HIGH_RISK / CONFIRMED_SCAM).
  bool get isOpenLinkBlocked =>
      verdict == LinkVerdict.suspicious ||
      verdict == LinkVerdict.highRisk ||
      verdict == LinkVerdict.confirmedScam;

  /// Whether the "Open Link" button should be secondary/small
  /// (LOW_DATA / CHECK_LIMITED — not enough info to vouch for safety).
  bool get isOpenLinkSecondary =>
      verdict == LinkVerdict.lowData || verdict == LinkVerdict.checkLimited;
}
