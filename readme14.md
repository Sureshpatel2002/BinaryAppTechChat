Let’s gooo 🚀 — time to add **file and audio support** to your chat app so users can share documents, PDFs, and audio notes like a pro!

---

## 📁 Step 13: File and Audio Upload Support

### ✅ What We’ll Do:
1. Pick files (PDFs, docs, MP3s, etc.)
2. Upload to Firebase Storage
3. Send message with download link
4. Display file name with tap-to-download support

---

### 📦 1. Add Dependencies

In `pubspec.yaml`:

```yaml
file_picker: ^6.1.1
firebase_storage: ^11.6.1
open_file: ^3.3.2
```

Then:

```bash
flutter pub get
```

---

### 📥 2. Add File Picker Method in `ChatController`

```dart
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';

Future<void> pickAndSendFile() async {
  final result = await FilePicker.platform.pickFiles();
  if (result == null || result.files.isEmpty) return;

  final file = result.files.first;
  final fileBytes = file.bytes;
  final fileName = file.name;
  final extension = file.extension;

  final storageRef = FirebaseStorage.instance
      .ref()
      .child('chat_files')
      .child(chatId)
      .child(fileName);

  final uploadTask = await storageRef.putData(fileBytes!);
  final fileUrl = await uploadTask.ref.getDownloadURL();

  sendFileMessage(fileUrl, fileName, extension ?? 'file');
}

void sendFileMessage(String url, String name, String fileType) async {
  final currentUser = _auth.currentUser!;
  final docRef = _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .doc();

  final message = {
    'senderId': currentUser.uid,
    'receiverId': otherUid,
    'type': 'file',
    'content': url,
    'fileName': name,
    'fileType': fileType,
    'timestamp': FieldValue.serverTimestamp(),
    'readBy': [currentUser.uid],
  };

  await docRef.set(message);

  await _firestore.collection('chats').doc(chatId).update({
    'lastMessage': '[File] $name',
    'lastMessageTime': FieldValue.serverTimestamp(),
  });
}
```

---

### 🖼️ 3. Update `ChatView` – Add File Icon Button

Add another icon in the chat input row:

```dart
IconButton(
  icon: const Icon(Icons.attach_file),
  onPressed: controller.pickAndSendFile,
),
```

---

### 📄 4. Show File in Chat Bubble

Update the chat message renderer:

```dart
if (msg['type'] == 'file')
  GestureDetector(
    onTap: () => OpenFile.open(msg['content']),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file, size: 20),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              msg['fileName'] ?? 'File',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  )
```

---

### 🎤 5. (Optional) Record and Send Audio

Want to support **voice messages** next? We can add a mic button and use `flutter_sound` or `just_audio` for audio recording/playback.

Let me know — and I’ll guide you through it.

---

### ✅ You Now Have:
- Upload and send **any file**
- Clean UI to show file name & type
- Tappable file download + open
- Full Firebase Storage + Firestore integration

---

### 👇 What’s Next?

1. 🔊 Voice message support (record + playback)
2. 🧑 User profile edit screen (name, bio, avatar)
3. 🔐 Firestore security rules for production
4. 📊 Firebase Analytics + Crashlytics
5. 🧠 Add search in chat or user list

Let me know what you'd like to tackle next!