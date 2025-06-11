import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Uploads all program templates (lose_weight, build_muscle, fix_sleep) into Firestore
Future<void> uploadAllProgramTemplates() async {
  try {
    final String jsonString =
    await rootBundle.loadString('assets/fix_sleep_template.json');
    final dynamic parsedJson = json.decode(jsonString);

    if (parsedJson is Map<String, dynamic>) {
      // 🔁 Handle Map-style templates (e.g. lose_weight, build_muscle)
      for (final programId in parsedJson.keys) {
        final program = parsedJson[programId];
        final Map<String, dynamic> weeks = program['weeks'] ?? {};

        final templateRef = FirebaseFirestore.instance
            .collection('program_templates')
            .doc(programId);

        await templateRef.set({
          'type': program['type'] ?? '',
          if (program.containsKey('bmiRange')) 'bmiCategory': program['bmiRange'],
          'weeks': weeks.length,
          'title': program['title'] ?? '',
          'description': program['description'] ?? '',
        });

        for (final weekNumber in weeks.keys) {
          final week = weeks[weekNumber];
          await templateRef.collection('weeks').doc(weekNumber).set(week);
        }
      }
    } else if (parsedJson is List) {
      // 🔁 Handle List-style templates (e.g. fix_sleep flat list)
      for (final program in parsedJson) {
        final String programId = program['id'];
        final Map<String, dynamic> weeks = program['weeks'] ?? {};

        final templateRef = FirebaseFirestore.instance
            .collection('program_templates')
            .doc(programId);

        await templateRef.set({
          'type': program['type'] ?? '',
          if (program.containsKey('bmiRange')) 'bmiCategory': program['bmiRange'],
          'weeks': weeks.length,
          'title': program['title'] ?? '',
          'description': program['description'] ?? '',
        });

        for (final weekNumber in weeks.keys) {
          final week = weeks[weekNumber];
          await templateRef.collection('weeks').doc(weekNumber).set(week);
        }
      }
    } else {
      throw FormatException("Invalid JSON format.");
    }

    print('✅ All program templates uploaded to Firestore.');
  } catch (e) {
    print('❌ Failed to upload program templates: $e');
  }
}
