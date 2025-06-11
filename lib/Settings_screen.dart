import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habitfit_new/changepass_screen.dart';
import 'package:habitfit_new/reminder_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'user_guideline-screen.dart';
import 'terms_screen.dart';
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pop(dialogContext);
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                } catch (e) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $e')),
                  );
                }
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to permanently delete your account? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.currentUser?.delete();
                  Navigator.pop(dialogContext);
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                } catch (e) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Yes, Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }

  void _openAppSettings(BuildContext context) async {
    final opened = await openAppSettings();
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open app settings.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'General',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.grey[900],
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined, color: Colors.white70),
              title: const Text('Reminder Settings', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen())),
            ),
          ),
          Card(
            color: Colors.grey[900],
            child: ListTile(
              leading: const Icon(Icons.security_outlined, color: Colors.white70),
              title: const Text('Manage Permissions', style: TextStyle(color: Colors.white)),
              onTap: () => _openAppSettings(context),
            ),
          ),
          Card(
            color: Colors.grey[900],
            child: ListTile(
              leading: const Icon(Icons.article_outlined, color: Colors.white70),
              title: const Text('View Terms and condition', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsScreen()),
                );
              },
            ),
          ),
          Card(
            color: Colors.grey[900],
            child: ListTile(
              leading: const Icon(Icons.supervised_user_circle, color: Colors.white70),
              title: const Text('User Guideline', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => const UserGuidelineScreen())); },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.grey[900],
            child: ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.white70),
              title: const Text('Change Password', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
          ),
          Card(
            color: Colors.red[800],
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.white),
              title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
              onTap: () => _confirmDeleteAccount(context),
            ),
          ),
          Card(
            color: Colors.red[900],
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text('Log Out', style: TextStyle(color: Colors.white)),
              onTap: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }
}
