Perfect — now let’s enhance the **chat list UI** by showing the **other user’s name and profile picture** instead of just their UID. This makes your chat screen feel way more polished and human. 🧑‍🤝‍🧑✨

---

## 🧑 Step 10: Show Profile Name & Avatar in Chat List

### ✅ What We’ll Do:
1. Fetch other user’s data from `/users/{uid}`
2. Display their `displayName` and `photoUrl` in `HomeView`
3. Improve chat list tile UI

---

### 🔁 1. Update `HomeController` to Fetch Other User Profiles

Extend your `fetchChats()` to load other user details:

```dart
void fetchChats() {
  final uid = _auth.currentUser!.uid;

  _firestore
      .collection('chats')
      .where('participants', arrayContains: uid)
      .orderBy('lastMessageTime', descending: true)
      .snapshots()
      .listen((snapshot) async {
    final chatDocs = snapshot.docs;

    final List<Map<String, dynamic>> enrichedChats = [];

    for (var doc in chatDocs) {
      final chat = doc.data();
      chat['chatId'] = doc.id;

      final List participants = chat['participants'];
      final otherUid = participants.firstWhere((id) => id != uid);

      final userDoc = await _firestore.collection('users').doc(otherUid).get();
      final userData = userDoc.data();

      chat['otherUser'] = {
        'uid': otherUid,
        'displayName': userData?['displayName'] ?? 'Unknown',
        'photoUrl': userData?['photoUrl'] ?? '',
      };

      enrichedChats.add(chat);
    }

    chats.value = enrichedChats;
  });
}
```

---

### 🧱 2. Update `HomeView` Chat Tile UI

Replace the `ListTile` in your `ListView.builder` with:

```dart
final otherUser = chat['otherUser'];
final displayName = otherUser['displayName'];
final photoUrl = otherUser['photoUrl'];
final lastMsg = chat['lastMessage'] ?? '';
final time = (chat['lastMessageTime'] as Timestamp?)?.toDate();

return ListTile(
  leading: CircleAvatar(
    backgroundImage: photoUrl.isNotEmpty
        ? NetworkImage(photoUrl)
        : null,
    child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
  ),
  title: Text(displayName),
  subtitle: Text(lastMsg),
  trailing: time != null
      ? Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}')
      : null,
  onTap: () => Get.toNamed('/chat', arguments: {
    'chatId': chat['chatId'],
    'otherUid': otherUser['uid'],
  }),
);
```

---

### ✅ You Now Have:
- Full names + profile pics in chat list
- Cleaned-up `ListTile` UI
- Enriched UX like any modern chat app

---

### 👇 What’s Next?

1. 🧹 Add message edit/delete logic
2. 😍 Add emoji reactions to messages
3. 📁 Add file/doc/audio upload
4. 🔒 Add Firestore security rules (production-ready)
5. 🧑 Profile view/edit page

Let me know what you'd like next — we're almost feature-complete!