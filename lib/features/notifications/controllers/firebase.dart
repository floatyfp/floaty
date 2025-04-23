import 'dart:convert';

import 'package:floaty/features/notifications/controllers/notification.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:floaty/features/logs/repositories/log_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const firebaseOptions = FirebaseOptions(
  // hey floatplane devs if your reading this you didnt see the next 4 lines.
  apiKey: "AIzaSyAqwux9m8G0-s7YLJUGlJ6b8F4k2o_VyYU",
  appId: "1:405578561317:android:fc41c653d146bee5",
  messagingSenderId: "405578561317",
  projectId: "floatplane-production",
);

void showNotification(RemoteMessage message) async {
  final notification = message.notification;

  final notificationData = message.data;

  LogService.logInfo(notificationData.toString());

  LogService.logDebug("parsed!");

  flutterLocalNotificationsPlugin.show(
    notification.hashCode,
    notificationData.toString(),
    null,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        icon: 'mipmap/launcher_icon',
      ),
    ),
  );
}

Future<void> setupFirebaseMessaging() async {
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    LogService.logInfo('Foreground message received: ${message.messageId}');
    showNotification(message);
  });
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: firebaseOptions);
  showNotification(message);
  LogService.logInfo('Background message handled: ${jsonEncode(message.data)}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}
