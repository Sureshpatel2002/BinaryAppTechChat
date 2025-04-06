// home_view.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../routes/app_pages.dart';
import 'home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'BinaryAppTech',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
            onPressed: () => Get.toNamed('/new_chat'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.refreshChatList,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[300],
        child: Obx(() {
          if (controller.chats.isEmpty) {
            return const Center(
              child: Text(
                'No chats yet.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: controller.chats.length,
            itemBuilder: (context, index) {
              final chat = controller.chats[index];
              final participants = chat['participants'] as List;
              if (!participants.contains(currentUser!.uid) ||
                  participants.length <= 1) return const SizedBox.shrink();

              final otherUid = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => null,
              );

              final lastMsg = chat['lastMessage'] ?? '';
              final time = (chat['lastMessageTime'] as Timestamp?)?.toDate();

              if (otherUid == null || chat['chatId'] == null) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Center(
                          child: Text('Loading...',
                              style: TextStyle(fontSize: 14))),
                    );
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      !snapshot.data!.exists) {
                    return const ListTile(
                      title: Text('User not found',
                          style: TextStyle(color: Colors.red)),
                    );
                  }
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final displayName = userData['displayName'] ?? 'User';
                  final photoUrl = userData['photoUrl'] ?? '';
                  final isOnline = userData['onlineStatus'] == true;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl.isEmpty
                                ? const Icon(Icons.person, size: 24)
                                : null,
                          ),
                          if (isOnline)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                height: 12,
                                width: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: time != null
                          ? Text(
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            )
                          : null,
                      onTap: () {
                        Get.toNamed('/chat', arguments: {
                          'chatId': chat['chatId'],
                          'otherUid': otherUid,
                        });
                      },
                    ),
                  );
                },
              );
            },
          );
        }),
      ),
    );
  }

  void _showLogoutConfirmation() {
    Get.defaultDialog(
      title: "Logout",
      middleText: "Are you sure you want to log out?",
      textConfirm: "Yes",
      textCancel: "No",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        try {
          await FirebaseAuth.instance.signOut();
          // Navigate to the auth route after logging out
          Get.offAllNamed(Routes.auth); // Use the defined route name
          Get.snackbar('Logged Out', 'You have been successfully logged out.');
        } catch (e) {
          Get.snackbar('Error', 'Failed to log out. Please try again.');
        }
      },
    );
  }
}
