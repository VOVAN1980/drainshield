import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import "../services/wc_service.dart";
import "../widgets/design/ds_animated_button.dart";
import "../widgets/design/ds_fade_slide.dart";
import "../widgets/design/ds_background.dart";
import "../widgets/design/ds_slide_action.dart";
import "pro_screen.dart";
import "scan_screen.dart";
import "panic_scan_screen.dart";
import "portfolio_screen.dart";
import "settings_screen.dart";
import "../config/chains.dart";
import "../services/approval_scan_service.dart";
import "../widgets/mascot_image.dart";
import "../widgets/design/ds_gauge.dart";
import "../services/wallet/wallet_registry_service.dart";
import '../models/linked_wallet.dart';
import '../services/pro/pro_service.dart';
import '../services/security/system_health_service.dart';
import '../config/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  void _openScan(String address) {
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService.instance.t('dashboardConnectFirst'),
          ),
        ),
      );
      return;
    }
    // Resolve chainType from selected wallet card
    final registry = WalletRegistryService.instance;
    final selectedWallet = registry.wallets
        .where((w) => w.address.toLowerCase() == address.toLowerCase())
        .firstOrNull;
    final chainType = selectedWallet?.chainType ?? 'evm';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanScreen(
          address: address,
          chainType: chainType,
        ),
      ),
    );
  }

  void _panic() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocalizationService.instance.t('dashboardPanicNext')),
      ),
    );
  }

  late AnimationController _entranceCtrl;
  late AnimationController _shieldPulseCtrl;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;
  late Animation<double> _shieldScale;
  late Animation<double> _shieldGlow;
  int? _riskScore; // null => not scanned
  int _currentChainId = 0;
  String _currentAddress = '';
  bool _currentConnected = false;
  bool _isBooting = true;
  late AnimationController _bootCtrl;

  @override
  void initState() {
    super.initState();
    // Entrance animation — one-shot, triggers after first frame.
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
      value: 1.0,
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));

    // Shield pulse — slow looping 3 s, reverse so it goes 1.0 → 1.03 → 1.0.
    _shieldPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _shieldScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _shieldPulseCtrl, curve: Curves.easeInOut),
    );
    _shieldGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shieldPulseCtrl, curve: Curves.easeInOut),
    );

    _bootCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Listeners
      WcService().addListener(_onWalletUpdate);
      WalletRegistryService.instance.addListener(_onRegistryUpdate);
      SystemHealthService.instance.addListener(_onHealthUpdate);

      // Instant entry — services are already ready from BootScreen
      if (mounted) setState(() => _isBooting = false);
      _entranceCtrl.forward();
      _bootCtrl.forward();

      await WcService().init(context);

      if (mounted) {
        final wc = WcService();
        setState(() {
          _currentChainId = wc.currentChainId;
          _currentAddress = wc.address;
          _currentConnected = wc.isConnected;
        });
      }
    });
  }

  void _onWalletUpdate() {
    if (!mounted) return;
    final wc = WcService();
    final bool chainChanged = _currentChainId != wc.currentChainId;
    final bool addressChanged = _currentAddress != wc.address;
    final bool connectedChanged = _currentConnected != wc.isConnected;

    if (!chainChanged && !addressChanged && !connectedChanged) return;

    // Reset score if chain changed
    if (chainChanged) {
      _riskScore = null;
      _currentChainId = wc.currentChainId;
    }
    _currentAddress = wc.address;
    _currentConnected = wc.isConnected;

    setState(() {});
  }

  void _onRegistryUpdate() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _onHealthUpdate() {
    if (mounted) setState(() {});
  }

  Widget _buildSystemStatus(LocalizationService loc) {
    final health = SystemHealthService.instance.state;
    String labelKey;
    Color color;
    IconData icon;

    switch (health) {
      case SystemHealthState.protected:
        labelKey = 'dashboardStatusProtected';
        color = const Color(0xFF00FF9D);
        icon = Icons.verified_user_rounded;
        break;
      case SystemHealthState.networkDegraded:
        labelKey = 'dashboardStatusOffline';
        color = Colors.redAccent;
        icon = Icons.wifi_off_rounded;
        break;
      case SystemHealthState.threatIntelStale:
        labelKey = 'dashboardStatusStale';
        color = Colors.orangeAccent;
        icon = Icons.update_disabled_rounded;
        break;
      case SystemHealthState.subscriptionInactive:
        labelKey = 'dashboardStatusInactive';
        color = Colors.amberAccent;
        icon = Icons.star_outline_rounded;
        break;
      case SystemHealthState.monitoringPaused:
        labelKey = 'dashboardStatusPaused';
        color = AppColors.tertiaryText;
        icon = Icons.pause_circle_outline_rounded;
        break;
      default:
        labelKey = 'dashboardStatusInitializing';
        color = AppColors.tertiaryText;
        icon = Icons.hourglass_empty_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            loc.t(labelKey),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoLinkPrompt(LocalizationService loc) {
    final registry = WalletRegistryService.instance;
    final pendingAddr = registry.pendingAutoLinkAddress;

    if (pendingAddr == null) return const SizedBox.shrink();

    const activeColor = Color(0xFF00FF9D);
    final isPro = ProService.instance.isProActive();
    final canAdd = registry.canAddMoreWallets();

    return DsFadeSlide(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: activeColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: activeColor.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: activeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canAdd
                            ? loc.t('dashboardLinkWalletPrompt')
                            : loc.t('dashboardLinkWalletLimit'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (canAdd)
                        Text(
                          _short(pendingAddr),
                          style: const TextStyle(
                            color: AppColors.tertiaryText,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => registry.dismissPendingLink(),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.tertiaryText,
                    size: 20,
                  ),
                ),
              ],
            ),
            if (canAdd) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: _PressableOutlineButton(
                  accentColor: activeColor,
                  label: loc.t('dashboardLinkWalletAction'),
                  onPressed: () async {
                    final success = await registry.addWallet(LinkedWallet(
                      address: pendingAddr,
                      label: 'Wallet ${registry.wallets.length + 1}',
                      addedAt: DateTime.now(),
                      isPrimary: false,
                      isActive: isPro,
                    ));
                    if (success) {
                      registry.dismissPendingLink();
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WcService().removeListener(_onWalletUpdate);
    WalletRegistryService.instance.removeListener(_onRegistryUpdate);
    SystemHealthService.instance.removeListener(_onHealthUpdate);
    _entranceCtrl.dispose();
    _shieldPulseCtrl.dispose();
    _bootCtrl.dispose();
    super.dispose();
  }

  String _short(String address) {
    if (address.isEmpty || address.length < 10) return address;
    return "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
  }

  Future<void> _onPanicTap() async {
    final registry = WalletRegistryService.instance;

    // Collect all active wallets for multi-chain Panic scan
    final activeWallets = registry.wallets.where((w) => w.isActive).toList();

    if (activeWallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.redAccent,
          content: Text(
              LocalizationService.instance.t('dashboardPanicConnectFirst')),
        ),
      );
      return;
    }

    final activeAddress = registry.selectedAddress;

    // Navigate directly to the full-screen Panic Mode flow
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PanicScanScreen(
          address: activeAddress,
          wallets: activeWallets,
        ),
      ),
    );

    // Update score after panic scan completes
    if (mounted) {
      setState(() {
        _riskScore = ApprovalScanService.lastRiskScore;
      });
    }
  }

  /// Builds a shield-pulsing wrapper around [child].
  Widget _withShieldPulse(Widget child, Color accentColor) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _shieldPulseCtrl,
        builder: (_, inner) => Transform.scale(
          scale: _shieldScale.value,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 70, minHeight: 70),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.25 * _shieldGlow.value),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: inner,
            ),
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);
    final wc = WcService();
    final registry = WalletRegistryService.instance;

    // Unified Display Address: registry first, then active session
    // Non-EVM wallets may not have a WalletConnect session
    final String displayAddress = registry.selectedAddress.isNotEmpty
        ? registry.selectedAddress
        : (wc.isConnected ? wc.address : '');

    final bool isSessionMatch = wc.isConnected &&
        wc.address.toLowerCase().trim() == displayAddress.toLowerCase().trim();

    final int effectiveChainId = (wc.isConnected && wc.currentChainId != 0)
        ? wc.currentChainId
        : (registry.selectedChainId != 0 ? registry.selectedChainId : 56);

    final bool hasActiveWallets = registry.wallets.any((w) => w.isActive);

    // Resolve selected wallet's chainType for badge display
    final selectedWallet = registry.wallets
        .where((w) => w.address.toLowerCase() == displayAddress.toLowerCase())
        .firstOrNull;
    final String selectedChainType = selectedWallet?.chainType ?? 'evm';

    final bool isReadyToScan = displayAddress.isNotEmpty || hasActiveWallets;

    // Green for active session, Blue for read-only / mismatch
    final Color accentColor =
        isSessionMatch ? const Color(0xFF00FF9D) : const Color(0xFF00B8FF);

    final bool hasScan = _riskScore != null;

    return Scaffold(
      backgroundColor: const Color(0xFF030509),
      body: DsBackground(
        accentColor: accentColor,
        child: Stack(
          children: [
            // ── Main layout ─────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.t('dashboardTitle'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: AppColors.tertiaryText,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProScreen(),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                loc.t('dashboardPro'),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAutoLinkPrompt(loc),
                  const SizedBox(height: 16),
                  // ── Status card — entrance fade+slide ──
                  FadeTransition(
                    opacity: _entranceFade,
                    child: SlideTransition(
                      position: _entranceSlide,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isReadyToScan) ...[
                                  _withShieldPulse(
                                    AnimatedBuilder(
                                      animation: _bootCtrl,
                                      builder: (context, child) => DsGauge(
                                        value: _bootCtrl.value,
                                        accentColor: accentColor,
                                      ),
                                    ),
                                    accentColor,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _isBooting
                                        ? loc.t('dashboardLoadingTitle')
                                        : loc.t('dashboardSystemReadyTitle'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isBooting
                                        ? loc.t('dashboardLoadingSub')
                                        : loc.t('dashboardSystemReadySub'),
                                    style: const TextStyle(
                                      color: AppColors.tertiaryText,
                                      fontSize: 13,
                                    ),
                                  ),
                                ] else ...[
                                  if (!hasScan) ...[
                                    _withShieldPulse(
                                      Icon(
                                        Icons.verified_user_outlined,
                                        size: 70,
                                        color: accentColor.withOpacity(0.9),
                                      ),
                                      accentColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      displayAddress.isEmpty
                                          ? loc.t('dashboardSystemReadyTitle')
                                          : loc.t('dashboardReadyToScan'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildChainBadge(loc, effectiveChainId,
                                        selectedChainType, accentColor),
                                    const SizedBox(height: 12),
                                    Text(
                                      loc.t('dashboardNoRiskScore'),
                                      style: const TextStyle(
                                        color: AppColors.tertiaryText,
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildAddressInfo(loc, displayAddress, wc,
                                        isSessionMatch),
                                  ] else ...[
                                    _buildRiskScoreGauge(accentColor),
                                    const SizedBox(height: 8),
                                    Text(
                                      loc.t('dashboardScanResult'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    _buildChainBadge(loc, effectiveChainId,
                                        selectedChainType, accentColor),
                                    const SizedBox(height: 12),
                                    _buildAddressInfo(loc, displayAddress, wc,
                                        isSessionMatch),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ── Lion mascot below status card ──
                  Center(
                    child: MascotImage(
                      mascotState:
                          (hasScan && ApprovalScanService.hasRiskyApprovals)
                              ? MascotState.warning
                              : MascotState.safe,
                      width: 160,
                      height: 160,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── MAKE SAFE / CONNECT WALLET — animated button with sheen ──
                  FadeTransition(
                    opacity: _entranceFade,
                    child: SlideTransition(
                      position: _entranceSlide,
                      child: Opacity(
                        opacity: _isBooting ? 0.5 : 1.0,
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: DsAnimatedButton(
                            onPressed: _isBooting
                                ? null
                                : () async {
                                    // Resolve chainType from selected wallet card
                                    final selWallet = registry.wallets
                                        .where((w) =>
                                            w.address.toLowerCase() ==
                                            displayAddress.toLowerCase())
                                        .firstOrNull;
                                    final chainType =
                                        selWallet?.chainType ?? 'evm';

                                    // If no wallet in registry and not connected,
                                    // prompt WalletConnect
                                    if (selWallet == null && !wc.isConnected) {
                                      wc.connect(context);
                                      return;
                                    }

                                    // Use registry address if available,
                                    // fall back to WC address
                                    final scanAddr = displayAddress.isNotEmpty
                                        ? displayAddress
                                        : wc.address;

                                    if (scanAddr.isEmpty) {
                                      wc.connect(context);
                                      return;
                                    }

                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ScanScreen(
                                          address: scanAddr,
                                          chainId: effectiveChainId,
                                          chainType: chainType,
                                        ),
                                      ),
                                    );
                                    if (mounted) {
                                      setState(() {
                                        _riskScore =
                                            ApprovalScanService.lastRiskScore;
                                      });
                                    }
                                  },
                            gradient: LinearGradient(
                              colors: isSessionMatch
                                  ? [
                                      const Color(0xFF00FF9D),
                                      const Color(0xFF00B8FF),
                                    ]
                                  : [
                                      const Color(0xFF00B8FF),
                                      const Color(0xFF0055FF),
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            child: Center(
                              child: Text(
                                !wc.isConnected &&
                                        registry.selectedAddress.isEmpty
                                    ? loc.t('dashboardConnectWalletBtn')
                                    : loc.t('dashboardMakeSafeBtn'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Colors.black,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // ── PORTFOLIO — fade+slide entrance + press scale ──
                  DsFadeSlide(
                    delay: const Duration(milliseconds: 60),
                    child: Opacity(
                      opacity: _isBooting ? 0.5 : 1.0,
                      child: _PressableOutlineButton(
                        accentColor: accentColor,
                        onPressed: _isBooting
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PortfolioScreen(),
                                  ),
                                );
                              },
                        label: loc.t('dashboardPortfolioBtn'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── PANIC MODE — fade+slide entrance + press scale ──
                  DsFadeSlide(
                    delay: const Duration(milliseconds: 90),
                    child: Opacity(
                      opacity: _isBooting ? 0.5 : 1.0,
                      child: Column(
                        children: [
                          DsSlideAction(
                            onAction: (!hasActiveWallets || _isBooting)
                                ? null
                                : (ProService.instance.isProActive()
                                    ? _onPanicTap
                                    : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const ProScreen(),
                                          ),
                                        )),
                            label: loc.t('dashboardPanicModeBtn'),
                          ),
                          if (!ProService.instance.isProActive() && !_isBooting)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                loc.t('settingsSecurityProMonitoringHint'),
                                style: TextStyle(
                                  color: Colors.orange.withOpacity(0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChainBadge(
    LocalizationService loc,
    int chainId,
    String chainType,
    Color accentColor,
  ) {
    // Use chainType directly — avoids chainId=0 fallback to BNB for non-EVM
    final String label;
    if (chainType == 'solana') {
      label = 'SOLANA';
    } else if (chainType == 'tron') {
      label = 'TRON';
    } else {
      label = loc
          .t('chain${ChainConfig.getChainName(chainId).replaceAll(' ', '')}')
          .toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accentColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildRiskScoreGauge(Color accentColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            value: (_riskScore!.clamp(0, 100)) / 100,
            strokeWidth: 8,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          children: [
            Text(
              "${_riskScore!}%",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: accentColor,
                shadows: [
                  Shadow(
                    color: accentColor.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            Text(
              LocalizationService.instance.t('dashboardRiskScoreLabel'),
              style: const TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressInfo(
    LocalizationService loc,
    String address,
    WcService wc,
    bool isSessionMatch,
  ) {
    if (address.isEmpty) return const SizedBox.shrink();

    final registry = WalletRegistryService.instance;
    final wallet = registry.wallets.firstWhere(
      (w) => w.address.toLowerCase() == address.toLowerCase(),
      orElse: () => LinkedWallet(
          address: address, label: 'Wallet', addedAt: DateTime.now()),
    );

    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: wc.isConnected
              ? () {
                  wc.disconnect();
                }
              : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.transparent,
            child: Column(
              children: [
                Text(
                  wallet.label,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  _short(address),
                  style: const TextStyle(
                      color: AppColors.tertiaryText,
                      fontSize: 13,
                      fontFamily: 'monospace'),
                ),
                if (isSessionMatch)
                  Text(
                    loc.t('dashboardWalletTapDisconnectHint'),
                    style: TextStyle(
                        color: const Color(0xFF00FF9D).withOpacity(0.5),
                        fontSize: 9),
                  ),
              ],
            ),
          ),
        ),
        if (wc.isConnected && !isSessionMatch)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Text(
              loc.t('dashboardStatusReadOnly'),
              style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 8,
                  fontWeight: FontWeight.bold),
            ),
          )
        else if (!wc.isConnected)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Text(
              loc.t('dashboardStatusBrowser'),
              style: const TextStyle(
                  color: Colors.blue, fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}

// ── Reusable pressable outline button (0.99 scale on press) ──────────────────
class _PressableOutlineButton extends StatefulWidget {
  final Color accentColor;
  final VoidCallback? onPressed;
  final String label;

  const _PressableOutlineButton({
    required this.accentColor,
    required this.onPressed,
    required this.label,
  });

  @override
  State<_PressableOutlineButton> createState() =>
      _PressableOutlineButtonState();
}

class _PressableOutlineButtonState extends State<_PressableOutlineButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = Tween<double>(
      begin: 0.99,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) => _ctrl.reverse();
  void _up(TapUpDetails _) {
    _ctrl.forward();
    widget.onPressed?.call();
  }

  void _cancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _down : null,
      onTapUp: widget.onPressed != null ? _up : null,
      onTapCancel: widget.onPressed != null ? _cancel : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: widget.onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: widget.accentColor.withOpacity(0.55),
                width: 2,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.accentColor,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
