import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

const String _taskName = 'checkNewMessages';
const String _userIdKey = 'bg_user_id';

const String _baseUrl = 'https://espy9at2.us-east.insforge.app';
const String _apiKey = 'anon_23efa288ab9f4b85ae94a3ad53e05ba5b14b331d8ac5cb3b5bce7d4f5c70c681';

final FlutterLocalNotificationsPlugin _notifPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != _taskName) return Future.value(false);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      if (userId == null || userId.isEmpty) return Future.value(false);

      final headers = {
        'Content-Type': 'application/json',
        'apikey': _apiKey,
        'Authorization': 'Bearer $_apiKey',
      };

      final uri = Uri.parse('$_baseUrl/api/database/records/health_alerts')
          .replace(queryParameters: {
        'user_id': 'eq.$userId',
        'is_read': 'eq.false',
        'order': 'created_at.desc',
        'limit': '10',
        'select': 'id,message,alert_type,created_at',
      });

      final response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) return Future.value(false);

      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) return Future.value(false);

      final notifiedIds = prefs.getStringList('notified_message_ids') ?? [];
      final List<String> newNotifiedIds = List.from(notifiedIds);

      await _initNotifications();

      for (final alert in data) {
        final id = alert['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        if (notifiedIds.contains(id)) continue;

        newNotifiedIds.add(id);

        final title = _titleForType(alert['alert_type']?.toString() ?? '');
        final message = alert['message']?.toString() ?? '';

        await _notifPlugin.show(
          id.hashCode,
          title,
          message,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'messages_channel',
              'Mensajes',
              channelDescription: 'Mensajes del centro de salud',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              autoCancel: true,
            ),
          ),
        );
      }

      if (newNotifiedIds.length > notifiedIds.length) {
        await prefs.setStringList('notified_message_ids', newNotifiedIds);
      }

      return Future.value(true);
    } catch (e) {
      print('Background task error: $e');
      return Future.value(false);
    }
  });
}

Future<void> _initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await _notifPlugin.initialize(initSettings);
}

String _titleForType(String type) {
  switch (type) {
    case 'critical':
      return 'Alerta Critica';
    case 'warning':
      return 'Precaucion';
    case 'reminder':
      return 'Recordatorio';
    default:
      return 'Nuevo Mensaje';
  }
}
