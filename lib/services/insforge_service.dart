import 'dart:convert';
import 'package:http/http.dart' as http;

class InsForgeRpcException implements Exception {
  final int statusCode;
  final String message;
  InsForgeRpcException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class AuthSession {
  final String userId;
  final String accessToken;
  final String refreshToken;
  AuthSession({required this.userId, required this.accessToken, required this.refreshToken});
}

class InsForgeService {
  static const String _baseUrl = 'https://espy9at2.us-east.insforge.app';
  static const String _apiKey = 'anon_23efa288ab9f4b85ae94a3ad53e05ba5b14b331d8ac5cb3b5bce7d4f5c70c681';

  // Sesion activa: cuando hay token de usuario, las llamadas viajan como
  // authenticated y el RLS solo deja ver los datos propios (o todos si es admin).
  static String? _accessToken;
  static String? _refreshToken;
  static DateTime? _tokenIssuedAt;

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;

  static void setSession({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _tokenIssuedAt = DateTime.now();
  }

  static void clearSession() {
    _accessToken = null;
    _refreshToken = null;
    _tokenIssuedAt = null;
  }

  // El access token dura ~15 min: lo renovamos antes de cada tanda de
  // llamadas para que la sesion no caduque con la app abierta.
  Future<void> _ensureFreshSession() async {
    final issued = _tokenIssuedAt;
    if (_accessToken == null || issued == null) return;
    if (DateTime.now().difference(issued) < const Duration(minutes: 10)) return;
    await refreshSession();
  }

  Map<String, String> get _anonHeaders => {
    'Content-Type': 'application/json',
    'apikey': _apiKey,
    'Authorization': 'Bearer $_apiKey',
  };

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'apikey': _apiKey,
    'Authorization': 'Bearer ${_accessToken ?? _apiKey}',
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
      await _ensureFreshSession();
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
      await _ensureFreshSession();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/database/records/$table'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Insert error on $table: $e');
      return false;
    }
  }

  // Generic PATCH to update records
  Future<bool> _update(String table, Map<String, dynamic> data, Map<String, String> filters) async {
    try {
      await _ensureFreshSession();
      final params = _buildParams(filters: filters);
      final uri = Uri.parse('$_baseUrl/api/database/records/$table')
          .replace(queryParameters: params);
      final response = await http.patch(uri, headers: _headers, body: jsonEncode(data));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Update error on $table: $e');
      return false;
    }
  }

  // Generic DELETE
  Future<bool> _delete(String table, Map<String, String> filters) async {
    try {
      await _ensureFreshSession();
      final params = _buildParams(filters: filters);
      final uri = Uri.parse('$_baseUrl/api/database/records/$table')
          .replace(queryParameters: params);
      final response = await http.delete(uri, headers: _headers);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Delete error on $table: $e');
      return false;
    }
  }

  // RPC call: lanza InsForgeRpcException si el servidor responde con error.
  Future<dynamic> _rpc(String functionName, [Map<String, dynamic>? params]) async {
    await _ensureFreshSession();
    var response = await http.post(
      Uri.parse('$_baseUrl/api/database/rpc/$functionName'),
      headers: _headers,
      body: jsonEncode(params ?? {}),
    );

    // Si el access token vencio, lo renovamos y reintentamos una vez.
    if (response.statusCode == 401 && _accessToken != null && await refreshSession()) {
      response = await http.post(
        Uri.parse('$_baseUrl/api/database/rpc/$functionName'),
        headers: _headers,
        body: jsonEncode(params ?? {}),
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return null;
      }
    }

    String message = 'Error del servidor (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        message = (decoded['message'] ?? decoded['error'] ?? message).toString();
      }
    } catch (_) {
      if (response.body.isNotEmpty) message = response.body;
    }
    throw InsForgeRpcException(response.statusCode, message);
  }

  // === AUTH (InsForge) ===

  String _emailForUsername(String username) =>
      '${username.trim().toLowerCase()}@seniorsalud.app';

  Future<AuthSession?> signIn(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/sessions?client_type=mobile'),
        headers: _anonHeaders,
        body: jsonEncode({'email': _emailForUsername(username), 'password': password}),
      );
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      final userId = data['user']?['id'] as String?;
      if (accessToken == null || userId == null) return null;

      setSession(accessToken: accessToken, refreshToken: refreshToken ?? '');
      return AuthSession(
        userId: userId,
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
      );
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  Future<bool> refreshSession() async {
    final current = _refreshToken;
    if (current == null || current.isEmpty) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/refresh?client_type=mobile'),
        headers: _anonHeaders,
        body: jsonEncode({'refresh_token': current}),
      );
      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String? ?? current;
      if (accessToken == null) return false;

      setSession(accessToken: accessToken, refreshToken: refreshToken);
      return true;
    } catch (e) {
      print('Error refreshing session: $e');
      return false;
    }
  }

  // Refresca usando una sesion guardada (SharedPreferences) sin login previo.
  static Future<bool> restoreSession(String refreshToken) async {
    if (refreshToken.isEmpty) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/refresh?client_type=mobile'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _apiKey,
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      final accessToken = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String? ?? refreshToken;
      if (accessToken == null) return false;

      setSession(accessToken: accessToken, refreshToken: newRefresh);
      return true;
    } catch (e) {
      print('Error restoring session: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    final token = _accessToken;
    try {
      if (token != null) {
        await http.post(
          Uri.parse('$_baseUrl/api/auth/logout?client_type=mobile'),
          headers: {
            'Content-Type': 'application/json',
            'apikey': _apiKey,
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      print('Error signing out: $e');
    }
    clearSession();
  }


  // === USERS ===

  // Self-registration: always creates a pending patient (role/status forced server-side).
  Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String username,
    required String phone,
    required String password,
    int? age,
  }) async {
    final response = await _rpc('register_user', {
      'p_name': name,
      'p_username': username,
      'p_phone': phone,
      'p_password': password,
      'p_age': age,
    });
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  Future<Map<String, dynamic>?> createUser({
    required String name,
    required String username,
    required String phone,
    required String password,
    int? age,
    bool approved = true,
    String role = 'patient',
  }) async {
    final response = await _rpc('admin_create_user', {
      'p_name': name,
      'p_username': username,
      'p_phone': phone,
      'p_password': password,
      'p_age': age,
      'p_status': approved ? 'approved' : 'pending',
      'p_role': role,
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

  Future<bool> updateUser({
    required String userId,
    required String name,
    required String username,
    required String phone,
    String? password,
    int? age,
  }) async {
    return _update('users', {
      'name': name,
      'username': username,
      'phone': phone,
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
      if (age != null) 'age': age,
    };
    final updated = await _update('users', updates, {'id': 'eq.$userId'});
    if (!updated) return false;

    // La contrasena se guarda hasheada en la cuenta de autenticacion.
    if (password != null && password.isNotEmpty) {
      await _rpc('admin_set_user_password', {
        'p_user_id': userId,
        'p_password': password,
      });
    }
    return true;
  }

  Future<bool> deleteUser(String userId) async {
    return adminDeleteUser(userId);
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

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final users = await _fetchUsers();
    return users.where((u) => u['status'] == 'pending').toList();
  }

  Future<List<Map<String, dynamic>>> getApprovedUsers() async {
    final users = await _fetchUsers();
    return users.where((u) => u['status'] == 'approved').toList();
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
