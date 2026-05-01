import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/linked_wallet.dart';
import '../../services/wallet/wallet_registry_service.dart';
import '../../services/wc_service.dart';
import '../../services/localization_service.dart';
import '../../services/pro/pro_service.dart';
import '../../widgets/design/ds_background.dart';
import '../pro_screen.dart';
import '../../config/app_colors.dart';

class LinkedWalletsScreen extends StatefulWidget {
  const LinkedWalletsScreen({super.key});

  @override
  State<LinkedWalletsScreen> createState() => _LinkedWalletsScreenState();
}

class _LinkedWalletsScreenState extends State<LinkedWalletsScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  bool _isProcessingPrimary = false;
  bool _isWaitingForNewSession =
      false; // Guard: ignore events until WC modal is open
  Timer? _primaryTimeoutTimer;
  void Function()? _wcListener;

  @override
  void dispose() {
    _addressController.dispose();
    _labelController.dispose();
    _cleanupPrimaryFlow(updateUi: false); // Never setState during dispose
    super.dispose();
  }

  void _cleanupPrimaryFlow({bool updateUi = true}) {
    _primaryTimeoutTimer?.cancel();
    _primaryTimeoutTimer = null;
    final listener = _wcListener;
    if (listener != null) {
      WcService().removeListener(listener);
      _wcListener = null;
    }
    if (updateUi && mounted) {
      setState(() => _isProcessingPrimary = false);
    }
  }

  Future<void> _handleSetPrimary(LinkedWallet targetWallet) async {
    final loc = LocalizationProvider.of(context);
    final wc = WcService();
    final registry = WalletRegistryService.instance;

    // 1. Confirm with user
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(loc.t('linkedWalletsConfirmPrimaryTitle'),
            style: const TextStyle(color: Colors.white)),
        content: Text(loc.t('linkedWalletsConfirmPrimaryMessage'),
            style: const TextStyle(color: AppColors.secondaryText)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.t('panicCancel'))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(loc.t('panicConfirm'))),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isProcessingPrimary = true;
      _isWaitingForNewSession = false;
    });

    // 2. Disconnect existing session and wait for WC to fully clear state
    if (wc.isConnected) {
      await wc.disconnect();
      await Future.delayed(const Duration(milliseconds: 800));
    }
    if (!mounted) {
      _cleanupPrimaryFlow();
      return;
    }

    // 3. Now mark that we're waiting for a NEW connection (ignores disconnect events)
    setState(() => _isWaitingForNewSession = true);

    _primaryTimeoutTimer = Timer(const Duration(seconds: 90), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(loc.t('linkedWalletsPrimaryChangeCancelled')),
              backgroundColor: Colors.orange),
        );
        _cleanupPrimaryFlow();
      }
    });

    _wcListener = () {
      // Guard: ignore all events until we're actually waiting for the new session
      if (!_isWaitingForNewSession) return;
      // Only react when user has chosen a wallet
      if (!wc.isConnected) return;

      final connectedAddr = wc.address.toLowerCase().trim();
      final targetAddr = targetWallet.address.toLowerCase().trim();

      if (connectedAddr == targetAddr) {
        // SUCCESS: Perfect match
        registry.setPrimaryWallet(targetWallet.address);
        registry.setSelectedAddress(targetWallet.address);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(loc.t('linkedWalletsPrimaryChangeSuccess')),
                backgroundColor: Colors.green),
          );
        }
        _cleanupPrimaryFlow();
      } else {
        // MISMATCH: Stop listening immediately to avoid recursion
        final listener = _wcListener;
        if (listener != null) {
          wc.removeListener(listener);
          _wcListener = null;
        }
        _primaryTimeoutTimer?.cancel();
        _primaryTimeoutTimer = null;
        if (mounted) {
          setState(() {
            _isProcessingPrimary = false;
            _isWaitingForNewSession = false;
          });
          wc.disconnect();
          _showMismatchDialog(loc, connectedAddr, targetWallet);
        }
      }
    };
    final listener = _wcListener;
    if (listener != null) {
      wc.addListener(listener);
    }

    // 4. Trigger Connect
    try {
      wc.connect(context);
    } catch (e) {
      debugPrint("[LinkedWalletsScreen] Connect error: $e");
      _cleanupPrimaryFlow();
    }
  }

  void _showSetNewPrimaryPrompt(LocalizationService loc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(loc.t('linkedWalletsSetNewPrimaryTitle'),
            style: const TextStyle(color: Colors.white)),
        content: Text(loc.t('linkedWalletsSetNewPrimaryMessage'),
            style: const TextStyle(color: AppColors.secondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('panicCancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Simply scroll or show the list, the user can now manually tap "Set Primary"
              // on any remaining wallet.
            },
            child: Text(loc.t('panicConfirm')),
          ),
        ],
      ),
    );
  }

  void _showMismatchDialog(
      LocalizationService loc, String selected, LinkedWallet target) {
    final wc = WcService();
    final String guest = wc.guestName;
    final String sShort =
        "${selected.substring(0, 6)}...${selected.substring(selected.length - 4)}";
    final String tShort =
        "${target.address.substring(0, 6)}...${target.address.substring(target.address.length - 4)}";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(loc.t('linkedWalletsMismatchTitle'),
            style: const TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
          loc.t('linkedWalletsMismatchMessage',
              {'selected': sShort, 'target': tShort, 'guest': guest}),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cleanupPrimaryFlow();
            },
            child: Text(loc.t('panicCancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Attempt to reconnect immediately
              WcService().connect(this.context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF9D),
              foregroundColor: Colors.black,
            ),
            child: Text(loc.t('linkedWalletsTryAgain')),
          ),
        ],
      ),
    );
  }

  void _showAddWalletDialog() {
    final loc = LocalizationProvider.of(context);
    final currentAddress = WcService().address;
    final canAddMore = WalletRegistryService.instance.canAddMoreWallets();

    if (currentAddress.isNotEmpty &&
        _addressController.text.isEmpty &&
        WalletRegistryService.instance.wallets.isEmpty) {
      _addressController.text = currentAddress;
      _labelController.text = "My Wallet";
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(
          loc.t('linkedWalletsAddWallet'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentAddress.isNotEmpty) ...[
              ElevatedButton(
                onPressed: canAddMore
                    ? () => _addWallet(currentAddress, "Current Wallet")
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF9D).withOpacity(0.1),
                  foregroundColor: const Color(0xFF00FF9D),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(loc.t('linkedWalletsAddCurrent')),
              ),
              const SizedBox(height: 16),
              const Text("--- OR ---",
                  style: TextStyle(color: AppColors.tertiaryText)),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _addressController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: loc.t('linkedWalletsAddressHint'),
                hintStyle: const TextStyle(color: AppColors.tertiaryText),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _labelController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: loc.t('linkedWalletsLabelHint'),
                hintStyle: const TextStyle(color: AppColors.tertiaryText),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addressController.clear();
              _labelController.clear();
              Navigator.pop(context);
            },
            child: Text(loc.t('panicCancel')),
          ),
          ElevatedButton(
            onPressed: canAddMore
                ? () {
                    if (_addressController.text.isNotEmpty) {
                      _addWallet(
                        _addressController.text,
                        _labelController.text.isEmpty
                            ? "Wallet"
                            : _labelController.text,
                      );
                    }
                  }
                : null,
            child: Text(loc.t('linkedWalletsAddByAddress')),
          ),
        ],
      ),
    );
  }

  Future<void> _addWallet(String address, String label) async {
    final success = await WalletRegistryService.instance.addWallet(
      LinkedWallet(address: address, label: label, addedAt: DateTime.now()),
    );

    if (mounted) {
      Navigator.pop(context);
      _addressController.clear();
      _labelController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? LocalizationProvider.of(context).t('linkedWalletsAddSuccess')
                : LocalizationProvider.of(context).t('linkedWalletsAddFailed'),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          DsBackground(
            child: Column(
              children: [
                _buildAppBar(context, loc.t('linkedWalletsTitle')),
                Expanded(
                  child: ListenableBuilder(
                    listenable: WalletRegistryService.instance,
                    builder: (context, _) {
                      final wallets = WalletRegistryService.instance.wallets;
                      final limit = ProService.instance.maxWallets();
                      final isPro = ProService.instance.isProActive();
                      final atLimit = wallets.length >= limit;

                      return Column(
                        children: [
                          // PRO upgrade banner when free user hits 1-wallet limit
                          if (!isPro && atLimit && wallets.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                              child: _buildProUpgradeCTA(loc),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${wallets.length} / $limit ${loc.t('settingsSubscriptionWalletLimit')}",
                                    style: const TextStyle(
                                      color: AppColors.tertiaryText,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (!atLimit)
                                  ElevatedButton.icon(
                                    onPressed: _isProcessingPrimary
                                        ? null
                                        : _showAddWalletDialog,
                                    icon: const Icon(Icons.add, size: 18),
                                    label:
                                        Text(loc.t('linkedWalletsAddWallet')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00FF9D),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: wallets.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 64,
                                          color: Colors.white.withOpacity(0.05),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          loc.t('linkedWalletsEmpty'),
                                          style: const TextStyle(
                                            color: AppColors.tertiaryText,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 48,
                                          ),
                                          child: Text(
                                            loc.t('linkedWalletsEmptyGuidance'),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: AppColors.tertiaryText,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    itemCount: wallets.length,
                                    itemBuilder: (context, index) {
                                      final wallet = wallets[index];
                                      return _buildWalletCard(
                                          wallet, loc, true, true);
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessingPrimary)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00FF9D)),
                    const SizedBox(height: 24),
                    Text(
                      loc.t('linkedWalletsConnectFirst'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.t('linkedWalletsConfirmPrimaryTitle').toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _cleanupPrimaryFlow,
                      child: Text(
                        loc.t('panicCancel').toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF00FF9D),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(
    LinkedWallet wallet,
    LocalizationService loc,
    bool isPro,
    bool isFreeSlot,
  ) {
    final bool isWalletActive = wallet.isPrimary || isPro || isFreeSlot;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWalletActive
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: wallet.isPrimary && isWalletActive
              ? const Color(0xFF00FF9D).withOpacity(0.3)
              : isWalletActive
                  ? Colors.white.withOpacity(0.05)
                  : Colors.orange.withOpacity(0.1),
        ),
      ),
      child: Opacity(
        opacity: isWalletActive ? 1.0 : 0.4,
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: wallet.isPrimary && isWalletActive
                          ? const Color(0xFF00FF9D).withOpacity(0.1)
                          : Colors.white.withOpacity(0.1),
                      child: Icon(
                        isWalletActive
                            ? Icons.account_balance_wallet
                            : Icons.lock,
                        color: wallet.isPrimary && isWalletActive
                            ? const Color(0xFF00FF9D)
                            : AppColors.tertiaryText,
                      ),
                    ),
                    // PRO badges hidden for review
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${wallet.address.substring(0, 8)}...${wallet.address.substring(wallet.address.length - 6)}",
                        style: const TextStyle(
                          color: AppColors.tertiaryText,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                if (wallet.isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF9D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF00FF9D).withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      loc.t('linkedWalletsPrimary').toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF00FF9D),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                PopupMenuButton(
                  enabled: !_isProcessingPrimary,
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.tertiaryText),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 160),
                  color: const Color(0xFF161B22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  itemBuilder: (context) {
                    final canAdd =
                        WalletRegistryService.instance.canAddMoreWallets();
                    return [
                      if (canAdd)
                        PopupMenuItem(
                          onTap: () =>
                              Future.microtask(() => _showAddWalletDialog()),
                          child: Row(
                            children: [
                              const Icon(Icons.add,
                                  size: 18, color: Colors.white70),
                              const SizedBox(width: 12),
                              Text(
                                loc.t('linkedWalletsAdd'),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      if (!wallet.isPrimary)
                        PopupMenuItem(
                          onTap: () => _handleSetPrimary(wallet),
                          child: Row(
                            children: [
                              const Icon(Icons.star_outline,
                                  size: 18, color: Colors.white70),
                              const SizedBox(width: 12),
                              Text(
                                loc.t('linkedWalletsSetPrimary'),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        onTap: () async {
                          final wc = WcService();
                          if (wc.isConnected &&
                              wc.address.toLowerCase() ==
                                  wallet.address.toLowerCase()) {
                            await wc.disconnect();
                          }

                          final registry = WalletRegistryService.instance;
                          final bool wasPrimary = wallet.isPrimary;

                          await registry.removeWallet(wallet.address);

                          if (wasPrimary && registry.wallets.isNotEmpty) {
                            if (mounted) {
                              _showSetNewPrimaryPrompt(loc);
                            }
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                size: 18, color: Colors.redAccent),
                            const SizedBox(width: 12),
                            Text(
                              loc.t('linkedWalletsRemove'),
                              style: const TextStyle(),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Shown when a free user has reached the 1-wallet limit
  Widget _buildProUpgradeCTA(LocalizationService loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FF9D).withOpacity(0.08),
            const Color(0xFF00D4FF).withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00FF9D).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium,
              color: Color(0xFF00FF9D), size: 32),
          const SizedBox(height: 12),
          Text(
            loc.t('proMultiWalletTitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.t('portfolioProSwitchSub'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.tertiaryText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF9D),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              loc.t('proUpgradeBtn'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 32, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
