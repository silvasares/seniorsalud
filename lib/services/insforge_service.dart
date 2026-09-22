import 'dart:convert';
import 'package:http/http.dart' as http;

class InsForgeService {
  static const String _baseUrl = 'https://espy9at2.us-east.insforge.app';
  static const String _apiKey = 'anon_23efa288ab9f4b85ae94a3ad53e05ba5b14b331d8ac5cb3b5bce7d4f5c70c681';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'apikey': _apiKey,
    'Authorization': 'Bearer $_apiKey',
  };

  // Build query params from PostgREST-style filters
  Map<String, String> _buildParams({
    String? select,
    Map<String, String>? filters,
    String? order,
    bool ascending = false,
    int? limit,
  }) {
    final params = <String, String>{};
    if (select != null) params['select'] = select;
    if (filters != null) {
      for (final entry in filters.entries) {
        params[entry.key] = entry.value;
      }
    }
    if (order != null) {
      params['order'] = ascending ? '$order.asc' : '$order.desc';
    }
    if (limit != null) params['limit'] = limit.toString();
    return params;
  }

  // Generic GET for table records
  Future<List<Map<String, dynamic>>> _select(
    String table, {
    String? select,
    Map<String, String>? filters,
    String? order,
    bool ascending = false,
    int? limit,
  }) async {
    try {
      final params = _buildParams(
        select: select,
        filters: filters,
        order: order,
        ascending: ascending,
        limit: limit,
      );

      final uri = Uri.parse('$_baseUrl/api/database/records/$table')
          .replace(queryParameters: params.isNotEmpty ? params : null);

      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e)).toList();
        }
        return [];
      }
      print('Select error on $table: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print('Select error on $table: $e');
      return [];
    }
  }

  // Generic POST to insert a record
  Future<bool> _insert(String table, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/database/records/$table'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Insert error on $table: $e');
      return false;
    }
  }

  // Generic PUT to update records
  Future<bool> _update(String table, Map<String, dynamic> data, Map<String, String> filters) async {
    try {
      final params = _buildParams(filters: filters);
      final uri = Uri.parse('$_baseUrl/api/database/records/$table')
          .replace(queryParameters: params);
      final response = await http.put(uri, headers: _headers, body: jsonEncode(data));
      return response.statusCode == 200;
    } catch (e) {
      print('Update error on $table: $e');
      return false;
    }
  }

  // Generic DELETE
  Future<bool> _delete(String table, Map<String, String> filters) async {
    try {
      final params = _buildParams(filters: filters);
      final uri = Uri.parse('$_baseUrl/api/database/records/$table')
          .replace(queryParameters: params);
      final response = await http.delete(uri, headers: _headers);
      return response.statusCode == 200;
    } catch (e) {
      print('Delete error on $table: $e');
      return false;
    }
  }

  // RPC call
  Future<dynamic> _rpc(String functionName, [Map<String, dynamic>? params]) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/database/rpc/$functionName'),
        headers: _headers,
        body: jsonEncode(params ?? {}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      print('RPC error on $functionName: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('RPC error on $functionName: $e');
      return null;
    }
  }

  // === USERS ===

  Future<Map<String, dynamic>?> createUser({
    required String name,
    required String username,
    required String phone,
    required String password,
    int? age,
    bool approved = true,
  }) async {
    final response = await _rpc('admin_create_user', {
      'p_name': name,
      'p_username': username,
      'p_phone': phone,
      'p_password': password,
      'p_age': age,
      'p_status': approved ? 'approved' : 'pending',
      'p_role': 'patient',
    });
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  Future<bool> checkUsernameExists(String username) async {
    try {
      final response = await _rpc('check_username_exists', {'p_username': username});
      return response == true;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserByUsernameAndPassword(String username, String password) async {
    try {
      final response = await _rpc('login_user', {
        'p_username': username,
        'p_password': password,
      });
      if (response != null) {
        return Map<String, dynamic>.from(response as Map);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _select('users', filters: {'id': 'eq.$userId'}, limit: 1);
      if (response.isNotEmpty) {
        return response.first;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    return;
  }

  Future<bool> updateUser({
    required String userId,
    required String name,
    required String username,
    required String phone,
    required String password,
    int? age,
  }) async {
    return _update('users', {
      'name': name,
      'username': username,
      'phone': phone,
      'password': password,
      if (age != null) 'age': age,
    }, {'id': 'eq.$userId'});
  }

  Future<bool> adminUpdateUser({
    required String userId,
    required String name,
    required String username,
    required String phone,
    required String role,
    required String status,
    String? password,
    int? age,
  }) async {
    final updates = <String, dynamic>{
      'name': name,
      'username': username,
      'phone': phone,
      'role': role,
      'status': status,
      if (password != null && password.isNotEmpty) 'password': password,
      if (age != null) 'age': age,
    };
    return _update('users', updates, {'id': 'eq.$userId'});
  }

  Future<bool> deleteUser(String userId) async {
    return _delete('users', {'id': 'eq.$userId'});
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      final response = await _rpc('admin_get_users');
      if (response is List) {
        return response.map((u) => Map<String, dynamic>.from(u as Map)).toList();
      }
      if (response is String && response.isNotEmpty) {
        final decoded = jsonDecode(response);
        if (decoded is List) {
          return decoded.map((u) => Map<String, dynamic>.from(u as Map)).toList();
        }
      }
      if (response is Map) {
        return [Map<String, dynamic>.from(response)];
      }
    } catch (e) {
      print('RPC admin_get_users failed: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final users = await _fetchUsers();
    return users.where((u) => u['status'] == 'pending').toList();
  }

  Future<List<Map<String, dynamic>>> getApprovedUsers() async {
    final users = await _fetchUsers();
    return users.where((u) => u['status'] == 'approved').toList();
  }

  Future<bool> updateUserStatus(String userId, String status) async {
    return false;
  }

  Future<bool> adminUpdateUserStatus(String userId, String status) async {
    try {
      await _rpc('admin_update_user_status', {
        'p_user_id': userId,
        'p_status': status,
      });
      return true;
    } catch (e) {
      print('Error updating user status: $e');
      return false;
    }
  }

  Future<bool> adminDeleteUser(String userId) async {
    try {
      await _rpc('admin_delete_user', {'p_user_id': userId});
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // === BLOOD PRESSURE READINGS ===

  Future<bool> addBloodPressureReading({
    required String userId,
    int? systolic,
    int? diastolic,
    int? heartRate,
    int? glucose,
    double? weight,
    double? temperature,
    String? notes,
  }) async {
    return _insert('blood_pressure_readings', {
      'user_id': userId,
      'systolic': systolic,
      'diastolic': diastolic,
      'heart_rate': heartRate,
      'glucose': glucose,
      'weight': weight,
      'temperature': temperature,
      'notes': notes,
    });
  }

  Future<List<Map<String, dynamic>>> getUserReadings(String userId) async {
    return _select(
      'blood_pressure_readings',
      filters: {'user_id': 'eq.$userId'},
      order: 'created_at',
      limit: 50,
    );
  }

  Future<List<Map<String, dynamic>>> getBloodPressureReadings(String userId) => getUserReadings(userId);

  Future<List<Map<String, dynamic>>> getAllReadings() async {
    try {
      final response = await _rpc('admin_get_all_readings');
      if (response == null) return [];
      if (response is List) {
        return response.map((r) {
          final map = Map<String, dynamic>.from(r as Map);
          map['users'] = {
            'name': map['user_name'],
            'username': map['user_username'],
          };
          return map;
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all readings: $e');
      return [];
    }
  }

  // === BP SCHEDULE ===

  Future<List<Map<String, dynamic>>> getSchedule({String? userId}) async {
    try {
      if (userId != null) {
        final response = await _rpc('get_user_schedule', {'p_user_id': userId});
        if (response == null) return [];
        if (response is List) {
          return response.map((s) => Map<String, dynamic>.from(s as Map)).toList();
        }
        return [];
      } else {
        final response = await _rpc('admin_get_all_schedules');
        if (response == null) return [];
        if (response is List) {
          return response.map((s) => Map<String, dynamic>.from(s as Map)).toList();
        }
        return [];
      }
    } catch (e) {
      print('Error getting schedule: $e');
      return [];
    }
  }

  Future<bool> addSchedule({required String userId, required String date, String? notes}) async {
    try {
      await _rpc('admin_add_schedule', {
        'p_user_id': userId,
        'p_date': date,
        'p_notes': notes ?? '',
      });
      return true;
    } catch (e) {
      print('Error adding schedule: $e');
      return false;
    }
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      await _rpc('admin_delete_schedule', {'p_id': scheduleId});
      return true;
    } catch (e) {
      print('Error deleting schedule: $e');
      return false;
    }
  }

  Future<List<String>> getUserScheduleDates(String userId) async {
    try {
      final response = await _select(
        'bp_schedule',
        select: 'scheduled_date',
        filters: {'user_id': 'eq.$userId'},
        order: 'scheduled_date',
      );
      return response.map((r) => r['scheduled_date']?.toString() ?? '').toList();
    } catch (e) {
      print('Error getting user schedule dates: $e');
      return [];
    }
  }

  // === HEALTH ALERTS ===

  Future<List<Map<String, dynamic>>> getUserAlerts(String userId) async {
    return _select(
      'health_alerts',
      filters: {'user_id': 'eq.$userId'},
      order: 'created_at',
      limit: 20,
    );
  }

  Future<bool> markAlertAsRead(String alertId) async {
    return _update('health_alerts', {'is_read': true}, {'id': 'eq.$alertId'});
  }

  Future<bool> deleteAlert(String alertId) async {
    return _delete('health_alerts', {'id': 'eq.$alertId'});
  }

  Future<bool> deleteAllAlerts(String userId) async {
    return _delete('health_alerts', {'user_id': 'eq.$userId'});
  }

  Future<List<Map<String, dynamic>>> getAllAlerts() async {
    try {
      final response = await _rpc('admin_get_all_alerts');
      if (response == null) return [];
      if (response is List) {
        return response.map((a) {
          final map = Map<String, dynamic>.from(a as Map);
          map['users'] = {
            'name': map['user_name'],
            'phone': map['user_phone'],
          };
          return map;
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all alerts: $e');
      return [];
    }
  }

  Future<bool> adminAddAlert({
    required String userId,
    required String message,
    required String type,
  }) async {
    return _insert('health_alerts', {
      'user_id': userId,
      'alert_type': type,
      'message': message,
    });
  }

  // === STATS FOR ADMIN ===

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _rpc('get_admin_stats');
      if (response == null) return {
        'totalUsers': 0, 'pendingUsers': 0, 'criticalAlerts': 0, 'stableUsers': 0, 'followUpUsers': 0,
      };
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error getting stats: $e');
      return {
        'totalUsers': 0, 'pendingUsers': 0, 'criticalAlerts': 0, 'stableUsers': 0, 'followUpUsers': 0,
      };
    }
  }

  // === MEDICATIONS ===

  Future<List<Map<String, dynamic>>> getMedications(String userId) async {
    return _select(
      'medications',
      filters: {'user_id': 'eq.$userId'},
      order: 'created_at',
    );
  }

  Future<bool> addMedication({
    required String userId,
    required String name,
    String? dosage,
    String? frequency,
    String? time,
    List<String>? reminderTimes,
  }) async {
    return _insert('medications', {
      'user_id': userId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'time': time ?? (reminderTimes?.isNotEmpty == true ? reminderTimes!.first : '00:00'),
      'reminder_times': reminderTimes ?? (time != null ? [time] : []),
    });
  }

  Future<bool> deleteMedication(String id) async {
    return _delete('medications', {'id': 'eq.$id'});
  }

  Future<bool> updateMedication({
    required String id,
    required String name,
    String? dosage,
    String? frequency,
    String? time,
  }) async {
    final updates = <String, dynamic>{
      'name': name,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (time != null) 'time': time,
    };
    return _update('medications', updates, {'id': 'eq.$id'});
  }

  Future<bool> deleteBloodPressureReading(String readingId) async {
    return _delete('blood_pressure_readings', {'id': 'eq.$readingId'});
  }

  Future<bool> deleteAllReadings() async {
    // Delete all readings - use a broad filter
    return _delete('blood_pressure_readings', {'id': 'not.is.null'});
  }

  Future<bool> deleteAllSchedules() async {
    return _delete('bp_schedule', {'id': 'not.is.null'});
  }

  Future<bool> deleteAllMedications() async {
    return _delete('medications', {'id': 'not.is.null'});
  }

  Future<bool> deleteAllAlertsGlobal() async {
    return _delete('health_alerts', {'id': 'not.is.null'});
  }
}
