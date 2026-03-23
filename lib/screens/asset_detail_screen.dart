import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/localization_service.dart';
import '../services/portfolio_service.dart';
import '../services/wc_service.dart';
import '../models/wallet_asset.dart';
import '../models/wallet_transaction.dart';
import '../models/approval.dart';
import '../config/chains.dart';
import '../config/app_colors.dart';
import '../widgets/design/ds_background.dart';
import '../widgets/design/ds_fade_slide.dart';
import 'package:url_launcher/url_launcher.dart';
import 'scan_screen.dart';

class AssetDetailScreen extends StatefulWidget {
  final WalletAsset asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  final PortfolioService _portfolioService = PortfolioService();
  bool _isLoading = true;
  List<WalletTransaction> _history = [];
  List<ApprovalData> _approvals = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final wc = WcService();
    if (!wc.isConnected) {
      setState(() {
        _isLoading = false;
        _error = "Wallet not connected";
      });
      return;
    }

    final chainSlug = ChainConfig.getMoralisChainSlug(wc.currentChainId) ?? 'eth';

    try {
      if (widget.asset.isNative) {
        final symbol = ChainConfig.getNativeSymbol(wc.currentChainId);
        _history = await _portfolioService.getRecentNativeTransactions(
          wc.address,
          chainSlug,
          nativeSymbol: symbol,
        );
      } else {
        _history = await _portfolioService.getRecentTokenTransfersFiltered(
          wc.address,
          widget.asset.address,
          chainSlug,
        );
        _approvals = await _portfolioService.getTokenApprovalsForAsset(
          wc.address,
          widget.asset.address,
          chainSlug,
        );
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _copyAddress(String address, LocalizationService loc) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.t('assetCopySuccess')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openInExplorer() {
    final wc = WcService();
    // Use the chainId stored within the asset for the most reliable link
    final url = ChainConfig.getExplorerUrl(
      widget.asset.chainId,
      widget.asset.isNative ? wc.address : widget.asset.address,
    );

    if (url != null) {
      try {
        launchUrl(
          Uri.parse(url),
          mode: LaunchMode.platformDefault,
        ).then((success) {
          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Could not launch explorer. No browser found?"),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Explorer not supported for chain ID: ${widget.asset.chainId}",
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
  }

  void _runScan() {
    final wc = WcService();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanScreen(
          address: wc.address,
          targetTokenAddress: widget.asset.isNative ? null : widget.asset.address,
          targetTokenName: widget.asset.name,
          targetTokenSymbol: widget.asset.symbol,
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
            _buildAppBar(loc),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(loc)
                  : _error != null
                      ? _buildErrorState(loc)
                      : _buildContent(loc, wc),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(LocalizationService loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 32, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            loc.t('assetDetailTitle'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF00FF9D)),
              onPressed: _loadData,
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(LocalizationService loc) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF00FF9D)),
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
          ElevatedButton(
            onPressed: _loadData,
            child: Text(loc.t('portfolioRetry')),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LocalizationService loc, WcService wc) {
    final asset = widget.asset;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(asset, loc),
        const SizedBox(height: 24),
        _buildActionButtons(loc, wc),
        const SizedBox(height: 32),
        if (!asset.isNative && _approvals.isNotEmpty) ...[
          _buildSectionTitle(loc.t('assetApprovalsTitle')),
          const SizedBox(height: 12),
          ..._approvals.map((a) => _buildApprovalItem(a, loc)),
          const SizedBox(height: 32),
        ],
        _buildSectionTitle(loc.t('assetHistoryTitle')),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          _buildEmptyState(loc.t('assetNoHistory'))
        else
          ..._history.map((tx) => _buildHistoryItem(tx, loc)),
      ],
    );
  }

  Widget _buildHeader(WalletAsset asset, LocalizationService loc) {
    return DsFadeSlide(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white10,
            backgroundImage: asset.logoUrl != null ? NetworkImage(asset.logoUrl!) : null,
            child: asset.logoUrl == null
                ? Text(
                    asset.symbol.isNotEmpty ? asset.symbol[0] : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            asset.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            asset.isNative ? loc.t('assetTypeNative') : loc.t('assetTypeERC20'),
            style: const TextStyle(
              color: AppColors.tertiaryText,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${asset.balance.toStringAsFixed(asset.balance < 0.0001 ? 8 : 4)} ${asset.symbol}',
            style: const TextStyle(
              color: Color(0xFF00FF9D),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(asset.valueUsd),
            style: const TextStyle(
              color: AppColors.tertiaryText,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LocalizationService loc, WcService wc) {
    final asset = widget.asset;
    
    // Debug logging for easier troubleshooting on device
    debugPrint("DEBUG: asset.isNative=${asset.isNative}, symbol='${asset.symbol}', name='${asset.name}', chainId=${asset.chainId}");

    // Combined exclusion list for the Scan button
    final bool isMajorToken = ['USDT', 'USDC', 'DAI', 'BUSD', 'BNB', 'ETH', 'MATIC', 'POL', 'WBTC', 'WETH', 'WBNB']
        .contains(asset.symbol.toUpperCase().trim());
    final bool isSpecialAsset = asset.name.toUpperCase().contains('BNB') || asset.name.toUpperCase().contains('NATIVE');
    
    final bool shouldHideScan = asset.isNative || isMajorToken || isSpecialAsset;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          Icons.copy,
          loc.t('assetActionCopy'),
          () => _copyAddress(asset.isNative ? wc.address : asset.address, loc),
        ),
        _buildActionButton(
          Icons.explore_outlined,
          loc.t('assetActionExplorer'),
          _openInExplorer,
        ),
        if (!shouldHideScan)
          _buildActionButton(
            Icons.security,
            loc.t('assetActionScan'),
            _runScan,
            isPrimary: true,
          ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {bool isPrimary = false}) {
    final color = isPrimary ? const Color(0xFF00FF9D) : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.tertiaryText,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          msg,
          style: const TextStyle(color: Colors.white24, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(WalletTransaction tx, LocalizationService loc) {
    final isIncoming = tx.isIncoming;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isIncoming ? Colors.green : Colors.orange).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncoming ? Icons.south_west : Icons.north_east,
              color: isIncoming ? Colors.green : Colors.orange,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIncoming ? 'Received' : 'Sent',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('dd MMM, HH:mm').format(tx.timestamp),
                  style: const TextStyle(color: AppColors.tertiaryText, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncoming ? '+' : '-'}${tx.value.toStringAsFixed(tx.value < 0.001 ? 6 : 4)} ${tx.symbol}',
                style: TextStyle(
                  color: isIncoming ? Colors.green : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Icon(Icons.chevron_right, size: 12, color: Colors.white10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalItem(ApprovalData a, LocalizationService loc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.security_update_warning, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.spender,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${loc.t('scanResAllowanceTitle')}: ${a.allowance > BigInt.from(1e30) ? 'Unlimited' : a.allowance.toString()}',
                  style: const TextStyle(color: AppColors.tertiaryText, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _runScan(), // Navigate to scan for revocation
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(60, 30),
            ),
            child: Text(loc.t('scanResRevokeBtn'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
