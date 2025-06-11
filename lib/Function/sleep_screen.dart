import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/sleep_entry.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final String today = DateFormat('EEE, MMM d').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSleepEntryDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18, color: Colors.white70),
                label: Text(today, style: const TextStyle(color: Colors.white70)),
                onPressed: () => _pickDate(context),
              ),
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Sleep History',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<SleepEntry>>(
              future: SleepEntry.fetchAll(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Error loading sleep entries', style: TextStyle(color: Colors.red));
                }

                final entries = snapshot.data ?? [];

                return Column(
                  children: [
                    _buildSleepGoalCard(entries),
                    const SizedBox(height: 30),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final formattedDate = DateFormat('MMM d, yyyy').format(entry.sleepTime);
                        final duration = _calculateSleepDuration(entry.sleepTime, entry.wakeTime);

                        return Card(
                          color: Colors.grey[850],
                          child: ListTile(
                            title: Text(formattedDate, style: const TextStyle(color: Colors.white)),
                            subtitle: Text('${duration.inHours}h ${duration.inMinutes.remainder(60)}m sleep',
                                style: const TextStyle(color: Colors.white70)),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  _showSleepEntryDialog(context, preset: entry);
                                } else if (value == 'delete') {
                                  await SleepEntry.delete(entry.id);
                                  setState(() {});
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Duration _calculateSleepDuration(DateTime sleepTime, DateTime wakeTime) {
    if (wakeTime.isBefore(sleepTime)) {
      wakeTime = wakeTime.add(const Duration(days: 1));
    }
    return wakeTime.difference(sleepTime);
  }

  Widget _buildSleepGoalCard(List<SleepEntry> entries) {
    final selectedKey = DateFormat('ddMMyyyy').format(selectedDate);
    final entry = entries.firstWhere(
          (e) => e.date == selectedKey,
      orElse: () => SleepEntry(
        id: '',
        sleepTime: DateTime.now(),
        wakeTime: DateTime.now(),
        date: selectedKey,
      ),
    );

    final duration = _calculateSleepDuration(entry.sleepTime, entry.wakeTime);
    final percent = duration.inHours / 7.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Sleep Goal Met', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 8,
            color: Colors.cyan,
            backgroundColor: Colors.white24,
          ),
          const SizedBox(height: 6),
          Text('${duration.inHours}h ${duration.inMinutes.remainder(60)}m of 7h',
              style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 14.0,
            percent: percent.clamp(0.0, 1.0),
            animation: true,
            progressColor: Colors.cyan,
            backgroundColor: Colors.white12,
            circularStrokeCap: CircularStrokeCap.round,
            center: Text(
              '${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
              style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSleepEntryDialog(BuildContext context, {SleepEntry? preset}) async {
    TimeOfDay sleepTime = preset != null ? TimeOfDay.fromDateTime(preset.sleepTime) : const TimeOfDay(hour: 22, minute: 0);
    TimeOfDay wakeTime = preset != null ? TimeOfDay.fromDateTime(preset.wakeTime) : const TimeOfDay(hour: 7, minute: 0);
    DateTime dialogDate = preset?.sleepTime ?? selectedDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Duration duration = _calculateDuration(sleepTime, wakeTime);

            return AlertDialog(
              title: Text(preset == null ? 'Add Sleep Entry' : 'Edit Sleep Entry'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('dd-MM-yyyy').format(dialogDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dialogDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => dialogDate = picked);
                    },
                  ),
                  ListTile(
                    title: const Text('Sleep Time'),
                    subtitle: Text(sleepTime.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: sleepTime);
                      if (picked != null) setState(() => sleepTime = picked);
                    },
                  ),
                  ListTile(
                    title: const Text('Wake Time'),
                    subtitle: Text(wakeTime.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: wakeTime);
                      if (picked != null) setState(() => wakeTime = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Total Duration: ${duration.inHours}h ${duration.inMinutes.remainder(60)}m'),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final sleepDT = DateTime(dialogDate.year, dialogDate.month, dialogDate.day, sleepTime.hour, sleepTime.minute);
                    DateTime wakeDT = DateTime(dialogDate.year, dialogDate.month, dialogDate.day, wakeTime.hour, wakeTime.minute);

                    if (wakeDT.isBefore(sleepDT)) {
                      wakeDT = wakeDT.add(const Duration(days: 1));
                    }

                    final newSleep = SleepEntry(
                      id: preset?.id ?? '',
                      sleepTime: sleepDT,
                      wakeTime: wakeDT,
                      date: DateFormat('ddMMyyyy').format(dialogDate),
                    );
                    await SleepEntry.addOrUpdate(newSleep);
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: Text(preset == null ? 'Save' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Duration _calculateDuration(TimeOfDay sleep, TimeOfDay wake) {
    final now = DateTime.now();
    DateTime sleepDT = DateTime(now.year, now.month, now.day, sleep.hour, sleep.minute);
    DateTime wakeDT = DateTime(now.year, now.month, now.day, wake.hour, wake.minute);

    if (wakeDT.isBefore(sleepDT)) {
      wakeDT = wakeDT.add(const Duration(days: 1));
    }
    return wakeDT.difference(sleepDT);
  }
}
