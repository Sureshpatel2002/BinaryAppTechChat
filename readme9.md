Awesome — time to bring in **push notifications** so users get alerts for new messages even when the app is closed or in the background.

---

## 🔔 Step 8: Push Notifications with Firebase Cloud Messaging (FCM)

### ✅ What We’ll Do:
1. Setup FCM in your project
2. Save user FCM tokens in Firestore
3. Trigger notification on new message
4. Handle tap to open chat

---

### 📦 Dependencies

Add to `pubspec.yaml`:

```yaml
firebase_messaging: ^14.7.16
flutter_local_notifications: ^17.0.0
```

Then run:

```bash
flutter pub get
```

---

### 🛠️ 1. Initialize FCM in `main.dart`

Update your `main()`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Local notification setup (Android)
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings,
      onDidReceiveNotificationResponse: (res) {
    // Optional: handle tap on notification
  });

  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Optional: log or process background message
}
```

---

### 📥 2. Save User Token in Firestore

Update `AuthController`:

```dart
Future<void> _createUserInFirestore(User user) async {
  final doc = _firestore.collection('users').doc(user.uid);
  final snapshot = await doc.get();

  final token = await FirebaseMessaging.instance.getToken();

  if (!snapshot.exists) {
    await doc.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? '',
      'photoUrl': user.photoURL ?? '',
      'bio': '',
      'lastSeen': FieldValue.serverTimestamp(),
      'onlineStatus': true,
      'fcmToken': token
    });
  } else {
    await doc.update({'fcmToken': token});
  }
}
```

---

### 📨 3. Trigger Notification on Message Send (Temporary Hack)

You can use a Firebase Cloud Function in production.

But for now, add **manual push** in `sendMessage()` in `ChatController` using FCM’s REST API:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendNotification(String receiverUid, String message) async {
  final doc = await _firestore.collection('users').doc(receiverUid).get();
  final token = doc.data()?['fcmToken'];
  if (token == null) return;

  final data = {
    "to": token,
    "notification": {
      "title": "New Message",
      "body": message,
    },
    "data": {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "chatId": chatId,
    }
  };

  await http.post(
    Uri.parse("https://fcm.googleapis.com/fcm/send"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "key=YOUR_SERVER_KEY" // Get from Firebase console
    },
    body: jsonEncode(data),
  );
}
```

Then call it after sending message:

```dart
await sendNotification(otherUid, text);
```

> **Note**: Use Firebase Functions for secure production setup.

---

### 💬 4. Handle Notifications in Foreground

In `HomeController` or a common `NotificationService`:

```dart
void initFCMListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        0,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_channel',
            'Chat Messages',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final chatId = message.data['chatId'];
    if (chatId != null) {
      Get.toNamed('/chat', arguments: {
        'chatId': chatId,
        'otherUid': '...' // You'll need to look this up
      });
    }
  });
}
```

Call `initFCMListeners()` after login or in `onInit()` of `HomeController`.

---

### ✅ You Now Have:
- Device token saved in Firestore
- Real push notifications (manual FCM call)
- Foreground alerts + tap to open chat
- Ready for Firebase Functions or production trigger setup

---

### 👇 What Next?
1. 🚪 Logout and auth persistence
2. 🧑 Show user profile names + avatars in chat list
3. 📁 Add file upload (docs, audio)
4. 🧹 Message delete/edit logic

Let me know where we’re heading next — you’re building a beast of an app!