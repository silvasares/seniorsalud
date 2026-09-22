import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/readings_provider.dart';
import '../../constants/app_colors.dart';

class PatientAlertsScreen extends StatefulWidget {
  final String userId;
  const PatientAlertsScreen({super.key, required this.userId});

  @override
  State<PatientAlertsScreen> createState() => _PatientAlertsScreenState();
}

class _PatientAlertsScreenState extends State<PatientAlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReadingsProvider>().loadAlerts(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mensajes y Avisos',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<ReadingsProvider>(
        builder: (context, rp, _) {
          if (rp.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final unreadAlerts = rp.alerts.where((a) => !a.isRead).toList();
          if (unreadAlerts.isEmpty) {
            return const Center(
              child: Text(
                'No tienes mensajes nuevos',
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: unreadAlerts.length,
            itemBuilder: (context, index) {
              final a = unreadAlerts[index];
              return Card(
                color: a.isRead ? Colors.white : const Color(0xFFFFF3E0),
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: Icon(
                    Icons.notifications,
                    color: a.isRead ? Colors.grey : Colors.orange[800],
                    size: 30,
                  ),
                  title: Text(
                    a.message,
                    style: TextStyle(
                      fontWeight: a.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(a.createdAt.toIso8601String().substring(0, 10)),
                  ),
                  onTap: () async {
                    if (!a.isRead) {
                      await rp.markAlertAsRead(a.id);
                      await rp.loadAlerts(widget.userId);
                    }
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      await rp.deleteAlert(a.id);
                      await rp.loadAlerts(widget.userId);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
