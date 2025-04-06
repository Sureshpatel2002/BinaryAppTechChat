import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxList<Map<String, dynamic>> chats = <Map<String, dynamic>>[].obs;

  /// Called once when controller is first created
  @override
  void onInit() {
    super.onInit();
    _setupAuthListener();
  }

  /// Called every time the associated view becomes visible
  @override
  void onReady() {
    super.onReady();
    fetchChats(); // 👈 Automatically refresh chats on navigation
  }

  /// Refresh chat list manually (called from refresh button)
  void refreshChatList() {
    fetchChats();
  }

  /// Fetch chats where current user is a participant
  void fetchChats() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      log('[HomeController] No user logged in');
      return;
    }

    try {
      _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .snapshots()
          .listen(
        (snapshot) {
          final chatList = snapshot.docs.map((doc) {
            final data = doc.data();
            data['chatId'] = doc.id;
            return data;
          }).toList();

          chats.value = chatList;
          log('[HomeController] Fetched ${chatList.length} chat(s)');
        },
        onError: (error) {
          log('[HomeController][ERROR] Failed to fetch chats: $error');
        },
      );
    } catch (e) {
      log('[HomeController][EXCEPTION] $e');
    }
  }

  /// Redirect to login if user logs out
  void _setupAuthListener() {
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        Get.offAllNamed('/login'); // 🔁 Adjust route name if needed
      }
    });
  }
}
