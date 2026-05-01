import 'dart:async';
import 'package:flutter/material.dart';
import '../models/approval.dart';
import '../models/gas_estimation_result.dart';
import '../services/global_approval_scanner.dart';
import '../services/transaction_queue.dart';
import '../services/risk_engine.dart';
import '../widgets/design/ds_background.dart';
import '../widgets/design/ds_scanning_flow.dart';
import '../services/localization_service.dart';
import '../widgets/design/ds_hazard_stripes.dart';
import '../services/security/security_event_service.dart';
import '../models/security_event.dart';
import '../services/pro/pro_service.dart';
import '../services/approval_scan_service.dart';
import '../models/linked_wallet.dart';
import 'pro_screen.dart';

class PanicScanScreen extends StatefulWidget {
  final String address;
  final List<LinkedWallet> wallets;
  const PanicScanScreen({
    super.key,
    required this.address,
    this.wallets = const [],
  });

  @override
  State<PanicScanScreen> createState() => _PanicScanScreenState();
}

enum _PanicState { scanning, noRisks, confirmRevoke, revoking, finished, error }

class _PanicScanScreenState extends State<PanicScanScreen> {
  _PanicState _state = _PanicState.scanning;
  String? _errorMessage;

  int _scanStepAction = 0;
  double _scanProgress = 0.0;

  List<ApprovalData> _allApprovals = [];
  List<ApprovalData> _riskyApprovals = [];
  GasEstimationResult? _gasEstimate;

  int _revokeTotal = 0;
  int _revokeCurrent = 0;
  int _revokeSuccess = 0;
  int _revokeFailed = 0;
  String _revokeStatusText = "";
  StreamSubscription? _queueSub;
  bool _isScanning = true;
  List<String> _getScanSteps(LocalizationService loc) {
    return [
      loc.t('panicScanStep1'),
      loc.t('panicScanStep2'),
      loc.t('panicScanStep3'),
      loc.t('panicScanStep4'),
      loc.t('panicScanStep5'),
      loc.t('panicScanStep6'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _runScan();
  }

  @override
  void dispose() {
    _queueSub?.cancel();
    super.dispose();
  }

  Future<void> _runScan() async {
    _isScanning = true;
    _scanProgress = 0.0;
    final startTime = DateTime.now();
    debugPrint('[PanicScan] ▶ START | wallets=${widget.wallets.length} | fallback=${widget.address.substring(0, 8)}...');
    _simulateScanProgress();

    try {
      _errorMessage = null;

      // Multi-chain scan: if wallets provided, scan each by chainType
      if (widget.wallets.isNotEmpty) {
        final allResults = <ApprovalData>[];

        for (final wallet in widget.wallets) {
          final walletStart = DateTime.now();
          debugPrint('[PanicScan] 🔍 Scanning ${wallet.chainType}/${wallet.address.substring(0, 8)}...');
          try {
            List<ApprovalData> results;
            if (wallet.chainType == 'evm') {
              // EVM gets the full enrichment pipeline
              results = await GlobalApprovalScanner.scanAllApprovals(
                wallet.address,
              );
            } else {
              // Solana/Tron use ApprovalScanService routing
              results = await ApprovalScanService.scan(
                wallet.address,
                chainType: wallet.chainType,
              );
            }
            final walletMs = DateTime.now().difference(walletStart).inMilliseconds;
            debugPrint('[PanicScan] ✅ ${wallet.chainType} done in ${walletMs}ms | found=${results.length}');
            allResults.addAll(results);
          } catch (e) {
            final walletMs = DateTime.now().difference(walletStart).inMilliseconds;
            debugPrint('[PanicScan] ❌ ${wallet.chainType} FAILED in ${walletMs}ms | $e');
            // Continue scanning other wallets
          }
        }

        _allApprovals = allResults;
      } else {
        // Fallback: single-address EVM scan (backward compat)
        debugPrint('[PanicScan] 🔍 Fallback EVM scan...');
        _allApprovals = await GlobalApprovalScanner.scanAllApprovals(
          widget.address,
        );
      }

      final scanMs = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('[PanicScan] 📊 All scans done in ${scanMs}ms | total=${_allApprovals.length} approvals');

      _riskyApprovals =
          _allApprovals.where((a) => a.assessment.shouldRevoke).toList();
      debugPrint('[PanicScan] ⚠️ Risky=${_riskyApprovals.length} / Total=${_allApprovals.length}');

      // Sort by risk score (descending) so critical items are handled first
      // Priority sorting: 1. Threat hits, 2. Score descending
      _riskyApprovals.sort((a, b) {
        final aThreat =
            a.assessment.reasons.any((r) => r.code == 'threat_db_hit') ? 1 : 0;
        final bThreat =
            b.assessment.reasons.any((r) => r.code == 'threat_db_hit') ? 1 : 0;
        if (aThreat != bThreat) return bThreat.compareTo(aThreat);
        return b.assessment.score.compareTo(a.assessment.score);
      });

      if (_riskyApprovals.isNotEmpty) {
        // Gas estimation only for EVM approvals
        final evmRisky =
            _riskyApprovals.where((a) => a.chainType == 'evm').toList();
        if (evmRisky.isNotEmpty) {
          debugPrint('[PanicScan] ⛽ Estimating gas for ${evmRisky.length} EVM revokes...');
          final queue = TransactionQueue();
          try {
            _gasEstimate = await queue.estimateTotalGas(evmRisky);
            debugPrint('[PanicScan] ⛽ Gas estimate ready');
          } catch (_) {
            debugPrint('[PanicScan] ⛽ Gas estimation failed');
          }
        }
      }
    } catch (e) {
      debugPrint('[PanicScan] ❌ FATAL: $e');
      _errorMessage = e is String ? e : e.toString();
    }

    // Ensure Panic scan animation runs for at least 8 seconds
    final elapsed = DateTime.now().difference(startTime);
    const minDuration = Duration(seconds: 8);
    if (elapsed < minDuration) {
      final padMs = (minDuration - elapsed).inMilliseconds;
      debugPrint('[PanicScan] ⏳ Padding ${padMs}ms to reach min 8s display');
      await Future.delayed(minDuration - elapsed);
    }

    _isScanning = false;
    final totalMs = DateTime.now().difference(startTime).inMilliseconds;
    debugPrint('[PanicScan] ⏹ Progress bar → 100% | total=${totalMs}ms');

    if (mounted) {
      setState(() {
        _scanProgress = 1.0;
        _scanStepAction =
            _getScanSteps(LocalizationService.instance).length - 1;
      });
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (!mounted) return;

    setState(() {
      if (_errorMessage != null) {
        _state = _PanicState.error;
      } else if (_riskyApprovals.isEmpty) {
        _state = _PanicState.noRisks;
        SecurityEventService.instance.logManualScan(widget.address, true, 0);
      } else {
        _state = _PanicState.confirmRevoke;
      }
    });

    if (_state == _PanicState.confirmRevoke && mounted) {
      _showConfirmDialog();
    }
  }

  Future<void> _showConfirmDialog() async {
    final loc = LocalizationProvider.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          loc.t('panicConfirmRevoke'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          loc.t('panicRevokeWarning', {'count': _riskyApprovals.length}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              loc.t('panicCancel'),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text(loc.t('panicRevokeAll')),
          ),
        ],
      ),
    );
    if (confirm == true) {
      if (!ProService.instance.canUseBulkRevoke()) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProScreen()),
          );
        }
        return;
      }
      _startRevoke();
    }
  }

  Future<void> _simulateScanProgress() async {
    final int totalSteps = _getScanSteps(LocalizationService.instance).length;

    while (_isScanning && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!_isScanning || !mounted) break;

      setState(() {
        // Asymptotic curve: approaches 99% but never stops moving
        _scanProgress += (0.99 - _scanProgress) * 0.05;

        // Update text steps based on progress
        _scanStepAction =
            (_scanProgress * totalSteps).floor().clamp(0, totalSteps - 1);
      });
    }
  }

  Future<void> _startRevoke() async {
    final loc = LocalizationProvider.of(context);
    setState(() {
      _state = _PanicState.revoking;
      _revokeTotal = _riskyApprovals.length;
      _revokeCurrent = 0;
      _revokeSuccess = 0;
      _revokeFailed = 0;
      _revokeStatusText = loc.t('panicStatusInitializing');
    });

    final queue = TransactionQueue();
    queue.clear();

    _queueSub = queue.progressStream.listen((p) {
      if (mounted) {
        setState(() {
          _revokeCurrent = p.completed;
          _revokeTotal = p.total;
          _revokeSuccess = p.successCount;
          _revokeFailed = p.failedCount;
          if (p.currentJob != null) {
            _revokeStatusText = loc.t('panicStatusRevoking', {
              'current': p.completed + 1,
              'total': p.total,
              'spender': p.currentJob!.approval.spender,
            });
          }
        });
      }
    });

    try {
      queue.addJobs(_riskyApprovals);
      final result = await queue.run(emitEvents: false);

      // Update counts from actual result, not from stream
      _revokeSuccess = result.successCount;
      _revokeFailed = result.failedCount;
    } catch (e) {
      debugPrint("Panic revoke failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _state = _PanicState.finished;
          _revokeStatusText = loc.t('panicStatusComplete');
        });

        // Emit security event for timeline (FREE & PRO)
        if (_revokeSuccess > 0) {
          SecurityEventService.instance.emit(
            SecurityEvent(
              type: SecurityEventType.panicTriggered,
              severity: 'high',
              timestamp: DateTime.now(),
              walletAddress: widget.address,
              title: loc.t('panicCompleteTitle'),
              message: loc.t('panicSuccess', {'count': _revokeSuccess}),
              metadata: {
                'successCount': _revokeSuccess,
                'failedCount': _revokeFailed,
                'totalProcessed': _revokeTotal,
              },
            ),
          );
        }
      }
    }
  }

  Widget _buildContent(LocalizationService loc) {
    switch (_state) {
      case _PanicState.scanning:
        return DsScanningFlow(
          title: loc.t('panicEmergencyScan'),
          steps: _getScanSteps(loc),
          currentStepIndex: _scanStepAction,
          progress: _scanProgress,
          accentColor: const Color(0xFFEF4444),
        );

      case _PanicState.error:
        return _buildErrorState(loc);

      case _PanicState.noRisks:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield, color: Color(0xFF10B981), size: 100),
                const SizedBox(height: 24),
                Text(
                  loc.t('panicCompleteTitle'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.t('panicRiskyNone'),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.t('panicSafeMsg'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                _buildBackButton(const Color(0xFF10B981), loc: loc),
              ],
            ),
          ),
        );

      case _PanicState.confirmRevoke:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emergency_share,
                    color: Colors.redAccent,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  loc.t('panicActionRequired'),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.t('panicDangerousFound', {
                    'count': _riskyApprovals.length,
                  }),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_gasEstimate != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.local_gas_station,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              loc.t('panicTotalFee', {
                                'fee': _gasEstimate!.formattedCost,
                              }),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          loc.t('panicFeeError'),
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.builder(
                      itemCount: _riskyApprovals.length,
                      itemBuilder: (_, i) {
                        final a = _riskyApprovals[i];
                        final sym = a.tokenSymbol ?? '???';
                        final isUnlimited =
                            a.allowance == RiskEngine.maxUint256;
                        return Container(
                          margin: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            bottom: 6,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.redAccent.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              // Chain badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  a.chainType == 'solana'
                                      ? 'SOL'
                                      : a.chainType == 'tron'
                                          ? 'TRX'
                                          : 'EVM',
                                  style: TextStyle(
                                    color: a.chainType == 'solana'
                                        ? const Color(0xFF9945FF)
                                        : a.chainType == 'tron'
                                            ? Colors.red
                                            : Colors.cyanAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Text(
                                sym,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (isUnlimited)
                                Text(
                                  loc.t('panicUnlimited'),
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _showConfirmDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: Colors.redAccent.withOpacity(0.5),
                    ),
                    child: Text(
                      loc.t('panicRevokeAll'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                const DsHazardStripes(height: 12),
                const SizedBox(height: 16),
                const DsHazardStripes(height: 12),
                _buildBackButton(
                  Colors.white54,
                  loc: loc,
                  label: loc.t('panicCancel'),
                ),
              ],
            ),
          ),
        );

      case _PanicState.revoking:
        final progress =
            _revokeTotal > 0 ? (_revokeCurrent / _revokeTotal) : 0.0;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DsHazardStripes(height: 12),
                const SizedBox(height: 40),
                const DsHazardStripes(height: 12),
                const SizedBox(height: 40),
                Text(
                  loc.t('panicRevoking'),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.redAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  loc.t('panicProgress', {
                    'current': _revokeCurrent,
                    'total': _revokeTotal,
                  }),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _revokeStatusText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                const DsHazardStripes(height: 12),
              ],
            ),
          ),
        );

      case _PanicState.finished:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _revokeFailed == 0
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: _revokeFailed == 0
                      ? const Color(0xFF10B981)
                      : Colors.orangeAccent,
                  size: 100,
                ),
                const SizedBox(height: 24),
                Text(
                  loc.t('panicFinished'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  loc.t('panicSuccess', {'count': _revokeSuccess}),
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (_revokeFailed > 0)
                  Text(
                    loc.t('panicFailed', {'count': _revokeFailed}),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 40),
                _buildBackButton(const Color(0xFF00FF9D), loc: loc),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildErrorState(LocalizationService loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.t('scanFailed'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? loc.t('scanNoData'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _state = _PanicState.scanning;
                    _scanProgress = 0;
                    _scanStepAction = 0;
                  });
                  _runScan();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
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
            _buildBackButton(
              Colors.white54,
              loc: loc,
              label: loc.t('panicBack'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(
    Color color, {
    required LocalizationService loc,
    String? label,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.55), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label ?? loc.t('panicBack'),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 1,
          ),
        ),
      ),
    );
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
        accentColor: const Color(0xFFEF4444),
        child: _buildContent(loc),
      ),
    );
  }
}
