import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  String? _selectedGoal;
  bool _isLoading = false;

  final List<Map<String, dynamic>> goals = [
    {
      'label': 'Lose Weight',
      'value': 'lose_weight',
      'color': Colors.blue,
    },
    {
      'label': 'Fix Sleep Schedule',
      'value': 'fix_sleep',
      'color': Colors.orange,
    },
    {
      'label': 'Build Muscle',
      'value': 'build_muscle',
      'color': Colors.red,
    },
  ];

  void _selectGoal(String goalValue) {
    setState(() {
      _selectedGoal = goalValue;
    });
  }

  Future<void> _continue() async {
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a goal to continue')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 30));

      // Get BMI from user profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final bmi = userDoc.data()?['bmi'];
      if (bmi == null) throw Exception('BMI not found. Please complete registration info.');

      double activityMinutes = 30;
      double maxCalories = 2000;
      double minSleepHours = 7.5;

      // Auto-generate based on goal + BMI
      switch (_selectedGoal) {
        case 'lose_weight':
          activityMinutes = bmi > 25 ? 40 : 30;
          maxCalories = bmi > 25 ? 1600 : 1800;
          minSleepHours = 8;
          break;
        case 'build_muscle':
          activityMinutes = 30;
          maxCalories = bmi < 22 ? 2500 : 2200;
          minSleepHours = 7;
          break;
        case 'fix_sleep':
          activityMinutes = 20;
          maxCalories = 1800;
          minSleepHours = 8.5;
          break;
      }

      // Save goal
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('goal')
          .doc('current')
          .set({
        'goalType': _selectedGoal,
        'startDate': now.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });

      // Save daily plan defaults
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_goal')
          .doc('plan')
          .set({
        'activityMinutes': activityMinutes,
        'maxCalories': maxCalories,
        'minSleepHours': minSleepHours,
      });

      // 🔥 Save program details to support dashboard display
      String bmiCategory;
      if (bmi < 18.5) {
        bmiCategory = 'underweight';
      } else if (bmi < 25) {
        bmiCategory = 'normal';
      } else if (bmi < 30) {
        bmiCategory = 'overweight';
      } else {
        bmiCategory = 'obese';
      }

      String templateId = _selectedGoal == 'fix_sleep'
          ? 'fix_sleep_generic'
          : '${_selectedGoal}_bmi_$bmiCategory';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('programs')
          .doc(_selectedGoal!)
          .set({
        'templateId': templateId,
        'currentWeek': 1,
        'startDate': now.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });

      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save goal: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Goal')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Choose one of your 30-day health goals:',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...goals.map((goal) {
              final bool isSelected = _selectedGoal == goal['value'];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  onPressed: () => _selectGoal(goal['value']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? goal['color'] : Colors.grey.shade200,
                    foregroundColor: isSelected ? Colors.white : Colors.black87,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(goal['label']),
                ),
              );
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : _continue,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
