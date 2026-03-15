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

  @override
  void dispose() {
    _addressController.dispose();
    _labelController.dispose();
    super.dispose();
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
      body: DsBackground(
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

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Text(
                          loc.t('linkedWalletsEmptyGuidance'),
                          style: const TextStyle(
                            color: AppColors.tertiaryText,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
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
                            if (wallets.length < limit)
                              ElevatedButton.icon(
                                onPressed: _showAddWalletDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(loc.t('linkedWalletsAddWallet')),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                itemCount: wallets.length + (isPro ? 0 : 1),
                                itemBuilder: (context, index) {
                                  if (index == wallets.length) {
                                    return _buildRenewCTA(loc);
                                  }
                                  final wallet = wallets[index];
                                  return _buildWalletCard(
                                      wallet, loc, isPro, index < 1);
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
    );
  }

  Widget _buildWalletCard(
    LinkedWallet wallet,
    LocalizationService loc,
    bool isPro,
    bool isFreeSlot,
  ) {
    final bool isWalletActive = wallet.isActive;

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
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isFreeSlot ? Colors.blueAccent : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          isFreeSlot ? "F" : "P",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.tertiaryText),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 160),
                  color: const Color(0xFF161B22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  itemBuilder: (context) => [
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
                        onTap: () => WalletRegistryService.instance
                            .setPrimaryWallet(wallet.address),
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
                      onTap: () => WalletRegistryService.instance.removeWallet(
                        wallet.address,
                      ),
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
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenewCTA(LocalizationService loc) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.15),
            Colors.orange.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.security_update_warning,
              color: Colors.orange, size: 32),
          const SizedBox(height: 12),
          const Text(
            "Security Monitoring Paused",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your wallets are currently not being monitored because your PRO subscription is inactive. Renew now to reactivate 24/7 protection.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.tertiaryText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "RENEW PRO SUBSCRIPTION",
              style: TextStyle(fontWeight: FontWeight.bold),
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
