import 'package:flutter/material.dart';

class UserGuidelineScreen extends StatelessWidget {
  const UserGuidelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Guideline")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              "Welcome to HabitFit!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text("📌 Here's how to use the app:"),
            SizedBox(height: 12),
            Text("1. Set your personal goal (e.g. Lose weight, Build muscle)."),
            Text("2. Log your daily physical activities, meals, and sleep."),
            Text("3. Check the Dashboard to see your streak and progress."),
            Text("4. Set reminders to stay on track."),
            Text("5. View your past records in the Progress Tracker."),
            SizedBox(height: 20),
            Text("🎯 Tips:"),
            Text("- Be consistent with your logs."),
            Text("- Use reminders to help build habits."),
            Text("- Sync your data with Firebase for backup."),
          ],
        ),
      ),
    );
  }
}
