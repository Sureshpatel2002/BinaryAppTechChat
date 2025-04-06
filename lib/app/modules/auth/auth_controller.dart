import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> signInWithGoogle() async {
    log('[AuthController] Starting Google Sign-In...');
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        log('[AuthController] Google sign-in was cancelled by the user.');
        return;
      }

      log('[AuthController] Google account selected: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      log('[AuthController] Received Google auth tokens.');

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      log('[AuthController] Signing in with Firebase using Google credentials...');
      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user!;
      log('[AuthController] Firebase user signed in: ${user.uid}');

      await _createUserInFirestore(user);
      await saveFcmToken(user);

      log('[AuthController] Redirecting to home...');
      Get.offAllNamed('/home');
    } catch (e) {
      log('[AuthController][ERROR] $e');
      Get.snackbar('Error', e.toString());
    }
  }

  void setOnlineStatus(bool isOnline) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'onlineStatus': isOnline,
      });
    }
  }

  Future<void> signUpWithEmail(
      String name, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = credential.user!;
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': name,
        'photoUrl': '',
        'bio': '',
        'lastSeen': FieldValue.serverTimestamp(),
        'onlineStatus': true,
      });
      await saveFcmToken(user);
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar("Signup Error", e.toString());
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCred.user;
      if (user != null) {
        await saveFcmToken(user); // Save FCM token
        setOnlineStatus(true); // Mark user as online
        Get.offAllNamed('/home'); // Navigate to home
      }
    } catch (e) {
      Get.snackbar("Login Error", e.toString());
    }
  }

  Future<void> saveFcmToken(User user) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        log('[AuthController] ✅ FCM token saved for ${user.uid}');
      } else {
        log('[AuthController][WARNING] FCM token is null');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
        });
        log('[AuthController] 🔄 FCM token refreshed and updated');
      });
    } catch (e) {
      log('[AuthController][ERROR] Failed to save FCM token: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
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

  @override
  void onClose() {
    setOnlineStatus(false);
    super.onClose();
  }
}
