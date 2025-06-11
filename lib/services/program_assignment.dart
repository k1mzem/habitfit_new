import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> assignBMIProgramToUser({
  required String uid,
  required double heightCm,
  required double currentWeight,
  required double targetWeight,
}) async {
  final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
  final programRef = userRef.collection('programs').doc('lose_weight');

  final heightM = heightCm / 100;
  final bmi = currentWeight / (heightM * heightM);

  // Determine template ID based on BMI
  String templateId;
  if (bmi < 18.5) {
    templateId = 'lose_weight_bmi_low';
  } else if (bmi < 25) {
    templateId = 'lose_weight_bmi_normal';
  } else if (bmi < 30) {
    templateId = 'lose_weight_bmi_overweight';
  } else {
    templateId = 'lose_weight_bmi_obese';
  }

  final now = DateTime.now();
  final startDate = now.toIso8601String();

  // Fetch Week 1 from selected BMI template
  final week1Doc = await FirebaseFirestore.instance
      .collection('program_templates')
      .doc(templateId)
      .collection('weeks')
      .doc('1')
      .get();

  if (!week1Doc.exists) {
    throw Exception('Week 1 not found in $templateId');
  }

  final weekData = week1Doc.data();

  // Save metadata
  await programRef.set({
    'startDate': startDate,
    'currentWeek': 1,
    'templateId': templateId,
    'bmi': double.parse(bmi.toStringAsFixed(2)),
    'targetWeight': targetWeight,
    'currentWeight': currentWeight,
    'height': heightCm,
    'active': true,
    'type': 'calorie_deficit',
  });

  // Store Week 1 goals
  await programRef.collection('weeks').doc('1').set({
    ...weekData!,
    'isCompleted': false,
    'completedPhysical': false,
    'completedMeal': false,
    'completedSleep': false,
  });

  print("✅ Assigned Lose Weight BMI program: $templateId → Week 1");
}
