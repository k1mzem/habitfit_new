import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DailyTaskGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> run() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userRef = _firestore.collection('users').doc(uid);
    final now = DateTime.now();
    final todayId = DateFormat('ddMMyyyy').format(now);

    //  Skip if already generated today
    final checkRef = userRef.collection('daily_tasks_generated').doc(todayId);
    final alreadyGenerated = await checkRef.get();
    if (alreadyGenerated.exists) {
      // Check if target values are invalid (zero)
      final dailyRef = userRef.collection('Daily_goal');
      final mealsDoc = await dailyRef.doc('meals').get();
      final physicalDoc = await dailyRef.doc('physical').get();
      final sleepDoc = await dailyRef.doc('sleep').get();

      bool hasInvalidTarget = false;
      for (final doc in [mealsDoc, physicalDoc, sleepDoc]) {
        final data = doc.data();
        if (data == null || (data['target'] ?? 0) == 0) {
          hasInvalidTarget = true;
          break;
        }
      }

      if (!hasInvalidTarget) {
        return; // Only skip if valid targets already exist
      }
    }


    // Fetch goal and assigned program
    final goalSnap = await userRef.collection('goal').doc('current').get();
    final goalType = goalSnap.data()?['goalType'] ?? '';
    final programSnap = await userRef.collection('programs').doc(goalType).get();
    if (!goalSnap.exists || !programSnap.exists) return;

    final int currentWeek = programSnap.data()?['currentWeek'] ?? 1;
    final String templateId = programSnap.data()?['templateId'] ?? '';

    //  Fetch week data from program_templates
    final weekSnap = await _firestore
        .collection('program_templates')
        .doc(templateId)
        .collection('weeks')
        .doc(currentWeek.toString())
        .get();
    if (!weekSnap.exists) return;

    final data = weekSnap.data() ?? {};

    //  Extract goal targets
    final double targetPhysical = _extractMinutes(data['physicalGoal'] ?? '');
    final double targetMeals = _extractMealTarget(data['mealGoal'] ?? '');
    final double targetSleep = _extractSleepTarget(data['sleepGoal'] ?? '');

    final dayStart = DateTime(now.year, now.month, now.day);
    final timestampStart = Timestamp.fromDate(dayStart);

    //  Physical
    final physQuery = await userRef
        .collection('activity_sessions')
        .where('createdAt', isGreaterThanOrEqualTo: timestampStart)
        .get();
    final totalPhysical = physQuery.docs.fold<double>(
      0,
          (sum, doc) => sum + (doc.data()['duration'] ?? 0).toDouble(),
    );

    // 🍽 Meals
    final mealsQuery = await userRef
        .collection('meals')
        .where('createdAt', isGreaterThanOrEqualTo: timestampStart)
        .get();
    final totalMeals = mealsQuery.docs.fold<double>(
      0,
          (sum, doc) => sum + (doc.data()['calories'] ?? 0).toDouble(),
    );

    // 💤 Sleep
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final sleepQuery = await userRef
        .collection('sleep_entries')
        .where('wakeTime', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('wakeTime', isLessThan: Timestamp.fromDate(tomorrow))
        .get();

    double totalSleep = 0;

    if (sleepQuery.docs.isNotEmpty) {
      final latestDoc = sleepQuery.docs.first;
      final data = latestDoc.data();
      final rawDuration = data['duration'];
      totalSleep = (rawDuration ?? 0).toDouble();
    }

    // Save to Daily_goal
    final dailyRef = userRef.collection('Daily_goal');
    await dailyRef.doc('physical').set({
      'type': 'physical',
      'target': targetPhysical,
      'current': totalPhysical,
      'date': now,
    });
    await dailyRef.doc('meals').set({
      'type': 'meals',
      'target': targetMeals,
      'current': totalMeals,
      'date': now,
    });
    await dailyRef.doc('sleep').set({
      'type': 'sleep',
      'target': targetSleep,
      'current': totalSleep,
      'date': now,
    });

    // 📌 Mark today's task as generated
    await checkRef.set({'generatedAt': now});
    print("✅ Daily goals generated from template: $templateId → Week $currentWeek");
  }

  double _extractMinutes(String input) {
    final match = RegExp(r'(\d+)\s*min').firstMatch(input.toLowerCase());
    return match != null ? double.tryParse(match.group(1)!) ?? 30 : 30;
  }

  double _extractMealTarget(String input) {
    final match = RegExp(r'(\d{3,4})').firstMatch(input);
    return match != null ? double.tryParse(match.group(1)!) ?? 1300 : 1300;
  }

  double _extractSleepTarget(String input) {
    final range = RegExp(r'(\d+\.?\d*)\s*[–-]\s*(\d+\.?\d*)').firstMatch(input);
    if (range != null) {
      final a = double.tryParse(range.group(1)!) ?? 7;
      final b = double.tryParse(range.group(2)!) ?? 9;
      return (a + b) / 2;
    }

    final single = RegExp(r'(\d+\.?\d*)').firstMatch(input);
    return single != null ? double.tryParse(single.group(1)!) ?? 8 : 8;
  }
}
