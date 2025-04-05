Nice — let’s now implement the **typing indicator** 💬 to show when the other user is actively typing in the chat!

---

## ✍️ Step 6: Typing Indicator in Real-Time

### ✅ What We’ll Do:
1. Store typing status in the main `/chats/{chatId}` doc
2. Update the status as the user types/stops
3. Display it in the chat UI if the other user is typing

---

### 📁 Firestore Structure (Update)

Add a field inside the chat document:

```json
"typing": {
  "uid1": false,
  "uid2": true
}
```

---

### 📥 Update `ChatController` – Typing Status Logic

Add a `debounce` timer so we don’t spam Firestore every keystroke.

Update `chat_controller.dart`:

```dart
import 'dart:async';

Timer? _typingTimer;

void updateTypingStatus(bool isTyping) {
  final currentUid = _auth.currentUser!.uid;

  _firestore.collection('chats').doc(chatId).update({
    'typing.$currentUid': isTyping,
  });

  // Reset typing after delay
  _typingTimer?.cancel();
  if (isTyping) {
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _firestore.collection('chats').doc(chatId).update({
        'typing.$currentUid': false,
      });
    });
  }
}
```

Then, attach a listener to the message input field:

```dart
messageController.addListener(() {
  updateTypingStatus(messageController.text.isNotEmpty);
});
```

---

### 👁️ Listen to Typing in `ChatController`

Add this reactive variable:

```dart
RxBool otherUserTyping = false.obs;
```

In `initChat()`, listen to changes in the `chat` document:

```dart
_firestore.collection('chats').doc(chatId).snapshots().listen((doc) {
  final data = doc.data();
  if (data != null && data['typing'] != null) {
    otherUserTyping.value = data['typing'][otherUid] ?? false;
  }
});
```

---

### 💬 Show Typing Indicator in `ChatView`

Above the message list or input field:

```dart
Obx(() {
  return controller.otherUserTyping.value
      ? const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Typing...', style: TextStyle(fontStyle: FontStyle.italic)),
          ),
        )
      : const SizedBox.shrink();
}),
```

---

### ✅ You Now Have:
- Real-time typing indicators
- Smooth UX with debounce (2s delay)
- Visibility only when other user is typing

---

### 👇 Next Steps (Your Pick):
1. 📸 Add image message sending (gallery/camera) with Firebase Storage
2. 🔔 Setup push notifications with Firebase Cloud Messaging (FCM)
3. 🧑 Show user profile photo + name in chat list
4. 🚪 Add logout & auth state persistence

Let me know what you’d like to implement next — we’re building something slick here!