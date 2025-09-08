import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';
import 'post_item_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void openChatWithUser(String otherUserId, String otherUserEmail) async {
    final myId = _auth.currentUser!.uid;
    final ids = [myId, otherUserId]..sort();
    final chatId = ids.join('_');
    await _firestore.collection('chats').doc(chatId).set({
      'users': ids,
      'userEmails': [_auth.currentUser!.email, otherUserEmail],
    }, SetOptions(merge: true));
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          otherUserEmail: otherUserEmail ?? 'User',
        ),
      ),
    );
  }

  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void openPostItemScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostItemScreen(isLost: true)),
    );
    setState(() {}); // Refresh after returning
  }

  // Delete Item
  void deleteItem(String id) {
    _firestore.collection("items").doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("items")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No items yet"));
                }
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data["itemName"] ?? "")
                      .toString()
                      .toLowerCase();
                  final desc = (data["description"] ?? "")
                      .toString()
                      .toLowerCase();
                  return name.contains(searchQuery) ||
                      desc.contains(searchQuery);
                }).toList();
                if (docs.isEmpty) {
                  return const Center(
                    child: Text("No items match your search."),
                  );
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading:
                            data["imageUrl"] != null &&
                                data["imageUrl"].toString().isNotEmpty
                            ? Image.network(
                                data["imageUrl"],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported, size: 40),
                        title: Text(data["itemName"] ?? "No Name"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data["description"] ?? ""),
                            Text("Category: ${data["category"] ?? ""}"),
                            Text("Location: ${data["location"] ?? ""}"),
                            Text("Type: ${data["type"] ?? ""}"),
                            Text("Date: ${data["date"] ?? ""}"),
                            if ((data["reward"] ?? '').toString().isNotEmpty)
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
                                      "Reward: ${data["reward"]}",
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
                        trailing: data["userId"] == _auth.currentUser?.uid
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => deleteItem(data.id),
                              )
                            : ElevatedButton.icon(
                                icon: const Icon(Icons.handshake, size: 18),
                                label: const Text(
                                  'Claim Item',
                                  style: TextStyle(fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  final ownerId = data["userId"];
                                  final ownerEmail =
                                      data["userEmail"] ?? 'User';
                                  openChatWithUser(ownerId, ownerEmail);
                                },
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openPostItemScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}
