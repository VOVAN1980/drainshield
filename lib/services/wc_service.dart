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
        url: "https://drainshield.app",
        icons: ["https://avatars.githubusercontent.com/u/37784886"],
        redirect: Redirect(
          // Р В РІР‚в„ўР В РЎвЂ™Р В РІР‚вЂњР В РЎСљР В РЎвЂє: Р В РЎвЂќР В РЎвЂўР В Р вЂ¦Р В РЎвЂќР РЋР вЂљР В Р’ВµР РЋРІР‚С™Р В Р вЂ¦Р РЋРІР‚в„–Р В РІвЂћвЂ“ callback, Р В РЎвЂќР В РЎвЂўР РЋРІР‚С™Р В РЎвЂўР РЋР вЂљР РЋРІР‚в„–Р В РІвЂћвЂ“ Р В РЎвЂ”Р РЋР вЂљР В РЎвЂР В Р вЂ¦Р В РЎвЂР В РЎВР В Р’В°Р В Р’ВµР РЋРІР‚С™ AndroidManifest
          native: "drainshield://wc",
          universal: "https://drainshield.app/wc",
          linkMode: false,
        ),
      ),
    );
    // Р В РІР‚С”Р РЋР вЂ№Р В Р’В±Р В РЎвЂўР В Р’Вµ Р В РЎвЂР В Р’В·Р В РЎВР В Р’ВµР В Р вЂ¦Р В Р’ВµР В Р вЂ¦Р В РЎвЂР В Р’Вµ Р РЋР С“Р В РЎвЂўР РЋР С“Р РЋРІР‚С™Р В РЎвЂўР РЋР РЏР В Р вЂ¦Р В РЎвЂР РЋР РЏ Р В РЎВР В РЎвЂўР В РўвЂР В Р’В°Р В Р’В»Р В РЎвЂќР В РЎвЂ Р Р†РІР‚В РІР‚в„ў Р В РЎвЂўР В Р’В±Р В Р вЂ¦Р В РЎвЂўР В Р вЂ Р В Р’В»Р РЋР РЏР В Р’ВµР В РЎВ UI
    _modal!.addListener(_onModalUpdate);
    await _modal!.init();
    _initing = false;
    notifyListeners();
  }

  void _onModalUpdate() => notifyListeners();
  void connect() {
    final m = _modal;
    if (m == null) throw StateError("WcService not initialized");
    // Р В РЎвЂєР РЋРІР‚С™Р В РЎвЂќР РЋР вЂљР РЋРІР‚в„–Р В Р вЂ Р В Р’В°Р В Р’ВµР В РЎВ Р РЋР С“Р РЋРІР‚С™Р В Р’В°Р В Р вЂ¦Р В РўвЂР В Р’В°Р РЋР вЂљР РЋРІР‚С™Р В Р вЂ¦Р РЋРІР‚в„–Р В РІвЂћвЂ“ UI WalletConnect (Р В РЎвЂўР В Р вЂ¦ Р РЋР С“Р В Р’В°Р В РЎВ Р В РўвЂР В РЎвЂўР В Р’В¶Р В РўвЂР РЋРІР‚ВР РЋРІР‚С™Р РЋР С“Р РЋР РЏ Р В Р’В±Р В РЎвЂР В РЎвЂўР В РЎВР В Р’ВµР РЋРІР‚С™Р РЋР вЂљР В РЎвЂР В РЎвЂ/Р В РЎвЂ”Р В РЎвЂР В Р вЂ¦Р В Р’В°)
    m.openModalView(const ReownAppKitModalAllWalletsPage());
  }

  Future<void> disconnect() async {
    final m = _modal;
    if (m == null) return;
    try {
      await m.disconnect();
    } catch (_) {}
    notifyListeners();
  }

  @override
  void dispose() {
    _modal?.removeListener(_onModalUpdate);
    super.dispose();
  }
}
