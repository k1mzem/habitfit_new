import 'package:flutter/material.dart';
import 'running_screen.dart';
import 'cycling_screen.dart';
import 'customactivity_screen.dart';
import 'activity_history_screen.dart';

class SelectSportScreen extends StatelessWidget {
  const SelectSportScreen({super.key});

  void _navigateToActivity(BuildContext context, String sportType) {
    if (sportType == 'running') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RunningScreen()));
    } else if (sportType == 'cycling') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CyclingScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomActivityScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sports = [
      {'label': 'Running', 'icon': Icons.directions_run, 'value': 'running'},
      {'label': 'Cycling', 'icon': Icons.directions_bike, 'value': 'cycling'},
      {'label': 'Custom', 'icon': Icons.fitness_center, 'value': 'custom'},
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Choose Your Activity',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select a sport to begin',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...sports.map((sport) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToActivity(context, sport['value']),
                  icon: Icon(sport['icon'], color: Colors.white),
                  label: Text(
                    sport['label'],
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[700],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ActivityHistoryScreen()),
                );
              },
              icon: const Icon(Icons.history, color: Colors.white),
              label: const Text(
                'Activity History',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[850],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
