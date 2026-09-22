import 'package:flutter/material.dart';
import 'constants/app_theme.dart';
import 'screens/login_screen.dart';

class SeniorSaludApp extends StatelessWidget {
  final String? initialPayload;
  const SeniorSaludApp({super.key, this.initialPayload});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeniorSalud',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: LoginScreen(initialPayload: initialPayload),
    );
  }
}
