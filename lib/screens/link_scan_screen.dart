import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/localization_service.dart';
import '../widgets/design/ds_background.dart';
import '../widgets/design/ds_scanning_flow.dart';
import '../widgets/design/ds_animated_button.dart';
import '../config/app_colors.dart';
import '../models/link_scan_result.dart';
import '../services/link_shield/local_analyzer.dart';
import '../services/link_shield/link_shield_api.dart';
import 'link_result_screen.dart';

/// Link Shield scan screen.
///
/// Two modes:
/// - Manual: user pastes URL and taps "Start Scan"
/// - Share: [sharedUrl] is pre-filled, scan starts automatically
class LinkScanScreen extends StatefulWidget {
  final String? sharedUrl;

  const LinkScanScreen({super.key, this.sharedUrl});

  @override
  State<LinkScanScreen> createState() => _LinkScanScreenState();
}

enum _ScreenState { input, scanning, error }

class _LinkScanScreenState extends State<LinkScanScreen> {
  final TextEditingController _urlCtrl = TextEditingController();
  _ScreenState _state = _ScreenState.input;
  String? _errorMessage;

  // Scan progress
  int _currentStep = 0;
  double _progress = 0.0;
  bool _isScanning = false;

  List<String> _getScanSteps(LocalizationService loc) => [
        loc.t('linkScanStep1'),
        loc.t('linkScanStep2'),
        loc.t('linkScanStep3'),
        loc.t('linkScanStep4'),
        loc.t('linkScanStep5'),
        loc.t('linkScanStep6'),
      ];

  @override
  void initState() {
    super.initState();
    if (widget.sharedUrl != null) {
      // Try to extract a valid URL from shared text
      final extracted = _extractUrl(widget.sharedUrl!);
      _urlCtrl.text = extracted ?? widget.sharedUrl!;
      if (extracted != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
      } else {
        // Not a valid URL — show input with error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showNotALinkError();
        });
      }
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() => _urlCtrl.text = data.text!.trim());
    }
  }

  Future<void> _startScan() async {
    final raw = _urlCtrl.text.trim();
    if (raw.isEmpty) return;

    // Try to extract a valid URL from the input
    final url = _extractUrl(raw);
    if (url == null) {
      _showNotALinkError();
      return;
    }

    // Update field with cleaned URL
    _urlCtrl.text = url;

    setState(() {
      _state = _ScreenState.scanning;
      _progress = 0.0;
      _currentStep = 0;
      _isScanning = true;
    });

    final startTime = DateTime.now();
    debugPrint('[LinkScan] ▶ START scan: $url');

    // Start visual progress in parallel
    _simulateProgress();

    // Run actual analysis: backend first, local fallback
    LinkScanResult? result;
    try {
      // Try backend first
      debugPrint('[LinkScan] Trying backend...');
      final backendResult = await LinkShieldApi.scanLink(url);
      if (backendResult != null) {
        debugPrint('[LinkScan] ✅ Backend verdict: ${backendResult.verdict}');
        result = backendResult.toScanResult(url);

        // Merge with local analysis for Web3 signals and additional checks
        try {
          final localResult = await LocalLinkAnalyzer.analyze(url);
          // If local found higher risk, take the higher score
          if (localResult.riskScore > result.riskScore) {
            result = LinkScanResult(
              originalUrl: url,
              verdict: localResult.verdict,
              confidence: result.confidence,
              riskScore: localResult.riskScore,
              domainInfo: result.domainInfo,
              web3Signals: localResult.web3Signals,
              riskFactors:
                  {...result.riskFactors, ...localResult.riskFactors}.toList(),
              scannedAt: DateTime.now(),
            );
          } else if (localResult.web3Signals.isNotEmpty) {
            // Enrich with local Web3 signals
            result = LinkScanResult(
              originalUrl: url,
              verdict: result.verdict,
              confidence: result.confidence,
              riskScore: result.riskScore,
              domainInfo: result.domainInfo,
              web3Signals: localResult.web3Signals,
              riskFactors:
                  {...result.riskFactors, ...localResult.riskFactors}.toList(),
              scannedAt: DateTime.now(),
            );
          }
        } catch (_) {}
      } else {
        // Backend unreachable — local fallback
        debugPrint('[LinkScan] ⚠ Backend unreachable, using local analyzer');
        result = await LocalLinkAnalyzer.analyze(url);
      }
    } catch (e) {
      debugPrint('[LinkScan] ❌ Error: $e');
      // Final fallback to local
      try {
        result = await LocalLinkAnalyzer.analyze(url);
      } catch (e2) {
        debugPrint('[LinkScan] ❌ Local also failed: $e2');
        _errorMessage = e2.toString();
      }
    }

    // Ensure minimum 10 seconds for trust UX
    final elapsed = DateTime.now().difference(startTime);
    const minDuration = Duration(seconds: 10);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    _isScanning = false;

    if (mounted) {
      setState(() {
        _progress = 1.0;
        _currentStep = _getScanSteps(LocalizationService.instance).length - 1;
      });
      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (!mounted) return;

    if (result == null) {
      setState(() => _state = _ScreenState.error);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LinkResultScreen(result: result!),
        ),
      );
    }
  }

  // ── URL Validation ─────────────────────────────────────────────────────────

  /// Allowed deep-link schemes for wallet/Web3 apps.
  static const _allowedSchemes = [
    'http://',
    'https://',
    'wc:',
    'metamask://',
    'trust://',
    'phantom://',
    'solflare://',
    'tronlink://',
    'rainbow://',
  ];

  /// Try to extract a valid URL from raw text (e.g. shared message).
  /// Returns cleaned URL string, or null if nothing valid found.
  String? _extractUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // 1. Check for allowed deep-link schemes
    final lower = trimmed.toLowerCase();
    for (final scheme in _allowedSchemes) {
      if (lower.startsWith(scheme)) {
        return trimmed;
      }
    }

    // 2. Try to find a URL inside text (shared from Telegram, WhatsApp, etc.)
    final urlRegex = RegExp(
      r'https?://[^\s<>"\)\]]+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(trimmed);
    if (match != null) return match.group(0)!;

    // 3. Check if it looks like a bare domain: word.tld or sub.word.tld/path
    final domainRegex = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)+(/\S*)?$',
    );
    if (domainRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }

  void _showNotALinkError() {
    if (!mounted) return;
    final loc = LocalizationService.instance;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.t('linkScanNotALink')),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _simulateProgress() async {
    final total = _getScanSteps(LocalizationService.instance).length;
    while (_isScanning && mounted) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!_isScanning || !mounted) break;
      setState(() {
        _progress += (0.99 - _progress) * 0.04;
        _currentStep = (_progress * total).floor().clamp(0, total - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);
    const accentColor = Color(0xFF00B8FF);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: DsBackground(
        accentColor: _state == _ScreenState.error ? Colors.orange : accentColor,
        child: _state == _ScreenState.scanning
            ? DsScanningFlow(
                title: loc.t('linkScanTitle'),
                steps: _getScanSteps(loc),
                currentStepIndex: _currentStep,
                progress: _progress,
                accentColor: accentColor,
              )
            : (_state == _ScreenState.error
                ? _buildErrorState(loc)
                : _buildInputState(loc, accentColor)),
      ),
    );
  }

  Widget _buildInputState(LocalizationService loc, Color accentColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shield icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B8FF), Color(0xFF8B5CF6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.link_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              loc.t('linkScanTitle'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.t('linkShieldSubtitle'),
              style: const TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),

            // URL input field
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _urlCtrl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: loc.t('linkScanPlaceholder'),
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.content_paste_rounded,
                      color: accentColor.withOpacity(0.6),
                    ),
                    onPressed: _pasteFromClipboard,
                  ),
                ),
                maxLines: 1,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _startScan(),
              ),
            ),
            const SizedBox(height: 12),

            // Paste button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _pasteFromClipboard,
                icon: Icon(
                  Icons.content_paste_go_rounded,
                  color: accentColor.withOpacity(0.7),
                  size: 18,
                ),
                label: Text(
                  loc.t('linkScanPasteBtn'),
                  style: TextStyle(
                    color: accentColor.withOpacity(0.8),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: accentColor.withOpacity(0.2),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Start Scan button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DsAnimatedButton(
                onPressed: _startScan,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00B8FF), Color(0xFF8B5CF6)],
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
                    loc.t('linkScanStartBtn'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(LocalizationService loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.t('scanFailed'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? loc.t('unknownError'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _state = _ScreenState.input;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  loc.t('portfolioRetry'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.55),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  loc.t('scanBackToDashboard'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
