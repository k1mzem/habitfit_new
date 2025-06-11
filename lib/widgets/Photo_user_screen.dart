import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Day1PhotoScreen extends StatefulWidget {
  const Day1PhotoScreen({super.key});

  @override
  State<Day1PhotoScreen> createState() => _Day1PhotoScreenState();
}

class _Day1PhotoScreenState extends State<Day1PhotoScreen> {
  File? _image;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadPhoto() async {
    if (_image == null) return;
    setState(() => _isUploading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final ref = FirebaseStorage.instance
          .ref('progress_photos/$uid/day1.jpg');
      await ref.putFile(_image!);
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('progressPhotos')
          .doc('day1')
          .set({
        'url': downloadUrl,
        'uploadedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Day 1 photo uploaded successfully!')),
      );
      Navigator.pop(context); // Go back or move to the next screen
    } catch (e) {
      print('Upload failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload: ${e.toString()}')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Day 1 Photo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Let\'s begin your transformation!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickImage,
              child: _image == null
                  ? Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[800],
                ),
                child: const Center(
                  child: Text(
                    'Tap to select photo',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_image!, height: 200),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadPhoto,
              icon: const Icon(Icons.upload),
              label: _isUploading
                  ? const CircularProgressIndicator()
                  : const Text('Upload'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
