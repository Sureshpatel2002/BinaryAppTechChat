import 'dart:developer'; // ✅ Correct import

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _showNotification(message);
}

/// Show system notification
Future<void> _showNotification(RemoteMessage message) async {
  const androidDetails = AndroidNotificationDetails(
    'chat_channel',
    'Chat Notifications',
    channelDescription: 'Channel for chat messages',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );
  const platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    message.notification?.title ?? 'New Message',
    message.notification?.body ?? '',
    platformDetails,
    payload: message.data['chatId'],
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseMessaging.instance.setAutoInitEnabled(true);


  // Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Local notification setup
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) async {
      if (response.payload != null) {
        Get.toNamed('/chat', arguments: {'chatId': response.payload});
      }
    },
  );

  // Notification permissions
  final settings = await FirebaseMessaging.instance.requestPermission();
  log('[FCM] Permission: ${settings.authorizationStatus}');

  // Foreground handler
  FirebaseMessaging.onMessage.listen(_showNotification);

  // Background tap handler
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final chatId = message.data['chatId'];
    if (chatId != null) {
      Get.toNamed('/chat', arguments: {'chatId': chatId});
    }
  });

  // FCM token
  final token = await FirebaseMessaging.instance.getToken();
  log('[FCM TOKEN] $token');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BinaryAppTech',
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.initial, // Start with splash
      getPages: AppPages.routes,
    );
  }
}
