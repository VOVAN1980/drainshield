# 🛡️ DrainShield

<p align="center">
  <img src="assets/logo/lion_safe.png" alt="DrainShield Lion" width="220">
</p>

<p align="center"><b>Proactive Web3 Security — Wallet Defense + Link Threat Intelligence</b></p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=app.drainshield.guard">
    <img src="https://img.shields.io/badge/Google%20Play-Download-brightgreen?style=for-the-badge&logo=google-play" alt="Google Play">
  </a>
  <a href="https://vovan1980.github.io/drainshield/">
    <img src="https://img.shields.io/badge/Website-drainshield-blue?style=for-the-badge&logo=google-chrome" alt="Website">
  </a>
  <a href="https://vovan1980.github.io/IBITILabs">
    <img src="https://img.shields.io/badge/IBITI-Labs-purple?style=for-the-badge" alt="IBITI Labs">
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-0.3.1-informational?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/flutter-3.41.3-02569B?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/backend-Cloudflare%20Workers-F38020?style=flat-square&logo=cloudflare" alt="Cloudflare">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/platform-Android-3DDC84?style=flat-square&logo=android" alt="Android">
  <img src="https://img.shields.io/badge/languages-17-blueviolet?style=flat-square" alt="Languages">
</p>

---

**DrainShield** is a comprehensive Web3 security platform that protects users from two major attack vectors:

1. **🔐 Wallet Defense** — Audit and revoke malicious token approvals across 8 blockchain networks.
2. **🔗 Link Shield** — Scan any URL for phishing, wallet drainers, and crypto scams using multi-source threat intelligence.

DrainShield focuses on **proactive defense** — detecting and neutralizing threats before they can lead to asset loss.

---

## 📲 Download

DrainShield is available on **Google Play**:

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=app.drainshield.guard">
    <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play" width="240">
  </a>
</p>

---

## 🚀 Core Features

### 🔗 Link Shield — URL Threat Intelligence *(NEW in v0.3.0)*

Check any link before clicking. Paste a URL or share it from another app — get a clear safety verdict in seconds.

**How it works:**
```
URL → Trusted List → Our DB (D1) → External Feeds → Web3 Pattern Engine → Verdict
```

| Layer | What it does |
|-------|-------------|
| **Trusted List** | Whitelist of known safe domains (binance.com, google.com...) |
| **DrainShield DB** | Own threat database powered by Cloudflare D1 |
| **External Feeds** | Google Safe Browsing + MetaMask PhishDetect |
| **Web3 Pattern Engine** | 34 crypto brands × 30 scam keywords × 24 suspicious TLDs |
| **Community Reports** | Truecaller-style reputation model — users report scams |

**Verdicts:**
- ✅ **Safe** — Trusted domain, no threats found
- 🔵 **Low Data** — Unknown domain, be cautious
- 🟡 **Suspicious** — Multiple risk signals detected
- 🟠 **High Risk** — Likely wallet drainer
- 🔴 **Confirmed Scam** — Known scam site

**Key capabilities:**
- Detects fake MetaMask, PancakeSwap, Uniswap, and 30+ brand impersonation sites — even when external databases miss them
- Recognizes scam patterns: `claim-airdrop`, `free-mint`, `connect-wallet`, `approve-token`...
- Catches typosquatting, homograph attacks, IP-based URLs, suspicious TLDs
- Share scan results with friends to warn them
- Report scam links to protect the community

### 🔐 Approval Auditing (Deep Scans)
Goes beyond basic scanning to analyze the technical nature of spenders and contracts:
- **Proxy Detection**: Identifying upgradeable contracts that could change behavior.
- **Ownership Analysis**: Checking for centralized control or suspicious owner permissions.
- **Capabilities Probe**: Detecting if a contract has "drain-like" behavioral patterns (e.g., unlimited withdrawal logic).

### 🧠 Multi-Factor Risk Engine (0-100 Score)
Every approval is assigned a security score from 0 (Safe) to 100 (Critical) based on:
- **Allowance Magnitude**: Deep analysis of unlimited vs. specific amount risk.
- **Contract Reputation**: Verified status, age, and historical interaction metrics.
- **Spender Metadata**: Real-time identification of known protocols vs. unverified entities.
- **Threat Intelligence**: Cross-referencing against global malicious feed databases (GitHub, Moralis).

### 🚨 Panic Mode (Emergency Response)
A dedicated, high-priority interface for rapid asset isolation.
- **Batch Revocation**: Select and revoke multiple high-risk permissions in a single workflow.
- **Smart Filtering**: Automatically prioritizes the most dangerous exposures for immediate action.

### 💎 PRO Protection
Advanced security tier for intensive wallet management:
- **24/7 Auto-Monitoring** — Continuous background scanning with real-time alerts.
- **Batch Risk Revoke** — One-tap remediation of multiple threats.
- **5+ Wallet Slots** — Manage and monitor multiple wallets simultaneously.
- **Priority Threat Alerts** — Push notifications with sound & vibration for critical events.
- **Advanced Risk Intel** — Deeper heuristic analysis and contract intelligence.
- **Zero-Trust Guard** — Automatic flagging of all new unverified approvals.

### 🔒 Non-Custodial & Privacy-First
- **Zero-Knowledge Architecture**: Private keys and seed phrases are never asked for or stored.
- **Local Signing**: All security actions are signed directly within your connected wallet (MetaMask, Trust, etc.) via WalletConnect.
- **Zero PII**: No personal identity information (Name, Email, IP) is collected.

---

## ⛓ Supported Networks

DrainShield provides real-time security auditing across multiple blockchain ecosystems:

### EVM Networks
| Network | Status |
|---------|--------|
| **BNB Smart Chain (BSC)** | ✅ Full Support |
| **Ethereum (Mainnet)** | ✅ Full Support |
| **Polygon (PoS)** | ✅ Full Support |
| **Arbitrum (One)** | ✅ Full Support |
| **Optimism (Mainnet)** | ✅ Full Support |
| **Base (Mainnet)** | ✅ Full Support |

### Multi-Chain Expansion
| Network | Status |
|---------|--------|
| **Tron (TRC-20)** | 🔄 Integrated |
| **Solana (SPL)** | 🔄 Integrated |

> Each chain maintains **isolated wallet management** — dedicated address spaces, independent card carousels, and chain-specific RPC communication with zero cross-chain data leakage.

---

## 🏗 Technical Architecture

Built on a modular service-oriented architecture for maximum reliability and decentralization.

### Frontend (Flutter)
- **ApprovalScanService**: High-speed indexing of token allowances across all supported chains.
- **RiskEngine**: The brain of the app, calculating 0-100 scores using multi-factor heuristics.
- **ThreatIntelligenceService**: Integrates external security feeds to stay ahead of known exploits.
- **BlockchainAnalysisService**: Deep-dives into contract verification and bytecode properties.
- **LinkShieldApi**: Communicates with the backend for URL threat intelligence.
- **LocalAnalyzer**: Client-side URL analysis engine (Web3 patterns, typosquatting, suspicious TLDs).
- **ShareIntentService**: Receives shared URLs from Android Share Sheet.
- **WalletRegistryService**: Multi-chain wallet lifecycle management with strict chain isolation.
- **MonitoringService**: Background 24/7 wallet surveillance with push notification dispatch.

### Backend (Cloudflare Workers)
- **Link Shield API** — Serverless edge computing for URL scanning.
- **D1 Database** — SQLite-based storage for domain reputation, scan history, and user reports.
- **KV Cache** — Fast edge caching for scan results and external feed data.
- **Web3 Pattern Engine** — Local brand impersonation and scam keyword detection.
- **External Feeds** — Google Safe Browsing API + MetaMask eth-phishing-detect.

### Data Layer
- **SQLite (sqflite)**: Persistent local storage for scan history, risk decisions, and postmortem analysis.
- **SharedPreferences**: User settings, PRO status, and wallet configuration.
- **Cloudflare D1**: Server-side domain reputation and community report storage.

---

## 🛠 Technology Stack

| Component | Technology |
|-----------|------------|
| **Framework** | Flutter 3.41.3 / Dart |
| **Backend** | Cloudflare Workers (TypeScript) |
| **Database** | Cloudflare D1 (SQLite) + KV + local SQLite |
| **Web3 Protocol** | Reown AppKit (WalletConnect v2) |
| **Threat Intel** | Google Safe Browsing + MetaMask PhishDetect |
| **Infrastructure** | Moralis Web3 APIs |
| **Background Tasks** | WorkManager |
| **Notifications** | Flutter Local Notifications |
| **Connectivity** | Connectivity Plus |
| **Design System** | Premium "Lion" themed interface with reactive state management |

---

## 🌍 Supported Languages

DrainShield is available in **17 languages**:

🇬🇧 English · 🇷🇺 Русский · 🇸🇦 العربية · 🇩🇪 Deutsch · 🇪🇸 Español · 🇫🇷 Français · 🇮🇳 हिन्दी · 🇮🇩 Bahasa Indonesia · 🇮🇹 Italiano · 🇯🇵 日本語 · 🇰🇷 한국어 · 🇵🇱 Polski · 🇧🇷 Português · 🇹🇷 Türkçe · 🇺🇦 Українська · 🇻🇳 Tiếng Việt · 🇨🇳 中文

---

## ⚙️ Getting Started

### Requirements
- Flutter SDK (3.41.3 or newer)
- Java 21 (for Android builds)
- Moralis API Key (Required for wallet scanning)
- Cloudflare account (Required for Link Shield backend)

### Installation
1.  **Clone & Install**:
    ```bash
    git clone https://github.com/VOVAN1980/drainshield.git
    cd drainshield
    flutter pub get
    ```
2.  **Moralis Configuration**:
    Create `secrets/moralis.json` in the root directory:
    ```json
    {
      "MORALIS_API_KEY": "YOUR_API_KEY"
    }
    ```
3.  **Link Shield Backend** (optional):
    ```bash
    cd linkshield-worker
    npx wrangler d1 create linkshield-db
    npx wrangler d1 execute linkshield-db --file=schema.sql
    npx wrangler secret put GOOGLE_SAFE_BROWSING_KEY
    npx wrangler deploy
    ```
4.  **Run**:
    ```bash
    flutter run
    ```

---

## 🌐 Links

| Resource | URL |
|----------|-----|
| 🌍 **Website** | [vovan1980.github.io/drainshield](https://vovan1980.github.io/drainshield/) |
| 📲 **Google Play** | [DrainShield on Play Store](https://play.google.com/store/apps/details?id=app.drainshield.guard) |
| 🧪 **IBITI Labs** | [vovan1980.github.io/IBITILabs](https://vovan1980.github.io/IBITILabs) |
| 🐦 **X (Twitter)** | [@ibiticoin](https://x.com/ibiticoin) |
| 💬 **Telegram** | [IBITIcoin_chat](https://t.me/IBITIcoin_chat) |
| 📧 **Contact** | info@ibiticoin.com |

---

## 🔒 Privacy & Safety
DrainShield is a non-custodial tool for informational analysis. Users remain responsible for verifying transactions.  
[Read the full Privacy Policy](https://vovan1980.github.io/drainshield/privacy.html) · [Terms of Use](https://vovan1980.github.io/drainshield/terms.html)

---

## 📄 License
This project is licensed under the MIT License.

---

<p align="center">
  <b>© 2026 IBITI Labs</b> — Securing your on-chain journey.
</p>
