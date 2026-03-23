import "package:flutter/material.dart";
import "package:reown_appkit/reown_appkit.dart";

class WcService extends ChangeNotifier {
  static final WcService _i = WcService._internal();
  factory WcService() => _i;
  WcService._internal();
  ReownAppKitModal? _modal;
  bool _initing = false;
  ReownAppKitModal? get modal => _modal;
  bool get isReady => _modal != null;
  bool get isConnected => _modal?.isConnected ?? false;
  String get address {
    final s = _modal?.session;
    final ns = s?.namespaces;
    if (ns == null || ns.isEmpty) return "";
    final accounts = ns["eip155"]?.accounts ?? const <String>[];
    if (accounts.isEmpty) return "";
    final parts = accounts.first.split(":"); // eip155:56:0x...
    return parts.length >= 3 ? parts[2] : "";
  }

  String get guestName {
    final s = _modal?.session;
    if (s == null) return "Wallet";
    return s.peer?.metadata.name ?? "Wallet";
  }

  int get currentChainId {
    final chainIdStr = _modal?.selectedChain?.chainId;
    if (chainIdStr != null) {
      // It might be "56" or "eip155:56"
      final parts = chainIdStr.split(':');
      final rawNum = parts.isNotEmpty ? parts.last : chainIdStr;
      final parsed = int.tryParse(rawNum);
      if (parsed != null) return parsed;
    }

    final s = _modal?.session;
    final ns = s?.namespaces;
    if (ns == null || ns.isEmpty) return 0;
    final accounts = ns["eip155"]?.accounts ?? const <String>[];
    if (accounts.isEmpty) return 0;
    final parts = accounts.first.split(":"); // eip155:56:0x...
    if (parts.length >= 2) {
      return int.tryParse(parts[1]) ?? 0;
    }
    return 0;
  }

  Future<void> init(BuildContext context) async {
    if (_modal != null || _initing) return;
    _initing = true;
    _modal = ReownAppKitModal(
      context: context,
      projectId: "84fb59b50867c77427e2e81a44cfa3b7",
      metadata: const PairingMetadata(
        name: "DrainShield",
        description: "Wallet Approval Risk Scanner & Revoke Tool",
        url: "https://ibiticoin.com",
        icons: ["https://avatars.githubusercontent.com/u/37784886"],
        redirect: Redirect(
          native: "drainshield://wc",
          universal: "https://ibiticoin.com/wc",
        ),
      ),
      optionalNamespaces: {
        'eip155': const RequiredNamespace(
          chains: [
            "eip155:1", // Ethereum
            "eip155:56", // BSC
            "eip155:137", // Polygon
            "eip155:10", // Optimism
            "eip155:100", // Gnosis
          ],
          methods: [
            'personal_sign',
            'eth_sendTransaction',
            'eth_signTypedData',
            'eth_signTypedData_v4',
            'wallet_switchEthereumChain',
            'wallet_addEthereumChain',
          ],
          events: [
            'chainChanged',
            'accountsChanged',
          ],
        ),
      },
    );
    // Refresh UI on modal updates
    _modal!.addListener(_onModalUpdate);
    await _modal!.init();
    debugPrint("[WcService] Modal initialized");
    _initing = false;
    notifyListeners();
  }

  void _onModalUpdate() {
    debugPrint("[WcService] _onModalUpdate: "
        "isConnected=$isConnected, "
        "address=$address, "
        "currentChainId=$currentChainId, "
        "hasSession=${_modal?.session != null}, "
        "selectedChainId=${_modal?.selectedChain?.chainId}");
    notifyListeners();
  }

  void connect(BuildContext context) {
    debugPrint("[WcService] connect started");
    final m = _modal;
    if (m == null) throw StateError("WcService not initialized");
    // Open the WalletConnect modal
    // Revert to AllWalletsPage as SelectWalletPage was not found
    m.openModalView(const ReownAppKitModalAllWalletsPage());
  }

  Future<void> disconnect() async {
    debugPrint("[WcService] disconnect called");
    final m = _modal;
    if (m == null) return;
    try {
      await m.disconnect();
    } catch (e) {
      debugPrint("[WcService] disconnect error: $e");
    }
    debugPrint("[WcService] after disconnect: isConnected=$isConnected");
    notifyListeners();
  }

  @override
  void dispose() {
    _modal?.removeListener(_onModalUpdate);
    super.dispose();
  }
}
