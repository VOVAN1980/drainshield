import 'package:flutter/foundation.dart';
import '../../models/link_scan_result.dart';

/// Enhanced local URL analyzer (Milestone 2).
///
/// Improvements over M1:
/// - Punycode / homograph attack detection
/// - URL shortener detection
/// - Expanded Web3 dApp allowlist
/// - Better typosquatting with Levenshtein distance
/// - More scam keywords and patterns
/// - Data URI / javascript URI detection
/// - Excessive query parameter detection
class LocalLinkAnalyzer {
  // ── Trusted domains (green badge only for these) ──────────────────────────
  static const _trustedDomains = <String>{
    // Wallets
    'metamask.io',
    'trustwallet.com',
    'phantom.app',
    'rainbow.me',
    'rabby.io',
    'zerion.io',
    'zapper.xyz',
    'safe.global',
    'app.safe.global',
    'ledger.com',
    'trezor.io',
    // DEXes
    'uniswap.org',
    'app.uniswap.org',
    'pancakeswap.finance',
    'curve.fi',
    'app.1inch.io',
    '1inch.io',
    'raydium.io',
    'jupiter.ag',
    'jup.ag',
    'orca.so',
    'sushi.com',
    'app.sushi.com',
    'quickswap.exchange',
    'traderjoexyz.com',
    'spooky.fi',
    'sunswap.com',
    'sun.io',
    // DeFi
    'aave.com',
    'app.aave.com',
    'compound.finance',
    'lido.fi',
    'stake.lido.fi',
    'rocketpool.net',
    'frax.finance',
    'makerdao.com',
    'app.spark.fi',
    'yearn.fi',
    'convexfinance.com',
    'pendle.finance',
    'eigenlayer.xyz',
    // NFT / Markets
    'opensea.io',
    'blur.io',
    'magiceden.io',
    'rarible.com',
    'foundation.app',
    'looksrare.org',
    'x2y2.io',
    // Bridges
    'bridge.arbitrum.io',
    'app.optimism.io',
    'portal.polygon.technology',
    'stargate.finance',
    'across.to',
    'hop.exchange',
    'cbridge.celer.network',
    'wormhole.com',
    // Explorers
    'etherscan.io',
    'bscscan.com',
    'polygonscan.com',
    'arbiscan.io',
    'basescan.org',
    'optimistic.etherscan.io',
    'tronscan.org',
    'solscan.io',
    'explorer.solana.com',
    'snowtrace.io',
    'ftmscan.com',
    'gnosisscan.io',
    'celoscan.io',
    // Exchanges
    'binance.com',
    'coinbase.com',
    'kraken.com',
    'okx.com',
    'bybit.com',
    'kucoin.com',
    'gate.io',
    'htx.com',
    'mexc.com',
    'bitget.com',
    'crypto.com',
    // Data / Analytics
    'coingecko.com',
    'coinmarketcap.com',
    'dexscreener.com',
    'dextools.io',
    'defillama.com',
    'debank.com',
    'nansen.ai',
    'dune.com',
    'messari.io',
    'glassnode.com',
    // General
    'google.com',
    'github.com',
    'twitter.com',
    'x.com',
    'telegram.org',
    't.me',
    'discord.com',
    'discord.gg',
    'youtube.com',
    'reddit.com',
    'linkedin.com',
    'medium.com',
    'mirror.xyz',
    'substack.com',
    'notion.so',
    // DrainShield
    'drainshield.guard',
    'vovan1980.github.io',
  };

  // ── URL shorteners (suspicious when wrapping Web3 links) ──────────────────
  static const _urlShorteners = <String>{
    'bit.ly',
    'bitly.com',
    't.co',
    'tinyurl.com',
    'goo.gl',
    'ow.ly',
    'is.gd',
    'buff.ly',
    'rb.gy',
    'short.io',
    'cutt.ly',
    'shorturl.at',
    'tiny.cc',
    'lnkd.in',
    's.id',
    'qr.ae',
    'v.gd',
    'clck.ru',
    'u.to',
    'shrtco.de',
  };

  // ── Suspicious TLDs often used in phishing ────────────────────────────────
  static const _suspiciousTlds = <String>{
    '.xyz',
    '.top',
    '.click',
    '.buzz',
    '.info',
    '.win',
    '.loan',
    '.racing',
    '.review',
    '.party',
    '.trade',
    '.bid',
    '.stream',
    '.gq',
    '.cf',
    '.tk',
    '.ml',
    '.ga',
    '.cam',
    '.rest',
    '.monster',
    '.sbs',
    '.cfd',
    '.cyou',
    '.icu',
  };

  // ── Web3 scam keywords in URL path/query ──────────────────────────────────
  static const _web3ScamKeywords = <String>[
    'claim-airdrop',
    'free-mint',
    'connect-wallet',
    'approve-token',
    'claim-reward',
    'bonus-claim',
    'free-token',
    'airdrop-claim',
    'wallet-verify',
    'wallet-sync',
    'wallet-validate',
    'seed-phrase',
    'private-key',
    'recovery-phrase',
    'claim-nft',
    'free-nft',
    'mint-free',
    'presale-mint',
    'whitelist-mint',
    'claim-tokens',
    'unlock-wallet',
    'restore-wallet',
    'verify-wallet',
    'confirm-wallet',
    'dapp-approve',
    'token-approval',
    'swap-bonus',
    'staking-reward',
    'yield-bonus',
    'liquidity-reward',
  ];

  // ── Crypto brand names for typosquatting detection ─────────────────────────
  static const _brandNames = <String, String>{
    'metamask': 'metamask.io',
    'uniswap': 'uniswap.org',
    'pancakeswap': 'pancakeswap.finance',
    'opensea': 'opensea.io',
    'coinbase': 'coinbase.com',
    'binance': 'binance.com',
    'trustwallet': 'trustwallet.com',
    'phantom': 'phantom.app',
    'aave': 'aave.com',
    'compound': 'compound.finance',
    'lido': 'lido.fi',
    'ethereum': 'ethereum.org',
    'solana': 'solana.com',
    'arbitrum': 'arbitrum.io',
    'optimism': 'optimism.io',
    'polygon': 'polygon.technology',
    'sushiswap': 'sushi.com',
    'curve': 'curve.fi',
    'jupiter': 'jupiter.ag',
    'raydium': 'raydium.io',
    'ledger': 'ledger.com',
    'trezor': 'trezor.io',
  };

  // ── Homograph / Punycode confusion characters ─────────────────────────────
  static const _homoglyphs = <String, String>{
    'а': 'a', // Cyrillic а → Latin a
    'е': 'e', // Cyrillic е → Latin e
    'о': 'o', // Cyrillic о → Latin o
    'р': 'p', // Cyrillic р → Latin p
    'с': 'c', // Cyrillic с → Latin c
    'х': 'x', // Cyrillic х → Latin x
    'у': 'y', // Cyrillic у → Latin y
    'і': 'i', // Ukrainian і → Latin i
    'ⅰ': 'i', // Roman numeral
    'ⅼ': 'l', // Roman numeral
    'ο': 'o', // Greek omicron
    'α': 'a', // Greek alpha
    'ε': 'e', // Greek epsilon
    'ν': 'v', // Greek nu
    'τ': 't', // Greek tau
    'κ': 'k', // Greek kappa
    'ρ': 'p', // Greek rho
    '0': 'o', // Zero → o
    '1': 'l', // One → l
    '!': 'l', // Exclamation → l
  };

  /// Main analysis entry point. Returns a [LinkScanResult].
  static Future<LinkScanResult> analyze(String rawUrl) async {
    debugPrint('[LocalAnalyzer] ▶ Analyzing: $rawUrl');

    // 0. Check for dangerous URI schemes
    final schemeCheck = _checkDangerousScheme(rawUrl);
    if (schemeCheck != null) return schemeCheck;

    // 1. Parse URL
    final uri = _parseUrl(rawUrl);
    if (uri == null) {
      return LinkScanResult(
        originalUrl: rawUrl,
        verdict: LinkVerdict.suspicious,
        confidence: LinkConfidence.low,
        riskScore: 60,
        riskFactors: ['linkRiskInvalidUrl'],
        scannedAt: DateTime.now(),
      );
    }

    final domain = uri.host.toLowerCase();
    final rootDomain = _extractRootDomain(domain);
    final fullPath = uri.toString().toLowerCase();

    int riskScore = 0;
    final riskFactors = <String>[];
    final web3Signals = <Web3Signal>[];

    // 2. Check trusted allowlist
    if (_trustedDomains.contains(domain) ||
        _trustedDomains.contains(rootDomain)) {
      debugPrint('[LocalAnalyzer] ✅ Trusted domain: $domain');
      return LinkScanResult(
        originalUrl: rawUrl,
        finalUrl: uri.toString(),
        verdict: LinkVerdict.trusted,
        confidence: LinkConfidence.high,
        riskScore: 0,
        domainInfo: DomainInfo(
          domain: domain,
          age: DomainAge.established,
          reputation: DomainReputation.clean,
        ),
        scannedAt: DateTime.now(),
      );
    }

    // 3. Check URL shortener
    if (_urlShorteners.contains(domain) ||
        _urlShorteners.contains(rootDomain)) {
      riskScore += 25;
      riskFactors.add('linkRiskUrlShortener');
    }

    // 4. Check IP-based URL (no domain name)
    if (_isIpAddress(domain)) {
      riskScore += 40;
      riskFactors.add('linkRiskIpAddress');
    }

    // 5. Check suspicious TLDs
    for (final tld in _suspiciousTlds) {
      if (domain.endsWith(tld)) {
        riskScore += 20;
        riskFactors.add('linkRiskSuspiciousTld');
        break;
      }
    }

    // 6. Check excessive subdomain depth (more than 3 dots = suspicious)
    final dotCount = domain.split('.').length - 1;
    if (dotCount > 3) {
      riskScore += 25;
      riskFactors.add('linkRiskDeepSubdomain');
    }

    // 7. Check Web3 scam keywords in URL
    for (final keyword in _web3ScamKeywords) {
      if (fullPath.contains(keyword)) {
        riskScore += 30;
        riskFactors.add('linkRiskWeb3ScamKeyword');
        web3Signals.add(Web3Signal(
          type: Web3SignalType.claimAirdrop,
          value: keyword,
          descriptionKey: 'linkWeb3ScamKeywordFound',
        ));
        break;
      }
    }

    // 8. Check for Ethereum addresses in URL
    final ethAddressRegex = RegExp(r'0x[a-fA-F0-9]{40}');
    if (ethAddressRegex.hasMatch(fullPath)) {
      riskScore += 15;
      riskFactors.add('linkRiskContractInUrl');
      final match = ethAddressRegex.firstMatch(fullPath)!;
      web3Signals.add(Web3Signal(
        type: Web3SignalType.contractAddress,
        value: match.group(0)!,
        descriptionKey: 'linkWeb3ContractFound',
      ));
    }

    // 9. Check for WalletConnect URI
    if (fullPath.contains('wc:') || fullPath.contains('wc%3A')) {
      riskScore += 20;
      riskFactors.add('linkRiskWalletConnect');
      web3Signals.add(const Web3Signal(
        type: Web3SignalType.walletConnectUri,
        value: 'wc:',
        descriptionKey: 'linkWeb3WalletConnectFound',
      ));
    }

    // 10. Check for wallet deep links
    const walletSchemes = [
      'metamask://',
      'trust://',
      'phantom://',
      'rainbow://',
      'zerion://',
      'rabby://',
    ];
    for (final scheme in walletSchemes) {
      if (fullPath.contains(scheme)) {
        riskScore += 20;
        riskFactors.add('linkRiskWalletDeepLink');
        web3Signals.add(Web3Signal(
          type: Web3SignalType.walletDeepLink,
          value: scheme,
          descriptionKey: 'linkWeb3DeepLinkFound',
        ));
        break;
      }
    }

    // 11. Punycode / Homograph attack detection
    final homographResult = _checkHomographAttack(domain);
    if (homographResult != null) {
      riskScore += 45;
      riskFactors.add('linkRiskHomograph');
      debugPrint(
          '[LocalAnalyzer] ⚠ Homograph detected: $domain looks like $homographResult');
    }

    // 12. Typosquatting check (improved Levenshtein)
    final typosquatBrand = _checkTyposquatting(domain);
    if (typosquatBrand != null) {
      riskScore += 35;
      riskFactors.add('linkRiskTyposquatting');
      debugPrint('[LocalAnalyzer] ⚠ Typosquat of: $typosquatBrand');
    }

    // 13. HTTP (not HTTPS) warning
    if (uri.scheme == 'http') {
      riskScore += 10;
      riskFactors.add('linkRiskNoHttps');
    }

    // 14. Suspicious query params (connect, approve, etc.)
    final queryLower = uri.query.toLowerCase();
    const suspiciousParams = [
      'approve=',
      'spender=',
      'private_key=',
      'seed=',
      'mnemonic=',
      'wallet=0x',
    ];
    for (final param in suspiciousParams) {
      if (queryLower.contains(param)) {
        riskScore += 20;
        riskFactors.add('linkRiskSuspiciousParams');
        break;
      }
    }

    // 15. Extremely long URL (often used to hide real destination)
    if (rawUrl.length > 500) {
      riskScore += 10;
      riskFactors.add('linkRiskLongUrl');
    }

    // Clamp score, enforce minimum 25 for unknown (non-allowlisted) domains
    riskScore = riskScore.clamp(0, 100);
    if (riskScore < 25) riskScore = 25; // Unknown != safe

    // Determine verdict
    final verdict = _resolveVerdict(riskScore, riskFactors);

    // Without external APIs, we CANNOT claim "clean" — always "notVerified"
    final domainRep = riskScore >= 40
        ? DomainReputation.suspicious
        : DomainReputation.notVerified;

    debugPrint(
        '[LocalAnalyzer] ⏹ Result: verdict=$verdict, riskScore=$riskScore, factors=${riskFactors.length}');

    return LinkScanResult(
      originalUrl: rawUrl,
      finalUrl: uri.toString(),
      verdict: verdict,
      confidence: LinkConfidence.low, // Local-only = always low confidence
      riskScore: riskScore,
      domainInfo: DomainInfo(
        domain: domain,
        age: DomainAge.unknown,
        reputation: domainRep,
      ),
      web3Signals: web3Signals,
      riskFactors: riskFactors,
      scannedAt: DateTime.now(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Block dangerous URI schemes (javascript:, data:, blob:)
  static LinkScanResult? _checkDangerousScheme(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.startsWith('javascript:') ||
        lower.startsWith('data:') ||
        lower.startsWith('blob:') ||
        lower.startsWith('vbscript:')) {
      return LinkScanResult(
        originalUrl: raw,
        verdict: LinkVerdict.highRisk,
        confidence: LinkConfidence.high,
        riskScore: 90,
        riskFactors: ['linkRiskDangerousScheme'],
        scannedAt: DateTime.now(),
      );
    }
    return null;
  }

  static Uri? _parseUrl(String raw) {
    var url = raw.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) return null;
      return uri;
    } catch (_) {
      return null;
    }
  }

  static String _extractRootDomain(String domain) {
    final parts = domain.split('.');
    if (parts.length <= 2) return domain;
    return parts.sublist(parts.length - 2).join('.');
  }

  static bool _isIpAddress(String domain) {
    final ipv4 = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    return ipv4.hasMatch(domain);
  }

  /// Detect Punycode / homograph attacks.
  /// Returns the "real" brand name if a homograph is detected, null otherwise.
  static String? _checkHomographAttack(String domain) {
    // Convert domain to "normalized" form by replacing lookalike chars
    String normalized = domain;
    for (final entry in _homoglyphs.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    // If normalization changed the domain, check if it now matches a known brand
    if (normalized == domain) return null;
    for (final brand in _brandNames.keys) {
      if (normalized.contains(brand)) {
        return brand;
      }
    }
    // Even if it doesn't match a brand, mixed scripts = suspicious
    if (_hasMixedScripts(domain)) {
      return '[mixed scripts]';
    }
    return null;
  }

  /// Check if domain contains characters from multiple Unicode scripts.
  static bool _hasMixedScripts(String domain) {
    bool hasLatin = false;
    bool hasCyrillic = false;
    bool hasGreek = false;
    for (final codeUnit in domain.runes) {
      if (codeUnit >= 0x0041 && codeUnit <= 0x007A) hasLatin = true;
      if (codeUnit >= 0x0400 && codeUnit <= 0x04FF) hasCyrillic = true;
      if (codeUnit >= 0x0370 && codeUnit <= 0x03FF) hasGreek = true;
    }
    int scriptCount = 0;
    if (hasLatin) scriptCount++;
    if (hasCyrillic) scriptCount++;
    if (hasGreek) scriptCount++;
    return scriptCount > 1;
  }

  /// Typosquatting check using Levenshtein distance.
  static String? _checkTyposquatting(String domain) {
    // Strip www and extract the "name" part (before TLD)
    final clean = domain.replaceFirst(RegExp(r'^www\.'), '');
    final parts = clean.split('.');
    if (parts.length < 2) return null;
    // Get the main name (everything before the last TLD segment)
    final name = parts.sublist(0, parts.length - 1).join('');

    for (final entry in _brandNames.entries) {
      final brand = entry.key;
      if (name == brand) continue; // exact match = legitimate
      if (name.contains(brand) && name.length > brand.length + 3) {
        continue; // subdomain
      }

      final dist = _levenshteinDistance(name, brand);
      if (dist > 0 && dist <= 2) {
        return brand;
      }
    }
    return null;
  }

  /// Standard Levenshtein distance algorithm.
  static int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    // Optimization: if length difference > 3, skip
    if ((s.length - t.length).abs() > 3) return 99;

    final m = s.length;
    final n = t.length;
    final d = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 0; i <= m; i++) {
      d[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      d[0][j] = j;
    }

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1, // deletion
          d[i][j - 1] + 1, // insertion
          d[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return d[m][n];
  }

  static LinkVerdict _resolveVerdict(int riskScore, List<String> factors) {
    if (riskScore >= 70) return LinkVerdict.highRisk;
    if (riskScore >= 40) return LinkVerdict.suspicious;
    return LinkVerdict
        .lowData; // No data = lowData, never green without allowlist
  }
}
