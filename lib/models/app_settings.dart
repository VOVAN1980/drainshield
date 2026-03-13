import 'notification_settings.dart';
import 'sound_settings.dart';

class AppSettings {
  final String languageCode;
  final NotificationSettings notificationSettings;
  final SoundSettings soundSettings;
  final bool autoMonitoringEnabled;
  final int monitoringIntervalMinutes;
  final bool multiWalletMonitoringEnabled;
  final bool quietModeEnabled;
  final String quietModeStart; // HH:mm
  final String quietModeEnd; // HH:mm

  AppSettings({
    this.languageCode = 'en',
    NotificationSettings? notificationSettings,
    SoundSettings? soundSettings,
    this.autoMonitoringEnabled = false,
    this.monitoringIntervalMinutes = 60,
    this.multiWalletMonitoringEnabled = false,
    this.quietModeEnabled = false,
    this.quietModeStart = "22:00",
    this.quietModeEnd = "08:00",
  })  : notificationSettings = notificationSettings ?? NotificationSettings(),
        soundSettings = soundSettings ?? SoundSettings();

  Map<String, dynamic> toJson() => {
        'languageCode': languageCode,
        'notificationSettings': notificationSettings.toJson(),
        'soundSettings': soundSettings.toJson(),
        'autoMonitoringEnabled': autoMonitoringEnabled,
        'monitoringIntervalMinutes': monitoringIntervalMinutes,
        'multiWalletMonitoringEnabled': multiWalletMonitoringEnabled,
        'quietModeEnabled': quietModeEnabled,
        'quietModeStart': quietModeStart,
        'quietModeEnd': quietModeEnd,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        languageCode: json['languageCode'] ?? 'en',
        notificationSettings: json['notificationSettings'] != null
            ? NotificationSettings.fromJson(json['notificationSettings'])
            : null,
        soundSettings: json['soundSettings'] != null
            ? SoundSettings.fromJson(json['soundSettings'])
            : null,
        autoMonitoringEnabled: json['autoMonitoringEnabled'] ?? false,
        monitoringIntervalMinutes: json['monitoringIntervalMinutes'] ?? 60,
        multiWalletMonitoringEnabled:
            json['multiWalletMonitoringEnabled'] ?? false,
        quietModeEnabled: json['quietModeEnabled'] ?? false,
        quietModeStart: json['quietModeStart'] ?? "22:00",
        quietModeEnd: json['quietModeEnd'] ?? "08:00",
      );
}
