import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/approval.dart';
import '../models/gas_estimation_result.dart';
import 'revoke_service.dart';
import 'security/security_event_service.dart';
import '../models/security_event.dart';
import 'localization_service.dart';
import 'solana/solana_signing_bridge.dart';
import 'tron/tron_signing_bridge.dart';

enum RevokeJobStatus { pending, waitingWallet, submitted, confirmed, failed }

class RevokeJob {
  final ApprovalData approval;
  RevokeJobStatus status;
  String? error;
  String? txHash;

  RevokeJob({
    required this.approval,
    this.status = RevokeJobStatus.pending,
    this.error,
    this.txHash,
  });
}

class RevokeProgress {
  final int total;
  final int completed;
  final int successCount;
  final int failedCount;
  final RevokeJob? currentJob;

  RevokeProgress({
    required this.total,
    required this.completed,
    required this.successCount,
    required this.failedCount,
    this.currentJob,
  });

  double get percent => total == 0 ? 0 : completed / total;
}

/// Result of a TransactionQueue.run() execution.
/// Callers MUST check this to determine actual success/failure.
class QueueRunResult {
  final int total;
  final int successCount;
  final int failedCount;
  final List<String> txHashes;
  final List<String> errors;

  QueueRunResult({
    required this.total,
    required this.successCount,
    required this.failedCount,
    required this.txHashes,
    required this.errors,
  });

  bool get hasSuccess => successCount > 0;
  bool get allSucceeded => successCount == total;
  bool get allFailed => failedCount == total;
}

class TransactionQueue {
  static final TransactionQueue _instance = TransactionQueue._internal();
  factory TransactionQueue() => _instance;
  TransactionQueue._internal();

  final List<RevokeJob> _jobs = [];
  bool _isRunning = false;

  final _progressController = StreamController<RevokeProgress>.broadcast();
  Stream<RevokeProgress> get progressStream => _progressController.stream;

  bool get isRunning => _isRunning;
  int get totalJobs => _jobs.length;

  void addJobs(List<ApprovalData> approvals) {
    for (var a in approvals) {
      _jobs.add(RevokeJob(approval: a));
    }
    _notify();
  }

  void clear() {
    if (_isRunning) return;
    _jobs.clear();
    _notify();
  }

  /// Returns [QueueRunResult] with actual success/failure counts.
  /// Callers MUST check result — do not assume success after this returns.
  Future<QueueRunResult> run({bool emitEvents = true}) async {
    if (_isRunning || _jobs.isEmpty) {
      return QueueRunResult(
        total: 0,
        successCount: 0,
        failedCount: 0,
        txHashes: [],
        errors: [],
      );
    }
    _isRunning = true;

    int successCount = 0;
    int failedCount = 0;
    int completed = 0;

    // We process only pending jobs
    while (true) {
      RevokeJob? job;
      try {
        job = _jobs.firstWhere((j) => j.status == RevokeJobStatus.pending);
      } catch (e) {
        break; // No more pending jobs
      }

      job.status = RevokeJobStatus.waitingWallet;
      _notifyProgress(completed, successCount, failedCount, job);

      try {
        // Route revoke by chain type
        final chainType = job.approval.chainType;
        String txHash;

        switch (chainType) {
          case 'solana':
            if (!SolanaSigningBridge.canSign()) {
              throw LocalizationService.instance.t('revokeConnectSolana');
            }
            txHash = await SolanaSigningBridge.revokeApproval(job.approval);
            break;
          case 'tron':
            if (!TronSigningBridge.canSign()) {
              throw LocalizationService.instance.t('revokeConnectTron');
            }
            txHash = await TronSigningBridge.revokeApproval(job.approval);
            break;
          default:
            // EVM revoke (existing flow)
            txHash = await RevokeService.revokeApproval(a: job.approval);
        }

        job.txHash = txHash;
        job.status = RevokeJobStatus.submitted;
        successCount++;

        // Emit security event for timeline (FREE & PRO)
        if (emitEvents) {
          SecurityEventService.instance.emit(
            SecurityEvent(
              type: SecurityEventType.revokeCompleted,
              severity: 'low',
              timestamp: DateTime.now(),
              walletAddress: job.approval.walletAddress,
              title: 'Revoke Successful',
              message:
                  'Permission revoked for ${job.approval.tokenSymbol} on ${job.approval.spender}',
              metadata: {
                'token': job.approval.token,
                'spender': job.approval.spenderAddress,
                'chainId': job.approval.chainId,
                'txHash': txHash,
              },
            ),
          );
        }
      } catch (e) {
        job.error = e.toString();
        job.status = RevokeJobStatus.failed;
        failedCount++;
      }

      completed++;
      _notifyProgress(completed, successCount, failedCount, job);

      // Add a small delay between requests to avoid spamming the wallet or hitting rate limits
      await Future.delayed(const Duration(milliseconds: 600));
    }

    _isRunning = false;
    _notifyProgress(completed, successCount, failedCount, null);

    return QueueRunResult(
      total: completed,
      successCount: successCount,
      failedCount: failedCount,
      txHashes: _jobs
          .where((j) => j.txHash != null && j.txHash!.isNotEmpty)
          .map((j) => j.txHash!)
          .toList(),
      errors: _jobs
          .where((j) => j.error != null && j.error!.isNotEmpty)
          .map((j) => j.error!)
          .toList(),
    );
  }

  void _notifyProgress(
    int completed,
    int success,
    int failed,
    RevokeJob? current,
  ) {
    _progressController.add(
      RevokeProgress(
        total: _jobs.length,
        completed: completed,
        successCount: success,
        failedCount: failed,
        currentJob: current,
      ),
    );
  }

  void _notify() {
    _notifyProgress(
      _jobs.where((j) => j.status != RevokeJobStatus.pending).length,
      _jobs
          .where(
            (j) =>
                j.status == RevokeJobStatus.submitted ||
                j.status == RevokeJobStatus.confirmed,
          )
          .length,
      _jobs.where((j) => j.status == RevokeJobStatus.failed).length,
      null,
    );
  }

  /// Estimates total gas for a list of approvals
  Future<GasEstimationResult?> estimateTotalGas(
    List<ApprovalData> approvals,
  ) async {
    if (approvals.isEmpty) return null;

    BigInt totalGas = BigInt.zero;
    BigInt maxGasPrice = BigInt.zero;
    int successCount = 0;

    for (var a in approvals) {
      // Skip non-EVM approvals — gas estimation is EVM-specific
      if (a.chainType != 'evm') continue;

      try {
        final estimate = await RevokeService.estimateGas(a: a);
        totalGas += estimate.estimatedGas;
        if (estimate.estimatedGasPrice > maxGasPrice) {
          maxGasPrice = estimate.estimatedGasPrice;
        }
        successCount++;
      } catch (e) {
        // Ignore failures for individual estimates to not break the flow
        debugPrint("Failed to estimate gas for ${a.token}: $e");
      }
    }

    if (successCount == 0) return null;

    return GasEstimationResult(
      estimatedGas: totalGas,
      estimatedGasPrice: maxGasPrice,
    );
  }
}
