class HealthAlert {
  final String id;
  final String userId;
  final String message;
  final String alertType;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? userInfo;

  HealthAlert({
    required this.id,
    required this.userId,
    required this.message,
    this.alertType = 'custom',
    this.isRead = false,
    DateTime? createdAt,
    this.userInfo,
  }) : createdAt = createdAt ?? DateTime.now();

  factory HealthAlert.fromMap(Map<String, dynamic> map) {
    return HealthAlert(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      alertType: map['alert_type']?.toString() ?? 'custom',
      isRead: map['is_read'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      userInfo: map['users'] != null
          ? Map<String, dynamic>.from(map['users'] as Map)
          : null,
    );
  }
}
