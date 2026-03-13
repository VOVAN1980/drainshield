import 'package:flutter/material.dart';
import '../../services/settings/settings_service.dart';
import '../../services/localization_service.dart';
import '../../widgets/design/ds_background.dart';
import '../../models/notification_settings.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DsBackground(
        child: Column(
          children: [
            _buildAppBar(context, loc.t('settingsNotifications')),
            Expanded(
              child: ListenableBuilder(
                listenable: SettingsService.instance,
                builder: (context, _) {
                  final settings =
                      SettingsService.instance.settings.notificationSettings;
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    children: [
                      _buildSectionHeader(loc.t('settingsQuietMode')),
                      _buildToggle(
                        loc.t('settingsQuietMode'),
                        SettingsService.instance.settings.quietModeEnabled,
                        (val) => SettingsService.instance
                            .updateQuietMode(enabled: val),
                        subtitle: loc.t('settingsQuietModeHelper'),
                      ),
                      if (SettingsService
                          .instance.settings.quietModeEnabled) ...[
                        _buildTimeRow(
                          context,
                          loc.t('settingsQuietStart'),
                          SettingsService.instance.settings.quietModeStart,
                          (time) => SettingsService.instance
                              .updateQuietMode(start: time),
                        ),
                        _buildTimeRow(
                          context,
                          loc.t('settingsQuietEnd'),
                          SettingsService.instance.settings.quietModeEnd,
                          (time) => SettingsService.instance
                              .updateQuietMode(end: time),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildSectionHeader(loc.t('settingsNotifications')),
                      _buildToggle(
                        loc.t('settingsNotificationsCritical'),
                        settings.criticalThreatAlerts,
                        (val) => _update(
                          settings.copyWith(criticalThreatAlerts: val),
                        ),
                        isCritical: true,
                      ),
                      _buildToggle(
                        loc.t('settingsNotificationsHighRisk'),
                        settings.highRiskApprovalAlerts,
                        (val) => _update(
                          settings.copyWith(highRiskApprovalAlerts: val),
                        ),
                      ),
                      _buildToggle(
                        loc.t('settingsNotificationsUnlimited'),
                        settings.unlimitedApprovalAlerts,
                        (val) => _update(
                          settings.copyWith(unlimitedApprovalAlerts: val),
                        ),
                      ),
                      _buildToggle(
                        loc.t('settingsNotificationsThreatDb'),
                        settings.threatDatabaseAlerts,
                        (val) => _update(
                          settings.copyWith(threatDatabaseAlerts: val),
                        ),
                      ),
                      _buildToggle(
                        loc.t('settingsNotificationsPanic'),
                        settings.panicAlerts,
                        (val) => _update(settings.copyWith(panicAlerts: val)),
                      ),
                      _buildToggle(
                        loc.t('settingsNotificationsRevoke'),
                        settings.revokeResultAlerts,
                        (val) =>
                            _update(settings.copyWith(revokeResultAlerts: val)),
                      ),
                      _buildToggle(
                        loc.t('settingsNotificationsSubscription'),
                        settings.subscriptionReminders,
                        (val) => _update(
                          settings.copyWith(subscriptionReminders: val),
                        ),
                      ),
                      _buildToggle(
                        loc.t('settingsNotificationsMonitoring'),
                        settings.monitoringHealthAlerts,
                        (val) => _update(
                          settings.copyWith(monitoringHealthAlerts: val),
                        ),
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

  void _update(NotificationSettings newSettings) {
    SettingsService.instance.updateNotificationSettings(newSettings);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4, top: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildToggle(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
    bool isCritical = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCritical
                ? Colors.red.withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: SwitchListTile(
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isCritical ? Colors.redAccent : Colors.white,
              fontSize: 15,
              fontWeight: isCritical ? FontWeight.bold : FontWeight.normal,
            ),
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
          activeColor: isCritical ? Colors.redAccent : const Color(0xFF00FF9D),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(BuildContext context, String title, String value,
      ValueChanged<String> onTimeSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          final parts = value.split(':');
          final initialTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
          );

          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: initialTime,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF00FF9D),
                    onPrimary: Colors.black,
                    surface: Color(0xFF161B22),
                    onSurface: Colors.white,
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00FF9D),
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );

          if (picked != null) {
            final String formatted =
                '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
            onTimeSelected(formatted);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70)),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF00FF9D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
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
}
