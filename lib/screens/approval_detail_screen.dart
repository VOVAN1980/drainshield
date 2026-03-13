import 'dart:async';
import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/approval.dart';
import '../models/gas_estimation_result.dart';
import '../config/chains.dart';
import '../services/risk_engine.dart';
import '../services/risk_explanation_service.dart';
import '../services/revoke_service.dart';
import '../widgets/design/ds_background.dart';
import '../widgets/top_nav.dart';

/// Full-screen risk inspection card for a single [ApprovalData].
///
/// Opens from any approval tap in Make Safe results or Panic Mode findings.
/// Shows token/spender details, risk explanation, recommendation, and revoke.
class ApprovalDetailScreen extends StatefulWidget {
  final ApprovalData approval;

  /// The wallet address of the connected user, required for revoke.
  final String walletAddress;

  /// Pre-fetched gas estimation (if any).

  const ApprovalDetailScreen({
    super.key,
    required this.approval,
    required this.walletAddress,
  });

  @override
  State<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  GasEstimationResult? _gasEstimate;
  bool _loadingGas = true;
  bool _revoking = false;
  bool _revoked = false;

  late final List<String> _reasons;
  late final String _recommendation;
  late final Color _accentColor;
  late String _riskLabelKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reasons = RiskExplanationService.explain(widget.approval);
    _recommendation = RiskExplanationService.recommendation(widget.approval);

    switch (widget.approval.riskLevel) {
      case RiskLevel.danger:
        _accentColor = const Color(0xFFEF4444);
        _riskLabelKey = 'scanRiskHigh';
        break;
      case RiskLevel.warning:
        _accentColor = const Color(0xFFF59E0B);
        _riskLabelKey = 'scanRiskMedium';
        break;
      case RiskLevel.safe:
        _accentColor = const Color(0xFF10B981);
        _riskLabelKey = 'scanRiskLow';
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadGasEstimate();
  }

  Future<void> _loadGasEstimate() async {
    try {
      final estimate = await RevokeService.estimateGas(a: widget.approval);
      if (mounted) setState(() => _gasEstimate = estimate);
    } catch (_) {
      // Gas estimation failed (wallet may not be connected). That's fine.
    } finally {
      if (mounted) setState(() => _loadingGas = false);
    }
  }

  Future<void> _revoke() async {
    setState(() => _revoking = true);
    final loc = LocalizationProvider.of(context);
    try {
      await RevokeService.revokeApproval(a: widget.approval);
      widget.approval.allowance = BigInt.zero;
      if (mounted) {
        setState(() {
          _revoking = false;
          _revoked = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('approvalRevokeSent')),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _revoking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);
    final a = widget.approval;
    final isUnlimited = a.allowance == RiskEngine.maxUint256;
    final allowanceStr = isUnlimited
        ? loc.t('scanAllowanceUnlimited')
        : a.allowance == BigInt.zero
            ? loc.t('approvalRevoked')
            : a.allowance.toString();

    final tokenName = a.tokenName ?? 'Unknown Token';
    final tokenSymbol = a.tokenSymbol ?? '???';
    final chainLabel = ChainConfig.getChainName(a.chainId).toUpperCase();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const TopNav(),
      body: DsBackground(
        accentColor: _accentColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── SUMMARY CARD ────────────────────────────────────────────
                _SectionCard(
                  borderColor: _accentColor,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tokenSymbol,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tokenName,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _accentColor),
                            ),
                            child: Text(
                              loc.t(_riskLabelKey),
                              style: TextStyle(
                                color: _accentColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'CHAIN',
                        value: chainLabel,
                        valueColor: Colors.white70,
                      ),
                      if (a.isVerified) ...[
                        const SizedBox(height: 4),
                        _InfoRow(
                          label: 'STATUS',
                          value: loc.t('approvalDetailVerified'),
                          valueColor: const Color(0xFF10B981),
                        ),
                      ],
                      const SizedBox(height: 4),
                      _InfoRow(
                        label: 'REPUTATION',
                        value: a.reputation == SpenderReputation.trusted
                            ? loc.t('approvalRepTrusted')
                            : a.reputation == SpenderReputation.suspicious
                                ? loc.t('approvalRepSuspicious')
                                : loc.t('approvalRepUnknown'),
                        valueColor: a.reputation == SpenderReputation.trusted
                            ? const Color(0xFF10B981)
                            : a.reputation == SpenderReputation.suspicious
                                ? Colors.redAccent
                                : Colors.white38,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── APPROVAL DETAILS ─────────────────────────────────────────
                _SectionCard(
                  title: loc.t('approvalDetailTitle'),
                  titleColor: Colors.white70,
                  child: Column(
                    children: [
                      _InfoRow(label: loc.t('approvalToken'), value: tokenName),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: loc.t('approvalSymbol'),
                        value: tokenSymbol,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: loc.t('approvalAllowance'),
                        value: allowanceStr,
                        valueColor: isUnlimited
                            ? const Color(0xFFEF4444)
                            : Colors.white70,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: loc.t('approvalSpender'),
                        value: a.spender != a.spenderAddress
                            ? a.spender
                            : loc.t('approvalUnknownSpender'),
                        valueColor: Colors.white70,
                      ),
                      const SizedBox(height: 4),
                      // Copyable spender address
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: a.spenderAddress),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.t('approvalAddressCopied')),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  a.spenderAddress,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.copy_outlined,
                                size: 14,
                                color: Colors.white38,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Explorer button
                      Builder(
                        builder: (ctx) {
                          final url = ChainConfig.getExplorerUrl(
                            a.chainId,
                            a.spenderAddress,
                          );
                          if (url == null) {
                            return Text(
                              loc.t('approvalExplorerUnavailable'),
                              style: const TextStyle(
                                color: Colors.white30,
                                fontSize: 11,
                              ),
                            );
                          }
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          loc.t('approvalExplorerError'),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(
                                Icons.open_in_new,
                                size: 14,
                                color: Color(0xFF00B8FF),
                              ),
                              label: Text(
                                loc.t('approvalViewExplorer'),
                                style: const TextStyle(
                                  color: Color(0xFF00B8FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Gas estimate row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.t('approvalGasEstimate'),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          _loadingGas
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.white38,
                                  ),
                                )
                              : Text(
                                  _gasEstimate?.formattedCost ?? 'Unavailable',
                                  style: TextStyle(
                                    color: _gasEstimate != null
                                        ? Colors.white70
                                        : Colors.white30,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── WHY THIS IS RISKY ─────────────────────────────────────────
                _SectionCard(
                  title: loc.t('approvalWhyRisky'),
                  titleColor: _accentColor,
                  borderColor: _accentColor.withOpacity(0.35),
                  child: _reasons.isEmpty
                      ? Row(
                          children: [
                            const Icon(
                              Icons.verified_user,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                loc.t('approvalNoRisks'),
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: _reasons
                              .map(
                                (r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: _accentColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          r,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 12),

                // ── RECOMMENDED ACTION ─────────────────────────────────────────
                _SectionCard(
                  title: loc.t('approvalRecommendedAction'),
                  titleColor: Colors.white70,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        widget.approval.riskLevel == RiskLevel.danger
                            ? Icons.gpp_bad_outlined
                            : widget.approval.riskLevel == RiskLevel.warning
                                ? Icons.gpp_maybe_outlined
                                : Icons.gpp_good_outlined,
                        color: _accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _recommendation,
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── REVOKE SECTION ─────────────────────────────────────────────
                if (_revoked)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF10B981),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          loc.t('approvalRevokeSuccess'),
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _revoking ? null : _revoke,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        disabledBackgroundColor: const Color(0xFF334155),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _revoking
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              loc.t('approvalRevokeBtn'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        loc.t('approvalBackBtn'),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── HELPER WIDGETS ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Color? titleColor;
  final Color? borderColor;

  const _SectionCard({
    required this.child,
    this.title,
    this.titleColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                color: titleColor ?? Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
