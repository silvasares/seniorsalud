import 'blood_pressure_reading.dart';

class ReadingWithUser extends BloodPressureReading {
  final String userName;
  final String userUsername;

  ReadingWithUser({
    required super.id,
    required super.userId,
    super.systolic,
    super.diastolic,
    super.heartRate,
    super.glucose,
    super.weight,
    super.temperature,
    super.notes,
    super.createdAt,
    required this.userName,
    required this.userUsername,
  });

  factory ReadingWithUser.fromMap(Map<String, dynamic> map) {
    final reading = BloodPressureReading.fromMap(map);
    return ReadingWithUser(
      id: reading.id,
      userId: reading.userId,
      systolic: reading.systolic,
      diastolic: reading.diastolic,
      heartRate: reading.heartRate,
      glucose: reading.glucose,
      weight: reading.weight,
      temperature: reading.temperature,
      notes: reading.notes,
      createdAt: reading.createdAt,
      userName: map['user_name']?.toString() ?? map['users']?['name']?.toString() ?? '',
      userUsername: map['user_username']?.toString() ?? map['users']?['username']?.toString() ?? '',
    );
  }
}
