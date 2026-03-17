# 🛡️ DrainShield

<p align="center">
  <img src="assets/logo/lion_safe.png" alt="DrainShield Lion" width="220">
</p>

<p align="center"><b>Proactive Web3 wallet security</b></p>

**DrainShield** is a powerful non-custodial security dashboard designed to protect Web3 users from malicious token approvals and permission abuse.  
It provides a high-fidelity audit of wallet exposure, classifies risks using a multi-factor assessment engine, and enables instant, batch-revocation of dangerous permissions.

DrainShield focuses on **proactive defense**—detecting and neutralizing threats before they can lead to asset loss.

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

### �️ Non-Custodial & Privacy-First
- **Zero-Knowledge Architecture**: Private keys and seed phrases are never asked for or stored.
- **Local Signing**: All security actions are signed directly within your connected wallet (MetaMask, Trust, etc.) via WalletConnect v2.
- **Zero PII**: No personal identity information (Name, Email, IP) is collected.

---

## ⛓ Supported Networks

DrainShield provides real-time security auditing across the most active EVM ecosystems:

- **BNB Smart Chain (BSC)**
- **Ethereum (Mainnet)**
- **Polygon (PoS)**
- **Arbitrum (One)**
- **Optimism (Mainnet)**
- **Base (Mainnet)**

---

## 🏗 Technical Architecture

Built on a modular service-oriented architecture for maximum reliability and decentralization.

### Core Services
- **ApprovalScanService**: High-speed indexing of token allowances.
- **RiskEngine**: The brain of the app, calculating 0-100 scores using multi-factor heuristics.
- **ThreatIntelligenceService**: Integrates external security feeds to stay ahead of known exploits.
- **BlockchainAnalysisService**: Deep-dives into contract verification and bytecode properties.

---

## 🛠 Technology Stack
- **Framework**: Flutter (3.13+) / Dart
- **Web3 Protocol**: WalletConnect v2
- **Infrastructure**: Moralis Web3 APIs
- **Design System**: Premium "Lion" themed interface with reactive state management.

---

## ⚙️ Getting Started

### Requirements
- Flutter SDK (3.13 or newer)
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

## 🔒 Privacy & Safety
DrainShield is a non-custodial tool for informational analysis. Users remain responsible for verifying transactions.  
[Read the full Privacy Policy](https://vovan1980.github.io/drainshield/privacy.html)

---

## 📄 License
This project is licensed under the MIT License.
