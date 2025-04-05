Great! Let’s move to the **next essential feature** — creating and storing **user profiles in Firestore** after a successful login.

---

## 🔗 Step 2: Firestore User Profile Creation After Login

### ✅ What We’ll Do:
1. On first login, check if the user exists in Firestore
2. If not, create their user profile
3. Structure the user data for easy querying later

---

### 📁 Firestore Collection

We'll use the `/users` collection with each document keyed by `uid`.

Example:
```json
/users/{uid}
{
  "uid": "abc123",
  "email": "jane@example.com",
  "displayName": "Jane",
  "photoUrl": "https://...",
  "bio": "",
  "lastSeen": "...",
  "onlineStatus": true
}
```

---

### 🧠 Modify `AuthController` to Save User Data

Update your `auth_controller.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user!;
      
      await _createUserInFirestore(user);

      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> _createUserInFirestore(User user) async {
    final doc = _firestore.collection('users').doc(user.uid);

    final snapshot = await doc.get();

    if (!snapshot.exists) {
      await doc.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'bio': '',
        'lastSeen': FieldValue.serverTimestamp(),
        'onlineStatus': true,
      });
    }
  }
}
```

---

### 🔐 Firestore Rules (for testing)
Go to Firestore → Rules and set:

```plaintext
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

This allows users to only read/write their own user documents.

---

### ✅ Output

Now, after a successful Google Sign-In:
- The user is authenticated
- Their profile is stored in Firestore under `/users/{uid}`

---

### 👇 Up Next?

Options you can pick from:
1. ✍️ Add Email/Password sign-up/login flow
2. 🏠 Load and display all recent chats on Home screen
3. 💬 Build real-time messaging between two users using Firestore
4. ✅ Implement logout and re-auth
5. 📱 Build user profile page (edit name, avatar, bio)

Let me know what you'd like to do next!