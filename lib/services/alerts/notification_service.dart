import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../main.dart'; // Import navigatorKey
import '../../screens/scan_screen.dart';
import '../../screens/settings/subscription_screen.dart';
import '../settings/settings_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    tz.initializeTimeZones();

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    // Check for cold-start notification
    final details = await _notifications.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      final payload = details.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        try {
          final data = json.decode(payload);
          // Wait a bit for navigationKey to be ready
          Future.delayed(
              const Duration(seconds: 1), () => _handleRouting(data));
        } catch (e) {
          debugPrint('[NotificationService] Cold start payload error: $e');
        }
      }
    }
  }

  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final Map<String, dynamic> data = json.decode(payload);
      _handleRouting(data);
    } catch (e) {
      debugPrint('[NotificationService] Failed to parse payload: $e');
    }
  }

  void _handleRouting(Map<String, dynamic> data) {
    final type = data['type'];
    final state = navigatorKey.currentState;
    if (state == null) {
      debugPrint(
          '[NotificationService] Navigator state is null, cannot route.');
      return;
    }

    final walletAddress = data['walletAddress'] as String?;

    switch (type) {
      case 'security_alert':
        if (walletAddress != null) {
          final metadata = data['metadata'] as Map<String, dynamic>?;
          final spender = metadata?['spender'] as String?;
          final token = metadata?['token'] as String?;

          debugPrint(
              '[NotificationService] Deep linking to ScanScreen for $walletAddress (Highlight: $spender / $token)');
          state.pushReplacement(
            MaterialPageRoute(
              builder: (_) => ScanScreen(
                address: walletAddress,
                highlightSpender: spender,
                highlightToken: token,
              ),
            ),
          );
        } else {
          _goHome(state);
        }
        break;
      case 'subscription_expiry':
        debugPrint('[NotificationService] Deep linking to SubscriptionScreen');
        // We'll import it below
        _goToSubscription(state);
        break;
      default:
        _goHome(state);
    }
  }

  void _goHome(NavigatorState state) {
    // Fallback to Dashboard/Initial route if we can't find specific context
    state.popUntil((route) => route.isFirst);
  }

  void _goToSubscription(NavigatorState state) {
    // We need to import the screen
    // For now, let's assume it's available or we'll add the import
    // Note: To be minimally invasive, we use MaterialPageRoute
    state.push(
      MaterialPageRoute(
        builder: (_) => const SubscriptionScreen(),
      ),
    );
  }

  Future<void> showCriticalAlert(String title, String body,
      {Map<String, dynamic>? payload}) async {
    if (_isQuietMode()) {
      debugPrint('[NotificationService] Muted by Quiet Mode: $title');
      return;
    }
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'critical_threats',
      'Critical Threats',
      channelDescription: 'Emergency alerts for token theft detection',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      color: Color(0xFFFF4B4B),
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      0,
      title,
      body,
      platformDetails,
      payload: payload != null ? json.encode(payload) : null,
    );
  }

  bool _isQuietMode() {
    final settings = SettingsService.instance.settings;
    if (!settings.quietModeEnabled) return false;

    try {
      final now = DateTime.now();
      final startParts =
          settings.quietModeStart.split(':').map(int.parse).toList();
      final endParts = settings.quietModeEnd.split(':').map(int.parse).toList();

      final startTime =
          DateTime(now.year, now.month, now.day, startParts[0], startParts[1]);
      var endTime =
          DateTime(now.year, now.month, now.day, endParts[0], endParts[1]);

      if (endTime.isBefore(startTime)) {
        // Quiet mode spans midnight
        if (now.isAfter(startTime)) {
          return true;
        }
        if (now.isBefore(endTime)) {
          return true;
        }
        return false;
      } else {
        return now.isAfter(startTime) && now.isBefore(endTime);
      }
    } catch (e) {
      debugPrint('[NotificationService] Error checking quiet mode: $e');
      return false;
    }
  }

  Future<void> showWarningAlert(String title, String body,
      {Map<String, dynamic>? payload}) async {
    if (_isQuietMode()) return;
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'security_warnings',
      'Security Warnings',
      channelDescription: 'Alerts for high-risk approvals',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      1,
      title,
      body,
      platformDetails,
      payload: payload != null ? json.encode(payload) : null,
    );
  }

  Future<void> showInfoAlert(String title, String body,
      {Map<String, dynamic>? payload}) async {
    if (_isQuietMode()) return;
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'general_info',
      'General Information',
      channelDescription: 'Status updates and scan results',
      importance: Importance.low,
      priority: Priority.low,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      2,
      title,
      body,
      platformDetails,
      payload: payload != null ? json.encode(payload) : null,
    );
  }

  Future<void> scheduleSubscriptionExpiry(DateTime expiryDate) async {
    // Cancel any previous expiry notifications to avoid duplicates
    // We'll use specific IDs for expiry: 107 (7 days), 103 (3 days), 101 (1 day)
    await _notifications.cancel(107);
    await _notifications.cancel(103);
    await _notifications.cancel(101);

    final now = DateTime.now();

    void scheduleAt(int daysBefore, int id) async {
      final scheduledDate = expiryDate.subtract(Duration(days: daysBefore));
      // Set to 10:00 AM on that day
      final finalScheduled = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        10,
        0,
      );

      if (finalScheduled.isAfter(now)) {
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
          'subscription_alerts',
          'Subscription Alerts',
          channelDescription: 'Reminders for subscription renewal',
          importance: Importance.high,
          priority: Priority.high,
        );

        const NotificationDetails platformDetails = NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(),
        );

        final daysLeft = daysBefore == 0 ? "today" : "in $daysBefore days";
        final body = daysBefore == 0
            ? "Your PRO subscription expires today! Renew now to keep your wallets protected."
            : "Your PRO subscription will expire $daysLeft. Don't forget to renew!";

        await _notifications.zonedSchedule(
          id,
          'Subscription Reminder',
          body,
          tz.TZDateTime.from(finalScheduled, tz.local),
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }

    scheduleAt(7, 107);
    scheduleAt(3, 103);
    scheduleAt(1, 101);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
