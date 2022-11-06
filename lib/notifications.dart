import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class Notifications {
  static Future initialize(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    const androidInit = AndroidInitializationSettings('mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    debugPrint('In init for notifs.');
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  static Future showBigTextNotification(
      {required String title,
      required String body,
      var payload,
      required FlutterLocalNotificationsPlugin fln}) async {
    debugPrint('hello');
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('shima_activate', 'shima_default_channel',
            importance: Importance.max, priority: Priority.high);
    const notification = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails());
    await fln.show(0, title, body, notification);
  }
}
