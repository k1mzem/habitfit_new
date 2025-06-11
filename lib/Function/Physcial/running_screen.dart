import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../models/activity_session.dart';

class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key});

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  bool _showSave = false;

  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;
  double _totalDistance = 0.0;

  double get distanceKm => _totalDistance / 1000;
  double get speedKmh => distanceKm / (_seconds / 3600 == 0 ? 1 : _seconds / 3600);

  void _startTimerAndTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    if (!serviceEnabled || (permission == LocationPermission.denied || permission == LocationPermission.deniedForever)) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      if (_lastPosition != null) {
        _totalDistance += Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
      }
      _lastPosition = position;
    });
  }

  void _toggleStartStop() {
    if (_isRunning) {
      _timer?.cancel();
      _positionStream?.cancel();
      _timer = null;
      setState(() {
        _showSave = true;
      });
    } else {
      _startTimerAndTracking();
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _reset() {
    _timer?.cancel();
    _positionStream?.cancel();
    _timer = null;
    _positionStream = null;
    setState(() {
      _seconds = 0;
      _isRunning = false;
      _showSave = false;
      _totalDistance = 0.0;
      _lastPosition = null;
    });
  }

  Future<void> _saveActivity() async {
    try {
      await ActivitySessionService.addSession(
        type: 'Running',
        duration: _seconds,
        distance: distanceKm,
        speed: speedKmh,
        date: DateTime.now(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Running session has been saved!')),
      );
      _reset();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save running session: $e')),
      );
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatPace(int seconds, double distanceKm) {
    if (distanceKm == 0) return '-';
    final paceSeconds = seconds / distanceKm;
    final minutes = (paceSeconds ~/ 60).toInt();
    final remainingSeconds = (paceSeconds % 60).toInt();
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    _formatTime(_seconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Metric(title: 'DISTANCE', value: '${distanceKm.toStringAsFixed(2)} km'),
                      _Metric(title: 'PACE', value: '${_formatPace(_seconds, distanceKm)} /km'),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRunning ? Colors.red : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _toggleStartStop,
                      child: Text(
                        _isRunning ? 'STOP' : 'START',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_isRunning && _seconds > 0) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('RESET', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_showSave)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveActivity,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('SAVE RUNNING'),
                        ),
                      ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;

  const _Metric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
