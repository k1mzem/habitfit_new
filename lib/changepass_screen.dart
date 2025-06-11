import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  void _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;

    // Detect Google sign-in user (no password provider)
    final providers = await FirebaseAuth.instance.fetchSignInMethodsForEmail(user!.email!);
    if (!providers.contains('password')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ You signed up with Google. Password change is not available."),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: _oldPasswordController.text.trim(),
    );

    try {
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPasswordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Password updated successfully.")),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Something went wrong.";
      if (e.code == 'wrong-password') {
        errorMsg = "❌ Incorrect current password.";
      } else {
        errorMsg = "⚠️ ${e.message}";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter current password' : null,
              ),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (value) =>
                value != null && value.length >= 6 ? null : 'Minimum 6 characters',
              ),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
                validator: (value) =>
                value == _newPasswordController.text ? null : 'Passwords do not match',
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _updatePassword,
                child: const Text("Update Password"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
