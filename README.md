# 🛡️ DrainShield

<p align="center">
  <img src="assets/logo/lion_safe.png" alt="DrainShield Lion" width="220">
</p>

<p align="center"><b>Proactive Web3 Wallet Security — Multi-Chain Defense Platform</b></p>

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
  <img src="https://img.shields.io/badge/version-0.2.1-informational?style=flat-square" alt="Version">
  <img src="https://img.shields.io/badge/flutter-3.41.3-02569B?style=flat-square&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License">
  <img src="https://img.shields.io/badge/platform-Android-3DDC84?style=flat-square&logo=android" alt="Android">
</p>

---

**DrainShield** is a powerful non-custodial security dashboard designed to protect Web3 users from malicious token approvals and permission abuse.  
It provides a high-fidelity audit of wallet exposure, classifies risks using a multi-factor assessment engine, and enables instant, batch-revocation of dangerous permissions.

DrainShield focuses on **proactive defense**—detecting and neutralizing threats before they can lead to asset loss.

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

### Core Services
- **ApprovalScanService**: High-speed indexing of token allowances across all supported chains.
- **RiskEngine**: The brain of the app, calculating 0-100 scores using multi-factor heuristics.
- **ThreatIntelligenceService**: Integrates external security feeds to stay ahead of known exploits.
- **BlockchainAnalysisService**: Deep-dives into contract verification and bytecode properties.
- **WalletRegistryService**: Multi-chain wallet lifecycle management with strict chain isolation.
- **MonitoringService**: Background 24/7 wallet surveillance with push notification dispatch.

### Data Layer
- **SQLite (sqflite)**: Persistent local storage for scan history, risk decisions, and postmortem analysis.
- **SharedPreferences**: User settings, PRO status, and wallet configuration.

---

## 🛠 Technology Stack

| Component | Technology |
|-----------|------------|
| **Framework** | Flutter 3.41.3 / Dart |
| **Web3 Protocol** | Reown AppKit (WalletConnect v2) |
| **Infrastructure** | Moralis Web3 APIs |
| **Database** | SQLite (sqflite) |
| **Background Tasks** | WorkManager |
| **Notifications** | Flutter Local Notifications |
| **Connectivity** | Connectivity Plus |
| **Design System** | Premium "Lion" themed interface with reactive state management |

---

## ⚙️ Getting Started

### Requirements
- Flutter SDK (3.41.3 or newer)
- Java 21 (for Android builds)
- Moralis API Key (Required for scanning)

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
3.  **Run**:
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
