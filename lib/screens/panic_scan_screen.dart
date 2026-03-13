import 'dart:async';
import 'package:flutter/material.dart';
import '../models/approval.dart';
import '../models/gas_estimation_result.dart';
import '../services/global_approval_scanner.dart';
import '../services/transaction_queue.dart';
import '../services/risk_engine.dart';
import '../widgets/design/ds_background.dart';
import '../widgets/design/ds_scanning_flow.dart';
import '../widgets/top_nav.dart';
import '../services/localization_service.dart';
import '../widgets/design/ds_hazard_stripes.dart';

class PanicScanScreen extends StatefulWidget {
  final String address;
  const PanicScanScreen({super.key, required this.address});

  @override
  State<PanicScanScreen> createState() => _PanicScanScreenState();
}

enum _PanicState { scanning, noRisks, confirmRevoke, revoking, finished }

class _PanicScanScreenState extends State<PanicScanScreen> {
  _PanicState _state = _PanicState.scanning;

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

  List<String> _getScanSteps(LocalizationService loc) {
    return [
      loc.t('panicStep1'),
      loc.t('panicStep2'),
      loc.t('panicStep3'),
      loc.t('panicStep4'),
      loc.t('panicStep5'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _queueSub?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    _simulateScanProgress();

    try {
      _allApprovals = await GlobalApprovalScanner.scanAllApprovals(
        widget.address,
      );

      _riskyApprovals =
          _allApprovals.where((a) => a.assessment.shouldRevoke).toList();

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
        final queue = TransactionQueue();
        try {
          _gasEstimate = await queue.estimateTotalGas(_riskyApprovals);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Panic scan failed: $e");
    }

    while (_scanProgress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    setState(() {
      if (_riskyApprovals.isEmpty) {
        _state = _PanicState.noRisks;
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
    if (confirm == true) _startRevoke();
  }

  Future<void> _simulateScanProgress() async {
    const int totalSteps = 5;
    const int delayPerStepMs = 800;
    const int updatesPerStep = 20;

    for (int i = 0; i < totalSteps; i++) {
      if (!mounted) return;
      setState(() => _scanStepAction = i);

      for (int k = 0; k < updatesPerStep; k++) {
        await Future.delayed(
          const Duration(milliseconds: delayPerStepMs ~/ updatesPerStep),
        );
        if (!mounted) return;
        setState(() {
          _scanProgress = (i + (k + 1) / updatesPerStep) / totalSteps;
        });
      }
    }
    if (mounted) {
      setState(() {
        _scanStepAction = totalSteps;
        _scanProgress = 1.0;
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
      await queue.run();
    } catch (e) {
      debugPrint("Panic revoke failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _state = _PanicState.finished;
          _revokeStatusText = loc.t('panicStatusComplete');
        });
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
      appBar: const TopNav(),
      body: DsBackground(
        accentColor: const Color(0xFFEF4444),
        child: _buildContent(loc),
      ),
    );
  }
}
