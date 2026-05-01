import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../widgets/design/ds_background.dart';
import '../config/app_colors.dart';
import '../widgets/design/ds_scanning_flow.dart';
import 'scan_result_screen.dart';
import '../models/approval.dart';
import '../services/approval_scan_service.dart';
import '../services/security/security_event_service.dart';

/// Make Safe scan screen.
///
/// Performs a targeted token-approval security scan using [ApprovalScanService].
/// Does NOT use [GlobalApprovalScanner] — that belongs exclusively to Panic Mode.
class ScanScreen extends StatefulWidget {
  final String address;
  final int? chainId;
  final String? targetTokenAddress;
  final String? targetTokenName;
  final String? targetTokenSymbol;
  final String? highlightSpender;
  final String? highlightToken;
  final String chainType; // 'evm', 'solana', 'tron'

  const ScanScreen({
    super.key,
    required this.address,
    this.chainId,
    this.targetTokenAddress,
    this.targetTokenName,
    this.targetTokenSymbol,
    this.highlightSpender,
    this.highlightToken,
    this.chainType = 'evm',
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum _ScanState { scanning, completeSafe, error }

class _ScanScreenState extends State<ScanScreen> {
  int _currentStep = 0;
  double _progress = 0.0;
  _ScanState _state = _ScanState.scanning;
  String? _errorMessage;
  bool _isScanning = true;

  // Make Safe specific scan steps
  List<String> _getScanSteps(LocalizationService loc) {
    return [
      loc.t('basicScanStep1'), // Scanning Protocols
      loc.t('basicScanStep2'), // Analyzing Approvals
      loc.t('basicScanStep3'), // Generating Report
    ];
  }

  @override
  void initState() {
    super.initState();
    _runScan();
  }

  Future<void> _runScan() async {
    _isScanning = true;
    _progress = 0.0;
    final startTime = DateTime.now();
    debugPrint('[ScanScreen] ▶ START scan | chain=${widget.chainType} | addr=${widget.address.substring(0, 8)}...');
    // Fire visual animation in parallel – does not block the real fetch.
    _simulateProgress();

    List<ApprovalData>? list;
    try {
      // MAKE SAFE uses ApprovalScanService only.
      // RiskEngine is called internally by the service → no duplicate call here.
      list = await ApprovalScanService.scan(
        widget.address,
        targetTokenAddress: widget.targetTokenAddress,
        chainId: widget.chainId,
        chainType: widget.chainType,
      );
      final networkMs = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('[ScanScreen] ✅ Network done in ${networkMs}ms | found=${list.length} approvals');
    } catch (e) {
      final networkMs = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('[ScanScreen] ❌ Scan FAILED in ${networkMs}ms | error=$e');
      _errorMessage = e is String ? e : e.toString();
      list = null;
    }

    // Ensure the scan animation runs for at least 5 seconds
    // so it doesn't feel rushed to the user.
    final elapsed = DateTime.now().difference(startTime);
    const minDuration = Duration(seconds: 5);
    if (elapsed < minDuration) {
      final padMs = (minDuration - elapsed).inMilliseconds;
      debugPrint('[ScanScreen] ⏳ Padding ${padMs}ms to reach min 5s display');
      await Future.delayed(minDuration - elapsed);
    }

    _isScanning = false;
    final totalMs = DateTime.now().difference(startTime).inMilliseconds;
    debugPrint('[ScanScreen] ⏹ Progress bar → 100% | total=${totalMs}ms');

    if (mounted) {
      setState(() {
        _progress = 1.0;
        _currentStep = _getScanSteps(LocalizationService.instance).length - 1;
      });
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;

    if (list == null) {
      setState(() => _state = _ScanState.error);
    } else if (list.isEmpty) {
      setState(() => _state = _ScanState.completeSafe);
      SecurityEventService.instance.logManualScan(widget.address, true, 0);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultScreen(
            address: widget.address,
            targetTokenAddress: widget.targetTokenAddress,
            targetTokenName: widget.targetTokenName,
            targetTokenSymbol: widget.targetTokenSymbol,
            highlightSpender: widget.highlightSpender,
            highlightToken: widget.highlightToken,
            initialApprovals: list!,
            chainType: widget.chainType,
          ),
        ),
      );
    }
  }

  Future<void> _simulateProgress() async {
    final loc = LocalizationService.instance;
    final int total = _getScanSteps(loc).length;

    while (_isScanning && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isScanning || !mounted) break;

      setState(() {
        // Asymptotic curve: quickly approaches 99% but never stops moving
        _progress += (0.99 - _progress) * 0.05;

        // Update text step based on progress
        _currentStep = (_progress * total).floor().clamp(0, total - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: DsBackground(
        accentColor: _state == _ScanState.error
            ? Colors.orange
            : const Color(0xFF00FF9D),
        child: _state == _ScanState.scanning
            ? DsScanningFlow(
                title: loc.t('scanAnalyzingTitle'),
                steps: _getScanSteps(loc),
                currentStepIndex: _currentStep,
                progress: _progress,
                accentColor: const Color(0xFF00FF9D),
              )
            : (_state == _ScanState.error
                ? _buildErrorState(loc)
                : _buildSafeState(loc)),
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
            const Text(
              "Scan failed",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? "Unable to load approval data",
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
                    _state = _ScanState.scanning;
                    _progress = 0;
                    _currentStep = 0;
                  });
                  _runScan();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(
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
                child: const Text(
                  "Back",
                  style: TextStyle(
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

  Widget _buildSafeState(LocalizationService loc) {
    final score = ApprovalScanService.lastRiskScore ?? 100;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF9D).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 80,
                color: Color(0xFF00FF9D),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.t('scanCompleteTitle'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.t('scanNoRisky'),
              style: const TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.t('scanSecurityScore', {'score': score}),
              style: const TextStyle(
                color: Color(0xFF00FF9D),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.t('panicSafeMsg'), // Reusing "Your wallet is secure."
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: const Color(0xFF00FF9D).withOpacity(0.55),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  loc.t('scanBackToDashboard'),
                  style: const TextStyle(
                    color: Color(0xFF00FF9D),
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
