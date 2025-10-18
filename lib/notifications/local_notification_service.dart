import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize notification settings for Android & iOS
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // your app icon

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle tap on notification
        debugPrint('🔔 Notification clicked: ${response.payload}');
      },
    );
  }

  /// Show a notification when received in background or terminated state
  static Future<void> show(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel', // channel ID
          'High Importance Notifications', // channel name
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _notificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: message.data['route'], // Optional: to open specific screens
    );
  }
}

// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class LocalNotificationService {
//   static final FlutterLocalNotificationsPlugin _plugin =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> init() async {
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosInit = DarwinInitializationSettings();
//     const initSettings =
//         InitializationSettings(android: androidInit, iOS: iosInit);
//     await _plugin.initialize(initSettings);
//   }

//   static Future<void> show(RemoteMessage message) async {
//     const androidDetails = AndroidNotificationDetails(
//       'chat_channel',
//       'Chat Notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//     );

//     const iosDetails = DarwinNotificationDetails();

//     const notificationDetails =
//         NotificationDetails(android: androidDetails, iOS: iosDetails);

//     await _plugin.show(
//       0,
//       message.notification?.title ?? 'New Message',
//       message.notification?.body ?? 'You have a new message',
//       notificationDetails,
//     );
//   }
// }
