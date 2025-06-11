import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'services/notification_service.dart';// 🔔 new import
import 'package:habitfit_new/widgets/username_screen.dart';
import 'widgets/profile_screen.dart';
import 'services/program_uploader.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'goal_screen.dart';
import 'dashboard_screen.dart';
import 'placeholder_screen.dart';
import 'Function/Physcial/select_sport_screen.dart';
import 'Function/Physcial/running_screen.dart';
import 'Function/progress_tracker_screen.dart';
import 'Settings_screen.dart';
import 'Function/eat_screen.dart';
import 'Function/sleep_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/bmi_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  tz.initializeTimeZones(); // ⏰ Timezone init
  await NotificationService.init(); // 🔔 Initialize local notifications

  if (kDebugMode) {
    await uploadAllProgramTemplates();
  }

  runApp(const HabitFitApp());
}


class HabitFitApp extends StatelessWidget {
  const HabitFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
      ),
      themeMode: ThemeMode.dark,// ✅ Apply custom monochrome theme here
      home: const EntryPoint(),
      //const EntryPoint(),
      //const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/goal': (context) => const GoalScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/physical': (context) => const SelectSportScreen(),
        '/eating': (context) => const EatingHabitsScreen(),
        '/sleep': (context) => const SleepScreen(),
        '/progress': (context) => const ProgressTrackerScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/running': (context) => const RunningScreen(),
        '/username': (context) => const UsernameScreen(),
        '/bmi': (context) => const BmiScreen(),

      },
    );
  }
}
class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}


class EntryPoint extends StatelessWidget {
  const EntryPoint({super.key});

  Future<String> _initializeUserAndRoute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '/login';

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();
    final data = snapshot.data() ?? {};

    // If new Google user → create base profile
    if (!snapshot.exists) {
      await userDoc.set({
        'username': user.displayName ?? '',
        'email': user.email,
        'photoUrl': user.photoURL ?? '',
        'createdAt': DateTime.now(),
        'goal': null,
        'bmi': 0,
        'height': 0,
        'weight': 0,
        'streak': 0,
      });
      return '/username';
    }

    if ((data['username'] ?? '').toString().isEmpty) return '/username';
    if ((data['height'] ?? 0) == 0 || (data['weight'] ?? 0) == 0) return '/bmi';
    final goalDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('goal')
        .doc('current')
        .get();

    final hasGoal = goalDoc.exists && (goalDoc.data()?['goalType'] ?? '').toString().isNotEmpty;
    if (!hasGoal) return '/goal';


    return '/dashboard';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _initializeUserAndRoute(), // 🔄 Changed to Future<String>
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final route = snapshot.data ?? '/login';

        // 🔁 Wait until first frame, then redirect
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, route);
        });

        return const SizedBox(); // 🧼 Empty widget while redirecting
      },
    );
  }
}


