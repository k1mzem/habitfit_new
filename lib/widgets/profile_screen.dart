// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:habitfit_new/main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String? photoUrl;
  String username = '';
  String goal = '';
  String? targetWeight;
  double bmi = 0;
  String? bmiCategory;
  String? dayMessage;
  int? daysPassed;
  List<String> contributionStatus = List.filled(28, 'none');

  String _formatGoal(String value) {
    switch (value) {
      case 'lose_weight':
        return 'Lose weight';
      case 'build_muscle':
        return 'Build muscle';
      case 'fix_sleep':
        return 'Fix sleep';
      default:
        return value;
    }
  }


  final List<String> availableGoals = [
    'Lose weight',
    'Build muscle',
    'Fix sleep',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadContributionStatus();
  }

  Future<void> _loadProfileData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final data = doc.data();

    final goalDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('goal')
        .doc('current')
        .get();

    if (data != null) {
      final goalType = goalDoc.data()?['goalType'] ?? '';
      final formattedGoal = _formatGoal(goalType);

      final created = (data['createdAt'] as Timestamp?)?.toDate();
      final int? days = created != null ? DateTime.now().difference(created).inDays + 1 : null;

      setState(() {
        photoUrl = data['photoUrl'];
        username = data['username'] ?? '';
        goal = formattedGoal;
        targetWeight = (data['targetWeight'] ?? '').toString();
        bmi = (data['bmi'] ?? 0).toDouble();

        if (bmi < 18.5) {
          bmiCategory = 'Underweight';
        } else if (bmi < 25) {
          bmiCategory = 'Normal';
        } else if (bmi < 30) {
          bmiCategory = 'Overweight';
        } else {
          bmiCategory = 'Obese';
        }

        daysPassed = days;
        dayMessage = days != null ? "Day $days of 30" : null;
      });
    }
  }


  Future<void> _loadContributionStatus() async {
    // 🔒 REAL LOGIC (commented out for demo)
    /*
  final uid = user?.uid;
  if (uid == null) return;

  List<String> statuses = [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (int i = 0; i < 28; i++) {
    final date = today.subtract(Duration(days: i));
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dailyTasks')
        .doc(dateStr)
        .get();

    final int done = doc.data()?['done'] ?? 0;

    String status;
    if (done == 3) {
      status = 'full';    // Green
    } else if (done == 0 && date.isBefore(today)) {
      status = 'missed';  // Red
    } else {
      status = 'future';  // Grey
    }

    statuses.add(status);
  }

  setState(() {
    contributionStatus = statuses.reversed.toList();
  });
  */

    // 🧪 DUMMY LOGIC FOR DEMO (11 boxes colored, rest grey)
    List<String> dummyStatuses = [];

    for (int i = 0; i < 28; i++) {
      if (i < 6) {
        dummyStatuses.add('full');    // First 6: Green
      } else if (i < 11) {
        dummyStatuses.add('missed');  // Next 5: Red
      } else {
        dummyStatuses.add('future');  // Remaining: Grey
      }
    }

    setState(() {
      contributionStatus = dummyStatuses.reversed.toList();
    });
  }




  Future<void> _pickAndUploadProgressImage({required String docId}) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    await _uploadProgressImage(docId: docId, pickedFile: picked);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    await _uploadProgressImage(docId: docId, pickedFile: picked);
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadProgressImage({required String docId, required XFile pickedFile}) async {
    final file = File(pickedFile.path);
    final ref = FirebaseStorage.instance.ref().child('progress_pictures/${user!.uid}_$docId.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('progressPhotos')
        .doc(docId)
        .set({'url': url});

    setState(() {});
  }

  Future<void> _changeUserGoal(String newGoal) async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'goal': newGoal});
    setState(() => goal = newGoal);
  }

  Widget _buildProgressPhoto({
    required String label,
    required String docId,
    bool enableUpload = true,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .collection('progressPhotos')
              .doc(docId)
              .get(),
          builder: (context, snapshot) {
            final data = snapshot.data;
            final url = (data != null && data.exists) ? data.get('url') : null;

            return GestureDetector(
              onTap: url != null
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(imageUrl: url),
                  ),
                );
              }
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: url != null
                    ? Image.network(url, height: 100, width: 75, fit: BoxFit.cover)
                    : Container(
                  height: 100,
                  width: 75,
                  color: Colors.grey[700],
                  child: const Icon(Icons.image, color: Colors.white30),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.camera_alt, color: enableUpload ? Colors.white : Colors.grey),
          onPressed: enableUpload ? () => _pickAndUploadProgressImage(docId: docId) : null,
        )
      ],
    );
  }


  Widget _buildLegendBox(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildContributionGrid() {
    int boxCount = 28;
    List<Widget> boxes = List.generate(boxCount, (index) {
      final status = index < contributionStatus.length ? contributionStatus[index] : 'none';
      final color = switch (status) {
        'full' => Colors.green,
        'missed' => Colors.red,
        'future' => Colors.grey,
        _ => Colors.grey,
      };


      return Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    });

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monthly Achievement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(spacing: 4, runSpacing: 4, children: boxes),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildLegendBox(Colors.green),
                const SizedBox(width: 6),
                const Text('All Achieved'),
                const SizedBox(width: 12),
                _buildLegendBox(Colors.red),
                const SizedBox(width: 6),
                const Text('Missed'),
                const SizedBox(width: 12),
                _buildLegendBox(Colors.grey),
                const SizedBox(width: 6),
                const Text('Upcoming'),
              ],
            )

          ],
        ),
      ),
    );
  }

  Widget buildProfileHeader() {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GestureDetector(
              onTap: () async {
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  final file = File(picked.path);
                  final ref = FirebaseStorage.instance.ref().child('profile_pictures/${user!.uid}.jpg');
                  await ref.putFile(file);
                  final downloadUrl = await ref.getDownloadURL();
                  await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'photoUrl': downloadUrl});
                  setState(() => photoUrl = downloadUrl);
                }
              },
              child: CircleAvatar(
                radius: 40,
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? NetworkImage(photoUrl!)
                    : const AssetImage('assets/img/profile_placeholder.png') as ImageProvider,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Goal: $goal', style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold, color: Colors.white)),
                  if (goal.toLowerCase() == 'lose weight' || goal.toLowerCase() == 'build muscle')
                    Text('Target: $targetWeight kg', style: const TextStyle(fontSize: 16, color: Colors.greenAccent)),
                  Text('BMI: ${bmi.toStringAsFixed(1)} ($bmiCategory)', style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold, color: Colors.white)),
                  if (dayMessage != null)
                    Text(dayMessage!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildProfileHeader(), // 🔼 Header appears first
            const SizedBox(height: 20),

            const Text("Ready to change your goal?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/goal');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Go to Goal Screen", style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 32),
            _buildContributionGrid(),

            const SizedBox(height: 32),
            const Text("Progress Photos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProgressPhoto(label: 'Day 1', docId: 'day1'),
                if (daysPassed != null && daysPassed! >= 30)
                  _buildProgressPhoto(label: 'Day 30', docId: 'day30')
                else
                  Column(
                    children: [
                      _buildProgressPhoto(label: 'Day 30', docId: 'day30', enableUpload: false),
                      const Text('Available on Day 30', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
