class Goal {
  final String type; // 'physical', 'meals', 'sleep'
  final double target;
  final double current;
  final DateTime date;

  Goal({
    required this.type,
    required this.target,
    required this.current,
    required this.date,
  });

  bool get isAchieved => current >= target;

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'target': target,
      'current': current,
      'date': date.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      type: map['type'],
      target: map['target'],
      current: map['current'],
      date: DateTime.parse(map['date']),
    );
  }
}
