class BloodPressureReading {
  final String id;
  final String userId;
  final int? systolic;
  final int? diastolic;
  final int? heartRate;
  final int? glucose;
  final double? weight;
  final double? temperature;
  final int? spo2;
  final String? notes;
  final DateTime createdAt;

  BloodPressureReading({
    required this.id,
    required this.userId,
    this.systolic,
    this.diastolic,
    this.heartRate,
    this.glucose,
    this.weight,
    this.temperature,
    this.spo2,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory BloodPressureReading.fromMap(Map<String, dynamic> map) {
    return BloodPressureReading(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      systolic: map['systolic'] as int?,
      diastolic: map['diastolic'] as int?,
      heartRate: map['heart_rate'] as int?,
      glucose: map['glucose'] as int?,
      weight: (map['weight'] as num?)?.toDouble(),
      temperature: (map['temperature'] as num?)?.toDouble(),
      spo2: map['spo2'] as int?,
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'user_id': userId,
    'systolic': systolic,
    'diastolic': diastolic,
    'heart_rate': heartRate,
    'glucose': glucose,
    'weight': weight,
    'temperature': temperature,
    'notes': notes,
  };

  bool get hasPressure => systolic != null && diastolic != null;
  bool get hasHeartRate => heartRate != null;
  bool get hasGlucose => glucose != null;
  bool get hasWeight => weight != null;
  bool get hasTemperature => temperature != null;
  bool get hasSpo2 => spo2 != null;
  bool get hasNotes => notes != null && notes!.isNotEmpty;
}
