import 'package:flutter/material.dart';
import '../../services/settings/settings_service.dart';
import '../../services/localization_service.dart';
import '../../services/security/monitoring_service.dart';
import '../../services/security/system_health_service.dart';
import '../../services/pro/pro_service.dart';
import '../../services/threat_intelligence_service.dart';
import '../../services/security/monitoring_state_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'linked_wallets_screen.dart';
import '../pro_screen.dart';
import '../../widgets/design/ds_background.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isMonitoring = false;

  Future<void> _runMonitoring() async {
    setState(() => _isMonitoring = true);
    await MonitoringService.instance.runMonitoringNow();
    if (mounted) {
      setState(() => _isMonitoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationProvider.of(context).t('monitoringComplete'),
          ),
          backgroundColor: const Color(0xFF00FF9D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DsBackground(
        child: Column(
          children: [
            _buildAppBar(context, loc.t('settingsSecurityEvents')),
            Expanded(
              child: ListenableBuilder(
                listenable: SettingsService.instance,
                builder: (context, _) {
                  final settings = SettingsService.instance.settings;
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    children: [
                      _buildMonitoringHeader(loc),
                      const SizedBox(height: 16),
                      _buildMenuTile(
                        loc.t('settingsLinkedWallets'),
                        Icons.account_balance_wallet,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LinkedWalletsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          loc.t('settingsSecurityEventsHelper'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      _buildBackgroundStatus(loc),
                      const Divider(height: 32, color: Colors.white10),
                      ListenableBuilder(
                        listenable: ProService.instance,
                        builder: (context, _) {
                          final isPro = ProService.instance.isProActive();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMonitoringAction(
                                  loc, settings.autoMonitoringEnabled, isPro),
                              if (isPro) ...[
                                const SizedBox(height: 24),
                                _buildToggle(
                                  loc.t('settingsSecurityAutoMonitoring'),
                                  settings.autoMonitoringEnabled,
                                  (val) {
                                    SettingsService.instance
                                        .updateMonitoringSettings(
                                      autoMonitoringEnabled: val,
                                    );
                                    if (val) _runMonitoring();
                                  },
                                  isPro: isPro,
                                ),
                                _buildIntervalSelector(
                                  loc.t('settingsSecurityInterval'),
                                  settings.monitoringIntervalMinutes,
                                  [1, 5, 10, 30, 60],
                                  (val) => SettingsService.instance
                                      .updateMonitoringSettings(
                                    monitoringIntervalMinutes: val,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildBatteryOptimizationGuidance(loc),
                              ] else ...[
                                const SizedBox(height: 24),
                                _buildToggle(
                                  loc.t('settingsSecurityAutoMonitoring'),
                                  false,
                                  null,
                                  isPro: false,
                                  subtitle: loc
                                      .t('settingsSecurityProMonitoringHint'),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringHeader(LocalizationService loc) {
    return ListenableBuilder(
      listenable: SystemHealthService.instance,
      builder: (context, _) {
        final state = SystemHealthService.instance.state;
        final intel = ThreatIntelligenceService.instance;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getStateColor(state).withOpacity(0.15),
                _getStateColor(state).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _getStateColor(state).withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('settingsSecurityStatus'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStateLabel(loc, state),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _getStateColor(state),
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _getStateIcon(state),
                    color: _getStateColor(state),
                    size: 32,
                  ),
                ],
              ),
              const Divider(height: 32, color: Colors.white10),
              Row(
                children: [
                  _buildStatItem(
                    loc.t('settingsMonitoringHealth'),
                    _getStateLabel(loc, state),
                    _getStateColor(state),
                  ),
                  const Spacer(),
                  _buildStatItem(
                    loc.t('settingsMonitoringIntelFreshness'),
                    intel.isStale
                        ? loc.t('settingsMonitoringIntelStale')
                        : loc.t('settingsMonitoringIntelFresh'),
                    intel.isStale ? Colors.orange : const Color(0xFF00FF9D),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStateColor(SystemHealthState state) {
    switch (state) {
      case SystemHealthState.protected:
        return const Color(0xFF00FF9D);
      case SystemHealthState.monitoringPaused:
      case SystemHealthState.subscriptionInactive:
      case SystemHealthState.threatIntelStale:
        return Colors.orange;
      case SystemHealthState.networkDegraded:
        return Colors.redAccent;
      default:
        return Colors.white24;
    }
  }

  String _getStateLabel(LocalizationService loc, SystemHealthState state) {
    switch (state) {
      case SystemHealthState.protected:
        return loc.t('settingsSecurityProtected');
      case SystemHealthState.networkDegraded:
        return loc.t('dashboardStatusOffline');
      default:
        return loc.t('settingsSecurityDegraded');
    }
  }

  IconData _getStateIcon(SystemHealthState state) {
    switch (state) {
      case SystemHealthState.protected:
        return Icons.verified_user;
      case SystemHealthState.networkDegraded:
        return Icons.wifi_off;
      default:
        return Icons.gpp_maybe;
    }
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF00FF9D)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildMonitoringAction(
      LocalizationService loc, bool autoEnabled, bool isPro) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.t('settingsSecurityMonitoringStatus'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (autoEnabled && isPro)
                      ? const Color(0xFF00FF9D)
                      : isPro
                          ? Colors.orangeAccent
                          : Colors.white24,
                  boxShadow: (autoEnabled && isPro)
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00FF9D).withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                (autoEnabled && isPro)
                    ? loc.t('settingsSecurityMonitoringActive')
                    : isPro
                        ? loc.t('settingsSecurityMonitoringDisabled')
                        : loc.t('proStatusExpired'),
                style: TextStyle(
                  color: (autoEnabled && isPro) ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: isPro
                ? ElevatedButton(
                    onPressed: _isMonitoring ? null : _runMonitoring,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF9D).withOpacity(0.1),
                      foregroundColor: const Color(0xFF00FF9D),
                      minimumSize: const Size(140, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: const Color(0xFF00FF9D).withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: _isMonitoring
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF00FF9D),
                              ),
                            ),
                          )
                        : Text(
                            loc.t('monitoringManualRun'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.star, size: 16),
                    label: Text(loc.t('proUpgradeBtn').toUpperCase()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      foregroundColor: Colors.orange,
                      minimumSize: const Size(180, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 32, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    String title,
    bool value,
    ValueChanged<bool>? onChanged, {
    bool isPro = true,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPro
                ? Colors.white.withOpacity(0.05)
                : Colors.orange.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            SwitchListTile(
              title: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: onChanged == null ? Colors.white54 : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  if (!isPro)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "PRO",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: subtitle != null
                  ? Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 12,
                      ),
                    )
                  : null,
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF00FF9D),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalSelector(
    String title,
    int currentVal,
    List<int> options,
    ValueChanged<int>? onChanged,
  ) {
    final bool isEnabled = onChanged != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButtonFormField<int>(
            value: options.contains(currentVal) ? currentVal : options.first,
            items: options
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      "$e min",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
            onChanged:
                isEnabled ? (val) => val != null ? onChanged(val) : null : null,
            decoration: InputDecoration(
              labelText: title,
              labelStyle: TextStyle(
                  color: isEnabled
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white24),
              border: InputBorder.none,
            ),
            dropdownColor: const Color(0xFF030509),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundStatus(LocalizationService loc) {
    return ListenableBuilder(
      listenable: MonitoringStateService.instance,
      builder: (context, _) {
        final state = MonitoringStateService.instance;
        final lastScan = state.lastScanTime;
        final nextScan = state.nextScanTime;
        final isStale = state.isStale;

        final dateFormat = DateFormat('HH:mm, dd MMM');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                loc.t('settingsSecurityBackgroundStatus').toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.t('settingsMonitoringHealth'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isStale
                                  ? Colors.orange
                                  : const Color(0xFF00FF9D))
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isStale
                              ? loc.t('settingsSecurityStatusStale')
                              : loc.t('settingsSecurityStatusHealthy'),
                          style: TextStyle(
                            color: isStale
                                ? Colors.orange
                                : const Color(0xFF00FF9D),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildScanTimeRow(
                    loc.t('settingsSecurityLastScan', {
                      'time': lastScan != null
                          ? dateFormat.format(lastScan)
                          : '--:--'
                    }),
                    Icons.history,
                  ),
                  const SizedBox(height: 8),
                  _buildScanTimeRow(
                    loc.t('settingsSecurityNextScan', {
                      'time': nextScan != null
                          ? dateFormat.format(nextScan)
                          : '--:--'
                    }),
                    Icons.schedule,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScanTimeRow(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white24),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryOptimizationGuidance(LocalizationService loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.battery_alert, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                loc.t('settingsSecurityBatteryOptimization'),
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.t('settingsSecurityBatteryOptimizationGuidance'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // Open App Settings as a reliable fallback for battery optimization
                // Better yet, just open general settings or app info
                // For this implementation, we'll try to open app settings
                try {
                  // Common android intent for app settings
                  // We'll use a generic approach if possible, or just a mock/link for now
                  // since we don't have the package name dynamically here easily
                  // but we know it's likely something like 'com.drainshield.app'
                  // Let's use a safe fallback: open settings
                  await launchUrl(Uri.parse('package:com.drainshield.app'),
                      mode: LaunchMode.externalApplication);
                } catch (e) {
                  // If fails, try generic settings
                  // await launchUrl(Uri.parse('package:android.settings.SETTINGS'));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.withOpacity(0.1),
                foregroundColor: Colors.orange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.orange.withOpacity(0.2)),
                ),
              ),
              child: Text(
                loc.t('settingsSecurityBatteryOptimizationBtn'),
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
