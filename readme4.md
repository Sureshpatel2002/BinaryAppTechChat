Awesome, you’re cruising! 🚀  
Next up: **displaying recent chats on the Home screen** using Firestore.

---

## 🏠 Step 3: Display Recent Chats (Home Screen)

### ✅ What We’ll Do:
1. Create a Firestore structure for storing chats
2. Query the current user's conversations
3. Show them as a scrollable list on the Home screen
4. Navigate to a `ChatView` on tap

---

### 📁 Firestore Structure

We'll use:

```
/chats/{chatId}
  - participants: [uid1, uid2]
  - lastMessage: "Hey"
  - lastMessageTime: Timestamp
  - typing: {uid1: false, uid2: false}
```

The `chatId` is generated like this:

```dart
String getChatId(String uid1, String uid2) {
  return uid1.hashCode <= uid2.hashCode
      ? '$uid1\_$uid2'
      : '$uid2\_$uid1';
}
```

---

### 🔁 `HomeController`: Load Recent Chats

Update `home_controller.dart`:

```dart
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
  }

  void fetchChats() {
    final uid = _auth.currentUser!.uid;

    _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen((snapshot) {
      chats.value = snapshot.docs.map((doc) {
        final data = doc.data();
        data['chatId'] = doc.id;
        return data;
      }).toList();
    });
  }
}
```

---

### 🖼️ `HomeView`: Show Chat List

Update `home_view.dart`:

```dart
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
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
            final otherUid = (chat['participants'] as List)
                .firstWhere((id) => id != FirebaseAuth.instance.currentUser!.uid);

            return ListTile(
              title: Text('Chat with $otherUid'),
              subtitle: Text(lastMsg),
              trailing: time != null ? Text('${time.hour}:${time.minute}') : null,
              onTap: () => Get.toNamed('/chat', arguments: {
                'chatId': chat['chatId'],
                'otherUid': otherUid,
              }),
            );
          },
        );
      }),
    );
  }
}
```

---

### 🛠️ Add Navigation Argument in `ChatView`

Update `chat_view.dart` to receive `chatId` and `otherUid`:

```dart
class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatController>();
    final args = Get.arguments;
    controller.initChat(args['chatId'], args['otherUid']);

    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(child: Container()), // Will be message list
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
```

---

### ✅ Now You Can:
- Log in
- Land on a home screen showing recent chats
- Tap a chat → open chat view

---

### 👇 Next Step Options:

1. 💬 Implement real-time messaging in `ChatView`
2. 🧑 Load other user’s name/photo in chat list
3. ✅ Add logout functionality
4. 🔔 Set up FCM push notifications
5. 📱 Show online status + typing indicators

Let me know what you want next — and we’ll keep building!