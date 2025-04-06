import 'package:get/get.dart';



import '../modules/auth/auth_binding.dart';
import '../modules/auth/auth_view.dart';
import '../modules/chat/chat_binding.dart';
import '../modules/chat/chat_view.dart';
import '../modules/chat/new_chat_view.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';

part 'app_routes.dart';

class AppPages {
  static const initial = Routes.auth;
  static const home = Routes.home;
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
      page: () =>  ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(name: '/new_chat', page: () => NewChatView()),
  ];
}