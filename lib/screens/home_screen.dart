import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart'; // Make sure you have this file

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  String category = "Lost"; // default

  // Add Item
  void addItem() async {
    String title = titleController.text.trim();
    String description = descriptionController.text.trim();
    String contact = contactController.text.trim();

    if (title.isEmpty || description.isEmpty || contact.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("All fields are required")));
      return;
    }

    await _firestore.collection("items").add({
      "title": title,
      "description": description,
      "category": category,
      "date": FieldValue.serverTimestamp(),
      "userId": _auth.currentUser!.uid,
      "contact": contact,
    });

    titleController.clear();
    descriptionController.clear();
    contactController.clear();
    Navigator.pop(context);
  }

  // Add Item Dialog
  void showAddItemDialog() {
    titleController.clear();
    descriptionController.clear();
    contactController.clear();
    category = "Lost";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Lost/Found Item"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: "Title"),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(hintText: "Description"),
              ),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(hintText: "Contact Info"),
              ),
              DropdownButton<String>(
                value: category,
                items: ["Lost", "Found"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    category = val!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(onPressed: addItem, child: const Text("Add")),
        ],
      ),
    );
  }

  // Edit Item Dialog
  void showEditItemDialog(DocumentSnapshot doc) {
    titleController.text = doc["title"];
    descriptionController.text = doc["description"];
    contactController.text = doc["contact"];
    category = doc["category"];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Item"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: "Title"),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(hintText: "Description"),
              ),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(hintText: "Contact Info"),
              ),
              DropdownButton<String>(
                value: category,
                items: ["Lost", "Found"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    category = val!;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection("items").doc(doc.id).update({
                "title": titleController.text.trim(),
                "description": descriptionController.text.trim(),
                "contact": contactController.text.trim(),
                "category": category,
                "date": FieldValue.serverTimestamp(),
              });

              titleController.clear();
              descriptionController.clear();
              contactController.clear();
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // Delete Item
  void deleteItem(String id) {
    _firestore.collection("items").doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lost & Found"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (user != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green[900],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Logged in as: ${user.email}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    "UID: ${user.uid}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("items")
                  .orderBy("date", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No items yet"));
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    return ListTile(
                      title: Text(data["title"]),
                      subtitle: Text(
                        "${data["description"]}\nCategory: ${data["category"]}\nContact: ${data["contact"]}",
                      ),
                      isThreeLine: true,
                      trailing: data["userId"] == _auth.currentUser!.uid
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => showEditItemDialog(data),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => deleteItem(data.id),
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
