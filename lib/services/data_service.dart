import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DataService {
  static Future<Map<String, dynamic>> fetchDataForDay(DateTime day) async {
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
}
