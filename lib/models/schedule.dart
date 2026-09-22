class Schedule {
  final String id;
  final String userId;
  final String scheduledDate;
  final String? notes;

  Schedule({
    required this.id,
    required this.userId,
    required this.scheduledDate,
    this.notes,
  });

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      scheduledDate: map['scheduled_date']?.toString() ?? '',
      notes: map['notes']?.toString(),
    );
  }
}
