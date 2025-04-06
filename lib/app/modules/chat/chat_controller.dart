import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'image_viewer.dart';

class ChatController extends GetxController {
  final messageController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String chatId = '';
  String otherUid = '';

  RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxMap<String, String> emojiReactions = <String, String>{}.obs;
  RxBool isTyping = false.obs;
  Timer? _typingTimer;

  void initChat(String id, String uid) {
    chatId = id;
    otherUid = uid;
    listenToMessages();
    listenToTypingStatus();

    messageController.addListener(() {
      updateTypingStatus(messageController.text.isNotEmpty);
    });
  }

  void listenToMessages() {
    _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      final newMessages = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Attach message ID for updates
        return data;
      }).toList();

      messages.value = newMessages;
      markMessagesAsRead(newMessages);
    });
  }

  void listenToTypingStatus() {
    if (chatId.isEmpty) return;
    _firestore.collection('chats').doc(chatId).snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null) {
        isTyping.value = data['typing'][otherUid] ?? false;
      }
    });
  }

  Future<void> addEmojiReaction(String messageId, String emoji) async {
    try {
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      // Update locally
      emojiReactions[messageId] = emoji;

      // Update Firestore with emoji field
      await messageRef.update({
        'reaction': emoji,
      });

      log('[ChatController] Reaction "$emoji" added to message $messageId');
    } catch (e) {
      log('[ChatController][ERROR] Failed to add emoji reaction: $e');
      Get.snackbar('Error', 'Failed to add emoji');
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = _auth.currentUser!;
    final docRef =
        _firestore.collection('chats').doc(chatId).collection('messages').doc();

    final message = {
      'senderId': currentUser.uid,
      'receiverId': otherUid,
      'type': 'text',
      'content': text,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': [currentUser.uid],
      'reaction': null,
    };

    await docRef.set(message);
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    messageController.clear();
    await sendNotification(otherUid, text);
  }

  Future<void> pickAndSendImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: source, imageQuality: 75);

      if (pickedFile == null) {
        log('[ChatController] No image selected.');
        return;
      }

      final file = File(pickedFile.path);

      if (!await file.exists()) {
        log('[ChatController] File does not exist: ${file.path}');
        return;
      }

      // Navigate to preview screen before uploading
      Get.to(() => ImagePreviewScreen(
            imageFile: file,
            onSend: () async {
              Get.back(); // Close preview
              await _uploadAndSendImage(file);
            },
          ));
    } catch (e) {
      log('[ChatController][ERROR] Image pick failed: $e');
      Get.snackbar('Error', 'Image selection failed.');
    }
  }

  Future<void> _uploadAndSendImage(File file) async {
    try {
      // Ensure file exists
      if (!await file.exists()) {
        log('[ChatController][ERROR] File does not exist: ${file.path}');
        Get.snackbar('Upload Failed', 'Selected file no longer exists.');
        return;
      }

      // Ensure chatId is initialized
      if (chatId.isEmpty) {
        log('[ChatController][ERROR] chatId is empty!');
        Get.snackbar('Upload Failed', 'Chat ID is not set.');
        return;
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(chatId)
          .child(fileName);

      log('[ChatController] Uploading image to: ${storageRef.fullPath}');

      // Start upload
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;

      // Check if upload succeeded
      if (snapshot.state == TaskState.success) {
        final imageUrl = await snapshot.ref.getDownloadURL();
        log('[ChatController] Upload successful! Image URL: $imageUrl');
        await sendImageMessage(imageUrl);
      } else {
        log('[ChatController][ERROR] Upload failed. Snapshot state: ${snapshot.state}');
        Get.snackbar('Upload Failed', 'Image failed to upload.');
      }
    } catch (e) {
      log('[ChatController][ERROR] Image upload failed: $e');
      Get.snackbar('Upload Failed', e.toString());
    }
  }

  Future<void> sendImageMessage(String imageUrl) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        log('[ChatController][ERROR] No user logged in');
        Get.snackbar('Error', 'User not authenticated');
        return;
      }

      if (chatId.isEmpty || otherUid.isEmpty) {
        log('[ChatController][ERROR] chatId or otherUid is empty');
        Get.snackbar('Error', 'Invalid chat session');
        return;
      }

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
      log('[ChatController] Image message sent to chat $chatId');

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': '[Image]',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      log('[ChatController] Chat metadata updated with last image message');
    } catch (e) {
      log('[ChatController][ERROR] Failed to send image message: $e');
      Get.snackbar('Send Failed', 'Could not send image message');
    }
  }

  void markMessagesAsRead(List<Map<String, dynamic>> messages) async {
    final currentUid = _auth.currentUser!.uid;
    final batch = _firestore.batch();

    for (var msg in messages) {
      if (msg['senderId'] == otherUid &&
          !(msg['readBy'] as List).contains(currentUid)) {
        final docRef = _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(msg['id']);

        batch.update(docRef, {
          'readBy': FieldValue.arrayUnion([currentUid])
        });
      }
    }

    await batch.commit();
  }

  void updateTypingStatus(bool isTyping) {
    final currentUid = _auth.currentUser!.uid;

    _firestore.collection('chats').doc(chatId).update({
      'typing.$currentUid': isTyping,
    });

    _typingTimer?.cancel();
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _firestore.collection('chats').doc(chatId).update({
          'typing.$currentUid': false,
        });
      });
    }
  }

  Future<void> clearChat() async {
    try {
      final chatDocRef = _firestore.collection('chats').doc(chatId);

      // Step 1: Delete all messages in the subcollection
      final messagesSnapshot = await chatDocRef.collection('messages').get();
      final batch = _firestore.batch();

      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Step 2: Delete the main chat document
      batch.delete(chatDocRef);

      await batch.commit();

      // Clear UI messages as well
      messages.clear();

      log('[ChatController] Entire chat "$chatId" deleted including all messages.');
      Get.snackbar('Deleted', 'Chat has been permanently removed');
    } catch (e) {
      log('[ChatController][ERROR] Failed to delete chat: $e');
      Get.snackbar('Error', 'Failed to delete chat');
    }
  }

  Future<void> sendNotification(String recipientUid, String message,) async {
    final token = await _getUserToken(recipientUid);
    if (token == null) {
      log('[Notification] No FCM token found for user $recipientUid');
      return;
    }

    final data = {
      'notification': {
        'title': 'New Message',
        'body': message,
      },
      'data': {
        'chatId': chatId,
      },
      'to': token,
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'AIzaSyAzJeYHIhgYBIpU2P7iK9sZs1X7KqJgt3I', // Replace with actual server key
    };

    log('[Notification] Sending FCM notification to $token with payload: ${json.encode(data)}');

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] == 1) {
          log('[Notification] ✅ Notification sent successfully to $recipientUid');
        } else {
          log('[Notification] ⚠️ Notification sent but FCM reported failure: $responseBody');
        }
      } else {
        log('[Notification][ERROR] ❌ Failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      log('[Notification][ERROR] Exception while sending notification: $e');
    }
  }

  Future<String?> _getUserToken(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.data()?['fcmToken'];
  }

  @override
  void onClose() {
    _typingTimer?.cancel();
    messageController.dispose();
    super.onClose();
  }
}
