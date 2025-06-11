import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/goal_service.dart';

class Meal {
  final String id;
  final String name;
  final int calories;
  final String mealType;
  final DateTime date;

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.mealType,
    required this.date,
  });

  factory Meal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Meal(
      id: doc.id,
      name: data['name'] ?? '',
      calories: data['calories'] ?? 0,
      mealType: data['mealType'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  static Future<void> addToFirestore(Meal meal) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meals');

    final dateId = DateFormat('ddMMyyyy').format(meal.date);

    final data = {
      'name': meal.name,
      'calories': meal.calories,
      'mealType': meal.mealType,
      'date': meal.date,
      'dateId': dateId,
    };

    if (meal.id.isNotEmpty) {
      await collection.doc(meal.id).set(data);
    } else {
      await collection.add(data);
    }

    // ✅ Refresh meal goal progress
    await GoalService().evaluateTodayGoals();
  }

  static Future<List<Meal>> fetchFromFirestore(String mealType) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meals')
        .where('mealType', isEqualTo: mealType)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => Meal.fromFirestore(doc)).toList();
  }

  static Future<List<Meal>> fetchAllMeals() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meals')
        .orderBy('name')
        .get();

    return snapshot.docs.map((doc) => Meal.fromFirestore(doc)).toList();
  }

  static Future<void> deleteFromFirestore(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc(id)
        .delete();

    // ✅ Re-evaluate meal goal after deletion
    await GoalService().evaluateTodayGoals();
  }

  static Future<List<Meal>> fetchAllFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meals')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => Meal.fromFirestore(doc)).toList();
    } catch (e) {
      print("⚠️ Error in fetchAllFromFirestore: $e");
      return [];
    }
  }
}
