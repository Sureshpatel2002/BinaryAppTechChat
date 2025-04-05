import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxList<Map<String, dynamic>> chats = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchChats();

    // Handle auth state changes (e.g., logout)
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        Get.offAllNamed('/auth');
      }
    });
  }

  void fetchChats() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        final chatList = snapshot.docs.map((doc) {
          final data = doc.data();
          data['chatId'] = doc.id;
          return data;
        }).toList();

        chats.value = chatList;

        print('[HomeController] Fetched ${chatList.length} chat(s)');
      },
      onError: (error) {
        print('[HomeController][ERROR] Failed to fetch chats: $error');
      },
    );
  }
}
