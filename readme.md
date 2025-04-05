// 📁 lib/main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Initialize Firebase here

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Firebase Chat',
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}

// 📁 lib/app/routes/app_pages.dart
import 'package:get/get.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/auth_view.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/chat/chat_binding.dart';
import '../modules/chat/chat_view.dart';

part 'app_routes.dart';

class AppPages {
  static const initial = Routes.auth;

  static final routes = [
    GetPage(
      name: Routes.auth,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.chat,
      page: () => const ChatView(),
      binding: ChatBinding(),
    ),
  ];
}

// 📁 lib/app/routes/app_routes.dart
part of 'app_pages.dart';

abstract class Routes {
  static const auth = '/auth';
  static const home = '/home';
  static const chat = '/chat';
}

// 📁 lib/app/modules/auth/auth_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: controller.signInWithGoogle,
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}

// 📁 lib/app/modules/auth/auth_controller.dart
import 'package:get/get.dart';

class AuthController extends GetxController {
  Future<void> signInWithGoogle() async {
    // TODO: Add Firebase Auth logic
  }
}

// 📁 lib/app/modules/auth/auth_binding.dart
import 'package:get/get.dart';
import 'auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
  }
}

// 📁 lib/app/modules/home/home_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: const Center(child: Text('Chat List will appear here')),
    );
  }
}

// 📁 lib/app/modules/home/home_controller.dart
import 'package:get/get.dart';

class HomeController extends GetxController {
  // TODO: Implement chat list loading
}

// 📁 lib/app/modules/home/home_binding.dart
import 'package:get/get.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}

// 📁 lib/app/modules/chat/chat_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'chat_controller.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(child: Container(color: Colors.grey.shade200)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.messageController,
                  decoration: const InputDecoration(hintText: 'Type a message'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: controller.sendMessage,
              )
            ],
          )
        ],
      ),
    );
  }
}

// 📁 lib/app/modules/chat/chat_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final messageController = TextEditingController();

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isNotEmpty) {
      // TODO: Add Firestore send logic
      messageController.clear();
    }
  }
}

// 📁 lib/app/modules/chat/chat_binding.dart
import 'package:get/get.dart';
import 'chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController());
  }
}



