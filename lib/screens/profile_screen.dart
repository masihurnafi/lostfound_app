import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? profileImageUrl;
  bool uploadingImage = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController batchController = TextEditingController();

  bool isLoading = true;

  void loadUserProfile() async {
    final userId = _auth.currentUser!.uid;
    final doc = await _firestore.collection("users").doc(userId).get();
    if (doc.exists) {
      nameController.text = doc["name"];
      phoneController.text = doc["phone"];
      departmentController.text = doc["department"];
      batchController.text = doc["batch"];
      if (doc.data()!.containsKey('profileImageUrl')) {
        profileImageUrl = doc["profileImageUrl"];
      }
    }
    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  Future<void> pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    final file = File(picked.path);
    final bytes = await file.length();
    if (bytes > 2 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image must be less than 2MB.')),
      );
      return;
    }
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 85,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Picture',
          toolbarColor: Colors.green,
          toolbarWidgetColor: Colors.white,
          hideBottomControls: true,
        ),
        IOSUiSettings(title: 'Crop Profile Picture'),
      ],
    );
    if (cropped == null) {
      return;
    }
    setState(() => uploadingImage = true);
    try {
      final userId = _auth.currentUser!.uid;
      final ref = FirebaseStorage.instance.ref().child(
        'profile_pics/$userId.jpg',
      );
      await ref.putFile(File(cropped.path));
      final url = await ref.getDownloadURL();
      await _firestore.collection('users').doc(userId).set({
        'profileImageUrl': url,
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        profileImageUrl = url;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    } finally {
      if (mounted) setState(() => uploadingImage = false);
    }
  }

  void updateProfile() async {
    final userId = _auth.currentUser!.uid;
    await _firestore.collection("users").doc(userId).set({
      "name": nameController.text.trim(),
      "phone": phoneController.text.trim(),
      "department": departmentController.text.trim(),
      "batch": batchController.text.trim(),
      "email": _auth.currentUser!.email,
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );
  }

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.green[700],
                              backgroundImage:
                                  (profileImageUrl != null &&
                                      profileImageUrl!.isNotEmpty)
                                  ? NetworkImage(profileImageUrl!)
                                  : null,
                              child:
                                  (profileImageUrl == null ||
                                      profileImageUrl!.isEmpty)
                                  ? Text(
                                      (user?.displayName != null &&
                                              user!.displayName!.isNotEmpty)
                                          ? user.displayName![0].toUpperCase()
                                          : (user?.email != null &&
                                                user!.email!.isNotEmpty)
                                          ? user.email![0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: uploadingImage
                                    ? null
                                    : pickAndUploadProfileImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: uploadingImage
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          size: 18,
                                          color: Colors.green,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.green),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: "Name",
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.green),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: phoneController,
                                  decoration: const InputDecoration(
                                    labelText: "Phone",
                                    border: InputBorder.none,
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.school, color: Colors.green),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: departmentController,
                                  decoration: const InputDecoration(
                                    labelText: "Department",
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.group, color: Colors.green),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: batchController,
                                  decoration: const InputDecoration(
                                    labelText: "Batch",
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: updateProfile,
                              icon: const Icon(Icons.save),
                              label: const Text(
                                "Update Profile",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    "Your Posted Items",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection("items")
                        .where("userId", isEqualTo: _auth.currentUser!.uid)
                        .orderBy("createdAt", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Text("No items posted yet");
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index];
                          final item = data.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading:
                                  item["imageUrl"] != null &&
                                      item["imageUrl"].toString().isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item["imageUrl"],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                    ),
                              title: Text(
                                item["itemName"] ?? "No Name",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item["description"] ?? "",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text("Category: ${item["category"] ?? ""}"),
                                  Text("Location: ${item["location"] ?? ""}"),
                                  Text("Type: ${item["type"] ?? ""}"),
                                  Text("Date: ${item["date"] ?? ""}"),
                                  if ((item["reward"] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.card_giftcard,
                                            color: Colors.amber,
                                            size: 18,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            "Reward: ${item["reward"]}",
                                            style: const TextStyle(
                                              color: Colors.amber,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  await _firestore
                                      .collection("items")
                                      .doc(data.id)
                                      .delete();
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
