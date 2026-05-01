import 'dart:async';
import "package:flutter/material.dart";
import "../services/localization_service.dart";
import '../models/approval.dart';
import '../models/gas_estimation_result.dart';
import '../services/risk_engine.dart';
import '../models/risk_assessment.dart';
import '../services/verdict_service.dart';
import "../services/revoke_service.dart";
import "../services/transaction_queue.dart";
import "../config/chains.dart";
import "../widgets/design/ds_background.dart";
import "../widgets/scan_summary.dart";
import "approval_detail_screen.dart";
import "pro_screen.dart";
import "../services/approval_scan_service.dart";
import "../services/pro/pro_service.dart";
import "../services/security/security_event_service.dart";
import "../config/app_colors.dart";
import "../services/solana/solana_signing_bridge.dart";
import "../services/tron/tron_signing_bridge.dart";

/// Scan Result screen.
///
/// This screen only DISPLAYS pre-scanned data вЂ” it never initiates a new scan.
/// All [ApprovalData] must be passed in via [initialApprovals].
class ScanResultScreen extends StatefulWidget {
  final String address;
  final String? targetTokenAddress;
  final String? targetTokenName;
  final String? targetTokenSymbol;
  final String? highlightSpender;
  final String? highlightToken;
  final String chainType; // 'evm', 'solana', 'tron'

  /// Pre-fetched approval list from the preceding scan screen.
  /// Must not be null вЂ” scan screens must always pass data.
  final List<ApprovalData> initialApprovals;

  const ScanResultScreen({
    super.key,
    required this.address,
    required this.initialApprovals,
    this.targetTokenAddress,
    this.targetTokenName,
    this.targetTokenSymbol,
    this.highlightSpender,
    this.highlightToken,
    this.chainType = 'evm',
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late List<ApprovalData> _approvals;
  bool _isRefreshing = false;
  final Set<String> _revokingKeys = <String>{};
  final Set<String> _selectedKeys = <String>{};
  bool _isPerformingBulkRevoke = false;
  int _revokeTotal = 0;
  int _revokeCurrent = 0;
  StreamSubscription? _queueSub;

  @override
  void initState() {
    super.initState();
    // Load pre-scanned data directly.
    _approvals = widget.initialApprovals.toList();

    // Log manual scan findings (risks found)
    SecurityEventService.instance.logManualScan(
      widget.address,
      false,
      _approvals.length,
    );
  }

  @override
  void dispose() {
    _queueSub?.cancel();
    super.dispose();
  }

  String _key(ApprovalData a) => "${a.token}:${a.spenderAddress}";
  Color _badgeColor(RiskLabel r) {
    switch (r) {
      case RiskLabel.safe:
        return const Color(0xFF10B981); // Green
      case RiskLabel.caution:
        return const Color(0xFFF59E0B); // Orange
      case RiskLabel.danger:
        return const Color(0xFFEF4444); // Red
      case RiskLabel.critical:
        return const Color(0xFF9333EA); // Purple/Critical
    }
  }

  String _badgeLabel(RiskLabel r, LocalizationService loc) {
    switch (r) {
      case RiskLabel.safe:
        return loc.t('riskLabelSafe');
      case RiskLabel.caution:
        return loc.t('riskLabelCaution');
      case RiskLabel.danger:
        return loc.t('riskLabelDanger');
      case RiskLabel.critical:
        return loc.t('riskLabelCritical');
    }
  }

  void _toggleSelection(ApprovalData a) {
    final k = _key(a);
    setState(() {
      if (_selectedKeys.contains(k)) {
        _selectedKeys.remove(k);
      } else {
        _selectedKeys.add(k);
      }
    });
  }

  void _toggleSelectAll(List<ApprovalData> all) {
    setState(() {
      if (_selectedKeys.length == all.length) {
        _selectedKeys.clear();
      } else {
        for (var a in all) {
          _selectedKeys.add(_key(a));
        }
      }
    });
  }

  Future<void> _refreshApprovals() async {
    if (!mounted) return;
    setState(() {
      _isRefreshing = true;
    });

    try {
      final newList = await ApprovalScanService.scan(
        widget.address,
        targetTokenAddress: widget.targetTokenAddress,
        chainType: widget.chainType,
      );

      if (!mounted) return;
      setState(() {
        _approvals = newList;
        // Clean up selected keys that no longer exist
        final validKeys = _approvals.map((a) => _key(a)).toSet();
        _selectedKeys.removeWhere((k) => !validKeys.contains(k));

        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
      });
      debugPrint("Rescan failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Refresh failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _revokeSelected(List<ApprovalData> all) async {
    final selectedItems =
        all.where((a) => _selectedKeys.contains(_key(a))).toList();
    if (selectedItems.isEmpty) return;

    final canBulk = ProService.instance.canUseBulkRevoke();
    if (!canBulk) {
      // PRO Gating for Bulk Revoke
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProScreen()),
        );
      }
      return;
    }

    final loc = LocalizationProvider.of(context);

    // Check if non-EVM items need a compatible wallet
    if (selectedItems.any((a) => a.chainType == 'solana') &&
        !SolanaSigningBridge.canSign()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('revokeConnectSolana'))),
      );
      return;
    }
    if (selectedItems.any((a) => a.chainType == 'tron') &&
        !TronSigningBridge.canSign()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('revokeConnectTron'))),
      );
      return;
    }

    // Estimate total gas
    GasEstimationResult? estimate;
    try {
      final queue = TransactionQueue();
      estimate = await queue.estimateTotalGas(selectedItems);
    } catch (e) {
      debugPrint("Gas estimation failed: $e");
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          loc.t('scanResConfirmBulkRevoke'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.t('scanResRevokeCount', {'count': selectedItems.length}),
              style: const TextStyle(color: AppColors.tertiaryText),
            ),
            const SizedBox(height: 16),
            if (estimate != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_gas_station,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.t('scanResTotalEstimatedFee'),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            estimate.formattedCost,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                loc.t('scanResCouldNotEstimate'),
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              loc.t('scanResCancelBtn'),
              style: const TextStyle(color: AppColors.tertiaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text(loc.t('scanResRevokeAllSelectedBtn')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isPerformingBulkRevoke = true;
      for (var a in selectedItems) {
        _revokingKeys.add(_key(a));
      }
    });

    try {
      final queue = TransactionQueue();
      queue.clear();

      _queueSub = queue.progressStream.listen((p) {
        if (mounted) {
          setState(() {
            _revokeCurrent = p.completed;
            _revokeTotal = p.total;
          });
        }
      });

      queue.addJobs(selectedItems);
      final result = await queue.run();

      _queueSub?.cancel();

      if (!mounted) return;

      if (result.hasSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.t('scanResRevokeTxSubmitted'))),
        );
        _selectedKeys.clear();
        // Rescan only after confirmed success
        await _refreshApprovals();
      } else {
        final errorMsg =
            result.errors.isNotEmpty ? result.errors.first : 'Revoke failed';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isPerformingBulkRevoke = false;
          _revokingKeys.clear();
        });
      }
    }
  }

  Future<void> _revoke(ApprovalData a, List<ApprovalData> all) async {
    // Keep individual revoke logic for internal calls if needed,
    // but the UI will primarily use _revokeSelected.
    final k = _key(a);
    if (_revokingKeys.contains(k)) return;

    final loc = LocalizationProvider.of(context);

    // Only block if compatible signing wallet is NOT connected
    if (a.chainType == 'solana' && !SolanaSigningBridge.canSign()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('revokeConnectSolana'))),
      );
      return;
    }
    if (a.chainType == 'tron' && !TronSigningBridge.canSign()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('revokeConnectTron'))),
      );
      return;
    }

    setState(() => _revokingKeys.add(k));

    GasEstimationResult? estimate;

    // Gas estimation is EVM-only — skip for Solana/Tron
    if (a.chainType == 'evm') {
      try {
        estimate = await RevokeService.estimateGas(a: a);
      } catch (e) {
        debugPrint("Gas estimation failed: $e");
      }
    }

    if (!mounted) {
      _revokingKeys.remove(k);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          loc.t('scanResConfirmBtnCapitalize'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.t('scanResRevokeTokenMsg', {
                'token': a.tokenSymbol ?? 'Token',
              }),
              style: const TextStyle(color: AppColors.tertiaryText),
            ),
            const SizedBox(height: 16),
            if (estimate != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_gas_station,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.t('scanResTotalEstimatedFee'),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            estimate.formattedCost,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                loc.t('scanResCouldNotEstimate'),
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              loc.t('scanResCancelCapitalize'),
              style: const TextStyle(color: AppColors.tertiaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(loc.t('scanResConfirmBtnCapitalize')),
          ),
        ],
      ),
    );

    if (confirm != true) {
      if (mounted) setState(() => _revokingKeys.remove(k));
      return;
    }

    try {
      final queue = TransactionQueue();
      queue.clear();
      queue.addJobs([a]);
      final result = await queue.run();

      if (!mounted) return;

      if (result.hasSuccess) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.t('scanResRevokeSent'))));
        // Rescan only after confirmed success
        await _refreshApprovals();
      } else {
        final errorMsg =
            result.errors.isNotEmpty ? result.errors.first : 'Revoke failed';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _revokingKeys.remove(k));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: DsBackground(
        child: Stack(
          children: [
            Builder(
              builder: (context) {
                final loc = LocalizationProvider.of(context);
                final approvals = _approvals.toList();

                // Sort by explicit priority: Danger (1) > Unlimited (2) > Warning (3) > Safe (4)
                // Priority sorting: 1. Threat hits, 2. Score descending
                approvals.sort((a, b) {
                  final aThreat =
                      a.assessment.reasons.any((r) => r.code == 'threat_db_hit')
                          ? 1
                          : 0;
                  final bThreat =
                      b.assessment.reasons.any((r) => r.code == 'threat_db_hit')
                          ? 1
                          : 0;
                  if (aThreat != bThreat) return bThreat.compareTo(aThreat);

                  // Keep highlighted item at very top if exists
                  if (widget.highlightSpender != null &&
                      widget.highlightToken != null) {
                    final aIsHighlight = a.spenderAddress.toLowerCase() ==
                            widget.highlightSpender?.toLowerCase() &&
                        a.token.toLowerCase() ==
                            widget.highlightToken?.toLowerCase();
                    final bIsHighlight = b.spenderAddress.toLowerCase() ==
                            widget.highlightSpender?.toLowerCase() &&
                        b.token.toLowerCase() ==
                            widget.highlightToken?.toLowerCase();
                    if (aIsHighlight != bIsHighlight) {
                      return aIsHighlight ? -1 : 1;
                    }
                  }

                  return b.assessment.score.compareTo(a.assessment.score);
                });

                // Re-calculate score based on all results
                // Re-calculate score based on all results using upgraded engine
                final walletAssessment = RiskEngine.computeWalletAssessment(
                  approvals,
                );
                int score = 100 - walletAssessment.score;

                final isTargeted = widget.targetTokenName != null;
                final scoreColor = score > 80
                    ? const Color(0xFF10B981)
                    : score > 50
                        ? Colors.orangeAccent
                        : const Color(0xFFEF4444);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60), // Clear TopNav
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 24,
                        bottom: 12,
                        left: 16,
                        right: 16,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              approvals.isNotEmpty
                                  ? widget.chainType == 'solana'
                                      ? 'SOLANA DELEGATE AUDIT'
                                      : widget.chainType == 'tron'
                                          ? 'TRON ALLOWANCE AUDIT'
                                          : '${ChainConfig.getChainName(approvals.first.chainId).toUpperCase()} AUDIT'
                                  : 'SECURITY AUDIT REPORT',
                              style: const TextStyle(
                                color: AppColors.tertiaryText,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isTargeted)
                            Text(
                              '${widget.targetTokenSymbol ?? widget.targetTokenName} APPROVALS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            )
                          else
                            const Text(
                              'WALLET SECURITY OVERVIEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$score',
                                style: TextStyle(
                                  color: scoreColor,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '/100',
                                style: TextStyle(
                                  color: scoreColor.withOpacity(0.5),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'OVERALL SECURITY SCORE',
                            style: TextStyle(
                              color: scoreColor.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Stage 11: Wallet Verdict
                          Builder(
                            builder: (context) {
                              final v = VerdictService.getWalletVerdict(
                                walletAssessment,
                              );
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _badgeColor(v.label).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        _badgeColor(v.label).withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      loc.t(v.titleKey),
                                      style: TextStyle(
                                        color: _badgeColor(v.label),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      loc.t(v.summaryKey),
                                      style: const TextStyle(
                                        color: AppColors.tertiaryText,
                                        fontSize: 11,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      loc.t(v.actionKey),
                                      style: TextStyle(
                                        color: v.urgent
                                            ? Colors.orangeAccent
                                            : AppColors.tertiaryText,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: approvals.isEmpty
                          ? Center(
                              // ... (No changes to empty state)
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.verified_user_rounded,
                                        size: 80,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      loc.t('scanResNoApprovalsFound'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      widget.targetTokenName != null
                                          ? loc.t('scanResNoActiveApprovals')
                                          : loc.t('scanResCleanWalletMsg'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.tertiaryText,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.shield_outlined,
                                            size: 16,
                                            color: Color(0xFF10B981),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            loc.t('scanResSecureStatus'),
                                            style: const TextStyle(
                                              color: Color(0xFF10B981),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                ScanSummary(
                                  approvals: approvals,
                                  selectedCount: _selectedKeys.length,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: _selectedKeys.length ==
                                                approvals.length &&
                                            approvals.isNotEmpty,
                                        onChanged: (_) =>
                                            _toggleSelectAll(approvals),
                                        activeColor: const Color(0xFF00FF9D),
                                        checkColor: Colors.black,
                                        side: const BorderSide(
                                          color: Colors.white24,
                                          width: 2,
                                        ),
                                      ),
                                      Text(
                                        loc.t('scanSelectAll'),
                                        style: const TextStyle(
                                          color: AppColors.tertiaryText,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        loc.t('scanSelectedCount', {
                                          'count': _selectedKeys.length,
                                        }),
                                        style: const TextStyle(
                                          color: AppColors.tertiaryText,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: approvals.length,
                                    itemBuilder: (_, i) {
                                      final a = approvals[i];
                                      final k = _key(a);
                                      final isSelected =
                                          _selectedKeys.contains(k);

                                      final isHighlighted =
                                          widget.highlightSpender != null &&
                                              a.spenderAddress.toLowerCase() ==
                                                  widget.highlightSpender
                                                      ?.toLowerCase() &&
                                              a.token.toLowerCase() ==
                                                  widget.highlightToken
                                                      ?.toLowerCase();

                                      final isUnlimited =
                                          a.allowance == RiskEngine.maxUint256;
                                      final allowanceStr = isUnlimited
                                          ? "Unlimited"
                                          : "${a.allowance.toString()} ${widget.targetTokenSymbol ?? 'tokens'}";

                                      final tokenSymbol = a.tokenSymbol ??
                                          widget.targetTokenSymbol ??
                                          '???';

                                      return Card(
                                        color: const Color(0xFF111827),
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          side: BorderSide(
                                            color: isHighlighted
                                                ? const Color(
                                                    0xFF00E5FF) // Cyan for deep link highlight
                                                : isSelected
                                                    ? const Color(0xFF00FF9D)
                                                    : _badgeColor(
                                                        a.assessment.label,
                                                      ).withOpacity(0.3),
                                            width: (isSelected || isHighlighted)
                                                ? 2
                                                : 1,
                                          ),
                                        ),
                                        // Add glow effect for highlighted item
                                        shadowColor: isHighlighted
                                            ? const Color(0xFF00E5FF)
                                                .withOpacity(0.5)
                                            : Colors.transparent,
                                        elevation: isHighlighted ? 8 : 0,
                                        child: InkWell(
                                          onTap: () => _toggleSelection(a),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Checkbox(
                                                          value: isSelected,
                                                          onChanged: (_) =>
                                                              _toggleSelection(
                                                                  a),
                                                          activeColor:
                                                              const Color(
                                                            0xFF00FF9D,
                                                          ),
                                                          checkColor:
                                                              Colors.black,
                                                          side:
                                                              const BorderSide(
                                                            color:
                                                                Colors.white24,
                                                            width: 2,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          tokenSymbol,
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _badgeColor(
                                                          a.assessment.label,
                                                        ).withOpacity(0.1),
                                                        border: Border.all(
                                                          color: _badgeColor(
                                                            a.assessment.label,
                                                          ),
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          4,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        _badgeLabel(
                                                          a.assessment.label,
                                                          loc,
                                                        ),
                                                        style: TextStyle(
                                                          color: _badgeColor(
                                                            a.assessment.label,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black26,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                      color: Colors.white12,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .account_tree_outlined,
                                                        color: Colors.white38,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Row(
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                a.spender,
                                                                style:
                                                                    const TextStyle(
                                                                  color: AppColors
                                                                      .tertiaryText,
                                                                  fontSize: 13,
                                                                  fontFamily:
                                                                      'monospace',
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            if (a.reputation !=
                                                                SpenderReputation
                                                                    .unknown) ...[
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 1,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: a.reputation ==
                                                                          SpenderReputation
                                                                              .trusted
                                                                      ? const Color(
                                                                          0xFF10B981,
                                                                        )
                                                                          .withOpacity(
                                                                          0.1,
                                                                        )
                                                                      : Colors
                                                                          .red
                                                                          .withOpacity(
                                                                          0.1,
                                                                        ),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                    4,
                                                                  ),
                                                                  border: Border
                                                                      .all(
                                                                    color: a.reputation ==
                                                                            SpenderReputation
                                                                                .trusted
                                                                        ? const Color(
                                                                            0xFF10B981,
                                                                          )
                                                                        : Colors
                                                                            .red,
                                                                    width: 0.5,
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  a.reputation ==
                                                                          SpenderReputation
                                                                              .trusted
                                                                      ? loc.t(
                                                                          'scanResTrusted',
                                                                        )
                                                                      : loc.t(
                                                                          'scanResSuspicious',
                                                                        ),
                                                                  style:
                                                                      TextStyle(
                                                                    color: a.reputation ==
                                                                            SpenderReputation
                                                                                .trusted
                                                                        ? const Color(
                                                                            0xFF10B981,
                                                                          )
                                                                        : Colors
                                                                            .red,
                                                                    fontSize: 8,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      loc.t(
                                                        'scanResAllowanceTitle',
                                                      ),
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .tertiaryText,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                    Text(
                                                      isUnlimited
                                                          ? '∞'
                                                          : allowanceStr,
                                                      style: TextStyle(
                                                        color: isUnlimited
                                                            ? Colors.redAccent
                                                            : Colors.white,
                                                        fontSize: isUnlimited
                                                            ? 20
                                                            : 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                // Risk Detail Section
                                                Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(
                                                      0.03,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.05),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            loc.t(
                                                              'riskAssessmentHeader',
                                                            ),
                                                            style: TextStyle(
                                                              color:
                                                                  _badgeColor(
                                                                a.assessment
                                                                    .label,
                                                              ).withOpacity(
                                                                      0.7),
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                              letterSpacing:
                                                                  1.2,
                                                            ),
                                                          ),
                                                          Text(
                                                            "${a.assessment.score}/100",
                                                            style: TextStyle(
                                                              color:
                                                                  _badgeColor(
                                                                a.assessment
                                                                    .label,
                                                              ),
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (a.assessment.reasons
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                            height: 8),
                                                        ...a.assessment.reasons
                                                            .take(3)
                                                            .map(
                                                              (r) => Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                  bottom: 4,
                                                                ),
                                                                child: Row(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Icon(
                                                                      r.weight > 0
                                                                          ? Icons
                                                                              .warning_amber_rounded
                                                                          : Icons
                                                                              .verified_user_outlined,
                                                                      size: 12,
                                                                      color: r.weight > 0
                                                                          ? Colors
                                                                              .orangeAccent
                                                                          : Colors
                                                                              .tealAccent,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Expanded(
                                                                      child:
                                                                          Text(
                                                                        loc.t(
                                                                          r.messageKey,
                                                                        ),
                                                                        style:
                                                                            const TextStyle(
                                                                          color:
                                                                              AppColors.tertiaryText,
                                                                          fontSize:
                                                                              11,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                      ],
                                                      // Stage 11: Verdict
                                                      Builder(
                                                        builder: (context) {
                                                          final verdict =
                                                              VerdictService
                                                                  .getApprovalVerdict(
                                                            a.assessment,
                                                          );
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                              top: 10,
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical: 2,
                                                                  ),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color:
                                                                        _badgeColor(
                                                                      verdict
                                                                          .label,
                                                                    ).withOpacity(
                                                                      0.1,
                                                                    ),
                                                                    borderRadius:
                                                                        BorderRadius
                                                                            .circular(
                                                                      4,
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    loc.t(
                                                                      verdict
                                                                          .titleKey,
                                                                    ),
                                                                    style:
                                                                        TextStyle(
                                                                      color:
                                                                          _badgeColor(
                                                                        verdict
                                                                            .label,
                                                                      ),
                                                                      fontSize:
                                                                          8,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w900,
                                                                      letterSpacing:
                                                                          0.5,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Text(
                                                                  loc.t(
                                                                    verdict
                                                                        .summaryKey,
                                                                  ),
                                                                  style:
                                                                      const TextStyle(
                                                                    color: AppColors
                                                                        .secondaryText,
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 2,
                                                                ),
                                                                Text(
                                                                  loc.t(
                                                                    verdict
                                                                        .actionKey,
                                                                  ),
                                                                  style:
                                                                      TextStyle(
                                                                    color: verdict.urgent
                                                                        ? Colors
                                                                            .orangeAccent
                                                                        : AppColors
                                                                            .tertiaryText,
                                                                    fontSize:
                                                                        10,
                                                                    fontStyle:
                                                                        FontStyle
                                                                            .italic,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: TextButton.icon(
                                                    onPressed: () =>
                                                        Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ApprovalDetailScreen(
                                                          approval: a,
                                                          walletAddress:
                                                              widget.address,
                                                        ),
                                                      ),
                                                    ),
                                                    icon: const Icon(
                                                      Icons.shield_outlined,
                                                      size: 14,
                                                      color: Color(0xFF00FF9D),
                                                    ),
                                                    label: Text(
                                                      loc.t('scanResDetails'),
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF00FF9D),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      minimumSize: Size.zero,
                                                      tapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (_selectedKeys.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 60,
                                      child: ElevatedButton(
                                        onPressed: _isPerformingBulkRevoke
                                            ? null
                                            : () => _revokeSelected(approvals),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFEF4444),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          elevation: 8,
                                        ),
                                        child: _isPerformingBulkRevoke
                                            ? Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    loc.t('scanResSubmitting', {
                                                      'current': _revokeCurrent,
                                                      'total': _revokeTotal,
                                                    }),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 40,
                                                    ),
                                                    child:
                                                        LinearProgressIndicator(
                                                      value: _revokeTotal > 0
                                                          ? _revokeCurrent /
                                                              _revokeTotal
                                                          : 0,
                                                      color: Colors.white,
                                                      backgroundColor:
                                                          Colors.white24,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                loc.t('scanResRevokeSelected', {
                                                  'count': _selectedKeys.length,
                                                }),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
            if (_isRefreshing)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00FF9D),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
