import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/app_input_field.dart';
import 'register_screen.dart';
import 'patient/dashboard_screen.dart';
import 'admin/admin_dashboard.dart';
import 'alarms/medication_alarm_screen.dart';
import 'alarms/blood_pressure_alarm_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class LoginScreen extends StatefulWidget {
  final String? initialPayload;
  const LoginScreen({super.key, this.initialPayload});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationPayload(widget.initialPayload!);
      });
    }
  }

  void _handleNotificationPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data['type'] == 'medication') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => MedicationAlarmScreen(
              medicineName: data['name'] ?? '',
              dosage: data['dosage'] ?? '',
              frequency: data['frequency'] ?? '',
              time: data['time'] ?? '',
              notificationId: data['id'] as int?,
            ),
          ),
        );
      } else if (data['type'] == 'blood_pressure') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => BloodPressureAlarmScreen(
              userId: data['userId'] ?? '',
              scheduledDate: data['date'] ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling initial notification: $e');
    }
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final result = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final user = result.user!;
      
      if (user.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminDashboard(userId: user.id),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(userId: user.id),
          ),
        );
      }
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', height: 180),
                const SizedBox(height: 10),
                Text(
                  'SeniorSalud',
                  style: GoogleFonts.lexend(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 60),
                AppRoundedInputField(
                  controller: _usernameController,
                  hint: 'Usuario',
                  icon: Icons.person,
                ),
                const SizedBox(height: 20),
                AppRoundedInputField(
                  controller: _passwordController,
                  hint: 'Contraseña',
                  icon: Icons.lock,
                  isObscure: true,
                ),
                const SizedBox(height: 45),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.isLoading) {
                      return const CircularProgressIndicator();
                    }
                    return Column(
                      children: [
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 70),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add_alt_1, size: 24),
                          label: const Text(
                            'Solicitar Acceso',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 70),
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 2.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
