import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  int height = 170;
  int weight = 65;

  void _saveBmiAndContinue() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final bmi = weight / ((height / 100) * (height / 100));
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'height': height,
      'weight': weight,
      'bmi': bmi,
    });

    Navigator.pushReplacementNamed(context, '/goal');
  }

  Widget _buildPicker({
    required String label,
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SizedBox(
            height: 180, // Bigger height for better UX
            child: ListWheelScrollView.useDelegate(
              itemExtent: 50,
              perspective: 0.003,
              diameterRatio: 2,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) => onChanged(min + index),
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  final current = min + index;
                  return Center(
                    child: Text(
                      '$current',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: current == value ? FontWeight.bold : FontWeight.normal,
                        color: current == value ? Colors.orange : Colors.white,
                      ),
                    ),
                  );
                },
                childCount: max - min + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Your BMI')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Set your Height & Weight', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Row(
              children: [
                _buildPicker(
                  label: 'Height (cm)',
                  value: height,
                  min: 100,
                  max: 220,
                  onChanged: (val) => setState(() => height = val),
                ),
                const SizedBox(width: 16),
                _buildPicker(
                  label: 'Weight (kg)',
                  value: weight,
                  min: 30,
                  max: 150,
                  onChanged: (val) => setState(() => weight = val),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveBmiAndContinue,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
