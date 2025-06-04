// import 'dart:convert';

// import 'package:floaty/features/notifications/controllers/notification.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:floaty/features/logs/repositories/log_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// const firebaseOptions = FirebaseOptions(
//   apiKey: 'AIzaSyBIKRtWt3dwPSku43xTjMZ5I9arp7Hm7zs',
//   appId: '1:430361853609:android:d92021ba319938ea83b3b8',
//   messagingSenderId: '430361853609',
//   projectId: 'floaty-notif-test',
// );

// void showNotification(RemoteMessage message) async {
//   final notification = message.notification;

//   final notificationData = message.data;

//   LogService.logInfo(notificationData.toString());

//   LogService.logDebug("parsed!");

//   flutterLocalNotificationsPlugin.show(
//     notification.hashCode,
//     notification?.title,
//     notification?.body,
//     NotificationDetails(
//       android: AndroidNotificationDetails(
//         channel.id,
//         channel.name,
//         channelDescription: channel.description,
//         icon: 'mipmap/launcher_icon',
//       ),
//     ),
//   );
// }

// Future<void> setupFirebaseMessaging() async {
//   await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
//     alert: true,
//     badge: true,
//     sound: true,
//   );

//   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//     LogService.logInfo('Foreground message received: ${message.messageId}');
//     showNotification(message);
//   });
// }

// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: firebaseOptions);
//   showNotification(message);
//   LogService.logInfo('Background message handled: ${jsonEncode(message.data)}');
// }

// void registerBackgroundHandler() {
//   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
// }
