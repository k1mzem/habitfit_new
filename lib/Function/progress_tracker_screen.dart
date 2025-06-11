import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProgressTrackerScreen extends StatefulWidget {
  const ProgressTrackerScreen({super.key});

  @override
  State<ProgressTrackerScreen> createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen> {
  late DateTime startOfWeek;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
  }

  Future<Map<String, dynamic>> _fetchDataForDay(DateTime day) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final dateId = DateFormat('ddMMyyyy').format(day);

    final activitySnapshot = await userRef
        .collection('activity_sessions')
        .where('dateId', isEqualTo: dateId)
        .get();

    final mealSnapshot = await userRef
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .get();

    final sleepSnapshot = await userRef
        .collection('sleep_entries')
        .where('sleepTime', isGreaterThanOrEqualTo: start)
        .where('sleepTime', isLessThan: end)
        .get();

    return {
      'activities': activitySnapshot.docs,
      'meals': mealSnapshot.docs,
      'sleep': sleepSnapshot.docs,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchWeekData() async {
    List<Map<String, dynamic>> weekData = [];
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final data = await _fetchDataForDay(day);
      weekData.add(data);
    }
    return weekData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Tracker')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchWeekData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No Data Found'));
          }

          final weekData = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: weekData.length,
            itemBuilder: (context, index) {
              final dayData = weekData[index];
              final date = startOfWeek.add(Duration(days: index));
              return _buildDaySection(date, dayData);
            },
          );
        },
      ),
    );
  }

  Widget _buildDaySection(DateTime date, Map<String, dynamic> data) {
    final formattedDate = DateFormat('EEEE, dd MMM').format(date);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formattedDate, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            _buildSection('Physical Activities', data['activities'], isActivity: true),
            const SizedBox(height: 12),
            _buildSection('Meals', data['meals'], isMeal: true),
            const SizedBox(height: 12),
            _buildSection('Sleep', data['sleep'], isSleep: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items,
      {bool isActivity = false, bool isMeal = false, bool isSleep = false}) {
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyan)),
          const SizedBox(height: 8),
          const Text('No record', style: TextStyle(color: Colors.white70)),
        ],
      );
    }

    String _formatDuration(int seconds) {
      final minutes = seconds ~/ 60;
      final remSeconds = seconds % 60;
      return '${minutes}m ${remSeconds}s';
    }

    String _formatSleepDuration(Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyan)),
        const SizedBox(height: 8),
        ...items.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          if (isActivity) {
            final type = data['type'] ?? 'Activity';
            final duration = data['duration'] ?? 0;
            final distance = (data['distance'] ?? 0.0).toDouble();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '$type - ${_formatDuration(duration)} - ${distance.toStringAsFixed(2)} km',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          } else if (isMeal) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${data['mealType'] ?? 'Meal'}: ${data['name'] ?? ''} (${(data['calories'] ?? 0).toString()} kcal)',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          } else if (isSleep) {
            final sleepTime = (data['sleepTime'] as Timestamp).toDate();
            final wakeTime = (data['wakeTime'] as Timestamp).toDate();
            final duration = wakeTime.difference(sleepTime);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Slept for ${_formatSleepDuration(duration)} (${DateFormat('hh:mm a').format(sleepTime)} ➔ ${DateFormat('hh:mm a').format(wakeTime)})',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          return const SizedBox.shrink();
        }).toList(),
      ],
    );
  }
}
