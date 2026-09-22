import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';
import '../screens/alarms/blood_pressure_alarm_screen.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  if (notificationResponse.actionId == 'register_action') {
    final payload = notificationResponse.payload;
    if (payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(payload);
        if (data['type'] == 'medication') {
          final plugin = FlutterLocalNotificationsPlugin();

          // Show a quick silent notification as confirmation for taking the medication
          await plugin.show(
            data['id'] + 10000,
            'Toma Registrada',
            'Has registrado la toma de ${data['name']}.',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'info_channel',
                'Información',
                channelDescription: 'Confirmaciones de acciones',
                importance: Importance.low,
                priority: Priority.low,
                playSound: false,
                enableVibration: false,
                autoCancel: true,
                timeoutAfter: 5000, // auto dismiss after 5 seconds
              ),
            ),
          );

          // Cancel the original medication reminder so it doesn't fire again
          final int originalId = data['id'];
          await plugin.cancel(originalId);
        }
      } catch (e) {
        print('Error en background: $e');
      }
    }
  }
}

class LocalNotificationsService {
  static final LocalNotificationsService _instance = LocalNotificationsService._internal();
  factory LocalNotificationsService() => _instance;
  LocalNotificationsService._internal();

  bool _initialized = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Track IDs of blood pressure reminders for selective cancellation
  final Set<int> _bpReminderIds = HashSet<int>();

  // Track message IDs that have been notified to avoid duplicates
  final Set<String> _notifiedMessageIds = {};

  // Base ID for message notifications to avoid conflicts
  static const int _messageIdBase = 50000;

  Future<void> init() async {
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Madrid'));

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
          final String? payload = notificationResponse.payload;
          
          // Handle register_action button in foreground
          if (notificationResponse.actionId == 'register_action') {
            notificationTapBackground(notificationResponse);
            return;
          }

          // If the user taps the notification body (not an action button), only navigate for blood_pressure
          if (notificationResponse.actionId == null && payload != null && payload.isNotEmpty) {
            try {
              final Map<String, dynamic> data = jsonDecode(payload);
              // Only navigate for blood_pressure type, not medication
              if (data['type'] == 'blood_pressure') {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => BloodPressureAlarmScreen(
                      userId: data['userId'] ?? '',
                      scheduledDate: data['date'] ?? '',
                    ),
                  ),
                );
              }
              // For medication: do nothing, the action button handles it
            } catch (e) {
              print('Error parsing notification payload: $e');
            }
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();

      try {
        final prefs = await SharedPreferences.getInstance();
        final notified = prefs.getStringList('notified_message_ids') ?? [];
        _notifiedMessageIds.addAll(notified);
      } catch (prefErr) {
        print('Error loading notified message IDs: $prefErr');
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  /// Muestra una notificación local para un nuevo mensaje/alerta de salud.
  /// Si el mensaje ya fue notificado en esta sesión, no se muestra de nuevo.
  Future<void> showMessageNotification({
    required String alertId,
    required String message,
    required String type,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    if (!_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final notified = prefs.getStringList('notified_message_ids') ?? [];
      _notifiedMessageIds.addAll(notified);
    } catch (e) {
      print('Error reloading notified message IDs: $e');
    }

    if (_notifiedMessageIds.contains(alertId)) return;
    _notifiedMessageIds.add(alertId);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('notified_message_ids', _notifiedMessageIds.toList());
    } catch (e) {
      print('Error saving notified message ID: $e');
    }

    try {
      final int notifId = _messageIdBase + _notifiedMessageIds.length;

      final String title;
      final AndroidNotificationChannel channel;
      final Importance importance;
      final Priority priority;

      switch (type) {
        case 'critical':
          title = '⚠️ Alerta Crítica';
          channel = const AndroidNotificationChannel(
            'critical_messages_channel',
            'Alertas Críticas',
            description: 'Alertas de salud críticas',
          );
          importance = Importance.max;
          priority = Priority.max;
          break;
        case 'warning':
          title = '⚡ Precaución';
          channel = const AndroidNotificationChannel(
            'warning_messages_channel',
            'Avisos Importantes',
            description: 'Avisos de precaución',
          );
          importance = Importance.high;
          priority = Priority.high;
          break;
        case 'reminder':
          title = '🔔 Recordatorio';
          channel = const AndroidNotificationChannel(
            'reminder_messages_channel',
            'Recordatorios',
            description: 'Recordatorios de salud',
          );
          importance = Importance.high;
          priority = Priority.high;
          break;
        default: // 'custom' or any other
          title = '💬 Nuevo Mensaje';
          channel = const AndroidNotificationChannel(
            'messages_channel',
            'Mensajes',
            description: 'Mensajes del centro de salud',
          );
          importance = Importance.defaultImportance;
          priority = Priority.defaultPriority;
          break;
      }

      await flutterLocalNotificationsPlugin.show(
        notifId,
        title,
        message,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: importance,
            priority: priority,
            icon: '@mipmap/ic_launcher',
            autoCancel: true,
          ),
        ),
      );
    } catch (e) {
      print('Error showing message notification: $e');
    }
  }

  Future<void> scheduleBloodPressureReminders(String userId, List<String> scheduledDatesStr) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    if (!_initialized) return;

    try {
      // Cancel only previous BP reminders, keep medication reminders intact
      for (final id in _bpReminderIds) {
        await flutterLocalNotificationsPlugin.cancel(id);
      }
      _bpReminderIds.clear();

      int idCounter = 1000; // Start at 1000 to avoid conflicts with medication IDs
      final now = DateTime.now();

      for (final dateStr in scheduledDatesStr) {
        try {
          final appointmentDate = DateTime.parse(dateStr);
          final targetDate = appointmentDate.subtract(const Duration(days: 1));
          final notificationTime = DateTime(targetDate.year, targetDate.month, targetDate.day, 9, 0);

          if (notificationTime.isAfter(now)) {
            final tzTime = tz.TZDateTime.from(notificationTime, tz.local);

            final String payload = jsonEncode({
              'type': 'blood_pressure',
              'userId': userId,
              'date': dateStr,
            });

            final int notifId = idCounter++;
            _bpReminderIds.add(notifId);

            await flutterLocalNotificationsPlugin.zonedSchedule(
              notifId,
              'Toma de Tensión Mañana',
              'Recuerda que mañana tienes una toma de tensión programada.',
              tzTime,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'reminder_channel',
                  'Recordatorios',
                  channelDescription: 'Canal para alertas de tomas de tensión',
                  importance: Importance.max,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                  fullScreenIntent: true,
                  ongoing: true,
                  category: AndroidNotificationCategory.alarm,
                  styleInformation: const BigTextStyleInformation(
                    'Recuerda que mañana tienes una toma de tensión programada en el centro de salud o en casa. Es importante para tu seguimiento.',
                    contentTitle: '🩺 Toma de Tensión Mañana',
                    summaryText: 'Recordatorio de Tensión',
                  ),
                ),
              ),
              payload: payload,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            );
          }
        } catch (e) {
          print('Error parsing date or scheduling notification: $e');
        }
      }
    } catch (e) {
      print('Error in scheduleBloodPressureReminders: $e');
    }
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required String frequency,
    required String timeStr,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    if (!_initialized) return;

    try {
      final now = DateTime.now();
      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      var scheduleTime = DateTime(now.year, now.month, now.day, hour, minute);

      if (scheduleTime.isBefore(now)) {
        scheduleTime = scheduleTime.add(const Duration(days: 1));
      }

      final tzTime = tz.TZDateTime.from(scheduleTime, tz.local);

      final String payload = jsonEncode({
        'type': 'medication',
        'id': id,
        'name': medicineName,
        'dosage': dosage,
        'frequency': frequency,
        'time': timeStr,
      });

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'medication_channel_v2', // new channel ID to override old cached channel
        'Recordatorios de Medicación',
        channelDescription: 'Canal para alarmas urgentes de medicación',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: false, // Don't auto-launch alarm screen
        ongoing: false,          // Allow user to dismiss
        autoCancel: true,
        category: AndroidNotificationCategory.reminder,
        styleInformation: BigTextStyleInformation(
          '💊 Medicamento: $medicineName\n⚖️ Dosis: $dosage\n🔄 Frecuencia: $frequency\n⏰ Hora: $timeStr',
          contentTitle: '🚨 ¡HORA DE TU MEDICINA!',
          summaryText: 'Alerta de Salud Urgente',
          htmlFormatContent: true,
          htmlFormatContentTitle: true,
        ),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500, 200, 1000]),
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
        visibility: NotificationVisibility.public,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'register_action',
            'REGISTRAR TOMA',
            showsUserInterface: false, // Do NOT open the app
            cancelNotification: true,
          ),
        ],
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        '🚨 ¡HORA DE TU MEDICINA!',
        'Toca para ver detalles de: $medicineName',
        tzTime,
        NotificationDetails(
          android: androidPlatformChannelSpecifics,
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Store the scheduled medication ID for future cancellation
      final prefs = await SharedPreferences.getInstance();
      final medIds = prefs.getStringList('medication_ids') ?? [];
      medIds.add(id.toString());
      await prefs.setStringList('medication_ids', medIds);
    } catch (e) {
      print('Error scheduling medication reminder: $e');
    }
  }

  /// Cancela todos los recordatorios de medicación programados.
  /// Se utiliza, por ejemplo, cuando el usuario desactiva las alertas de
  /// medicinas en la configuración de la app.
  Future<void> cancelAllMedicationReminders() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final prefs = await SharedPreferences.getInstance();
    final medIds = prefs.getStringList('medication_ids') ?? [];
    for (final idStr in medIds) {
      final id = int.tryParse(idStr);
      if (id != null) {
        await plugin.cancel(id);
      }
    }
    await prefs.remove('medication_ids');
  }
}
