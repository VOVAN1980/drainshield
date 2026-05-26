// DrainShield Link Shield API — Cloudflare Worker v2.2
// Truecaller-style reputation system for URLs/domains
// M3: Own DB (D1 + KV)
// M4: External feeds — cache-first, query once, remember forever

export interface Env {
  DB: D1Database;
  CACHE: KVNamespace;
  GOOGLE_SAFE_BROWSING_KEY?: string; // wrangler secret put
}

// ── CORS ────────────────────────────────────────────────────────────────────

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

// ── Helpers ─────────────────────────────────────────────────────────────────

function extractDomain(url: string): string {
  try {
    let u = url.trim();
    if (!u.startsWith("http://") && !u.startsWith("https://")) u = "https://" + u;
    return new URL(u).hostname.toLowerCase();
  } catch {
    const m = url.match(/([a-zA-Z0-9-]+\.[a-zA-Z]{2,})/);
    return m ? m[1].toLowerCase() : url.toLowerCase();
  }
}

function rootDomain(domain: string): string {
  const parts = domain.split(".");
  if (parts.length <= 2) return domain;
  return parts.slice(-2).join(".");
}

async function sha256(text: string): Promise<string> {
  const data = new TextEncoder().encode(text.toLowerCase().trim());
  const hash = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function generateId(): string {
  return crypto.randomUUID();
}

function nowISO(): string {
  return new Date().toISOString();
}

// ══════════════════════════════════════════════════════════════════════════════
// M4: EXTERNAL THREAT INTELLIGENCE ADAPTERS
// All free, no API keys required.
// Cache-first: check KV → check D1 source_hits → only then query external.
// Once found → save to D1 forever. Never re-query for same domain.
// ══════════════════════════════════════════════════════════════════════════════

interface ExternalHit {
  source: string;
  verdict: string;
  riskDelta: number;
  confidenceDelta: number;
  details?: string;
}

// ── 1. MetaMask eth-phishing-detect ─────────────────────────────────────────
// Free open-source list: ~15K+ phishing domains targeting crypto users

async function checkMetaMaskPhishing(domain: string, root: string, env: Env): Promise<ExternalHit | null> {
  const cacheKey = "metamask:phishing:list";

  try {
    let domains: string[] | null = null;
    const cached = await env.CACHE.get(cacheKey, "json");

    if (cached) {
      domains = cached as string[];
    } else {
      const resp = await fetch(
        "https://raw.githubusercontent.com/MetaMask/eth-phishing-detect/master/src/config.json",
        { headers: { "User-Agent": "DrainShield/2.1" } }
      );
      if (resp.ok) {
        const config = await resp.json() as any;
        domains = config.blacklist || [];
        // Cache list for 6 hours
        await env.CACHE.put(cacheKey, JSON.stringify(domains), { expirationTtl: 21600 });
      }
    }

    if (domains) {
      if (domains.includes(domain) || domains.includes(root)) {
        return {
          source: "metamask",
          verdict: "phishing",
          riskDelta: 30,
          confidenceDelta: 3,
          details: "Crypto phishing domain (MetaMask blacklist)",
        };
      }
    }
  } catch (e) {
    console.error("[MetaMask] Error:", e);
  }
  return null;
}

// ── 2. URLhaus (abuse.ch) ───────────────────────────────────────────────────
// Free malware URL database. ~1M+ entries.

async function checkURLhaus(domain: string, env: Env): Promise<ExternalHit | null> {
  try {
    const resp = await fetch("https://urlhaus-api.abuse.ch/v1/host/", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: `host=${encodeURIComponent(domain)}`,
    });

    if (resp.ok) {
      const data = await resp.json() as any;
      if (data.query_status === "no_results" || !data.urls || data.urls.length === 0) {
        return null;
      }

      return {
        source: "urlhaus",
        verdict: "malware",
        riskDelta: 25,
        confidenceDelta: 3,
        details: `${data.urls.length} malware URLs, threat: ${data.urls[0]?.threat || "unknown"}`,
      };
    }
  } catch (e) {
    console.error("[URLhaus] Error:", e);
  }
  return null;
}

// ── 3. GoPlus Security API ──────────────────────────────────────────────────
// Free Web3 security API for phishing site detection

async function checkGoPlus(url: string, env: Env): Promise<ExternalHit | null> {
  try {
    const resp = await fetch(
      `https://api.gopluslabs.com/api/v1/phishing_site?url=${encodeURIComponent(url)}`,
      { headers: { "User-Agent": "DrainShield/2.1" } }
    );

    if (resp.ok) {
      const data = await resp.json() as any;
      if (data.result?.phishing_site === 1) {
        return {
          source: "goplus",
          verdict: "phishing",
          riskDelta: 25,
          confidenceDelta: 3,
          details: "Web3 phishing site (GoPlus)",
        };
      }
    }
  } catch (e) {
    console.error("[GoPlus] Error:", e);
  }
  return null;
}

// ── 4. OpenPhish ────────────────────────────────────────────────────────────
// Free community phishing feed (URLs list)

async function checkOpenPhish(domain: string, env: Env): Promise<ExternalHit | null> {
  const cacheKey = "openphish:feed:domains";

  try {
    let domains: string[] | null = null;
    const cached = await env.CACHE.get(cacheKey, "json");

    if (cached) {
      domains = cached as string[];
    } else {
      const resp = await fetch("https://openphish.com/feed.txt", {
        headers: { "User-Agent": "DrainShield/2.1" },
      });
      if (resp.ok) {
        const text = await resp.text();
        const domainSet = new Set<string>();
        for (const line of text.split("\n")) {
          const trimmed = line.trim();
          if (!trimmed) continue;
          try {
            const u = new URL(trimmed);
            domainSet.add(u.hostname.toLowerCase());
          } catch {}
        }
        domains = Array.from(domainSet);
        // Cache for 4 hours
        await env.CACHE.put(cacheKey, JSON.stringify(domains), { expirationTtl: 14400 });
      }
    }

    if (domains && domains.includes(domain)) {
      return {
        source: "openphish",
        verdict: "phishing",
        riskDelta: 25,
        confidenceDelta: 3,
        details: "Active phishing URL (OpenPhish feed)",
      };
    }
  } catch (e) {
    console.error("[OpenPhish] Error:", e);
  }
  return null;
}

// ── 5. Google Safe Browsing ─────────────────────────────────────────────────
// Requires API key stored as Cloudflare secret (free 10K lookups/day)

async function checkGoogleSafeBrowsing(url: string, env: Env): Promise<ExternalHit | null> {
  if (!env.GOOGLE_SAFE_BROWSING_KEY) return null;

  try {
    const resp = await fetch(
      `https://safebrowsing.googleapis.com/v4/threatMatches:find?key=${env.GOOGLE_SAFE_BROWSING_KEY}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          client: { clientId: "drainshield", clientVersion: "2.1" },
          threatInfo: {
            threatTypes: [
              "MALWARE",
              "SOCIAL_ENGINEERING",
              "UNWANTED_SOFTWARE",
              "POTENTIALLY_HARMFUL_APPLICATION",
            ],
            platformTypes: ["ANY_PLATFORM"],
            threatEntryTypes: ["URL"],
            threatEntries: [{ url }],
          },
        }),
      }
    );

    if (resp.ok) {
      const data = await resp.json() as any;
      if (data.matches && data.matches.length > 0) {
        const threatType = data.matches[0].threatType || "UNKNOWN";
        return {
          source: "google_sb",
          verdict: threatType.toLowerCase().includes("malware") ? "malware" : "phishing",
          riskDelta: 35,
          confidenceDelta: 4,
          details: `Google Safe Browsing: ${threatType}`,
        };
      }
    }
  } catch (e) {
    console.error("[Google SB] Error:", e);
  }
  return null;
}

// ── 6. PhishTank ────────────────────────────────────────────────────────────
// Free phishing URL verification

async function checkPhishTank(url: string, env: Env): Promise<ExternalHit | null> {
  try {
    const resp = await fetch("https://checkurl.phishtank.com/checkurl/", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: `url=${encodeURIComponent(url)}&format=json&app_key=`,
    });

    if (resp.ok) {
      const data = await resp.json() as any;
      if (data.results?.in_database && data.results?.valid) {
        return {
          source: "phishtank",
          verdict: "phishing",
          riskDelta: 25,
          confidenceDelta: 3,
          details: "Verified phishing URL (PhishTank)",
        };
      }
    }
  } catch (e) {
    console.error("[PhishTank] Error:", e);
  }
  return null;
}

// ── Check if domain was already queried externally ──────────────────────────
// Returns true if we already have source_hits for this domain → skip external

async function hasExternalData(domain: string, root: string, env: Env): Promise<boolean> {
  // Check if we already queried this domain against external feeds
  const cacheKey = `ext_checked:${domain}`;
  const checked = await env.CACHE.get(cacheKey);
  if (checked === "1") return true;

  // Also check D1: if source_hits exist, we already have data
  const row = await env.DB.prepare(
    "SELECT COUNT(*) as cnt FROM source_hits WHERE domain = ? OR domain = ?"
  ).bind(domain, root).first<any>();

  return (row?.cnt || 0) > 0;
}

// ── Mark domain as externally checked ───────────────────────────────────────

async function markExternallyChecked(domain: string, env: Env): Promise<void> {
  // Mark in KV for 24 hours so we don't re-check too often
  await env.CACHE.put(`ext_checked:${domain}`, "1", { expirationTtl: 86400 });
}

// ── Run all external checks in parallel ─────────────────────────────────────
// Only called when we have NO existing data for this domain

async function queryExternalSources(
  domain: string,
  root: string,
  url: string,
  env: Env
): Promise<ExternalHit[]> {
  const checks = await Promise.allSettled([
    checkMetaMaskPhishing(domain, root, env),
    checkURLhaus(domain, env),
    checkGoPlus(url, env),
    checkOpenPhish(domain, env),
    checkGoogleSafeBrowsing(url, env),
    checkPhishTank(url, env),
  ]);

  const hits: ExternalHit[] = [];
  for (const result of checks) {
    if (result.status === "fulfilled" && result.value) {
      hits.push(result.value);
    }
  }
  return hits;
}

// ── Save external hits to D1 (permanent memory) ────────────────────────────

async function saveExternalHits(domain: string, hits: ExternalHit[], env: Env): Promise<void> {
  for (const hit of hits) {
    try {
      await env.DB.prepare(`
        INSERT OR IGNORE INTO source_hits (id, domain, source, verdict, risk_score, details_json, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `).bind(generateId(), domain, hit.source, hit.verdict, hit.riskDelta, hit.details || null, nowISO()).run();
    } catch (e) {
      console.error(`[saveHit] Error for ${hit.source}:`, e);
    }
  }

  // If any hit found risk, auto-promote to threat_domains
  if (hits.length > 0) {
    const maxRisk = hits.reduce((max, h) => Math.max(max, h.riskDelta), 0);
    const sourceList = hits.map((h) => h.source).join(",");

    await env.DB.prepare(`
      INSERT INTO threat_domains (domain, verdict, risk_score, reason, source, confidence, report_count, created_at, updated_at)
      VALUES (?, 'suspicious', ?, ?, ?, 50, 0, ?, ?)
      ON CONFLICT(domain) DO UPDATE SET
        risk_score = MAX(risk_score, excluded.risk_score),
        updated_at = ?
    `).bind(domain, Math.min(25 + maxRisk, 85), `External feed: ${sourceList}`, sourceList, nowISO(), nowISO(), nowISO()).run();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VERDICT ENGINE
// ══════════════════════════════════════════════════════════════════════════════

interface VerdictResult {
  verdict: string;
  riskScore: number;
  confidence: string;
  reasons: string[];
  sources: string[];
  reportCount: number;
  userLabels: string[];
}

async function computeVerdict(
  domain: string,
  env: Env,
  freshExternalHits: ExternalHit[] = [],
  url: string = ""
): Promise<VerdictResult> {
  const root = rootDomain(domain);
  const reasons: string[] = [];
  const sources: string[] = ["drainshield"];
  let riskScore = 25;
  let confidencePoints = 0;

  // 1. Check trusted_domains
  const trusted = await env.DB.prepare(
    "SELECT domain, label FROM trusted_domains WHERE domain = ? OR domain = ?"
  ).bind(domain, root).first();

  if (trusted) {
    // Trusted can still be overridden if external feeds found threats
    let overridden = false;
    for (const hit of freshExternalHits) {
      if (hit.riskDelta >= 25) {
        overridden = true;
        break;
      }
    }
    if (!overridden) {
      return {
        verdict: "trusted",
        riskScore: 0,
        confidence: "high",
        reasons: ["linkShareTrustedReason1"],
        sources,
        reportCount: 0,
        userLabels: [],
      };
    }
  }

  // 2. Check threat_domains (own DB)
  const threat = await env.DB.prepare(
    "SELECT * FROM threat_domains WHERE domain = ? OR domain = ?"
  ).bind(domain, root).first<any>();

  if (threat) {
    riskScore = Math.max(riskScore, threat.risk_score);
    reasons.push("linkRiskKnownThreat");
    confidencePoints += threat.confirmed ? 3 : 1;
  }

  // 3. Count community reports
  const reportRow = await env.DB.prepare(
    "SELECT COUNT(*) as cnt FROM link_reports WHERE domain = ? OR domain = ?"
  ).bind(domain, root).first<any>();

  const reportCount = reportRow?.cnt || 0;
  if (reportCount >= 1) {
    riskScore += Math.min(reportCount * 10, 40);
    reasons.push("linkRiskCommunityReports");
    confidencePoints += Math.min(reportCount, 4);
  }

  // 4. Saved source_hits from D1 (previously discovered data)
  const dbHits = await env.DB.prepare(
    "SELECT source, verdict FROM source_hits WHERE domain = ? OR domain = ?"
  ).bind(domain, root).all<any>();

  if (dbHits.results && dbHits.results.length > 0) {
    reasons.push("linkRiskExternalDbMatch");
    for (const hit of dbHits.results) {
      riskScore += 15; // lower than fresh hit since it's historical
      confidencePoints += 2;
    }
  }

  // 5. Apply fresh external hits (from this scan)
  if (freshExternalHits.length > 0) {
    if (!reasons.includes("linkRiskExternalDbMatch")) {
      reasons.push("linkRiskExternalDbMatch");
    }
    for (const hit of freshExternalHits) {
      riskScore += hit.riskDelta;
      confidencePoints += hit.confidenceDelta;
    }
  }

  // 6. LOCAL WEB3 PATTERN ENGINE — DrainShield's own brain
  // Even if external feeds are silent, we detect obvious scam patterns.
  const patternResult = analyzeWeb3Patterns(domain, root, url);
  if (patternResult.score > 0) {
    riskScore += patternResult.score;
    confidencePoints += patternResult.confidenceDelta;
    for (const r of patternResult.reasons) {
      if (!reasons.includes(r)) reasons.push(r);
    }
  }

  // 7. Get user labels
  const labels = await env.DB.prepare(
    "SELECT DISTINCT label FROM user_labels WHERE domain = ? OR domain = ?"
  ).bind(domain, root).all<any>();

  const userLabels = labels.results?.map((r: any) => r.label) || [];
  if (userLabels.length > 0) {
    confidencePoints += 1;
  }

  // Clamp score
  riskScore = Math.min(riskScore, 100);
  if (riskScore < 25) riskScore = 25;

  // Determine confidence
  const confidence = confidencePoints >= 3 ? "high" : "low";

  // Determine verdict
  let verdict: string;
  if (riskScore >= 70 && confidence === "high") {
    verdict = "confirmed_scam";
  } else if (riskScore >= 70) {
    verdict = "high_risk";
  } else if (riskScore >= 40) {
    verdict = "suspicious";
  } else {
    verdict = "low_data";
  }

  // If no specific reasons, add default
  if (reasons.length === 0) {
    reasons.push("linkRiskNotVerified");
  }

  return { verdict, riskScore, confidence, reasons, sources, reportCount, userLabels };
}

// ══════════════════════════════════════════════════════════════════════════════
// WEB3 PATTERN ANALYSIS ENGINE
// DrainShield's own brain — no external API needed.
// ══════════════════════════════════════════════════════════════════════════════

// Crypto brand names → official domains
const BRAND_DOMAINS: Record<string, string> = {
  metamask: "metamask.io",
  uniswap: "uniswap.org",
  pancakeswap: "pancakeswap.finance",
  opensea: "opensea.io",
  coinbase: "coinbase.com",
  binance: "binance.com",
  trustwallet: "trustwallet.com",
  phantom: "phantom.app",
  aave: "aave.com",
  compound: "compound.finance",
  lido: "lido.fi",
  ethereum: "ethereum.org",
  solana: "solana.com",
  arbitrum: "arbitrum.io",
  optimism: "optimism.io",
  polygon: "polygon.technology",
  sushiswap: "sushi.com",
  curve: "curve.fi",
  jupiter: "jupiter.ag",
  raydium: "raydium.io",
  ledger: "ledger.com",
  trezor: "trezor.io",
  rainbow: "rainbow.me",
  zerion: "zerion.io",
  blur: "blur.io",
  magiceden: "magiceden.io",
  kraken: "kraken.com",
  okx: "okx.com",
  bybit: "bybit.com",
  kucoin: "kucoin.com",
  dydx: "dydx.exchange",
  stargate: "stargate.finance",
};

// Service/platform brands (non-crypto) — for payment phishing detection
const SERVICE_BRANDS: Record<string, string[]> = {
  namecheap: ["namecheap.com"],
  privateemail: ["privateemail.com"],
  godaddy: ["godaddy.com"],
  paypal: ["paypal.com"],
  stripe: ["stripe.com"],
  apple: ["apple.com", "icloud.com"],
  microsoft: ["microsoft.com", "outlook.com", "live.com"],
  google: ["google.com", "gmail.com"],
  amazon: ["amazon.com", "aws.amazon.com"],
  netflix: ["netflix.com"],
  dropbox: ["dropbox.com"],
  cloudflare: ["cloudflare.com"],
  github: ["github.com"],
  discord: ["discord.com", "discord.gg"],
  telegram: ["telegram.org", "t.me"],
  whatsapp: ["whatsapp.com"],
  instagram: ["instagram.com"],
  facebook: ["facebook.com"],
  twitter: ["twitter.com", "x.com"],
  linkedin: ["linkedin.com"],
  zoom: ["zoom.us"],
  spotify: ["spotify.com"],
  steam: ["steampowered.com", "steamcommunity.com"],
};

// Payment/billing phishing keywords in URL path
const PAYMENT_KEYWORDS = [
  "payment", "billing", "invoice", "update-payment", "card",
  "renew", "renewal", "subscription", "checkout", "order",
  "secure-payment", "confirm-payment", "verify-payment",
  "account-suspended", "account-locked", "verify-account",
  "update-billing", "payment-method", "add-card",
  "reactivate", "overdue", "past-due", "expir",
];

// Suspicious TLDs frequently used in phishing
const SUSPICIOUS_TLDS = new Set([
  ".xyz", ".top", ".click", ".buzz", ".info", ".win", ".loan",
  ".racing", ".review", ".party", ".trade", ".bid", ".stream",
  ".gq", ".cf", ".tk", ".ml", ".ga", ".cam", ".rest",
  ".monster", ".sbs", ".cfd", ".cyou", ".icu",
]);

// Web3 scam keywords in domain or URL path
const SCAM_KEYWORDS = [
  "claim-airdrop", "free-mint", "connect-wallet", "approve-token",
  "claim-reward", "bonus-claim", "free-token", "airdrop-claim",
  "wallet-verify", "wallet-sync", "wallet-validate", "seed-phrase",
  "private-key", "recovery-phrase", "claim-nft", "free-nft",
  "mint-free", "presale-mint", "whitelist-mint", "claim-tokens",
  "unlock-wallet", "restore-wallet", "verify-wallet", "confirm-wallet",
  "dapp-approve", "token-approval", "swap-bonus", "staking-reward",
  "yield-bonus", "liquidity-reward",
];

// Single-word scam signals (checked in domain only)
const DOMAIN_SCAM_WORDS = [
  "claim", "airdrop", "reward", "freemint", "freetoken",
  "connectwallet", "walletconnect", "seedphrase", "privatekey",
  "giveaway", "bonus", "verify", "validate", "sync",
];

interface PatternResult {
  score: number;
  confidenceDelta: number;
  reasons: string[];
}

function analyzeWeb3Patterns(domain: string, root: string, url: string): PatternResult {
  let score = 0;
  let confidenceDelta = 0;
  const reasons: string[] = [];
  const fullUrl = url.toLowerCase();
  const domainLower = domain.toLowerCase();

  // 1. BRAND TYPOSQUATTING — domain contains brand name but is NOT the real domain
  for (const [brand, officialDomain] of Object.entries(BRAND_DOMAINS)) {
    if (domainLower.includes(brand) && root !== officialDomain && domainLower !== officialDomain) {
      score += 35;
      confidenceDelta += 2;
      if (!reasons.includes("linkRiskTyposquatting")) {
        reasons.push("linkRiskTyposquatting");
      }
      break;
    }
  }

  // 2. SUSPICIOUS TLD — .xyz, .tk, .ml, etc.
  for (const tld of SUSPICIOUS_TLDS) {
    if (domainLower.endsWith(tld)) {
      score += 20;
      confidenceDelta += 1;
      if (!reasons.includes("linkRiskSuspiciousTld")) {
        reasons.push("linkRiskSuspiciousTld");
      }
      break;
    }
  }

  // 3. SCAM KEYWORDS in URL path/query
  for (const kw of SCAM_KEYWORDS) {
    if (fullUrl.includes(kw)) {
      score += 30;
      confidenceDelta += 2;
      if (!reasons.includes("linkRiskWeb3ScamKeyword")) {
        reasons.push("linkRiskWeb3ScamKeyword");
      }
      break;
    }
  }

  // 4. DOMAIN SCAM WORDS — single words in domain itself
  for (const word of DOMAIN_SCAM_WORDS) {
    if (domainLower.includes(word)) {
      score += 15;
      confidenceDelta += 1;
      if (!reasons.includes("linkRiskScamDomainWord")) {
        reasons.push("linkRiskScamDomainWord");
      }
      break;
    }
  }

  // 5. DEEP SUBDOMAIN — more than 3 dots = suspicious
  const dotCount = domainLower.split(".").length - 1;
  if (dotCount > 3) {
    score += 25;
    confidenceDelta += 1;
    reasons.push("linkRiskDeepSubdomain");
  }

  // 6. BRAND + SCAM KEYWORD COMBO — deadly combination
  let hasBrand = false;
  for (const brand of Object.keys(BRAND_DOMAINS)) {
    if (domainLower.includes(brand)) {
      hasBrand = true;
      break;
    }
  }
  let hasScamWord = false;
  for (const word of DOMAIN_SCAM_WORDS) {
    if (fullUrl.includes(word)) {
      hasScamWord = true;
      break;
    }
  }
  if (hasBrand && hasScamWord) {
    // This is almost certainly a scam: brand name + scam keyword
    score += 20;
    confidenceDelta += 2;
    if (!reasons.includes("linkRiskBrandPlusScam")) {
      reasons.push("linkRiskBrandPlusScam");
    }
  }

  // 7. ETHEREUM ADDRESS in URL
  const ethRegex = /0x[a-fA-F0-9]{40}/;
  if (ethRegex.test(fullUrl)) {
    score += 15;
    confidenceDelta += 1;
    reasons.push("linkRiskContractInUrl");
  }

  // 8. IP ADDRESS as domain
  const ipRegex = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;
  if (ipRegex.test(domain)) {
    score += 40;
    confidenceDelta += 2;
    reasons.push("linkRiskIpAddress");
  }

  // 9. SERVICE BRAND IMPERSONATION — brand in subdomain/path but wrong root domain
  //    e.g. privateemail.abiluxitalia.com/namecheap/index.html
  let serviceBrandMatch: string | null = null;
  for (const [brand, officialDomains] of Object.entries(SERVICE_BRANDS)) {
    const inDomain = domainLower.includes(brand);
    const inPath = fullUrl.includes("/" + brand);
    if (inDomain || inPath) {
      const isOfficial = officialDomains.some(d => root === d || domainLower === d);
      if (!isOfficial) {
        serviceBrandMatch = brand;
        score += 35;
        confidenceDelta += 2;
        if (!reasons.includes("linkRiskBrandImpersonation")) {
          reasons.push("linkRiskBrandImpersonation");
        }
        break;
      }
    }
  }

  // 10. PAYMENT PHISHING — payment/billing keywords in URL
  let hasPaymentKeyword = false;
  for (const kw of PAYMENT_KEYWORDS) {
    if (fullUrl.includes(kw)) {
      hasPaymentKeyword = true;
      break;
    }
  }
  if (hasPaymentKeyword && serviceBrandMatch) {
    // Brand impersonation + payment page = almost certainly phishing
    score += 40;
    confidenceDelta += 3;
    if (!reasons.includes("linkRiskPaymentPhishing")) {
      reasons.push("linkRiskPaymentPhishing");
    }
  } else if (hasPaymentKeyword && hasBrand) {
    // Crypto brand + payment keywords = suspicious
    score += 25;
    confidenceDelta += 2;
    if (!reasons.includes("linkRiskPaymentPhishing")) {
      reasons.push("linkRiskPaymentPhishing");
    }
  }

  // 11. SERVICE BRAND + SCAM/PAYMENT COMBO — deadly combination
  if (serviceBrandMatch && (hasScamWord || hasPaymentKeyword)) {
    score += 20;
    confidenceDelta += 2;
    if (!reasons.includes("linkRiskBrandPlusScam")) {
      reasons.push("linkRiskBrandPlusScam");
    }
  }

  return { score, confidenceDelta, reasons };
}

// ── Rate Limiter ────────────────────────────────────────────────────────────

async function checkRateLimit(deviceHash: string, domain: string, env: Env): Promise<boolean> {
  const row = await env.DB.prepare(
    "SELECT report_count, window_start FROM report_rate_limits WHERE device_hash = ? AND domain = ?"
  ).bind(deviceHash, domain).first<any>();

  if (!row) return true;

  const windowStart = new Date(row.window_start).getTime();
  const oneHour = 60 * 60 * 1000;
  const now = Date.now();

  if (now - windowStart > oneHour) {
    await env.DB.prepare(
      "UPDATE report_rate_limits SET report_count = 0, window_start = ? WHERE device_hash = ? AND domain = ?"
    ).bind(nowISO(), deviceHash, domain).run();
    return true;
  }

  return row.report_count < 10;
}

async function incrementRateLimit(deviceHash: string, domain: string, env: Env): Promise<void> {
  await env.DB.prepare(`
    INSERT INTO report_rate_limits (device_hash, domain, report_count, window_start, last_report_at)
    VALUES (?, ?, 1, ?, ?)
    ON CONFLICT(device_hash, domain) DO UPDATE SET
      report_count = report_count + 1,
      last_report_at = ?
  `).bind(deviceHash, domain, nowISO(), nowISO(), nowISO()).run();
}

// ══════════════════════════════════════════════════════════════════════════════
// ROUTER
// ══════════════════════════════════════════════════════════════════════════════

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    try {
      if (path === "/health") {
        return json({
          ok: true,
          service: "DrainShield Link Shield API",
          version: "2.1.0",
        });
      }

      if (path === "/scan-link" && request.method === "POST") {
        return await handleScanLink(request, env);
      }

      if (path === "/report-link" && request.method === "POST") {
        return await handleReportLink(request, env);
      }

      if (path === "/label-link" && request.method === "POST") {
        return await handleLabelLink(request, env);
      }

      if (path.startsWith("/domain/") && path.endsWith("/reputation")) {
        return await handleReputation(path, env);
      }

      // Admin: force-purge KV cache for a URL
      if (path === "/purge-cache" && request.method === "POST") {
        const body = await request.json<{ url: string }>();
        if (!body?.url) return json({ ok: false, error: "Missing url" }, 400);
        const domain = extractDomain(body.url);
        const urlHash = await sha256(body.url);
        await env.CACHE.delete(`scan:${urlHash}`);
        await env.CACHE.delete(`ext_checked:${domain}`);
        await env.DB.prepare("DELETE FROM scan_cache WHERE url_hash = ?").bind(urlHash).run();
        return json({ ok: true, purged: domain, urlHash });
      }

      return json({ ok: false, error: "Not found" }, 404);
    } catch (e: any) {
      console.error("Worker error:", e);
      return json({ ok: false, error: "Internal server error" }, 500);
    }
  },
};

// ── POST /scan-link ─────────────────────────────────────────────────────────

async function handleScanLink(request: Request, env: Env): Promise<Response> {
  const body = await request.json<{ url: string }>();
  if (!body?.url) return json({ ok: false, error: "Missing url" }, 400);

  const domain = extractDomain(body.url);
  const root = rootDomain(domain);
  const urlHash = await sha256(body.url);

  // ── Step 1: KV cache (hot path, 1h TTL) ─────────────────────────────
  const cacheKey = `scan:${urlHash}`;
  const cached = await env.CACHE.get(cacheKey, "json");
  if (cached) {
    return json({ ok: true, cached: true, ...(cached as object) });
  }

  // ── Step 2: Prepare full URL for external checks ────────────────────
  let fullUrl = body.url.trim();
  if (!fullUrl.startsWith("http://") && !fullUrl.startsWith("https://")) {
    fullUrl = "https://" + fullUrl;
  }

  // ── Step 3: Cache-first external check ──────────────────────────────
  // Only query external feeds if we've NEVER checked this domain before.
  // If we already have source_hits → skip external, use stored data.
  let freshHits: ExternalHit[] = [];
  const alreadyChecked = await hasExternalData(domain, root, env);

  if (!alreadyChecked) {
    // First time seeing this domain → query all external feeds
    freshHits = await queryExternalSources(domain, root, fullUrl, env);

    // Save hits permanently to D1
    if (freshHits.length > 0) {
      await saveExternalHits(domain, freshHits, env);
    }

    // Mark as checked (KV, 24h) so we don't re-query tomorrow
    await markExternallyChecked(domain, env);
  }

  // ── Step 4: Compute verdict (D1 data + fresh hits) ──────────────────
  const result = await computeVerdict(domain, env, freshHits, fullUrl);

  // ── Step 5: Build response ──────────────────────────────────────────
  // IMPORTANT: Never expose source names to user.
  // Always say "DrainShield".
  const response = {
    domain,
    urlHash,
    verdict: result.verdict,
    riskScore: result.riskScore,
    confidence: result.confidence,
    reasons: result.reasons,
    reportCount: result.reportCount,
    userLabels: result.userLabels,
    checkedBy: "DrainShield",
    scannedAt: nowISO(),
  };

  // Cache for 1 hour
  await env.CACHE.put(cacheKey, JSON.stringify(response), { expirationTtl: 3600 });

  // Save to D1 scan_cache
  const expiresAt = new Date(Date.now() + 3600000).toISOString();
  await env.DB.prepare(`
    INSERT OR REPLACE INTO scan_cache (url_hash, domain, verdict, risk_score, reasons_json, expires_at)
    VALUES (?, ?, ?, ?, ?, ?)
  `).bind(urlHash, domain, result.verdict, result.riskScore, JSON.stringify(result.reasons), expiresAt).run();

  return json({ ok: true, cached: false, ...response });
}

// ── POST /report-link ───────────────────────────────────────────────────────

async function handleReportLink(request: Request, env: Env): Promise<Response> {
  const body = await request.json<{
    url: string;
    reportType: string;
    userLabel?: string;
    userComment?: string;
    deviceHash?: string;
  }>();

  if (!body?.url || !body?.reportType) {
    return json({ ok: false, error: "Missing url or reportType" }, 400);
  }

  const domain = extractDomain(body.url);
  const urlHash = await sha256(body.url);
  const deviceHash = body.deviceHash || "anonymous";

  const allowed = await checkRateLimit(deviceHash, domain, env);
  if (!allowed) {
    return json({ ok: false, error: "Rate limit exceeded. Max 10 reports/hour." }, 429);
  }

  const id = generateId();
  await env.DB.prepare(`
    INSERT INTO link_reports (id, url_hash, domain, report_type, user_label, user_comment, device_hash, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(id, urlHash, domain, body.reportType, body.userLabel || null, body.userComment || null, deviceHash, nowISO()).run();

  await incrementRateLimit(deviceHash, domain, env);

  const countRow = await env.DB.prepare(
    "SELECT COUNT(DISTINCT device_hash) as cnt FROM link_reports WHERE domain = ?"
  ).bind(domain).first<any>();

  const uniqueReports = countRow?.cnt || 0;

  if (uniqueReports >= 1) {
    const newScore = Math.min(25 + uniqueReports * 10, 90);
    const newVerdict = uniqueReports >= 5 ? "high_risk" : "suspicious";
    const newConfidence = Math.min(uniqueReports * 15, 90);

    await env.DB.prepare(`
      INSERT INTO threat_domains (domain, verdict, risk_score, reason, source, confidence, report_count, created_at, updated_at)
      VALUES (?, ?, ?, ?, 'community', ?, ?, ?, ?)
      ON CONFLICT(domain) DO UPDATE SET
        verdict = CASE WHEN excluded.risk_score > risk_score THEN excluded.verdict ELSE verdict END,
        risk_score = MAX(risk_score, excluded.risk_score),
        confidence = MAX(confidence, excluded.confidence),
        report_count = ?,
        updated_at = ?
    `).bind(domain, newVerdict, newScore, `${uniqueReports} community reports`, newConfidence, uniqueReports, nowISO(), nowISO(), uniqueReports, nowISO()).run();
  }

  // Invalidate caches
  await env.CACHE.delete(`scan:${urlHash}`);
  await env.CACHE.delete(`ext_checked:${domain}`);

  return json({
    ok: true,
    reportId: id,
    domain,
    totalReports: uniqueReports,
    message: "Report received. Thank you for protecting the community.",
  });
}

// ── POST /label-link ────────────────────────────────────────────────────────

async function handleLabelLink(request: Request, env: Env): Promise<Response> {
  const body = await request.json<{
    url: string;
    label: string;
    comment?: string;
    deviceHash?: string;
  }>();

  if (!body?.url || !body?.label) {
    return json({ ok: false, error: "Missing url or label" }, 400);
  }

  const domain = extractDomain(body.url);
  const urlHash = await sha256(body.url);
  const deviceHash = body.deviceHash || "anonymous";

  const allowed = await checkRateLimit(deviceHash, domain, env);
  if (!allowed) {
    return json({ ok: false, error: "Rate limit exceeded." }, 429);
  }

  const id = generateId();
  await env.DB.prepare(`
    INSERT INTO user_labels (id, domain, url_hash, label, comment, device_hash, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).bind(id, domain, urlHash, body.label, body.comment || null, deviceHash, nowISO()).run();

  await incrementRateLimit(deviceHash, domain, env);

  return json({
    ok: true,
    labelId: id,
    domain,
    label: body.label,
    message: "Label saved. Other users will see your input.",
  });
}

// ── GET /domain/:domain/reputation ──────────────────────────────────────────

async function handleReputation(path: string, env: Env): Promise<Response> {
  const match = path.match(/^\/domain\/(.+)\/reputation$/);
  if (!match) return json({ ok: false, error: "Invalid path" }, 400);

  const domain = decodeURIComponent(match[1]).toLowerCase();
  const result = await computeVerdict(domain, env, [], "https://" + domain);

  return json({
    ok: true,
    domain,
    ...result,
    checkedBy: "DrainShield",
    checkedAt: nowISO(),
  });
}
