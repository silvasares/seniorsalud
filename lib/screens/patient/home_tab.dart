import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/readings_provider.dart';
import '../../widgets/action_card.dart';
import '../../services/local_notifications_service.dart';
import '../../services/insforge_service.dart';
import 'add_reading_screen.dart';
import 'medication_screen.dart';
import 'patient_alerts_screen.dart';

class HomeTab extends StatefulWidget {
  final String userId;
  final ValueChanged<int>? onNavigate;
  const HomeTab({super.key, required this.userId, this.onNavigate});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final rp = context.read<ReadingsProvider>();
    await rp.loadProfile(widget.userId);
    await rp.loadAlerts(widget.userId);

    for (final alert in rp.alerts) {
      if (!alert.isRead) {
        LocalNotificationsService().showMessageNotification(
          alertId: alert.id,
          message: alert.message,
          type: alert.alertType,
        );
      }
    }

    final dates = await InsForgeService().getUserScheduleDates(widget.userId);
    LocalNotificationsService().scheduleBloodPressureReminders(widget.userId, dates);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReadingsProvider>(
      builder: (context, rp, _) {
        final name = rp.profile?.name ?? 'Usuario';
        final unreadAlerts = rp.unreadAlertsCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, $name',
                style: GoogleFonts.lexend(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              Text(
                '¿Cómo te sientes hoy?',
                style: GoogleFonts.lexend(
                  fontSize: 20,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 35),
              ActionCard(
                title: 'Añadir mis datos',
                subtitle: 'Registrar presión arterial',
                icon: Icons.add,
                bgColor: const Color(0xFF0056B3),
                titleColor: Colors.white,
                subtitleColor: Colors.white.withValues(alpha: 0.8),
                iconBgColor: Colors.white.withValues(alpha: 0.2),
                iconColor: Colors.white,
                arrowColor: Colors.white,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddReadingScreen(userId: widget.userId),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ActionCard(
                title: 'Ver mis resultados',
                subtitle: 'Historial y estadísticas',
                icon: Icons.bar_chart,
                bgColor: Colors.white,
                titleColor: const Color(0xFF0056B3),
                subtitleColor: Colors.grey[600]!,
                iconBgColor: const Color(0xFFE3F2FD),
                iconColor: const Color(0xFF0056B3),
                arrowColor: const Color(0xFF0056B3),
                onTap: () {
                  if (widget.onNavigate != null) widget.onNavigate!(1);
                },
              ),
              const SizedBox(height: 15),
              ActionCard(
                title: 'Mi Medicación',
                subtitle: 'Gestionar tomas y recordatorios',
                icon: Icons.medical_services,
                bgColor: Colors.white,
                titleColor: const Color(0xFF0056B3),
                subtitleColor: Colors.grey[600]!,
                iconBgColor: const Color(0xFFF5F5F5),
                iconColor: const Color(0xFF0056B3),
                arrowColor: const Color(0xFF0056B3),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicationScreen(userId: widget.userId),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ActionCard(
                title: 'Mis Citas',
                subtitle: 'Calendario y citas de control',
                icon: Icons.calendar_month,
                bgColor: Colors.white,
                titleColor: const Color(0xFF0056B3),
                subtitleColor: Colors.grey[600]!,
                iconBgColor: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFF0056B3),
                arrowColor: const Color(0xFF0056B3),
                onTap: () {
                  if (widget.onNavigate != null) widget.onNavigate!(2);
                },
              ),
              const SizedBox(height: 15),
              ActionCard(
                title: 'Mensajes y Avisos',
                subtitle: unreadAlerts > 0
                    ? 'Tienes $unreadAlerts mensajes nuevos'
                    : 'Sin mensajes nuevos',
                icon: Icons.notifications,
                bgColor: Colors.white,
                titleColor: Colors.black87,
                subtitleColor: Colors.grey[500]!,
                iconBgColor: const Color(0xFFF5F5F5),
                iconColor: Colors.grey[600]!,
                arrowColor: Colors.grey[400]!,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PatientAlertsScreen(userId: widget.userId),
                  ),
                ).then((_) => _load()),
              ),
            ],
          ),
        );
      },
    );
  }
}
