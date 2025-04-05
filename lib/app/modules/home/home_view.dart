import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.toNamed('/new_chat');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutConfirmation();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.chats.isEmpty) {
          return const Center(child: Text('No chats yet.'));
        }
        return ListView.builder(
          itemCount: controller.chats.length,
          itemBuilder: (context, index) {
            final chat = controller.chats[index];
            final lastMsg = chat['lastMessage'] ?? '';
            final time = (chat['lastMessageTime'] as Timestamp?)?.toDate();
            final otherUid = (chat['participants'] as List).firstWhere(
                (id) => id != FirebaseAuth.instance.currentUser!.uid);

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(title: Text("Loading..."));
                }

                if (userSnapshot.hasError) {
                  return const ListTile(title: Text("Error loading user"));
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const ListTile(title: Text("User not found"));
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final displayName = userData['displayName'] ?? 'User';
                final photoUrl = userData['photoUrl'] ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(displayName),
                  subtitle: Text(lastMsg),
                  trailing: time != null
                      ? Text(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      : null,
                  onTap: () => Get.toNamed('/chat', arguments: {
                    'chatId': chat['chatId'],
                    'otherUid': otherUid,
                  }),
                );
              },
            );
          },
        );
      }),
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
        await FirebaseAuth.instance.signOut();
        Get.offAllNamed('/login');
        Get.snackbar('Logged Out', 'You have been successfully logged out.');
      },
      onCancel: () {},
    );
  }
}
