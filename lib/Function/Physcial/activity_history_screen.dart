import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  Future<Map<String, List<Map<String, dynamic>>>> _fetchGroupedActivities() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('activity_sessions')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .orderBy('date', descending: false)
        .get();

    final Map<String, List<Map<String, dynamic>>> grouped = {
      for (var i = 0; i < 7; i++) DateFormat('EEEE').format(start.add(Duration(days: i))): []
    };

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as Timestamp).toDate();
      final day = DateFormat('EEEE').format(date);
      grouped[day]?.add({...data, 'id': doc.id});
    }

    return grouped;
  }

  void _editActivity(BuildContext context, String docId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit $docId (not implemented)')),
    );
  }

  void _deleteActivity(BuildContext context, String docId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('activity_sessions')
        .doc(docId)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity deleted')),
    );
  }

  double _calculateCalories(String type, int durationSeconds) {
    double met = 8.0;
    if (type == 'running') met = 9.8;
    else if (type == 'cycling') met = 7.5;
    else if (type == 'custom') met = 6.0;

    final weightKg = 70;
    return (met * 3.5 * weightKg / 200) * (durationSeconds / 60.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Activity History'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _fetchGroupedActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No activity this week.', style: TextStyle(color: Colors.white70)),
            );
          }

          final groupedActivities = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: groupedActivities.entries.expand((entry) {
              final day = entry.key;
              final activities = entry.value;

              return activities.map((activity) {
                final type = activity['type'] ?? 'Unknown';
                final duration = activity['duration'] ?? 0;
                final docId = activity['id'];
                final calories = _calculateCalories(type, duration);
                final time = '${duration ~/ 60}m ${duration % 60}s';

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$type • $time • ${calories.toStringAsFixed(1)} kcal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _editActivity(context, docId),
                              child: const Text('Edit', style: TextStyle(color: Colors.blue)),
                            ),
                            TextButton(
                              onPressed: () => _deleteActivity(context, docId),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              });
            }).toList(),
          );
        },
      ),
    );
  }
}
