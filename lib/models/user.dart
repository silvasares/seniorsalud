class AppUser {
  final String id;
  final String name;
  final String username;
  final String? phone;
  final String? password;
  final int? age;
  final String role;
  final String status;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    this.phone,
    this.password,
    this.age,
    this.role = 'patient',
    this.status = 'approved',
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      phone: map['phone']?.toString(),
      password: map['password']?.toString(),
      age: map['age'] as int?,
      role: map['role']?.toString() ?? 'patient',
      status: map['status']?.toString() ?? 'approved',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'username': username,
    'phone': phone,
    'password': password,
    'age': age,
    'role': role,
    'status': status,
  };

  bool get isAdmin => role == 'admin';
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
}

class AuthResult {
  final AppUser? user;
  final String? error;

  AuthResult({this.user, this.error});

  bool get isSuccess => user != null && error == null;
}
