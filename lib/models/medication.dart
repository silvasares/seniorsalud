class Medication {
  final String id;
  final String userId;
  final String name;
  final String? dosage;
  final String? frequency;
  final String? time;
  final List<String> reminderTimes;

  Medication({
    required this.id,
    required this.userId,
    required this.name,
    this.dosage,
    this.frequency,
    this.time,
    List<String>? reminderTimes,
  }) : reminderTimes = reminderTimes ?? [];

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      dosage: map['dosage']?.toString(),
      frequency: map['frequency']?.toString(),
      time: map['time']?.toString(),
      reminderTimes: map['reminder_times'] != null
          ? List<String>.from(map['reminder_times'] as List)
          : [],
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'user_id': userId,
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'time': time ?? (reminderTimes.isNotEmpty ? reminderTimes.first : '00:00'),
    'reminder_times': reminderTimes.isNotEmpty ? reminderTimes : (time != null ? [time] : []),
  };
}
