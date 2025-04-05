Let’s do it — next up is adding **message editing and deleting** functionality! 🧹  
This gives users control over their conversations, just like in WhatsApp, Signal, or Telegram.

---

## 🧹 Step 11: Edit & Delete Messages

### ✅ What We’ll Do:
1. Add long-press menu on messages (Edit/Delete)
2. Allow editing text messages
3. Support delete-for-me and delete-for-all
4. Update Firestore message documents

---

### 📁 Message Document Structure (Additions)

Update each message to support these fields:

```json
{
  "edited": false,
  "deletedFor": ["uid1"] // use this to support 'delete for me'
}
```

---

### ✏️ 1. Update `ChatView` – Add Long Press Menu

Wrap your message bubble with `GestureDetector`:

```dart
GestureDetector(
  onLongPress: () => _showMessageOptions(context, msg),
  child: Align(
    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
    child: ... // your message bubble
  ),
)
```

Add the `_showMessageOptions()` method:

```dart
void _showMessageOptions(BuildContext context, Map<String, dynamic> msg) {
  final currentUid = FirebaseAuth.instance.currentUser!.uid;
  final isMe = msg['senderId'] == currentUid;

  showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Wrap(
        children: [
          if (isMe && msg['type'] == 'text')
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editMessage(msg);
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text(isMe ? 'Delete for everyone' : 'Delete for me'),
            onTap: () {
              Navigator.pop(context);
              _deleteMessage(msg, isMe);
            },
          ),
        ],
      ),
    ),
  );
}
```

---

### 🔁 2. Add Edit & Delete Logic in `ChatController`

```dart
Future<void> _editMessage(Map<String, dynamic> msg) async {
  final textController = TextEditingController(text: msg['content']);

  await Get.dialog(AlertDialog(
    title: const Text('Edit Message'),
    content: TextField(controller: textController),
    actions: [
      TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
      TextButton(
        onPressed: () async {
          final newText = textController.text.trim();
          if (newText.isNotEmpty && newText != msg['content']) {
            await _firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .doc(msg['id'])
                .update({
              'content': newText,
              'edited': true,
            });
          }
          Get.back();
        },
        child: const Text('Save'),
      ),
    ],
  ));
}

Future<void> _deleteMessage(Map<String, dynamic> msg, bool isMe) async {
  final docRef = _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .doc(msg['id']);

  if (isMe) {
    // Delete for everyone
    await docRef.delete();
  } else {
    // Delete for self
    await docRef.update({
      'deletedFor': FieldValue.arrayUnion([_auth.currentUser!.uid])
    });
  }
}
```

---

### 🧼 3. Hide Deleted Messages in Chat List

In your message list builder:

```dart
final deletedFor = msg['deletedFor'] ?? [];
if (deletedFor.contains(FirebaseAuth.instance.currentUser!.uid)) {
  return const SizedBox.shrink(); // Hide message
}
```

---

### ✍️ 4. Show Edited Tag (Optional)

In your bubble UI:

```dart
Text(
  msg['content'] + (msg['edited'] == true ? ' (edited)' : ''),
  style: TextStyle(color: isMe ? Colors.white : Colors.black),
),
```

---

### ✅ You Now Have:
- Long press to **edit or delete** messages
- "Delete for me" + "delete for everyone"
- Edited messages marked in UI
- Messages hidden per user after deletion

---

### 👇 What’s Next?

1. 😍 Add emoji reactions to messages
2. 📁 Add file uploads (PDFs, audio, docs)
3. 🔐 Add Firestore security rules
4. 🧑 Add profile view/edit screen
5. 💾 Local drafts, message caching

Let’s power up the chat app — what’s next on your list?