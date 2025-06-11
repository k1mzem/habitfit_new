import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalService {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final _firestore = FirebaseFirestore.instance;

  /// ✅ Check if user has met all daily goals by comparing current vs target
  Future<bool> hasCompletedTodayGoal() async {
    if (uid == null) return false;

    final types = ['physical', 'meals', 'sleep'];
    bool allMet = true;

    for (String type in types) {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('Daily_goal')
          .doc(type)
          .get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final double current = (data['current'] ?? 0).toDouble();
      final double target = (data['target'] ?? 0).toDouble();

      if (current < target) {
        allMet = false;
      }
    }

    return allMet;
  }

  /// ✅ Update goal (current and/or target)
  Future<void> updateGoal({
    required String type,
    double? target,
    double? current,
  }) async {
    if (uid == null) return;

    final updates = <String, dynamic>{};
    if (target != null) updates['target'] = target;
    if (current != null) updates['current'] = current;

    if (updates.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('Daily_goal')
          .doc(type.toLowerCase())
          .set(updates, SetOptions(merge: true));
    }
  }

  /// Recalculate today activities
  Future<void> evaluateTodayGoals() async {
    if (uid == null) return;

    final userRef = _firestore.collection('users').doc(uid);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final todayId = '${now.day.toString().padLeft(2, '0')}${now.month.toString()
        .padLeft(2, '0')}${now.year}';
    final todayDateId = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    // Physical
    final activitySnapshot = await userRef
        .collection('activity_sessions')
        .where('dateId', isEqualTo: todayId)
        .get();

    final int totalSeconds = activitySnapshot.docs.fold(0, (sum, doc) {
      final value = doc['duration'];
      return sum + (value is int ? value : 0);
    });

    final double totalMinutes = totalSeconds / 60.0;
    await updateGoal(type: 'physical', current: totalMinutes);

    // Meals
    final mealSnapshot = await userRef
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: todayStart)
        .where('date', isLessThan: todayEnd)
        .get();

    final int totalCalories = mealSnapshot.docs.fold(0, (sum, doc) {
      final value = doc['calories'];
      return sum + (value is int ? value : 0);
    });

    await updateGoal(type: 'meals', current: totalCalories.toDouble());

    //  Sleep
    final sleepSnapshot = await userRef
        .collection('sleep_entries')
        .where('sleepTime', isGreaterThanOrEqualTo: todayStart)
        .where('sleepTime', isLessThan: todayEnd)
        .orderBy('sleepTime', descending: true)
        .limit(1)
        .get();

    if (sleepSnapshot.docs.isNotEmpty) {
      final data = sleepSnapshot.docs.first.data();
      final double sleepHours = (data['duration'] ?? 0).toDouble();
      await updateGoal(type: 'sleep', current: sleepHours);
    }

    //  Evaluate all goals
    final bool allCompleted = await hasCompletedTodayGoal();
    final int doneStatus = allCompleted ? 3 : 2;

    await userRef
        .collection('dailyTasks')
        .doc(todayDateId)
        .set({'done': doneStatus}, SetOptions(merge: true));
  }

  //  Streak Counter
  Future<void> updateStreakCounter() async {
    if (uid == null) return;

    final userRef = _firestore.collection('users').doc(uid);
    final now = DateTime.now();
    final todayId = DateTime(now.year, now.month, now.day);
    final yesterdayId = todayId.subtract(const Duration(days: 1));

    final todayFormatted = '${todayId.year}-${todayId.month.toString().padLeft(2, '0')}-'
        '${todayId.day.toString().padLeft(2, '0')}';
    final yesterdayFormatted = '${yesterdayId.year}-${yesterdayId.month.toString().padLeft(2, '0')}-'
        '${yesterdayId.day.toString().padLeft(2, '0')}';

    final todayDoc = await userRef.collection('dailyTasks').doc(todayFormatted).get();
    final yesterdayDoc = await userRef.collection('dailyTasks').doc(yesterdayFormatted).get();

    final userSnapshot = await userRef.get();
    int currentStreak = userSnapshot.data()?['streak'] ?? 0;

    final todayDone = todayDoc.data()?['done'] ?? 0;
    final yesterdayDone = yesterdayDoc.data()?['done'] ?? 0;

    if (todayDone == 3 && yesterdayDone == 3) {
      currentStreak += 1;
    } else if (todayDone == 3 && yesterdayDone != 3) {
      currentStreak = 1;
    } else if (todayDone != 3) {
      currentStreak = 0;
    }

    await userRef.set({'streak': currentStreak}, SetOptions(merge: true));
  }
}
