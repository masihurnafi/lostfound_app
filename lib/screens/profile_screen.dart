import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    }

    setState(() {
      isLoading = false;
    });
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
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: "Phone"),
                  ),
                  TextField(
                    controller: departmentController,
                    decoration: const InputDecoration(labelText: "Department"),
                  ),
                  TextField(
                    controller: batchController,
                    decoration: const InputDecoration(labelText: "Batch"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: updateProfile,
                    child: const Text("Update Profile"),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    "Your Posted Items",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection("items")
                        .where("userId", isEqualTo: _auth.currentUser!.uid)
                        .orderBy("date", descending: true)
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
                          return ListTile(
                            title: Text(data["title"]),
                            subtitle: Text(
                              "${data["description"]}\nCategory: ${data["category"]}\nContact: ${data["contact"]}",
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
