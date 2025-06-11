import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/goal_service.dart';

class SleepEntry {
  final String id;
  final DateTime sleepTime;
  final DateTime wakeTime;
  final String date; // formatted: ddMMyyyy

  SleepEntry({
    required this.id,
    required this.sleepTime,
    required this.wakeTime,
    required this.date,
  });

  factory SleepEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SleepEntry(
      id: doc.id,
      sleepTime: (data['sleepTime'] as Timestamp).toDate(),
      wakeTime: (data['wakeTime'] as Timestamp).toDate(),
      date: data['date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'sleepTime': sleepTime,
    'wakeTime': wakeTime,
    'date': date,
    'duration': wakeTime.difference(sleepTime).inMinutes / 60.0,
  };

  static Future<List<SleepEntry>> fetchAll() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sleep_entries')
        .orderBy('sleepTime', descending: true)
        .get();

    return snapshot.docs.map((doc) => SleepEntry.fromFirestore(doc)).toList();
  }

  static Future<void> addOrUpdate(SleepEntry entry) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sleep_entries');

    // ✅ Ensure correct date format
    final formattedDate = DateFormat('ddMMyyyy').format(entry.sleepTime);
    final data = {
      'sleepTime': entry.sleepTime,
      'wakeTime': entry.wakeTime,
      'date': formattedDate,
      'duration': entry.wakeTime.difference(entry.sleepTime).inMinutes / 60.0,
    };

    if (entry.id.isNotEmpty) {
      await ref.doc(entry.id).set(data);
    } else {
      await ref.add(data);
    }

    // ✅ Update 'current/sleep'
    final currentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('current')
        .doc('sleep');

    await currentRef.set({
      'duration': data['duration'],
      'sleepTime': data['sleepTime'],
      'wakeTime': data['wakeTime'],
      'date': data['date'],
    });

    // ✅ Re-evaluate today's goal
    await GoalService().evaluateTodayGoals();
  }

  static Future<void> delete(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sleep_entries');

    await ref.doc(id).delete();

    // ✅ Re-evaluate after deletion
    await GoalService().evaluateTodayGoals();
  }
}
