import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart'; // ✅ Import your AuthService

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showError('Please enter both email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('No user found');

      final goalDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('goal')
          .doc('current')
          .get();

      final hasGoal = goalDoc.exists && (goalDoc.data()?['goalType'] ?? '').toString().isNotEmpty;
      final route = hasGoal ? '/dashboard' : '/goal';

      Navigator.pushReplacementNamed(context, route);
    } catch (e) {
      showError(e is FirebaseAuthException
          ? e.message ?? 'Firebase error occurred'
          : 'Unexpected error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> loginWithGoogle() async {
    final userCredential = await AuthService().signInWithGoogle();
    final user = userCredential?.user;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    // ✅ If it's a new Google user, create a base profile
    if (!userDoc.exists) {
      await userRef.set({
        'username': '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'createdAt': DateTime.now(),
        'goal': null,
        'bmi': 0,
        'height': 0,
        'streak': 0,
      });
      Navigator.pushReplacementNamed(context, '/username');
      return;
    }

    // ✅ Existing user — check onboarding progress
    final data = userDoc.data() ?? {};
    if ((data['username'] ?? '').toString().isEmpty) {
      Navigator.pushReplacementNamed(context, '/username');
    } else if (data['height'] == null || data['weight'] == null) {
      Navigator.pushReplacementNamed(context, '/bmi');
    } else if ((data['goal'] ?? '').toString().isEmpty) {
      Navigator.pushReplacementNamed(context, '/goal');
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }





  void navigateToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'Welcome to HabitFit',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login'),
                ),
                const SizedBox(height: 16),

                // 🔵 Google Sign-In Button
                ElevatedButton.icon(
                  onPressed: loginWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text("Sign in with Google"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: navigateToRegister,
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
