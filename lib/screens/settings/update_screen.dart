import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/localization_service.dart';
import '../../services/update_service.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  UpdateCheckResult? _result;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _checkUpdates(silent: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkUpdates({bool silent = false}) async {
    if (!silent) setState(() => _isScanning = true);

    // Simulate minor delay for UX if requested manually
    if (!silent) await Future.delayed(const Duration(seconds: 2));

    final res =
        await UpdateService.instance.checkForUpdates(isAutoCheck: false);

    if (mounted) {
      setState(() {
        _result = res;
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = LocalizationService.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF05070B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          t.t('settingsUpdateTitle').toUpperCase(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildVisualizer(),
            const SizedBox(height: 48),
            _buildStatusText(t),
            const SizedBox(height: 64),
            _buildActions(t),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizer() {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 180 + (20 * _pulseController.value),
              height: 180 + (20 * _pulseController.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (_isScanning ||
                          _result?.status == UpdateStatus.updateAvailable)
                      ? Colors.blue
                          .withOpacity(0.3 * (1 - _pulseController.value))
                      : Colors.green
                          .withOpacity(0.3 * (1 - _pulseController.value)),
                  width: 2,
                ),
              ),
            );
          },
        ),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                (_isScanning || _result?.status == UpdateStatus.updateAvailable)
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.green.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Icon(
            _isScanning
                ? Icons.sync
                : (_result?.status == UpdateStatus.updateAvailable
                    ? Icons.system_update
                    : Icons.check_circle_outline),
            size: 64,
            color:
                (_isScanning || _result?.status == UpdateStatus.updateAvailable)
                    ? Colors.blue
                    : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText(LocalizationService t) {
    if (_isScanning) {
      return Text(
        'SCANNING SYSTEM...',
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          letterSpacing: 1.5,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (_result == null) return const SizedBox.shrink();

    final isUpdate = _result!.status == UpdateStatus.updateAvailable;

    return Column(
      children: [
        Text(
          isUpdate
              ? t.t('settingsUpdateNewMsg', {'version': _result!.latestDisplay})
              : t.t('settingsUpdateLatestMsg'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          t.t('settingsAboutVersion', {'version': _result!.currentDisplay}),
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(LocalizationService t) {
    if (_isScanning) return const SizedBox(height: 56);

    final isUpdate = _result?.status == UpdateStatus.updateAvailable;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildButton(
            label: isUpdate
                ? t.t('settingsUpdateActionUpdate')
                : t.t('settingsUpdateCheckBtn'),
            isPrimary: true,
            onTap: isUpdate ? _handleUpdate : () => _checkUpdates(),
          ),
          if (isUpdate) ...[
            const SizedBox(height: 16),
            _buildButton(
              label: t.t('settingsUpdateActionLater'),
              isPrimary: false,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildButton(
      {required String label,
      required bool isPrimary,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: isPrimary ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary
                ? Colors.blue.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isPrimary ? Colors.blue : Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  void _handleUpdate() {
    UpdateService.instance.launchStore();
  }
}
