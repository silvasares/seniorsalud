import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/readings_provider.dart';
import 'services/local_notifications_service.dart';
import 'services/background_service.dart' show callbackDispatcher;
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  final notifications = LocalNotificationsService();
  if (!kIsWeb) {
    await notifications.init();
  }
  // If medication alerts are disabled, cancel any pending medication reminders
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('medication_alerts_enabled') == false) {
    await notifications.cancelAllMedicationReminders();
  }

  String? initialPayload;
  if (!kIsWeb) {
    final NotificationAppLaunchDetails? launchDetails =
        await notifications.flutterLocalNotificationsPlugin
            .getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      initialPayload = launchDetails?.notificationResponse?.payload;
    }
  }

  await initializeDateFormatting('es_ES', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReadingsProvider()),
      ],
      child: SeniorSaludApp(initialPayload: initialPayload),
    ),
  );
}
