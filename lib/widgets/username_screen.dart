import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController usernameController = TextEditingController();
  bool isLoading = false;

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> saveUsername() async {
    final username = usernameController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (username.isEmpty || user == null) {
      showError('Username cannot be empty');
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': username,
        'email': user.email,
        'photoUrl': user.photoURL ?? '',
        'createdAt': Timestamp.now(),
      }, SetOptions(merge: true));

      Navigator.pushReplacementNamed(context, '/bmi'); // 🔜 next step
    } catch (e) {
      showError('Failed to save username: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Username')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Choose your username', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : saveUsername,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Next'),
            )
          ],
        ),
      ),
    );
  }
}
