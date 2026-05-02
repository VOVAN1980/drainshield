import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/localization_service.dart';
import '../services/portfolio_service.dart';
import '../services/wc_service.dart';
import '../services/wallet/wallet_registry_service.dart';

import '../models/wallet_asset.dart';
import '../models/linked_wallet.dart';
import '../config/chains.dart';
import '../config/app_colors.dart';
import '../config/address_validator.dart';
import '../widgets/design/ds_fade_slide.dart';
import '../widgets/design/ds_background.dart';
import '../widgets/mascot_image.dart';
import 'asset_detail_screen.dart';
import 'pro_screen.dart';
import 'wallet_selection_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final PortfolioService _portfolioService = PortfolioService();
  final WalletRegistryService _registry = WalletRegistryService.instance;
  List<WalletAsset>? _assets;
  bool _isLoading = false;
  String? _error;
  int _lastWalletChainId = 0;

  final List<Map<String, String>> _networks = ChainConfig.allNetworks;

  @override
  void initState() {
    super.initState();
    final wc = WcService();
    _lastWalletChainId = wc.currentChainId;
    _syncToWalletChain(); // Initial sync

    wc.addListener(_onWalletUpdate);
    _registry.addListener(_onRegistryUpdate);
    _fetchData();
  }

  @override
  void dispose() {
    WcService().removeListener(_onWalletUpdate);
    _registry.removeListener(_onRegistryUpdate);
    super.dispose();
  }

  void _onRegistryUpdate() {
    if (!mounted) return;
    setState(() {});
    _fetchData();
  }

  void _onWalletUpdate() {
    if (!mounted) return;
    final wc = WcService();

    if (wc.currentChainId != _lastWalletChainId) {
      _lastWalletChainId = wc.currentChainId;
      _syncToWalletChain();
      _fetchData();
    } else {
      setState(() {});
    }
  }

  void _syncToWalletChain() {
    // Only sync from WcService if currently on an EVM chain.
    // If the user manually selected Tron/Solana, don't override it
    // — WcService only tracks EVM chains and would reset to BSC.
    final currentChain = _registry.selectedChain;
    if (ChainConfig.isNonEvmChain(currentChain)) return;

    final activeSlug = ChainConfig.getMoralisChainSlug(_lastWalletChainId);
    if (activeSlug != null) {
      _registry.setSelectedChain(activeSlug);
    }
  }

  /// True when the selected chain requires a different address format
  /// than the currently active wallet (e.g. EVM wallet + Tron chain).
  bool _isChainMismatch = false;

  Future<void> _fetchData() async {
    final activeAddress = _registry.selectedAddress;
    if (activeAddress.isEmpty) return;

    final selectedChain = _registry.selectedChain;

    // ── Chain/Address compatibility check ──────────────────────────
    // Don't send an EVM address to Solana/Tron RPCs, and vice versa.
    if (ChainConfig.isNonEvmChain(selectedChain)) {
      // Check if the wallet is compatible with the selected chain
      final wallet = _registry.wallets.firstWhere(
        (w) => w.address.toLowerCase() == activeAddress.toLowerCase(),
        orElse: () => LinkedWallet(
            address: activeAddress, label: 'Wallet', addedAt: DateTime.now()),
      );

      if (wallet.chainType != selectedChain) {
        // Mismatch: EVM wallet selected but Tron/Solana chain chosen
        if (mounted) {
          setState(() {
            _isChainMismatch = true;
            _assets = null;
            _isLoading = false;
            _error = null;
          });
        }
        return;
      }
    }

    setState(() {
      _isChainMismatch = false;
      _isLoading = true;
      _error = null;
    });

    try {
      final assets = await _portfolioService.getPortfolio(
        activeAddress,
        chainOverride: selectedChain,
      );
      if (mounted) {
        setState(() {
          _assets = assets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  double get _totalValue {
    if (_assets == null) return 0.0;
    return _assets!.fold(0.0, (sum, asset) => sum + asset.valueUsd);
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(value);
  }

  String _formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String _getNetworkName(String id, LocalizationService loc) {
    final entry = _networks.firstWhere(
      (n) => n['id'] == id,
      orElse: () => {'id': id, 'name': id},
    );
    final name = entry['name']!;
    // If it's one of our known networks, localize it
    if ([
      'BNB Chain',
      'Ethereum',
      'Polygon',
      'Arbitrum',
      'Base',
    ].contains(name)) {
      final key = 'chain${name.replaceAll(' ', '')}';
      return loc.t(key);
    }
    return name;
  }

  void _onAssetTap(WalletAsset asset, String walletAddress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssetDetailScreen(asset: asset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);
    final wc = WcService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DsBackground(
        child: Column(
          children: [
            // Title row — above the lion, no z-order overlap
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      loc.t('portfolioTitle'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (wc.isConnected)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF00FF9D)),
                      onPressed: _isLoading ? null : _fetchData,
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            // Lion directly below title row — head fully visible
            Transform.translate(
              offset: const Offset(0, -35),
              child: const IgnorePointer(
                child: MascotImage(
                  mascotState: MascotState.portfolio,
                  width: 270,
                  height: 270,
                ),
              ),
            ),
            // Content pulled up to sit tight under lion's feet
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -80),
                child: Column(
                  children: [
                    if (_registry.selectedAddress.isEmpty && !wc.isConnected)
                      Expanded(child: _buildDisconnectedState(loc, wc))
                    else ...[
                      _buildMonitoringStatus(loc),
                      _buildTopSelectors(loc),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _isChainMismatch
                            ? _buildChainMismatchState(loc)
                            : _isLoading
                                ? _buildLoadingState(loc)
                                : _error != null
                                    ? _buildErrorState(loc)
                                    : (_assets == null || _assets!.isEmpty)
                                        ? _buildEmptyState(loc)
                                        : _buildPortfolioContent(
                                            loc, _registry.selectedAddress),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringStatus(LocalizationService loc) {
    final activeCount = _registry.getMonitoringEligibleWallets().length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        loc.t('portfolioMonitoringCount', {'count': activeCount}),
        style: TextStyle(
          color: const Color(0xFF00FF9D).withOpacity(0.7),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildTopSelectors(LocalizationService loc) {
    final activeAddress = _registry.selectedAddress;
    final wallet = _registry.wallets.firstWhere(
      (w) => w.address.toLowerCase() == activeAddress.toLowerCase(),
      orElse: () => LinkedWallet(
          address: activeAddress, label: 'Wallet', addedAt: DateTime.now()),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Network Selector
          _buildSelectorButton(
            onTap: () => _showNetworkBottomSheet(loc),
            icon: Icons.layers_outlined,
            label: _getNetworkName(_registry.selectedChain, loc),
            maxWidth: 110,
          ),
          const SizedBox(width: 8),
          // Wallet Selector
          _buildSelectorButton(
            onTap: () => _handleWalletSwitchTap(loc),
            icon: Icons.account_balance_wallet_outlined,
            label: wallet.label.replaceAll(RegExp(r'\s*\d+'), '').trim(),
            maxWidth: 130,
          ),

          // Space for future buttons
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSelectorButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    String? subLabel,
    bool isLocked = false,
    double? maxWidth,
  }) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 14,
                  color: isLocked ? Colors.white24 : const Color(0xFF00FF9D)),
              const SizedBox(width: 6),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subLabel != null)
                      Text(
                        subLabel,
                        style: const TextStyle(
                          color: AppColors.tertiaryText,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isLocked ? Icons.lock_outline : Icons.keyboard_arrow_down,
                size: 14,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNetworkBottomSheet(LocalizationService loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
                  child: Text(
                    loc.t('portfolioSelectNetwork'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _networks.length,
                    itemBuilder: (context, index) {
                      final network = _networks[index];
                      final isSelected =
                          _registry.selectedChain == network['id'];
                      return ListTile(
                        leading: _networkLogoWidget(network['id']!, isSelected),
                        title: Text(
                          _getNetworkName(network['id']!, loc),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.secondaryText,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: _networkColor(network['id']!))
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          if (!isSelected) {
                            _registry.setSelectedChain(network['id']!);
                            _fetchData();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _networkLogoUrl(String chainKey) {
    switch (chainKey) {
      case 'bsc':
        return 'https://cryptologos.cc/logos/bnb-bnb-logo.png?v=040';
      case 'eth':
        return 'https://cryptologos.cc/logos/ethereum-eth-logo.png?v=040';
      case 'polygon':
        return 'https://cryptologos.cc/logos/polygon-matic-logo.png?v=040';
      case 'arbitrum':
        return 'https://cryptologos.cc/logos/arbitrum-arb-logo.png?v=040';
      case 'base':
        return 'https://raw.githubusercontent.com/base-org/brand-kit/main/logo/symbol/Base_Symbol_Blue.png';
      case 'solana':
        return 'https://cryptologos.cc/logos/solana-sol-logo.png?v=040';
      case 'tron':
        return 'https://cryptologos.cc/logos/tron-trx-logo.png?v=040';
      default:
        return null;
    }
  }

  Widget _networkLogoWidget(String chainKey, bool isSelected) {
    final url = _networkLogoUrl(chainKey);
    final color = _networkColor(chainKey);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(isSelected ? 0.15 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(isSelected ? 0.4 : 0.1),
          width: 1.5,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: url != null
            ? Image.network(
                url,
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.currency_exchange,
                  size: 18,
                  color: color,
                ),
              )
            : Icon(Icons.layers_outlined, size: 18, color: color),
      ),
    );
  }

  Color _networkColor(String chainKey) {
    switch (chainKey) {
      case 'bsc':
        return const Color(0xFFF0B90B); // BNB Yellow
      case 'eth':
        return const Color(0xFF627EEA); // ETH Blue
      case 'polygon':
        return const Color(0xFF8247E5); // Polygon Purple
      case 'arbitrum':
        return const Color(0xFF28A0F0); // Arbitrum Blue
      case 'base':
        return const Color(0xFF0052FF); // Base Blue
      case 'solana':
        return const Color(0xFF14F195); // Solana Green
      case 'tron':
        return const Color(0xFFFF0013); // Tron Red
      default:
        return const Color(0xFF00FF9D);
    }
  }

  void _handleWalletSwitchTap(LocalizationService loc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WalletSelectionScreen()),
    );
  }

  void _showWalletBottomSheet(LocalizationService loc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final wallets = _registry.wallets;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.t('portfolioSwitchWallet'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (wallets.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    loc.t('linkedWalletsEmpty'),
                    style: const TextStyle(color: AppColors.tertiaryText),
                  ),
                ),
              ...wallets.map((wallet) {
                final isSelected = _registry.selectedAddress.toLowerCase() ==
                    wallet.address.toLowerCase();
                return ListTile(
                  leading: Icon(
                    Icons.account_balance_wallet_outlined,
                    color:
                        isSelected ? const Color(0xFF00FF9D) : Colors.white24,
                  ),
                  title: Text(
                    wallet.label,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : AppColors.secondaryText,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    _formatAddress(wallet.address),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.tertiaryText),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF00FF9D))
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (!isSelected) {
                      _registry.setSelectedAddress(wallet.address);
                    }
                  },
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showProPaywall(LocalizationService loc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          loc.t('portfolioProSwitchTitle'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          loc.t('portfolioProSwitchSub'),
          style: const TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('scanResCancelCapitalize'),
                style: const TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: Text(loc.t('proUpgradeBtn')),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedState(LocalizationService loc, WcService wc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Color(0xFF00B8FF),
            ),
            const SizedBox(height: 24),
            Text(
              loc.t('dashboardConnectToScan'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => wc.connect(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B8FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                loc.t('dashboardConnectWalletBtn'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(LocalizationService loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF00FF9D)),
          const SizedBox(height: 16),
          Text(
            loc.t('portfolioSyncing'),
            style: const TextStyle(color: AppColors.tertiaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LocalizationService loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            _error ?? loc.t('unknownError'),
            style: const TextStyle(color: AppColors.tertiaryText),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _fetchData,
            child: Text(
              loc.t('portfolioRetry'),
              style: const TextStyle(color: Color(0xFF00B8FF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChainMismatchState(LocalizationService loc) {
    final selectedChain = _registry.selectedChain;
    final chainName = ChainConfig.getChainNameByKey(selectedChain);
    final isSolana = selectedChain == 'solana';
    final color = isSolana ? const Color(0xFF9945FF) : const Color(0xFFFF0013);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: _networkLogoWidget(selectedChain, true),
            ),
            const SizedBox(height: 20),
            Text(
              loc.t('portfolioChainWalletRequired', {'chain': chainName}),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              loc.t('portfolioChainMismatchBody', {'chain': chainName}),
              style: const TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // ── Primary CTA: Add address ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showAddChainAddressDialog(chainName, selectedChain, color),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: Text(
                    loc.t('portfolioAddChainAddress', {'chain': chainName})),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChainAddressDialog(
      String chainName, String chainType, Color color) {
    final loc = LocalizationService.instance;
    final ctl = TextEditingController();
    String? errorText;
    String?
        hintStatus; // null = neutral, 'valid' = detected, 'wrong' = wrong chain

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111827),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  _networkLogoWidget(chainType, true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.t('portfolioAddChainWallet', {'chain': chainName}),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctl,
                    onChanged: (val) {
                      final addr = val.trim();
                      if (addr.isEmpty) {
                        setDialogState(() {
                          errorText = null;
                          hintStatus = null;
                        });
                        return;
                      }
                      final detected = AddressValidator.detectChainType(addr);
                      setDialogState(() {
                        if (detected == chainType) {
                          errorText = null;
                          hintStatus = 'valid';
                        } else if (detected == 'unknown') {
                          errorText = null;
                          hintStatus = null; // Still typing
                        } else {
                          errorText = null;
                          hintStatus = 'wrong';
                        }
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      hintText: chainType == 'solana'
                          ? 'e.g. 7xKXtg2CW87...'
                          : 'e.g. TN3zFJ...WSeB',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.2)),
                      errorText: errorText,
                      errorMaxLines: 3,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Dynamic status hint
                  if (hintStatus == 'valid')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: color, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          loc.t('portfolioChainAddressDetected',
                              {'chain': chainName}),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else if (hintStatus == 'wrong')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orangeAccent, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          loc.t('portfolioChainAddressWrong', {
                            'detected': AddressValidator.chainDisplayName(
                                AddressValidator.detectChainType(
                                    ctl.text.trim()))
                          }),
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      loc.t('portfolioPasteChainAddress', {'chain': chainName}),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(loc.t('scanResCancelCapitalize'),
                      style: const TextStyle(color: AppColors.tertiaryText)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final addr = ctl.text.trim();

                    if (addr.isEmpty) {
                      setDialogState(() => errorText =
                          loc.t('portfolioAddressEmpty', {'chain': chainName}));
                      return;
                    }

                    final detected = AddressValidator.detectChainType(addr);

                    if (detected != chainType) {
                      setDialogState(() {
                        errorText = detected == 'unknown'
                            ? chainType == 'solana'
                                ? loc.t('portfolioFormatInvalidSolana')
                                : loc.t('portfolioFormatInvalidTron')
                            : loc.t('portfolioChainNotMatch', {
                                'detected':
                                    AddressValidator.chainDisplayName(detected),
                                'chain': chainName
                              });
                      });
                      return;
                    }

                    // Check if already exists
                    if (_registry.wallets.any(
                        (w) => w.address.toLowerCase() == addr.toLowerCase())) {
                      setDialogState(() => errorText =
                          loc.t('portfolioWalletAlreadyRegistered'));
                      return;
                    }

                    // Add to registry
                    final added = await _registry.addWallet(LinkedWallet(
                      address: addr,
                      label: '$chainName Wallet',
                      addedAt: DateTime.now(),
                      chainType: chainType,
                    ));

                    if (!added) {
                      setDialogState(() =>
                          errorText = loc.t('portfolioWalletLimitReached'));
                      return;
                    }

                    // Select the new wallet and refresh
                    _registry.setSelectedAddress(addr);
                    Navigator.pop(ctx);
                    _fetchData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                      loc.t('portfolioAddChainAddress', {'chain': chainName})),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(LocalizationService loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.money_off, size: 60, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            loc.t('portfolioNoAssets', {
              'network': _getNetworkName(_registry.selectedChain, loc),
            }),
            style: const TextStyle(color: AppColors.tertiaryText),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _fetchData,
            child: Text(
              loc.t('portfolioRefresh'),
              style: const TextStyle(color: Color(0xFF00B8FF)),
            ),
          ),
        ],
      ),
    );
  }

  String _short(String address) {
    if (address.isEmpty || address.length < 10) return address;
    return "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
  }

  Widget _buildPortfolioContent(LocalizationService loc, String address) {
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFF00FF9D),
      backgroundColor: const Color(0xFF0B0F16),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(loc, address),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.t('portfolioAssets'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                loc.t('portfolioTokensCount', {'count': _assets?.length ?? 0}),
                style: const TextStyle(
                    color: AppColors.tertiaryText, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(_assets?.map((asset) => _buildAssetItem(asset, address)) ?? []),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(LocalizationService loc, String address) {
    return DsFadeSlide(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00B8FF).withOpacity(0.15),
              const Color(0xFF0055FF).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF00B8FF).withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.t('portfolioTotalValue'),
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(_totalValue),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    _getNetworkName(_registry.selectedChain, loc),
                    style: const TextStyle(
                      color: Color(0xFF00FF9D),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.wallet, size: 14, color: Colors.white38),
                const SizedBox(width: 8),
                Text(
                  _short(address),
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetItem(WalletAsset asset, String walletAddress) {
    return GestureDetector(
      onTap: () => _onAssetTap(asset, walletAddress),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white10,
              backgroundImage:
                  asset.logoUrl != null ? NetworkImage(asset.logoUrl!) : null,
              child: asset.logoUrl == null
                  ? Text(
                      asset.symbol[0],
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${asset.balance.toStringAsFixed(asset.balance < 0.001 ? 6 : 4)} ${asset.symbol}',
                    style: const TextStyle(
                        color: AppColors.tertiaryText, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      _formatCurrency(asset.valueUsd),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.white24,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(asset.priceUsd),
                  style: const TextStyle(
                      color: AppColors.tertiaryText, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
