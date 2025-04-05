import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'image_viewer.dart';

class ChatController extends GetxController {
  final messageController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late String chatId;
  late String otherUid;

  RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  Timer? _typingTimer;

  @override
  void onInit() {
    super.onInit();

    messageController.addListener(() {
      updateTypingStatus(messageController.text.isNotEmpty);
    });
  }

  void initChat(String id, String uid) {
    chatId = id;
    otherUid = uid;
    listenToMessages();
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
    };

    await docRef.set(message);

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    messageController.clear();
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
      // ✅ Ensure file exists
      if (!await file.exists()) {
        log('[ChatController][ERROR] File does not exist: ${file.path}');
        Get.snackbar('Upload Failed', 'Selected file no longer exists.');
        return;
      }

      // ✅ Ensure chatId is initialized
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

      // ✅ Check if upload succeeded
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

  // Future<void> _uploadAndSendImage(File file) async {
  //   try {
  //     final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
  //     final storageRef = FirebaseStorage.instance
  //         .ref()
  //         .child('chat_images')
  //         .child(chatId)
  //         .child(fileName);

  //     final uploadTask = storageRef.putFile(file);
  //     final snapshot = await uploadTask.whenComplete(() {});
  //     final imageUrl = await snapshot.ref.getDownloadURL();

  //     await sendImageMessage(imageUrl);
  //   } catch (e) {
  //     print('[ChatController][ERROR] Upload failed: $e');
  //     Get.snackbar('Error', 'Image upload failed');
  //   }
  // }

  @override
  void onClose() {
    _typingTimer?.cancel();
    messageController.dispose();
    super.onClose();
  }
}
