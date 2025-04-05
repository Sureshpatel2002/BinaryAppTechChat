Let’s go 🔥—time to add **image messaging** to your chat app using **Firebase Storage**! Users will be able to pick from gallery or camera and send inline image messages, just like WhatsApp or Messenger.

---

## 📸 Step 7: Send & Display Image Messages

### ✅ What We’ll Do:
1. Pick images from **camera/gallery**
2. Upload to **Firebase Storage**
3. Send a message with image URL
4. Display image in chat bubbles

---

### 📦 Dependencies

Add to `pubspec.yaml`:

```yaml
image_picker: ^1.0.7
firebase_storage: ^11.6.1
```

Then run:

```bash
flutter pub get
```

---

### 🔧 1. Add Image Picker Method in `ChatController`

```dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> pickAndSendImage(ImageSource source) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source, imageQuality: 75);

  if (pickedFile == null) return;

  final file = File(pickedFile.path);
  final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
  final storageRef = FirebaseStorage.instance
      .ref()
      .child('chat_images')
      .child(chatId)
      .child(fileName);

  final uploadTask = await storageRef.putFile(file);
  final imageUrl = await uploadTask.ref.getDownloadURL();

  sendImageMessage(imageUrl);
}

void sendImageMessage(String imageUrl) async {
  final currentUser = _auth.currentUser!;
  final docRef = _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .doc();

  final message = {
    'senderId': currentUser.uid,
    'receiverId': otherUid,
    'type': 'image',
    'content': imageUrl,
    'timestamp': FieldValue.serverTimestamp(),
    'readBy': [currentUser.uid],
  };

  await docRef.set(message);

  await _firestore.collection('chats').doc(chatId).update({
    'lastMessage': '[Image]',
    'lastMessageTime': FieldValue.serverTimestamp(),
  });
}
```

---

### 📷 2. Update `ChatView` UI – Add Image Buttons

Below the message input, update the row:

```dart
Row(
  children: [
    IconButton(
      icon: const Icon(Icons.camera_alt),
      onPressed: () => controller.pickAndSendImage(ImageSource.camera),
    ),
    IconButton(
      icon: const Icon(Icons.image),
      onPressed: () => controller.pickAndSendImage(ImageSource.gallery),
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
    )
  ],
)
```

---

### 🖼️ 3. Display Image in Bubble

Update the message bubble builder in `ChatView`:

```dart
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
        style: TextStyle(color: isMe ? Colors.white : Colors.black),
      ),
    if (isMe)
      Icon(
        (msg['readBy'] as List).length > 1 ? Icons.done_all : Icons.check,
        size: 16,
        color: (msg['readBy'] as List).length > 1 ? Colors.green : Colors.white70,
      )
  ],
),
```

---

### ✅ You Now Have:
- Image messages via **Camera or Gallery**
- Uploaded to **Firebase Storage**
- Inline **chat image previews**
- Fallback `[Image]` as last message

---

### 👇 Next Step Options:
1. 🔔 Push notifications via Firebase Cloud Messaging (FCM)
2. 🧑 Show user profiles (name + avatar) in home/chat list
3. 🚪 Add logout + auth persistence
4. 📁 Add file upload (PDF, docs, audio)

Pick your next move, and we’ll build it!