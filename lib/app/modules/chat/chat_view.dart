import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'chat_controller.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatController>();
    final args = Get.arguments;
    controller.initChat(args['chatId'], args['otherUid']);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(args['otherUid'])
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return AppBar(title: const Text('Chat'));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final displayName = userData['displayName'] ?? 'User';
            final photoUrl = userData['photoUrl'] ?? '';
            final isOnline = userData['onlineStatus'] == true;

            return AppBar(
              leadingWidth: 40,
              titleSpacing: 0,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontSize: 16)),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline ? Colors.greenAccent : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {}, // Add any menu/settings actions here
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final messages = controller.messages;
              return ListView.builder(
                controller: ScrollController(),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe =
                      msg['senderId'] == FirebaseAuth.instance.currentUser!.uid;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (msg['type'] == 'image')
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                msg['content'],
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Text(
                              msg['content'],
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                          if (isMe)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 4),
                                Icon(
                                  (msg['readBy'] as List).length > 1
                                      ? Icons.done_all
                                      : Icons.check,
                                  size: 16,
                                  color: (msg['readBy'] as List).length > 1
                                      ? Colors.green
                                      : Colors.white70,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () =>
                    controller.pickAndSendImage(ImageSource.camera),
              ),
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: () =>
                    controller.pickAndSendImage(ImageSource.gallery),
              ),
              Expanded(
                child: TextField(
                  controller: controller.messageController,
                  decoration: const InputDecoration(hintText: 'Type a message'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: controller.sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
