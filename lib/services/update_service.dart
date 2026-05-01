import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class UpdateService {
  static final UpdateService instance = UpdateService._internal();
  UpdateService._internal();

  static const String appId = 'app.drainshield.guard';
  static const String versionUrl =
      'https://vovan1980.github.io/drainshield/version.json';

  // Default fallback URL if JSON fetch fails or doesn't provide one
  static const String defaultPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=$appId';
  static const String defaultAppStoreUrl =
      'https://apps.apple.com/app/id6739669566';

  String? _cachedUpdateUrl;

  Future<void> initBackground() async {
    // This will be called from Workmanager callback
    // Background task usually doesn't show UI dialogs, just notifications
    await checkForUpdates(isAutoCheck: true);
  }

  Future<UpdateCheckResult> checkForUpdates({bool isAutoCheck = false}) async {
    try {
      if (isAutoCheck && !await _shouldCheckNow()) {
        return UpdateCheckResult(status: UpdateStatus.upToDate);
      }

      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String localVersion = packageInfo.version;
      final int localBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final remoteData = await _getRemoteVersionData();
      if (remoteData == null) {
        return UpdateCheckResult(
            status: isAutoCheck ? UpdateStatus.upToDate : UpdateStatus.error);
      }

      final String remoteVersion = remoteData['version'] ?? '0.0.0';
      final int remoteBuild = remoteData['build'] ?? 0;
      _cachedUpdateUrl = remoteData['url'];

      if (_isUpdateAvailable(
          localVersion, localBuild, remoteVersion, remoteBuild)) {
        if (isAutoCheck) {
          await _updateLastCheckTime();
        }
        return UpdateCheckResult(
          status: UpdateStatus.updateAvailable,
          localVersion: localVersion,
          localBuild: localBuild,
          remoteVersion: remoteVersion,
          remoteBuild: remoteBuild,
          updateUrl: _cachedUpdateUrl,
        );
      }

      if (isAutoCheck) {
        await _updateLastCheckTime();
      }

      return UpdateCheckResult(
        status: UpdateStatus.upToDate,
        localVersion: localVersion,
        localBuild: localBuild,
        remoteVersion: remoteVersion,
        remoteBuild: remoteBuild,
      );
    } catch (e) {
      debugPrint('[UpdateService] Error checking for updates: $e');
      return UpdateCheckResult(
          status: isAutoCheck ? UpdateStatus.upToDate : UpdateStatus.error);
    }
  }

  Future<Map<String, dynamic>?> _getRemoteVersionData() async {
    try {
      final response = await http.get(
          Uri.parse('$versionUrl?t=${DateTime.now().millisecondsSinceEpoch}'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[UpdateService] Failed to fetch version.json: $e');
    }
    return null;
  }

  bool _isUpdateAvailable(
      String localV, int localB, String remoteV, int remoteB) {
    try {
      final v1 = localV.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final v2 = remoteV.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      // Compare major.minor.patch
      for (var i = 0; i < 3; i++) {
        final val1 = i < v1.length ? v1[i] : 0;
        final val2 = i < v2.length ? v2[i] : 0;
        if (val2 > val1) return true;
        if (val2 < val1) return false;
      }

      // If versions are equal, compare build numbers
      return remoteB > localB;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _shouldCheckNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt('last_update_check_ms') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      // 12 hours = 12 * 60 * 60 * 1000 ms
      const twelveHours = 12 * 60 * 60 * 1000;
      return (now - lastCheck) > twelveHours;
    } catch (_) {
      return true;
    }
  }

  Future<void> _updateLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_update_check_ms', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> launchStore({String? customUrl}) async {
    final url = customUrl ??
        _cachedUpdateUrl ??
        (Platform.isAndroid ? defaultPlayStoreUrl : defaultAppStoreUrl);
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}

enum UpdateStatus { upToDate, updateAvailable, error }

class UpdateCheckResult {
  final UpdateStatus status;
  final String? localVersion;
  final int? localBuild;
  final String? remoteVersion;
  final int? remoteBuild;
  final String? updateUrl;

  UpdateCheckResult({
    required this.status,
    this.localVersion,
    this.localBuild,
    this.remoteVersion,
    this.remoteBuild,
    this.updateUrl,
  });

  String get currentDisplay => localVersion != null
      ? (localBuild != null ? '$localVersion ($localBuild)' : localVersion!)
      : '---';
  String get latestDisplay => remoteVersion != null
      ? (remoteBuild != null ? '$remoteVersion ($remoteBuild)' : remoteVersion!)
      : '---';
}
