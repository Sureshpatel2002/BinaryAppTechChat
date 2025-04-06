import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_controller.dart';

class ChatView extends StatelessWidget {
  ChatView({super.key});

  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  void _updateIsTyping(bool isTyping) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'isTyping': isTyping});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatController>();
    final args = Get.arguments;
    controller.initChat(args['chatId'], args['otherUid']);

    controller.messages.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    });

    _focusNode.addListener(() {
      _updateIsTyping(_focusNode.hasFocus);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    });
    controller.messages.listen((messages) {
      // Call markMessagesAsRead when messages are updated
      controller.markMessagesAsRead(messages);
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(args['otherUid'])
              .snapshots(), // 👈 live updates
          builder: (context, snapshot) {
            if (!snapshot.hasData) return AppBar(title: const Text('Chat'));

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final displayName = userData['displayName'] ?? 'User';
            final photoUrl = userData['photoUrl'] ?? '';
            final isOnline = userData['onlineStatus'] == true;
            final isTyping = userData['isTyping'] == true;

            return AppBar(
              backgroundColor: Colors.deepPurple,
              iconTheme: const IconThemeData(color: Colors.white),
              titleSpacing: 0,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        isTyping
                            ? 'Typing...'
                            : (isOnline ? 'Online' : 'Offline'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isTyping
                              ? Colors.orangeAccent
                              : (isOnline ? Colors.greenAccent : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'clear_chat') {
                      controller.clearChat();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'clear_chat',
                        child: Text('Clear Chat'),
                      ),
                    ];
                  },
                  icon: const Icon(Icons.more_vert),
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
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe =
                      msg['senderId'] == FirebaseAuth.instance.currentUser!.uid;
                  final messageTime =
                      (msg['timestamp'] as Timestamp?)?.toDate();

                  final previousTime = index > 0
                      ? (messages[index - 1]['timestamp'] as Timestamp?)
                          ?.toDate()
                      : null;

                  final showDateSeparator = messageTime != null &&
                      (previousTime == null ||
                          messageTime.day != previousTime.day);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDateSeparator)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(
                            child: Text(
                              '${messageTime!.day}/${messageTime.month}/${messageTime.year}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ),
                      Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                isMe ? Colors.blueGrey : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
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
                              if (messageTime != null)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.black87),
                                    ),
                                    const SizedBox(width: 4),
                                    if (isMe)
                                      FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(args['otherUid'])
                                            .get(),
                                        builder: (context, snapshot) {
                                          final readBy =
                                              msg['readBy'] as List? ?? [];
                                          final isOnline = (snapshot.data
                                                      ?.data()
                                                  as Map?)?['onlineStatus'] ==
                                              true;

                                          Icon icon;
                                          if (readBy.length > 1) {
                                            icon = const Icon(Icons.done_all,
                                                size: 16, color: Colors.green);
                                          } else if (isOnline) {
                                            icon = const Icon(Icons.done_all,
                                                size: 16,
                                                color: Colors.white70);
                                          } else {
                                            icon = const Icon(Icons.check,
                                                size: 16,
                                                color: Colors.white54);
                                          }
                                          return icon;
                                        },
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
          Material(
            elevation: 3,
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.messageController,
                      focusNode: _focusNode,
                      onChanged: (text) {
                        _updateIsTyping(text.isNotEmpty);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      controller.sendMessage();
                      _updateIsTyping(false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
