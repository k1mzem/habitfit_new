import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/goals.dart';
import '../services/goal_service.dart';

class ActivitySessionService {
  static CollectionReference<Map<String, dynamic>> _getUserActivityCollection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception("User not logged in");
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('activity_sessions');
  }

  // 🔥 Add a new session directly under users/{uid}/activity_sessions
  static Future<void> addSession({
    required String type,
    required int duration, // in seconds
    required double distance,
    required double speed,
    required DateTime date,
  }) async {
    final collection = _getUserActivityCollection();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final dateId = DateFormat('ddMMyyyy').format(date);

    // 1. Add activity session
    await collection.add({
      'type': type,
      'duration': duration,
      'distance': distance,
      'speed': speed,
      'date': date,
      'dateId': dateId,
    });

    // 2. Recalculate today's activity total
    await GoalService().evaluateTodayGoals();
  }

  // 🔥 Delete a session by document ID
  static Future<void> deleteSession(String docId) async {
    final collection = _getUserActivityCollection();
    await collection.doc(docId).delete();

    // ✅ Re-evaluate physical goal after deletion
    await GoalService().evaluateTodayGoals();
  }

  // 🔍 Fetch all sessions
  static Future<List<Map<String, dynamic>>> fetchAllSessions() async {
    final collection = _getUserActivityCollection();
    final snapshot = await collection.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // 🔍 Fetch by type (e.g. running)
  static Future<List<Map<String, dynamic>>> fetchSessionsByType(String type) async {
    final collection = _getUserActivityCollection();
    final snapshot = await collection
        .where('type', isEqualTo: type)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
