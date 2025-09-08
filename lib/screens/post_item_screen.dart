import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostItemScreen extends StatefulWidget {
  final bool isLost; // true for lost, false for found
  const PostItemScreen({required this.isLost, super.key});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final TextEditingController rewardController = TextEditingController();
  bool isLoading = false;
  Future<String?> uploadImage(File file) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child(
        'item_images/$userId/$fileName',
      );
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  String? category;
  File? imageFile;

  final List<String> categories = [
    'Electronics',
    'Books',
    'ID Cards',
    'Clothing',
    'Accessories',
    'Other',
  ];

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLost ? 'Post Lost Item' : 'Post Found Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rewardController,
                decoration: const InputDecoration(
                  labelText: 'Reward (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.card_giftcard),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => category = val),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? 'Select category' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: widget.isLost ? 'Location Lost' : 'Location Found',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date & Time',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (!mounted) return;
                  if (picked != null) {
                    dateController.text = picked.toString().split(' ')[0];
                  }
                },
                readOnly: true,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              imageFile == null
                  ? OutlinedButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Attach Photo'),
                    )
                  : Column(
                      children: [
                        Image.file(imageFile!, height: 120),
                        TextButton(
                          onPressed: () => setState(() => imageFile = null),
                          child: const Text('Remove Photo'),
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => isLoading = true);
                          String? imageUrl;
                          if (imageFile != null) {
                            imageUrl = await uploadImage(imageFile!);
                          }
                          final user = FirebaseAuth.instance.currentUser;
                          await FirebaseFirestore.instance
                              .collection('items')
                              .add({
                                'itemName': nameController.text.trim(),
                                'description': descController.text.trim(),
                                'category': category,
                                'location': locationController.text.trim(),
                                'date': dateController.text.trim(),
                                'imageUrl': imageUrl,
                                'type': widget.isLost ? 'lost' : 'found',
                                'userId': user?.uid ?? 'anonymous',
                                'userEmail': user?.email ?? '',
                                'reward': rewardController.text.trim(),
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                          setState(() => isLoading = false);
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Item posted successfully!'),
                              ),
                            );
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.isLost ? 'Post Lost Item' : 'Post Found Item',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
