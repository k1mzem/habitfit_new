// Dashboard with Goal Display + Daily Summary + Motivation + GitHub-style Grid
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../services/goal_service.dart';
import '../services/daily_task_generator.dart';
import '../services/data_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class DailyGoal {
  final String type;
  final double target;
  final double current;

  DailyGoal(this.type, this.target, this.current);
}

class _DashboardScreenState extends State<DashboardScreen> {
  String username = '';
  String userGoal = '';
  int currentStreak = 0;
  int _selectedIndex = 0;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  DateTime? goalStartDate;

  List<String> contributionStatus = List.filled(7, 'none');
  String dailyTip = 'You\'re awesome!!';
  Map<String, DailyGoal> _dailyGoals = {};


// then pass them into your _buildActivityHistoryCard


  String formatGoal(String value) {
    switch (value) {
      case 'lose_weight':
        return 'Lose Weight';
      case 'build_muscle':
        return 'Build Muscle';
      case 'fix_sleep':
        return 'Fix Sleep';
      default:
        return value;
    }
  }


  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    await DailyTaskGenerator().run();
    await GoalService().evaluateTodayGoals();
    await GoalService().updateStreakCounter();
    await _fetchUsername();
    await _fetchStreak();
    await _fetchDailyGoals();
    await _fetchContributionGrid();
    await _loadTodayData();
    setState(() {});
  }

  Map<String, dynamic>? todayData;



  Future<void> _fetchUsername() async {
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final goalDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('goal')
        .doc('current')
        .get();

    if (userDoc.exists) {
      final userData = userDoc.data();
      final goalType = goalDoc.data()?['goalType'] ?? '';

      setState(() {
        username = userData?['username'] ?? '';
        userGoal = formatGoal(goalType); // Optionally format
        goalStartDate = (userData?['createdAt'] as Timestamp?)?.toDate();
      });
    }
  }


  Future<void> _fetchStreak() async {
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      setState(() {
        currentStreak = doc.data()?['streak'] ?? 0;
      });
    }
  }

  Future<void> _fetchDailyGoals() async {
    if (uid == null) return;

    final types = ['physical', 'meals', 'sleep'];
    final result = <String, DailyGoal>{};

    for (final type in types) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('Daily_goal')
          .doc(type)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        result[type] = DailyGoal(
          type,
          (data['target'] ?? 1).toDouble(),
          (data['current'] ?? 0).toDouble(),
        );
      }
    }

    setState(() => _dailyGoals = result);
  }

  Future<void> _fetchContributionGrid() async {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    List<String> statuses = [];
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dailyTasks')
          .doc(DateFormat('yyyy-MM-dd').format(day))
          .get();
      if (!doc.exists) {
        statuses.add('none');
      } else {
        final data = doc.data();
        final done = data?['done'] ?? 0;
        statuses.add(done == 3 ? 'full' : done == 2 ? 'partial' : 'none');
      }
    }
    setState(() {
      contributionStatus = statuses;
    });
  }

// rest of your methods...
  Widget _buildTopHeader(BuildContext context) {
    final today = DateTime.now();
    final goalDay = goalStartDate != null
        ? today.difference(goalStartDate!).inDays + 1
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data?.data() == null) {
                        return const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        );
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final photoUrl = data['photoUrl'] as String?;

                      return CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : const AssetImage('assets/img/profile_placeholder.png')
                        as ImageProvider,
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username.isNotEmpty ? 'Hello, $username' : 'Loading...',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        userGoal.isNotEmpty ? 'Goal: $userGoal' : '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        goalDay != null
                            ? 'Day $goalDay of 30'
                            : 'Tracking...',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[600],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🔥 Streak: $currentStreak Days',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDailyProgressBars() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_dailyGoals.containsKey('physical'))
            _buildProgressBar(
                'Physical Activity', _dailyGoals['physical']!.current,
                _dailyGoals['physical']!.target, Colors.orange, 'min'),
          const SizedBox(height: 12),
          if (_dailyGoals.containsKey('meals'))
            _buildProgressBar('Meals (Calories)', _dailyGoals['meals']!.current,
                _dailyGoals['meals']!.target, Colors.blue, 'kcal'),
          const SizedBox(height: 12),
          if (_dailyGoals.containsKey('sleep'))
            _buildProgressBar('Sleep', _dailyGoals['sleep']!.current,
                _dailyGoals['sleep']!.target, Colors.purple, 'hrs'),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String title, double value, double goal, Color color,
      String unit) {
    double percent = (value / goal).clamp(0, 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title: ${value.toStringAsFixed(1)} / ${goal.toInt()} $unit'),
        const SizedBox(height: 4),
        LinearPercentIndicator(
          lineHeight: 14,
          percent: percent,
          backgroundColor: Colors.grey[300],
          progressColor: color,
          barRadius: const Radius.circular(8),
        ),
      ],
    );
  }

  Widget _buildWeeklyHighlights() {
    final longest = _dailyGoals['physical'] != null
        ? '${_dailyGoals['physical']!.current.toStringAsFixed(0)} mins'
        : 'No data';

    final calories = _dailyGoals['meals'] != null
        ? '${_dailyGoals['meals']!.current.toStringAsFixed(0)} kcal'
        : 'No data';

    final bestDay = contributionStatus.contains('full')
        ? 'Achieved all goals'
        : 'Keep going!';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Weekly Highlights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHighlightCard(
                  Icons.directions_run, "Longest", longest, Colors.orange),
              const SizedBox(width: 12),
              _buildHighlightCard(
                  Icons.local_dining, "Calories", calories, Colors.blue),
              const SizedBox(width: 12),
              _buildHighlightCard(
                  Icons.emoji_events, "Best Day", bestDay, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

//weekly Highlight helper
  Widget _buildHighlightCard(IconData icon, String label, String value,
      Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot> _todayActivities = [];
  List<QueryDocumentSnapshot> _todayMeals = [];
  List<QueryDocumentSnapshot> _todaySleepEntries = [];

  Future<void> _loadTodayData() async {
    final data = await DataService.fetchDataForDay(DateTime.now());
    setState(() {
      _todayActivities = data['activities'] ?? [];
      _todayMeals = data['meals'] ?? [];
      _todaySleepEntries = data['sleep'] ?? [];
    });
  }



  Widget _buildActivityHistoryCard({
    required List<QueryDocumentSnapshot> activities,
    required List<QueryDocumentSnapshot> meals,
    required List<QueryDocumentSnapshot> sleepEntries,
    required VoidCallback onSeeMore,
  }) {
    String formatDuration(int seconds) {
      final minutes = seconds ~/ 60;
      final remSeconds = seconds % 60;
      return '${minutes}m ${remSeconds}s';
    }

    String formatSleepDuration(Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
    }

    double totalMinutes = activities.fold(
      0.0,
          (sum, doc) => sum + (doc['duration'] ?? 0) / 60.0,
    );

    double totalCalories = meals.fold(
      0.0,
          (sum, doc) => sum + (doc['calories'] ?? 0),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📜 Today\'s Activity Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // 🏃 Physical
            Row(children: [
              const Icon(Icons.directions_run, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Total: ${totalMinutes.toStringAsFixed(1)} min', style: const TextStyle(color: Colors.white70)),
            ]),
            const SizedBox(height: 6),
            if (activities.isEmpty)
              const Text('No record', style: TextStyle(color: Colors.white70))
            else
              ...activities.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final type = data['type'] ?? 'Activity';
                final duration = data['duration'] ?? 0;
                final distance = (data['distance'] ?? 0.0).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '$type - ${formatDuration(duration)} - ${distance.toStringAsFixed(2)} km',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }),

            const SizedBox(height: 16),

            // 🍱 Meals
            Row(children: [
              const Icon(Icons.local_dining, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Total: ${totalCalories.toStringAsFixed(0)} kcal', style: const TextStyle(color: Colors.white70)),
            ]),
            const SizedBox(height: 6),
            if (meals.isEmpty)
              const Text('No record', style: TextStyle(color: Colors.white70))
            else
              ...meals.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${data['mealType'] ?? 'Meal'}: ${data['name']} (${data['calories']} kcal)',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }),

            const SizedBox(height: 16),

            // 😴 Sleep (Progress Tracker style – no total, just entries)
            // 😴 Sleep (Fully matching SleepEntry model)
            Row(children: [
              const Icon(Icons.bedtime, color: Colors.purpleAccent),
              const SizedBox(width: 8),
              const Text('Sleep', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white54)),
            ]),
            const SizedBox(height: 8),
            if (sleepEntries.isEmpty)
              const Text('No record', style: TextStyle(color: Colors.white70))
            else
              ...sleepEntries.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final sleepTime = (data['sleepTime'] as Timestamp).toDate();
                DateTime wakeTime = (data['wakeTime'] as Timestamp).toDate();

                if (wakeTime.isBefore(sleepTime)) {
                  wakeTime = wakeTime.add(const Duration(days: 1));
                }

                final duration = wakeTime.difference(sleepTime);

                String _formatSleepDuration(Duration duration) {
                  final hours = duration.inHours;
                  final minutes = duration.inMinutes % 60;
                  return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    'Slept for ${_formatSleepDuration(duration)} (${DateFormat('hh:mm a').format(sleepTime)} ➔ ${DateFormat('hh:mm a').format(wakeTime)})',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }),


            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onSeeMore,
                child: const Text("See More →", style: TextStyle(color: Colors.cyan)),
              ),
            ),
          ],
        ),
      ),
    );
  }


  //Navi Button
  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0: //profile button
        Navigator.pushNamed(context, '/profile');
        break;
    //Add Button
      case 1:
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.fitness_center),
                    title: const Text('Add Physical Activity'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/physical');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.restaurant),
                    title: const Text('Add Meals'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/eating');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bedtime),
                    title: const Text('Add Sleep'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/sleep');
                    },
                  ),
                ],
              ),
            );
          },
        );
        break;

    //Settings Button
      case 2: //Settings Button
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme
          .of(context)
          .scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _initializeDashboard();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildTopHeader(context),
              _buildDailyProgressBars(),
              _buildWeeklyHighlights(),
              _buildActivityHistoryCard(
                activities: _todayActivities,
                meals: _todayMeals,
                sleepEntries: _todaySleepEntries,
                onSeeMore: () {
                  Navigator.pushNamed(context, '/progress');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Add'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

  class ChartData {
  final String day;
  final double value;
  ChartData(this.day, this.value);

}
