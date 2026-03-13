import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_settings.dart';
import '../../models/notification_settings.dart';
import '../../models/sound_settings.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  static const String _key = 'app_settings';
  AppSettings _settings = AppSettings();

  AppSettings get settings => _settings;

  Future<void> init() async {
    await load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(jsonStr);
        _settings = AppSettings.fromJson(jsonMap);
      } catch (e) {
        _settings = AppSettings();
      }
    } else {
      _settings = AppSettings();
    }
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(_settings.toJson());
    await prefs.setString(_key, jsonStr);
    notifyListeners();
  }

  Future<void> updateNotificationSettings(
    NotificationSettings newSettings,
  ) async {
    _settings = AppSettings(
      languageCode: _settings.languageCode,
      notificationSettings: newSettings,
      soundSettings: _settings.soundSettings,
      autoMonitoringEnabled: _settings.autoMonitoringEnabled,
      monitoringIntervalMinutes: _settings.monitoringIntervalMinutes,
      multiWalletMonitoringEnabled: _settings.multiWalletMonitoringEnabled,
    );
    await save();
  }

  Future<void> updateSoundSettings(SoundSettings newSettings) async {
    _settings = AppSettings(
      languageCode: _settings.languageCode,
      notificationSettings: _settings.notificationSettings,
      soundSettings: newSettings,
      autoMonitoringEnabled: _settings.autoMonitoringEnabled,
      monitoringIntervalMinutes: _settings.monitoringIntervalMinutes,
      multiWalletMonitoringEnabled: _settings.multiWalletMonitoringEnabled,
    );
    await save();
  }

  Future<void> updateLanguage(String languageCode) async {
    _settings = AppSettings(
      languageCode: languageCode,
      notificationSettings: _settings.notificationSettings,
      soundSettings: _settings.soundSettings,
      autoMonitoringEnabled: _settings.autoMonitoringEnabled,
      monitoringIntervalMinutes: _settings.monitoringIntervalMinutes,
      multiWalletMonitoringEnabled: _settings.multiWalletMonitoringEnabled,
    );
    await save();
  }

  Future<void> updateMonitoringSettings({
    bool? autoMonitoringEnabled,
    int? monitoringIntervalMinutes,
    bool? multiWalletMonitoringEnabled,
  }) async {
    _settings = AppSettings(
      languageCode: _settings.languageCode,
      notificationSettings: _settings.notificationSettings,
      soundSettings: _settings.soundSettings,
      autoMonitoringEnabled:
          autoMonitoringEnabled ?? _settings.autoMonitoringEnabled,
      monitoringIntervalMinutes:
          monitoringIntervalMinutes ?? _settings.monitoringIntervalMinutes,
      multiWalletMonitoringEnabled: multiWalletMonitoringEnabled ??
          _settings.multiWalletMonitoringEnabled,
      quietModeEnabled: _settings.quietModeEnabled,
      quietModeStart: _settings.quietModeStart,
      quietModeEnd: _settings.quietModeEnd,
    );
    await save();
  }

  Future<void> updateQuietMode({
    bool? enabled,
    String? start,
    String? end,
  }) async {
    _settings = AppSettings(
      languageCode: _settings.languageCode,
      notificationSettings: _settings.notificationSettings,
      soundSettings: _settings.soundSettings,
      autoMonitoringEnabled: _settings.autoMonitoringEnabled,
      monitoringIntervalMinutes: _settings.monitoringIntervalMinutes,
      multiWalletMonitoringEnabled: _settings.multiWalletMonitoringEnabled,
      quietModeEnabled: enabled ?? _settings.quietModeEnabled,
      quietModeStart: start ?? _settings.quietModeStart,
      quietModeEnd: end ?? _settings.quietModeEnd,
    );
    await save();
  }
}
