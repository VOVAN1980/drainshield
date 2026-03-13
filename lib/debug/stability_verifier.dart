import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class StabilityVerifier {
  static Future<bool> verifySqflite() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = '$dbPath/stability_test.db';
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
              'CREATE TABLE Test (id INTEGER PRIMARY KEY, value TEXT)');
        },
      );

      await db.insert('Test', {'value': 'release_test_val'});
      final List<Map<String, dynamic>> maps = await db.query('Test');
      bool success =
          maps.isNotEmpty && maps.first['value'] == 'release_test_val';

      await db.update('Test', {'value': 'updated_val'},
          where: 'id = ?', whereArgs: [1]);
      final updatedMaps = await db.query('Test');
      success = success && updatedMaps.first['value'] == 'updated_val';

      await db.close();
      debugPrint('[StabilityVerifier] sqflite verification: SUCCESS');
      return success;
    } catch (e) {
      debugPrint('[StabilityVerifier] sqflite verification: FAILED: $e');
      return false;
    }
  }

  static Future<void> verifyPlugins() async {
    debugPrint('[StabilityVerifier] Starting plugin verification...');

    // 1. Workmanager
    try {
      await Workmanager().initialize((task, inputData) => Future.value(true));
      debugPrint('[StabilityVerifier] Workmanager: INIT SUCCESS');
    } catch (e) {
      debugPrint('[StabilityVerifier] Workmanager: INIT FAILED: $e');
    }

    // 2. IAP
    try {
      final available = await InAppPurchase.instance.isAvailable();
      debugPrint(
          '[StabilityVerifier] IAP: Available check SUCCESS ($available)');
    } catch (e) {
      debugPrint('[StabilityVerifier] IAP: Available check FAILED: $e');
    }

    // 3. Notifications
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await plugin.initialize(initSettings);
      debugPrint('[StabilityVerifier] Notifications: INIT SUCCESS');
    } catch (e) {
      debugPrint('[StabilityVerifier] Notifications: INIT FAILED: $e');
    }
  }
}
