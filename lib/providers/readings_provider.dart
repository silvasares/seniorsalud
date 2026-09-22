import 'package:flutter/material.dart';
import '../models/blood_pressure_reading.dart';
import '../models/user.dart';
import '../models/medication.dart';
import '../models/health_alert.dart';
import '../models/schedule.dart';
import '../services/insforge_service.dart';
import '../services/local_notifications_service.dart';

class ReadingsProvider extends ChangeNotifier {
  final InsForgeService _service = InsForgeService();

  List<BloodPressureReading> _readings = [];
  List<Medication> _medications = [];
  List<Schedule> _schedules = [];
  List<HealthAlert> _alerts = [];
  AppUser? _profile;
  bool _isLoading = false;
  String? _error;

  List<BloodPressureReading> get readings => _readings;
  List<Medication> get medications => _medications;
  List<Schedule> get schedules => _schedules;
  List<HealthAlert> get alerts => _alerts;
  AppUser? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfile(String userId) async {
    try {
      final data = await _service.getUserProfile(userId);
      if (data != null) _profile = AppUser.fromMap(data);
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar perfil.';
      notifyListeners();
    }
  }

  Future<void> loadReadings(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _service.getBloodPressureReadings(userId);
      _readings = data.map((m) => BloodPressureReading.fromMap(m)).toList();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar lecturas.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addReading({
    required String userId,
    int? systolic,
    int? diastolic,
    int? heartRate,
    int? glucose,
    double? weight,
    double? temperature,
  }) async {
    try {
      final success = await _service.addBloodPressureReading(
        userId: userId,
        systolic: systolic,
        diastolic: diastolic,
        heartRate: heartRate,
        glucose: glucose,
        weight: weight,
        temperature: temperature,
      );
      if (success) await loadReadings(userId);
      return success;
    } catch (e) {
      _error = 'Error al guardar la medición. Revisa tu conexión.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReading(String readingId, String userId) async {
    try {
      final success = await _service.deleteBloodPressureReading(readingId);
      if (success) await loadReadings(userId);
      return success;
    } catch (e) {
      _error = 'Error al eliminar la medición.';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMedications(String userId) async {
    try {
      final data = await _service.getMedications(userId);
      _medications = data.map((m) => Medication.fromMap(m)).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar medicamentos.';
      notifyListeners();
    }
  }

  Future<bool> updateMedication({
    required String id,
    required String userId,
    required String name,
    String? dosage,
    String? frequency,
    String? time,
  }) async {
    try {
      final success = await _service.updateMedication(
        id: id,
        name: name,
        dosage: dosage,
        frequency: frequency,
        time: time,
      );
      if (success) await loadMedications(userId);
      return success;
    } catch (e) {
      _error = 'Error al actualizar medicamento.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addMedication({
    required String userId,
    required String name,
    String? dosage,
    String? frequency,
    String? time,
  }) async {
    try {
      final success = await _service.addMedication(
        userId: userId,
        name: name,
        dosage: dosage,
        frequency: frequency,
        time: time,
      );
      if (success) await loadMedications(userId);
      return success;
    } catch (e) {
      _error = 'Error al guardar medicamento.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedication(String id, String userId) async {
    try {
      final success = await _service.deleteMedication(id);
      if (success) {
        // Cancel any scheduled medication reminders associated with this medication
        await LocalNotificationsService().cancelAllMedicationReminders();
        await loadMedications(userId);
      }
      return success;
    } catch (e) {
      _error = 'Error al eliminar medicamento.';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadAlerts(String userId) async {
    try {
      final data = await _service.getUserAlerts(userId);
      _alerts = data.map((a) => HealthAlert.fromMap(a)).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar mensajes.';
      notifyListeners();
    }
  }

  Future<bool> markAlertAsRead(String alertId) async {
    try {
      return await _service.markAlertAsRead(alertId);
    } catch (e) {
      _error = 'Error al actualizar mensaje.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAlert(String alertId) async {
    try {
      return await _service.deleteAlert(alertId);
    } catch (e) {
      _error = 'Error al eliminar mensaje.';
      notifyListeners();
      return false;
    }
  }

  int get unreadAlertsCount => _alerts.where((a) => !a.isRead).length;

  Future<void> loadSchedules(String userId) async {
    try {
      final data = await _service.getSchedule(userId: userId);
      _schedules = data.map((s) => Schedule.fromMap(s)).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar citas.';
      notifyListeners();
    }
  }

  List<Schedule> get upcomingSchedules {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    return _schedules
        .where((s) => s.scheduledDate.compareTo(todayStr) >= 0)
        .toList();
  }

  List<Schedule> schedulesForDate(DateTime day) {
    final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _schedules
        .where((s) => s.scheduledDate.startsWith(dateStr))
        .toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
