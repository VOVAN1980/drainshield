import 'package:flutter/material.dart';
import '../../services/settings/settings_service.dart';
import '../../services/localization_service.dart';
import '../../services/alerts/sound_service.dart';
import '../../services/alerts/notification_service.dart';
import '../../widgets/design/ds_background.dart';
import '../../models/sound_settings.dart';

class SoundsSettingsScreen extends StatefulWidget {
  const SoundsSettingsScreen({super.key});

  @override
  State<SoundsSettingsScreen> createState() => _SoundsSettingsScreenState();
}

class _SoundsSettingsScreenState extends State<SoundsSettingsScreen> {
  bool _isPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.instance.isPermissionGranted();
    if (mounted) setState(() => _isPermissionGranted = granted);
  }

  @override
  void dispose() {
    SoundService.instance.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationProvider.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DsBackground(
        child: Column(
          children: [
            _buildAppBar(context, loc.t('settingsSound')),
            Expanded(
              child: ListenableBuilder(
                listenable: SettingsService.instance,
                builder: (context, _) {
                  final settings =
                      SettingsService.instance.settings.soundSettings;
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    children: [
                      if (!_isPermissionGranted) _buildPermissionWarning(loc),
                      // SECTION: MAIN
                      _buildSectionHeader(loc.t('settingsSoundSectionMain')),
                      _buildToggle(
                        loc.t('settingsSoundEnabled'),
                        settings.soundEnabled,
                        (val) {
                          if (!val) SoundService.instance.stopAll();
                          _update(settings.copyWith(soundEnabled: val));
                        },
                      ),
                      _buildToggle(
                        loc.t('settingsVibrationEnabled'),
                        settings.vibrationEnabled,
                        (val) {
                          if (!val) SoundService.instance.stopVibration();
                          _update(settings.copyWith(vibrationEnabled: val));
                        },
                      ),
                      const SizedBox(height: 16),

                      // SECTION: NOTIFICATIONS
                      _buildSectionHeader(
                        loc.t('settingsSoundSectionNotifications'),
                      ),
                      _buildSelector(
                        context,
                        loc.t('settingsSoundAlertSelect'),
                        settings.selectedAlertSoundId,
                        SoundSettings.alertSounds,
                        (val) {
                          _update(settings.copyWith(selectedAlertSoundId: val));
                          SoundService.instance.previewAlertSound(val);
                        },
                        () => SoundService.instance.previewAlertSound(
                          settings.selectedAlertSoundId,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SECTION: CRITICAL THREATS
                      _buildSectionHeader(
                        loc.t('settingsSoundSectionCritical'),
                      ),
                      _buildToggle(
                        loc.t('settingsSoundCriticalAlarm'),
                        settings.criticalAlarmEnabled,
                        (val) => _update(
                          settings.copyWith(criticalAlarmEnabled: val),
                        ),
                      ),
                      _buildSelector(
                        context,
                        loc.t('settingsSoundCriticalSelect'),
                        settings.selectedCriticalSoundId,
                        SoundSettings.criticalSounds,
                        (val) {
                          _update(
                            settings.copyWith(selectedCriticalSoundId: val),
                          );
                          SoundService.instance.previewCriticalSound(val);
                        },
                        () => SoundService.instance.previewCriticalSound(
                          settings.selectedCriticalSoundId,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SECTION: PANIC MODE
                      _buildSectionHeader(loc.t('settingsSoundSectionPanic')),
                      _buildToggle(
                        loc.t('settingsSoundPanicAlarm'),
                        settings.panicAlarmEnabled,
                        (val) =>
                            _update(settings.copyWith(panicAlarmEnabled: val)),
                      ),
                      _buildSelector(
                        context,
                        loc.t('settingsSoundPanicSelect'),
                        settings.selectedPanicSoundId,
                        SoundSettings.panicSounds,
                        (val) {
                          _update(settings.copyWith(selectedPanicSoundId: val));
                          SoundService.instance.previewPanicSound(val);
                        },
                        () => SoundService.instance.previewPanicSound(
                          settings.selectedPanicSoundId,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SECTION: TESTING
                      _buildSectionHeader(loc.t('settingsSoundSectionTesting')),
                      _buildTestButton(
                        context,
                        loc.t('settingsSoundTestAudio'),
                        Icons.audiotrack,
                        () => SoundService.instance.previewCriticalSound(
                          settings.selectedCriticalSoundId,
                        ),
                      ),
                      _buildTestButton(
                        context,
                        loc.t('settingsSoundTestNotification'),
                        Icons.notification_important,
                        () {
                          // Stop any current sound to avoid overlap
                          SoundService.instance.stopAll();
                          // Show system notification
                          NotificationService.instance.showCriticalAlert(
                            loc.t('testNotificationTitle'),
                            loc.t('testNotificationBody'),
                          );
                        },
                      ),
                      _buildTestButton(
                        context,
                        loc.t('settingsSoundTestVibration'),
                        Icons.vibration,
                        () => SoundService.instance.stopAll().then((_) {
                          // Just a short vibe check
                          SoundService.instance.previewAlertSound(
                            settings.selectedAlertSoundId,
                          );
                        }),
                      ),
                      const SizedBox(height: 32),
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

  Widget _buildPermissionWarning(LocalizationService loc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4B4B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF4B4B).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFFF4B4B), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    loc.t('settingsNotificationPermissionDenied'),
                    style: const TextStyle(
                      color: Color(0xFFFF4B4B),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => NotificationService.instance.init().then((_) {
                  _checkPermission();
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4B4B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(loc.t('settingsNotificationPermissionEnableBtn')),
              ),
            ),
          ],
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
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

  Widget _buildToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF00FF9D),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildSelector(
    BuildContext context,
    String title,
    String currentId,
    List<String> options,
    ValueChanged<String> onChanged,
    VoidCallback onPlayPreview,
  ) {
    final loc = LocalizationProvider.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4, right: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: currentId,
                  items: options
                      .map(
                        (id) => DropdownMenuItem(
                          value: id,
                          child: Text(
                            loc.t('sound_$id'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => val != null ? onChanged(val) : null,
                  decoration: InputDecoration(
                    labelText: title,
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                  ),
                  dropdownColor: const Color(0xFF030509),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.play_circle_outline,
                color: Color(0xFF00FF9D),
                size: 28,
              ),
              onPressed: onPlayPreview,
              tooltip: loc.t('preview'), // Optional, will failback if missing
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF00FF9D), size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white24,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _update(SoundSettings newSettings) {
    SettingsService.instance.updateSoundSettings(newSettings);
  }
}
