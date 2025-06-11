import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static Future<List<Map<String, dynamic>>> fetchMealsByType(String type) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('meals')
        .where('mealType', isEqualTo: type)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
