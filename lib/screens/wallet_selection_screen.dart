import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/localization_service.dart';
import '../services/wallet/wallet_registry_service.dart';

import '../services/pro/pro_service.dart';
import '../models/linked_wallet.dart';
import '../config/chains.dart';

import '../widgets/design/ds_background.dart';
import '../widgets/design/ds_fade_slide.dart';
import 'package:url_launcher/url_launcher.dart';

import 'pro_screen.dart';

class WalletSelectionScreen extends StatefulWidget {
  const WalletSelectionScreen({super.key});

  @override
  State<WalletSelectionScreen> createState() => _WalletSelectionScreenState();
}

class _WalletSelectionScreenState extends State<WalletSelectionScreen> {
  final WalletRegistryService _registry = WalletRegistryService.instance;

  @override
  void initState() {
    super.initState();
    _registry.addListener(_onRegistryUpdate);
  }

  @override
  void dispose() {
    _registry.removeListener(_onRegistryUpdate);
    super.dispose();
  }

  void _onRegistryUpdate() {
    if (mounted) setState(() {});
  }

  String _formatAddress(String address) {
    if (address.length < 12) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }

  void _copyAddress(String address, LocalizationService loc) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.t('assetCopySuccess')),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF00FF9D).withOpacity(0.8),
      ),
    );
  }

  void _openInExplorer(String address) {
    final chainId = _registry.selectedChainId;
    final url = ChainConfig.getExplorerUrl(chainId, address);
    if (url != null) {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);
    final wallets = _registry.wallets;
    final activeAddress = _registry.selectedAddress;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DsBackground(
        child: Column(
          children: [
            _buildAppBar(loc),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  final isSelected = wallet.address.toLowerCase() ==
                      activeAddress.toLowerCase();
                  return _buildWalletCard(wallet, isSelected, loc);
                },
              ),
            ),
            if (!ProService.instance.isProActive())
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Text(
                  loc.t('proLimitHint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(LocalizationService loc) {
    final isPro = ProService.instance.isProActive();
    final badgeColor = isPro ? const Color(0xFFFFD700) : Colors.white30;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 32, 20, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            loc.t('portfolioSwitchWallet').toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeColor.withOpacity(0.3)),
              ),
              child: Text(
                'PRO',
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(
      LinkedWallet wallet, bool isSelected, LocalizationService loc) {
    const accentColor = Color(0xFF00FF9D);

    return DsFadeSlide(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withOpacity(0.08)
                : Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? accentColor.withOpacity(0.5) : Colors.white12,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: InkWell(
            onTap: () {
              if (!isSelected) {
                _registry.setSelectedAddress(wallet.address);
              }
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Status/Checkmark
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.account_balance_wallet_outlined,
                      color: isSelected ? accentColor : Colors.white38,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatAddress(wallet.address),
                          style: TextStyle(
                            color: isSelected
                                ? accentColor.withOpacity(0.7)
                                : Colors.white24,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  _buildActionButton(
                    icon: Icons.copy_outlined,
                    onTap: () => _copyAddress(wallet.address, loc),
                  ),
                  const SizedBox(width: 10),
                  _buildActionButton(
                    icon: Icons.open_in_new_outlined,
                    onTap: () => _openInExplorer(wallet.address),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
      ),
    );
  }
}
