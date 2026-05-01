import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/linked_wallet.dart';
import '../../models/security_event.dart';
import '../pro/pro_service.dart';
import '../wc_service.dart';
import '../security/security_event_service.dart';
import '../../config/chains.dart';

class WalletRegistryService extends ChangeNotifier {
  static final WalletRegistryService instance =
      WalletRegistryService._internal();
  WalletRegistryService._internal();

  static const String _key = 'linked_wallets';
  List<LinkedWallet> _wallets = [];

  // Track address that was just connected but not yet in registry
  String? _pendingAutoLinkAddress;
  String? get pendingAutoLinkAddress => _pendingAutoLinkAddress;

  List<LinkedWallet> get wallets => List.unmodifiable(_wallets);

  String? _selectedAddress;
  String get selectedAddress {
    if (_selectedAddress != null) return _selectedAddress!;
    final wcAddr = WcService().address;
    if (wcAddr.isNotEmpty) return wcAddr;
    return getPrimaryWallet()?.address ?? '';
  }

  void setSelectedAddress(String addr) {
    if (_selectedAddress?.toLowerCase() != addr.toLowerCase()) {
      _selectedAddress = addr;
      notifyListeners();
    }
  }

  String _selectedChain = 'bsc';
  String get selectedChain => _selectedChain;
  int get selectedChainId => ChainConfig.getChainId(_selectedChain);

  void setSelectedChain(String chain) {
    if (_selectedChain != chain) {
      _selectedChain = chain;
      notifyListeners();
    }
  }

  Future<void> init() async {
    await load();
    // Ensure we have exactly one primary wallet before any state refresh
    bool primaryChanged = _ensureSinglePrimary();
    if (primaryChanged) {
      await save();
    }
    // Sync states on startup
    _refreshWalletStates();
    // Listen to PRO status changes to reactivate/freeze wallets
    ProService.instance.addListener(_refreshWalletStates);

    // Listen to WalletConnect sessions to help syncing
    WcService().addListener(_onWcUpdate);
  }

  void _onWcUpdate() async {
    final wc = WcService();
    if (!wc.isConnected) {
      _pendingAutoLinkAddress = null;
      notifyListeners();
      return;
    }

    final addr = wc.address.toLowerCase();
    if (addr.isEmpty) return;

    // 1. Is it already in registry?
    final registeredWallet =
        _wallets.where((w) => w.address.toLowerCase() == addr).firstOrNull;
    if (registeredWallet != null) {
      // Auto-select the connected wallet if it's in our registry
      if (_selectedAddress?.toLowerCase() != addr) {
        _selectedAddress = registeredWallet.address;
      }
      _pendingAutoLinkAddress = null;
      notifyListeners();
      return;
    }

    // 2. Is registry empty? (First connect)
    if (_wallets.isEmpty) {
      debugPrint('[WalletRegistry] Auto-adding first wallet: $addr');
      await addWallet(LinkedWallet(
        address: addr,
        label: 'Wallet',

        addedAt: DateTime.now(),
        isPrimary: true,
        isActive: true, // First one is always active
      ));
      _pendingAutoLinkAddress = null;
    } else {
      // 3. New wallet connected, not in registry, registry not empty.
      // Trigger Intelligent Prompt state if within limits.
      if (canAddMoreWallets()) {
        if (_pendingAutoLinkAddress != addr) {
          _pendingAutoLinkAddress = addr;
          notifyListeners();
        }
      }
    }
  }

  void dismissPendingLink() {
    _pendingAutoLinkAddress = null;
    notifyListeners();
  }

  void _refreshWalletStates() {
    final isPro = ProService.instance.isProActive();
    bool changed = false;

    // We need to identify which wallet is primary to KEEP it active in Free mode.
    final primary = getPrimaryWallet();

    _wallets = _wallets.map((w) {
      // In Free mode, only the primary wallet is active.
      // In PRO, all linked wallets are active.
      bool shouldBeActive =
          isPro || (primary != null && w.address == primary.address);

      if (w.isActive != shouldBeActive) {
        changed = true;
        return w.copyWith(isActive: shouldBeActive);
      }
      return w;
    }).toList();

    if (changed) {
      save();
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonStr);
        _wallets = jsonList.map((e) => LinkedWallet.fromJson(e)).toList();
      } catch (e) {
        _wallets = [];
      }
    } else {
      _wallets = [];
    }
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_wallets.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
    notifyListeners();
  }

  bool canAddMoreWallets() {
    final limit = ProService.instance.maxWallets();
    return _wallets.length < limit;
  }

  Future<bool> addWallet(LinkedWallet wallet) async {
    if (!canAddMoreWallets()) return false;

    // Check if wallet already exists
    if (_wallets.any(
      (e) => e.address.toLowerCase() == wallet.address.toLowerCase(),
    )) {
      return false;
    }

    final isPro = ProService.instance.isProActive();

    // If this is the first wallet, make it primary
    final isFirst = _wallets.isEmpty;
    final walletToAdd = wallet.copyWith(
      isPrimary: isFirst || wallet.isPrimary,
      isActive: isFirst || isPro, // For review: now real PRO check
    );

    _wallets.add(walletToAdd);
    _ensureSinglePrimary(); // Ensure invariant after adding
    await save();

    // Emit security event for timeline (FREE & PRO)
    SecurityEventService.instance.emit(
      SecurityEvent(
        type: SecurityEventType.walletConnected,
        severity: 'low',
        timestamp: DateTime.now(),
        walletAddress: walletToAdd.address,
        title: 'Wallet Linked',
        message:
            'Security monitoring activated for ${walletToAdd.address.substring(0, 6)}...',
      ),
    );

    return true;
  }

  Future<void> removeWallet(String address) async {
    final bool wasSelected =
        _selectedAddress?.toLowerCase() == address.toLowerCase();

    _wallets.removeWhere(
      (e) => e.address.toLowerCase() == address.toLowerCase(),
    );

    _ensureSinglePrimary(); // Ensure invariant after removal (replaces manual logic)

    if (wasSelected) {
      // If we removed the selected wallet, switch to the new primary
      _selectedAddress = getPrimaryWallet()?.address ?? '';
    }

    await save();
  }

  Future<void> setPrimaryWallet(String address) async {
    _wallets = _wallets.map((w) {
      return w.copyWith(
        isPrimary: w.address.toLowerCase() == address.toLowerCase(),
      );
    }).toList();
    await save();
  }

  bool _ensureSinglePrimary() {
    if (_wallets.isEmpty) return false;

    int primaryCount = _wallets.where((e) => e.isPrimary).length;
    bool changed = false;

    if (primaryCount == 1) return false; // Invariant satisfied

    bool primaryFound = false;
    _wallets = _wallets.map((w) {
      if (w.isPrimary) {
        if (!primaryFound) {
          primaryFound = true;
          return w;
        } else {
          // Multiple primaries found, demote extra ones
          changed = true;
          return w.copyWith(isPrimary: false);
        }
      }
      return w;
    }).toList();

    // If zero primaries found, we no longer automatically promote.
    // The user must manually select a primary via the connection flow.
    // if (!primaryFound && _wallets.isNotEmpty) {
    //   _wallets[0] = _wallets[0].copyWith(isPrimary: true);
    //   changed = true;
    // }

    return changed;
  }

  Future<void> setMonitoringEnabled(String address, bool enabled) async {
    _wallets = _wallets.map((w) {
      if (w.address.toLowerCase() == address.toLowerCase()) {
        return w.copyWith(monitoringEnabled: enabled);
      }
      return w;
    }).toList();
    await save();
  }

  LinkedWallet? getPrimaryWallet() {
    try {
      return _wallets.firstWhere((e) => e.isPrimary);
    } catch (e) {
      return null;
    }
  }

  List<LinkedWallet> getMonitoringEligibleWallets() {
    // Monitoring is strictly a PRO feature.
    if (!ProService.instance.isProActive()) return [];

    // In PRO, all active linked wallets are monitored.
    return List.unmodifiable(_wallets.where((w) => w.isActive));
  }
}
