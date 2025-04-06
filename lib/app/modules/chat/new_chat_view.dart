import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewChatView extends StatefulWidget {
  NewChatView({super.key});

  @override
  State<NewChatView> createState() => _NewChatViewState();
}

class _NewChatViewState extends State<NewChatView> {
  final TextEditingController searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxString searchText = ''.obs;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(
            color: Colors.white), // <-- change back button color
        title: const Text(
          'Start New Chat',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by email',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    searchText.value = value.trim().toLowerCase()),
          ),
          Expanded(
            child: Obx(() {
              if (searchText.isEmpty) {
                return const Center(child: Text('Type an email to search.'));
              }

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('email', isGreaterThanOrEqualTo: searchText.value)
                    .where('email', isLessThan: searchText.value + 'z')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!.docs
                      .where((doc) => doc.id != _auth.currentUser!.uid)
                      .toList();

                  if (users.isEmpty) {
                    return const Center(
                        child: Text('No matching users found.'));
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        leading: user['photoUrl'] != ''
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(user['photoUrl']))
                            : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(user['displayName'] ?? ''),
                        subtitle: Text(user['email']),
                        onTap: () => _startChat(user.id),
                      );
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _startChat(String otherUserId) async {
    final currentUser = _auth.currentUser!;
    final chatId = _generateChatId(currentUser.uid, otherUserId);

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUser.uid, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }

    Get.toNamed('/chat', arguments: {
      'chatId': chatId,
      'otherUid': otherUserId,
    });
  }

  String _generateChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '$uid1\_$uid2' : '$uid2\_$uid1';
  }
}
