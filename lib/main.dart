import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'app/modules/auth/auth_controller.dart';
import 'app/routes/app_pages.dart';
import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _showNotification(message);
}

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

late final bool isLogin;
late final String initialRoute;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

  final settings = await FirebaseMessaging.instance.requestPermission();
  log('[FCM] Permission: ${settings.authorizationStatus}');

  FirebaseMessaging.onMessage.listen(_showNotification);
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final chatId = message.data['chatId'];
    if (chatId != null) {
      Get.toNamed('/chat', arguments: {'chatId': chatId});
    }
  });

  final token = await FirebaseMessaging.instance.getToken();
  log('[FCM TOKEN] $token');

  final user = FirebaseAuth.instance.currentUser;
  isLogin = user != null;
  initialRoute = isLogin ? Routes.home : Routes.auth;

  if (isLogin) {
    final authController = Get.put(AuthController());
    authController.setOnlineStatus(true);
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AuthController authController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (isLogin) {
      authController = Get.find<AuthController>();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isLogin) return;

    if (state == AppLifecycleState.resumed) {
      authController.setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      authController.setOnlineStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BinaryAppTech',
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    );
  }
}
