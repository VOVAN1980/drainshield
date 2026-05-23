import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/localization_service.dart';
import '../widgets/design/ds_background.dart';
import '../widgets/design/ds_fade_slide.dart';
import '../models/link_scan_result.dart';
import '../services/link_shield/link_shield_api.dart';

/// Link Shield result screen.
///
/// Displays the scan verdict with domain info, redirect chain, Web3 signals,
/// and action buttons. For HIGH_RISK/CONFIRMED_SCAM, the "Open Link" button
/// is intentionally hidden per security spec.
class LinkResultScreen extends StatelessWidget {
  final LinkScanResult result;

  const LinkResultScreen({super.key, required this.result});

  // ── Verdict colors and icons ──────────────────────────────────────────────
  Color _verdictColor() {
    switch (result.verdict) {
      case LinkVerdict.trusted:
        return const Color(0xFF00FF9D);
      case LinkVerdict.lowData:
      case LinkVerdict.checkLimited:
        return const Color(0xFFFFD700);
      case LinkVerdict.suspicious:
        return Colors.orange;
      case LinkVerdict.highRisk:
      case LinkVerdict.confirmedScam:
        return const Color(0xFFFF4444);
    }
  }

  IconData _verdictIcon() {
    switch (result.verdict) {
      case LinkVerdict.trusted:
        return Icons.verified_rounded;
      case LinkVerdict.lowData:
        return Icons.help_outline_rounded;
      case LinkVerdict.checkLimited:
        return Icons.cloud_off_rounded;
      case LinkVerdict.suspicious:
        return Icons.warning_amber_rounded;
      case LinkVerdict.highRisk:
        return Icons.dangerous_rounded;
      case LinkVerdict.confirmedScam:
        return Icons.gpp_bad_rounded;
    }
  }

  String _verdictKey() {
    switch (result.verdict) {
      case LinkVerdict.trusted:
        return 'linkResultSafe';
      case LinkVerdict.lowData:
        return 'linkResultLowData';
      case LinkVerdict.checkLimited:
        return 'linkResultCheckLimited';
      case LinkVerdict.suspicious:
        return 'linkResultSuspicious';
      case LinkVerdict.highRisk:
        return 'linkResultHighRisk';
      case LinkVerdict.confirmedScam:
        return 'linkResultConfirmedScam';
    }
  }

  String _verdictShareLabel() {
    switch (result.verdict) {
      case LinkVerdict.trusted:
        return '🟢 Looks safe';
      case LinkVerdict.lowData:
        return '🟡 Low data';
      case LinkVerdict.checkLimited:
        return '🟡 Check limited';
      case LinkVerdict.suspicious:
        return '🟠 Suspicious';
      case LinkVerdict.highRisk:
        return '🔴 High risk';
      case LinkVerdict.confirmedScam:
        return '🔴 Confirmed scam';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);
    final color = _verdictColor();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          DsBackground(
            accentColor: color,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
              child: Column(
                children: [
                  // ── Verdict badge ───────────────────────────────────────────
                  DsFadeSlide(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.12),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.25),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(_verdictIcon(), color: color, size: 52),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          loc.t(_verdictKey()),
                          style: TextStyle(
                            color: color,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Risk score
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${loc.t('linkResultRiskScore')}: ${result.riskScore}/100',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: color.withOpacity(0.3)),
                              ),
                              child: Text(
                                '${loc.t('linkResultConfidence')}: ${result.confidence == LinkConfidence.high ? loc.t('linkResultConfidenceHigh') : loc.t('linkResultConfidenceLow')}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Domain info card ────────────────────────────────────────
                  if (result.domainInfo != null)
                    DsFadeSlide(
                      delay: const Duration(milliseconds: 80),
                      child: _buildInfoCard(
                        loc,
                        icon: Icons.language_rounded,
                        title: loc.t('linkResultDomainAge'),
                        children: [
                          _infoRow(
                            loc.t('linkResultDomainLabel'),
                            result.domainInfo!.domain,
                          ),
                          _infoRow(
                            loc.t('linkResultDomainAge'),
                            _domainAgeLabel(result.domainInfo!.age, loc),
                          ),
                          _infoRow(
                            loc.t('linkResultDomainRep'),
                            _domainRepLabel(result.domainInfo!.reputation, loc),
                            valueColor: result.domainInfo!.reputation ==
                                    DomainReputation.suspicious
                                ? Colors.orange
                                : (result.domainInfo!.reputation ==
                                        DomainReputation.notVerified
                                    ? Colors.amber
                                    : null),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // ── URL info ────────────────────────────────────────────────
                  DsFadeSlide(
                    delay: const Duration(milliseconds: 120),
                    child: _buildInfoCard(
                      loc,
                      icon: Icons.link_rounded,
                      title: 'URL',
                      children: [
                        _infoRow(loc.t('linkResultOriginalUrl'),
                            _truncateUrl(result.originalUrl)),
                        if (result.finalUrl != null &&
                            result.finalUrl != result.originalUrl)
                          _infoRow(loc.t('linkResultFinalUrl'),
                              _truncateUrl(result.finalUrl!)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Web3 signals card ───────────────────────────────────────
                  if (result.web3Signals.isNotEmpty)
                    DsFadeSlide(
                      delay: const Duration(milliseconds: 160),
                      child: _buildInfoCard(
                        loc,
                        icon: Icons.token_rounded,
                        title: loc.t('linkResultWeb3Features'),
                        children: result.web3Signals
                            .map((s) => _infoRow(
                                  _web3SignalLabel(s.type, loc),
                                  s.value,
                                  valueColor: Colors.orange,
                                ))
                            .toList(),
                      ),
                    ),
                  if (result.web3Signals.isNotEmpty) const SizedBox(height: 12),

                  // ── Risk factors ────────────────────────────────────────────
                  if (result.riskFactors.isNotEmpty)
                    DsFadeSlide(
                      delay: const Duration(milliseconds: 200),
                      child: _buildInfoCard(
                        loc,
                        icon: result.verdict == LinkVerdict.trusted
                            ? Icons.shield_rounded
                            : Icons.flag_rounded,
                        title: result.verdict == LinkVerdict.trusted
                            ? loc.t('linkResultConfirmations')
                            : loc.t('linkResultRiskFactors'),
                        children: result.riskFactors.toSet().map((key) {
                          final isTrusted =
                              result.verdict == LinkVerdict.trusted;
                          final isDanger = result.isOpenLinkBlocked;
                          final color = isTrusted
                              ? Colors.green
                              : (isDanger ? Colors.redAccent : Colors.orange);
                          final icon = isTrusted
                              ? Icons.check_circle_rounded
                              : (isDanger
                                  ? Icons.dangerous_rounded
                                  : Icons.warning_amber_rounded);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(icon, color: color, size: 14),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    loc.t(key),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // ── Action buttons ──────────────────────────────────────────
                  DsFadeSlide(
                    delay: const Duration(milliseconds: 240),
                    child: Column(
                      children: [
                        // Open Link — only for TRUSTED (primary)
                        if (result.verdict == LinkVerdict.trusted) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () => _openLink(context),
                              icon: const Icon(Icons.open_in_new_rounded,
                                  size: 18),
                              label: Text(loc.t('linkResultOpenLink')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: color,
                                side: BorderSide(
                                  color: color.withOpacity(0.4),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        const SizedBox(height: 10),

                        // Share Result
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () => _shareResult(),
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: Text(loc.t('linkResultShareResult')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF00B8FF),
                              side: BorderSide(
                                color:
                                    const Color(0xFF00B8FF).withOpacity(0.25),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Report as Scam / Report Mistake
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () => _reportScam(context, loc),
                            icon: Icon(
                              result.isOpenLinkBlocked
                                  ? Icons.feedback_outlined
                                  : (result.verdict == LinkVerdict.trusted
                                      ? Icons.info_outline_rounded
                                      : Icons.report_outlined),
                              size: 18,
                            ),
                            label: Text(
                              result.isOpenLinkBlocked
                                  ? loc.t('linkResultReportMistake')
                                  : (result.verdict == LinkVerdict.trusted
                                      ? loc.t('linkResultReportIssue')
                                      : loc.t('linkResultReportScam')),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: result.isOpenLinkBlocked
                                  ? Colors.amber
                                  : (result.verdict == LinkVerdict.trusted
                                      ? Colors.white54
                                      : Colors.redAccent),
                              side: BorderSide(
                                color: (result.isOpenLinkBlocked
                                        ? Colors.amber
                                        : (result.verdict == LinkVerdict.trusted
                                            ? Colors.white54
                                            : Colors.redAccent))
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // "Open at your own risk" — only for LOW_DATA / CHECK_LIMITED
                        // SUSPICIOUS / HIGH_RISK / CONFIRMED_SCAM — blocked completely.
                        if (result.isOpenLinkSecondary) ...[
                          TextButton(
                            onPressed: () => _openLinkAtOwnRisk(context),
                            child: Text(
                              loc.t('linkResultOpenAnyway'),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.25),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withOpacity(0.15),
                              ),
                            ),
                          ),
                        ],

                        // Close
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              loc.t('linkResultClose'),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // X button floating top-left
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white70, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info card builder ───────────────────────────────────────────────────────
  Widget _buildInfoCard(
    LocalizationService loc, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _truncateUrl(String url) {
    if (url.length <= 60) return url;
    return '${url.substring(0, 45)}...${url.substring(url.length - 12)}';
  }

  String _domainAgeLabel(DomainAge age, LocalizationService loc) {
    switch (age) {
      case DomainAge.newDomain:
        return loc.t('linkResultDomainAgeNew');
      case DomainAge.unknown:
        return loc.t('linkResultDomainAgeUnknown');
      case DomainAge.established:
        return loc.t('linkResultDomainAgeEstablished');
    }
  }

  String _domainRepLabel(DomainReputation rep, LocalizationService loc) {
    switch (rep) {
      case DomainReputation.clean:
        return loc.t('linkResultRepClean');
      case DomainReputation.suspicious:
        return loc.t('linkResultSuspicious');
      case DomainReputation.listed:
        return loc.t('linkResultRepListed');
      case DomainReputation.notVerified:
        return loc.t('linkResultRepNotVerified');
    }
  }

  String _web3SignalLabel(Web3SignalType type, LocalizationService loc) {
    switch (type) {
      case Web3SignalType.walletConnectUri:
        return loc.t('linkResultWeb3WalletConnect');
      case Web3SignalType.walletDeepLink:
        return loc.t('linkResultWeb3WalletLink');
      case Web3SignalType.contractAddress:
        return loc.t('linkResultWeb3Contract');
      case Web3SignalType.connectWalletFlow:
        return loc.t('linkResultWeb3ConnectFlow');
      case Web3SignalType.claimAirdrop:
        return loc.t('linkResultWeb3ScamPattern');
      case Web3SignalType.fakeApproval:
        return loc.t('linkResultWeb3FakeApprove');
    }
  }

  void _openLink(BuildContext context) async {
    // Only TRUSTED can open — extra safety check
    if (result.verdict != LinkVerdict.trusted) return;

    String urlStr = result.originalUrl.trim();
    if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
      urlStr = 'https://$urlStr';
    }
    final uri = Uri.tryParse(urlStr);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        // Fallback: copy to clipboard
        if (context.mounted) {
          Clipboard.setData(ClipboardData(text: result.originalUrl));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(LocalizationService.instance.t('linkResultUrlCopied')),
            ),
          );
        }
      }
    }
  }

  void _openLinkAtOwnRisk(BuildContext context) async {
    // Only LOW_DATA / CHECK_LIMITED can use this
    if (result.isOpenLinkBlocked) return;

    String urlStr = result.originalUrl.trim();
    if (!urlStr.startsWith('http://') && !urlStr.startsWith('https://')) {
      urlStr = 'https://$urlStr';
    }
    final uri = Uri.tryParse(urlStr);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          Clipboard.setData(ClipboardData(text: result.originalUrl));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(LocalizationService.instance.t('linkResultUrlCopied')),
            ),
          );
        }
      }
    }
  }

  void _copyResult(BuildContext context, LocalizationService loc) {
    final text =
        '${_verdictShareLabel()} — ${result.domainInfo?.domain ?? result.originalUrl}\n'
        'Risk: ${result.riskScore}/100 | Checked by DrainShield';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.t('linkResultCopied'))),
    );
  }

  void _reportScam(BuildContext context, LocalizationService loc) {
    final domain = result.domainInfo?.domain ?? result.originalUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ReportSheet(
        url: result.originalUrl,
        domain: domain,
        isMistake: result.isOpenLinkBlocked,
        loc: loc,
      ),
    );
  }

  void _shareResult() {
    final loc = LocalizationService.instance;
    final domain = result.domainInfo?.domain ?? result.originalUrl;
    final emoji = _verdictShareEmoji();
    final verdictText = loc.t(_verdictKey());
    final meaning = _verdictMeaning(loc);

    final buf = StringBuffer();
    buf.writeln('\u{1F50E} ${loc.t("linkShareTitle")}');
    buf.writeln('');
    buf.writeln('$emoji $verdictText \u2014 $meaning');
    buf.writeln('${loc.t("linkShareLink")}: $domain');
    buf.writeln('${loc.t("linkShareChecked")}: DrainShield');
    buf.writeln('${loc.t("linkResultRiskScore")}: ${result.riskScore}/100');
    buf.writeln('');
    buf.writeln('${loc.t("linkShareWhy")}:');
    if (result.verdict == LinkVerdict.trusted) {
      buf.writeln('\u2022 ${loc.t("linkShareTrustedReason1")}');
      buf.writeln('\u2022 ${loc.t("linkShareTrustedReason2")}');
      buf.writeln('\u2022 ${loc.t("linkShareTrustedReason3")}');
    } else if (result.riskFactors.isNotEmpty) {
      for (final factor in result.riskFactors.toSet().take(3)) {
        buf.writeln('\u2022 ${loc.t(factor)}');
      }
    } else {
      buf.writeln('\u2022 ${loc.t("linkShareNoRiskFactors")}');
    }
    buf.writeln('');
    buf.writeln('${loc.t("linkShareAction")}:');
    buf.writeln(_verdictAction(loc));
    buf.writeln('');
    buf.writeln('${loc.t("linkShareFooter")}:');
    buf.write('https://lvs.network/drainshield');

    SharePlus.instance.share(ShareParams(text: buf.toString()));
  }

  String _verdictShareEmoji() {
    switch (result.verdict) {
      case LinkVerdict.trusted:
        return '\u{1F7E2}';
      case LinkVerdict.lowData:
      case LinkVerdict.checkLimited:
        return '\u{1F7E1}';
      case LinkVerdict.suspicious:
        return '\u{1F7E0}';
      case LinkVerdict.highRisk:
      case LinkVerdict.confirmedScam:
        return '\u{1F534}';
    }
  }

  String _verdictMeaning(LocalizationService loc) {
    switch (result.verdict) {
      case LinkVerdict.trusted:
        return loc.t('linkShareMeaningSafe');
      case LinkVerdict.lowData:
        return loc.t('linkShareMeaningLowData');
      case LinkVerdict.checkLimited:
        return loc.t('linkShareMeaningLimited');
      case LinkVerdict.suspicious:
        return loc.t('linkShareMeaningSuspicious');
      case LinkVerdict.highRisk:
        return loc.t('linkShareMeaningHighRisk');
      case LinkVerdict.confirmedScam:
        return loc.t('linkShareMeaningScam');
    }
  }

  String _verdictAction(LocalizationService loc) {
    switch (result.verdict) {
      case LinkVerdict.trusted:
        return loc.t('linkShareActionSafe');
      case LinkVerdict.lowData:
      case LinkVerdict.checkLimited:
        return loc.t('linkShareActionLowData');
      case LinkVerdict.suspicious:
        return loc.t('linkShareActionSuspicious');
      case LinkVerdict.highRisk:
      case LinkVerdict.confirmedScam:
        return loc.t('linkShareActionDanger');
    }
  }
}

// ── Truecaller-style Report Bottom Sheet ─────────────────────────────────────

class _ReportSheet extends StatefulWidget {
  final String url;
  final String domain;
  final bool isMistake;
  final LocalizationService loc;

  const _ReportSheet({
    required this.url,
    required this.domain,
    required this.isMistake,
    required this.loc,
  });

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _selectedType;
  final _commentCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  static const _reportTypes = [
    'scam',
    'phishing',
    'drainer',
    'fake_airdrop',
    'malware',
    'safe_mistake',
  ];

  String _typeLabel(String type) {
    return widget.loc.t('linkReportType_$type');
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'scam':
        return Icons.warning_amber_rounded;
      case 'phishing':
        return Icons.phishing_rounded;
      case 'drainer':
        return Icons.account_balance_wallet_outlined;
      case 'fake_airdrop':
        return Icons.card_giftcard_rounded;
      case 'malware':
        return Icons.bug_report_rounded;
      case 'safe_mistake':
        return Icons.check_circle_outline;
      default:
        return Icons.report_outlined;
    }
  }

  Future<void> _submit() async {
    if (_selectedType == null) return;
    setState(() => _sending = true);

    final success = await LinkShieldApi.reportLink(
      url: widget.url,
      reportType: _selectedType!,
      userLabel: _selectedType,
      userComment:
          _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
    );

    if (mounted) {
      setState(() {
        _sending = false;
        _sent = true;
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? widget.loc.t('linkResultReportSent')
                : widget.loc.t('linkResultReportFailed'),
          ),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            12,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: _sent
          ? SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      loc.t('linkResultReportSent'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isMistake
                        ? loc.t('linkReportMistakeTitle')
                        : loc.t('linkReportTitle'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.domain,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Report type selection
                  Text(
                    loc.t('linkReportSelectType'),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _reportTypes.map((type) {
                      final selected = _selectedType == type;
                      return ChoiceChip(
                        avatar: Icon(_typeIcon(type),
                            size: 16,
                            color: selected ? Colors.white : Colors.white54),
                        label: Text(_typeLabel(type)),
                        selected: selected,
                        selectedColor: Colors.redAccent.withOpacity(0.4),
                        backgroundColor: Colors.white.withOpacity(0.08),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: selected ? Colors.redAccent : Colors.white12,
                        ),
                        onSelected: (_) => setState(() => _selectedType = type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Comment field
                  Text(
                    loc.t('linkReportComment'),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    maxLength: 200,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: loc.t('linkReportCommentHint'),
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.2)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      counterStyle:
                          TextStyle(color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          _selectedType != null && !_sending ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              loc.t('linkReportSubmit'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
