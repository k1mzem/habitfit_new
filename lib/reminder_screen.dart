import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/notification_service.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  bool mealReminder = true;
  bool sleepReminder = false;
  bool physicalReminder = true;

  TimeOfDay mealTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay sleepTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay physicalTime = const TimeOfDay(hour: 7, minute: 0);

  Future<void> _pickTime(BuildContext context, TimeOfDay current, ValueChanged<TimeOfDay> onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  Future<void> _handleToggle({
    required bool value,
    required int notificationId,
    required String title,
    required String body,
    required TimeOfDay time,
    required void Function(bool) updateState,
    required String type,
  }) async {
    if (value) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        if (!result.isGranted) return;
      }

      final now = DateTime.now();
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      await NotificationService.scheduleNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledDateTime: scheduledDateTime,
      );

      await ReminderService.saveReminderToFirestore(
        type: type,
        enabled: true,
        hour: time.hour,
        minute: time.minute,
        title: title,
        body: body,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ '$title' reminder saved!")),
      );
    } else {
      await NotificationService.cancelReminder(notificationId);
      await ReminderService.saveReminderToFirestore(
        type: type,
        enabled: false,
        hour: time.hour,
        minute: time.minute,
        title: title,
        body: body,
      );
    }

    updateState(value);
  }

  Widget _reminderTile({
    required String title,
    required bool value,
    required int id,
    required String type,
    required String body,
    required TimeOfDay time,
    required void Function(bool) updateState,
  }) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(title),
          value: value,
          onChanged: (val) => _handleToggle(
            value: val,
            notificationId: id,
            title: title,
            body: body,
            time: time,
            updateState: updateState,
            type: type,
          ),
        ),
        if (value)
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text('Reminder Time: ${time.format(context)}'),
            trailing: const Icon(Icons.edit),
            onTap: () {
              _pickTime(context, time, (picked) async {
                setState(() {
                  if (id == 1) mealTime = picked;
                  if (id == 2) sleepTime = picked;
                  if (id == 3) physicalTime = picked;
                });

                final now = DateTime.now();
                final scheduledDateTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  picked.hour,
                  picked.minute,
                );

                await NotificationService.scheduleNotification(
                  id: id,
                  title: title,
                  body: body,
                  scheduledDateTime: scheduledDateTime,
                );

                await ReminderService.saveReminderToFirestore(
                  type: type,
                  enabled: true,
                  hour: picked.hour,
                  minute: picked.minute,
                  title: title,
                  body: body,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("🔄 '$title' time updated & saved!")),
                );
              });
            },
          ),
        const Divider(height: 0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reminder Settings")),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _reminderTile(
            title: "Meal Reminder",
            value: mealReminder,
            id: 1,
            type: 'meal',
            body: "Don't forget to log your meals in HabitFit!",
            time: mealTime,
            updateState: (val) => setState(() => mealReminder = val),
          ),
          _reminderTile(
            title: "Sleep Reminder",
            value: sleepReminder,
            id: 2,
            type: 'sleep',
            body: "Track your sleep and recover well!",
            time: sleepTime,
            updateState: (val) => setState(() => sleepReminder = val),
          ),
          _reminderTile(
            title: "Physical Activity Reminder",
            value: physicalReminder,
            id: 3,
            type: 'physical',
            body: "Time to get active! Log your workout.",
            time: physicalTime,
            updateState: (val) => setState(() => physicalReminder = val),
          ),
        ],
      ),
    );
  }
}
