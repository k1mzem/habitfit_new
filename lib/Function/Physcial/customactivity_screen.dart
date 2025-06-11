import 'package:flutter/material.dart';
import '../../models/activity_session.dart';

class CustomActivityScreen extends StatefulWidget {
  const CustomActivityScreen({super.key});

  @override
  State<CustomActivityScreen> createState() => _CustomActivityScreenState();
}

class _CustomActivityScreenState extends State<CustomActivityScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  String _difficulty = 'Easy';

  double _calculateCalories(int durationMinutes, String difficulty) {
    double factor;
    if (difficulty == 'Easy') {
      factor = 4.0;
    } else if (difficulty == 'Medium') {
      factor = 6.0;
    } else {
      factor = 8.0;
    }
    return durationMinutes * factor;
  }

  Future<void> _saveCustomActivity() async {
    final name = _nameController.text.trim();
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;

    if (name.isEmpty || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields correctly')),
      );
      return;
    }

    final caloriesBurned = _calculateCalories(duration, _difficulty);

    try {
      await ActivitySessionService.addSession(
        type: 'custom',
        duration: duration * 60,
        distance: 0,
        speed: 0,
        date: DateTime.now(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:
        Text('Workout saved. Calories burned: '
            '${caloriesBurned.toStringAsFixed(0)} kcal')),
      );

      _nameController.clear();
      _durationController.clear();
      setState(() {
        _difficulty = 'Easy';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save workout: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Custom Activity'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField(
                controller: _nameController,
                label: 'Workout Name',
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _durationController,
                label: 'Duration (minutes)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _difficulty,
                dropdownColor: Colors.grey[900],
                decoration: _inputDecoration('Difficulty'),
                items: ['Easy', 'Medium', 'Hard'].map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _difficulty = value!;
                  });
                },
              ),
              const Spacer(),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveCustomActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SAVE WORKOUT',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      keyboardAppearance: Brightness.dark,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white38),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    );
  }
}