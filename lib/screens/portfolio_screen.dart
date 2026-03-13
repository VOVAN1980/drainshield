import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/localization_service.dart';
import '../services/portfolio_service.dart';
import '../services/wc_service.dart';
import '../models/wallet_asset.dart';
import '../config/chains.dart';
import '../widgets/design/ds_fade_slide.dart';
import '../widgets/design/ds_background.dart';
import '../widgets/mascot_image.dart';
import 'scan_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final PortfolioService _portfolioService = PortfolioService();
  List<WalletAsset>? _assets;
  bool _isLoading = false;
  String? _error;
  String _selectedChain = 'bsc';
  int _lastWalletChainId = 0;

  final List<Map<String, String>> _networks = [
    {'id': 'bsc', 'name': 'BNB Chain'},
    {'id': 'eth', 'name': 'Ethereum'},
    {'id': 'polygon', 'name': 'Polygon'},
    {'id': 'arbitrum', 'name': 'Arbitrum'},
    {'id': 'base', 'name': 'Base'},
  ];

  @override
  void initState() {
    super.initState();
    final wc = WcService();
    _lastWalletChainId = wc.currentChainId;
    _syncToWalletChain(); // Initial sync
    wc.addListener(_onWalletUpdate);
    _fetchData();
  }

  @override
  void dispose() {
    WcService().removeListener(_onWalletUpdate);
    super.dispose();
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
    final activeSlug = ChainConfig.getMoralisChainSlug(_lastWalletChainId);
    if (activeSlug != null) {
      _selectedChain = activeSlug;
    }
  }

  Future<void> _fetchData() async {
    final wc = WcService();
    if (!wc.isConnected) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assets = await _portfolioService.getPortfolio(
        wc.address,
        chainOverride: _selectedChain,
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
    if (asset.isNative) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanScreen(
          address: walletAddress,
          targetTokenAddress: asset.address,
          targetTokenName: asset.name,
          targetTokenSymbol: asset.symbol,
        ),
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
            const MascotImage(
              mascotState: MascotState.portfolio,
              width: 270,
              height: 270,
            ),
            // Content pulled up -45px to sit tight under lion's feet
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -45),
                child: Column(
                  children: [
                    if (!wc.isConnected)
                      Expanded(child: _buildDisconnectedState(loc, wc))
                    else ...[
                      _buildNetworkSelector(loc),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _isLoading
                            ? _buildLoadingState(loc)
                            : _error != null
                                ? _buildErrorState(loc)
                                : (_assets == null || _assets!.isEmpty)
                                    ? _buildEmptyState(loc)
                                    : _buildPortfolioContent(loc, wc.address),
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

  Widget _buildNetworkSelector(LocalizationService loc) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _networks.length,
        itemBuilder: (context, index) {
          final network = _networks[index];
          final isSelected = _selectedChain == network['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                _getNetworkName(network['id']!, loc),
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected && _selectedChain != network['id']) {
                  setState(() {
                    _selectedChain = network['id']!;
                  });
                  _fetchData();
                }
              },
              selectedColor: const Color(0xFF00FF9D),
              backgroundColor: Colors.white.withOpacity(0.05),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF00FF9D) : Colors.white12,
                ),
              ),
            ),
          );
        },
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
              onPressed: () => wc.connect(),
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
            style: const TextStyle(color: Colors.white70),
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
            style: const TextStyle(color: Colors.white70),
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

  Widget _buildEmptyState(LocalizationService loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.money_off, size: 60, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            loc.t('portfolioNoAssets', {
              'network': _getNetworkName(_selectedChain, loc),
            }),
            style: const TextStyle(color: Colors.white70),
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
                style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                        color: Colors.white54,
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
                    _getNetworkName(_selectedChain, loc),
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
                  _formatAddress(address),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
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
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                    if (!asset.isNative)
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
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
