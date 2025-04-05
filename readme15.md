Sweet! Let’s now build the User Profile View/Edit Screen 👤 — so users can personalize their name, bio, and profile picture.

🧑 Step 14: User Profile View & Edit
✅ What We’ll Do:
Create a ProfileView screen

Fetch and display current user info

Allow editing displayName, bio, and photoUrl

Upload new profile pictures to Firebase Storage

🛠️ 1. Create Profile Module
Create files:

swift
Copy
Edit
📁 lib/app/modules/profile/
├── profile_view.dart
├── profile_controller.dart
├── profile_binding.dart
📍 app_routes.dart – Add Route
dart
Copy
Edit
static const profile = '/profile';
⚙️ profile_binding.dart
dart
Copy
Edit
import 'package:get/get.dart';
import 'profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProfileController());
  }
}
🧠 profile_controller.dart
dart
Copy
Edit
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final RxMap<String, dynamic> userData = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  void loadUserData() async {
    final doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
    userData.value = doc.data()!;
  }

  void updateProfile(String name, String bio) async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      'displayName': name,
      'bio': bio,
    });
    loadUserData();
    Get.snackbar('Success', 'Profile updated');
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    final fileName = '${_auth.currentUser!.uid}_avatar.jpg';

    final ref = FirebaseStorage.instance.ref().child('profile_pics/$fileName');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      'photoUrl': url,
    });

    loadUserData();
    Get.snackbar('Success', 'Profile picture updated');
  }
}
🖼️ profile_view.dart
dart
Copy
Edit
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    final nameController = TextEditingController();
    final bioController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Obx(() {
        final data = controller.userData;
        nameController.text = data['displayName'] ?? '';
        bioController.text = data['bio'] ?? '';

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: controller.pickAndUploadImage,
                child: CircleAvatar(
                  radius: 45,
                  backgroundImage: data['photoUrl'] != null && data['photoUrl'].isNotEmpty
                      ? NetworkImage(data['photoUrl'])
                      : null,
                  child: data['photoUrl'] == null || data['photoUrl'].isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => controller.updateProfile(
                  nameController.text.trim(),
                  bioController.text.trim(),
                ),
                child: const Text('Save Changes'),
              )
            ],
          ),
        );
      }),
    );
  }
}
➕ Add Route in AppPages.routes
dart
Copy
Edit
GetPage(
  name: Routes.profile,
  page: () => const ProfileView(),
  binding: ProfileBinding(),
),
👤 Add Profile Access from Home
In HomeView, add:

dart
Copy
Edit
actions: [
  IconButton(
    icon: const Icon(Icons.person),
    onPressed: () => Get.toNamed('/profile'),
  ),
]
✅ You Now Have:
Profile picture upload

Editable name + bio

Firestore + Storage integration

Smooth UX with success toasts

