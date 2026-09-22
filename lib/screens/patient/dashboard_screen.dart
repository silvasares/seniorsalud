import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import 'home_tab.dart';
import 'results_tab.dart';
import 'schedule_tab.dart';
import 'health_tips_tab.dart';
import 'profile_tab.dart';
import '../alarms/medication_alarm_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? initialPayload;
  const DashboardScreen({super.key, required this.userId, this.initialPayload});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMedicationAlert(widget.initialPayload!);
      });
    }
  }

  void _showMedicationAlert(Map<String, dynamic> data) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (context, anim1, anim2) => MedicationAlarmScreen(
        medicineName: data['medicineName'] ?? 'Medicina',
        dosage: data['dosage'] ?? '1 dosis',
        frequency: data['frequency'] ?? 'Según indicación',
        time: data['time'] ?? '--:--',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = [
      'Panel de Inicio',
      'Mis Resultados',
      'Mis Citas',
      'Consejos de Salud',
      'Mi Perfil',
    ];
    final List<Widget> tabs = [
      HomeTab(
        userId: widget.userId,
        onNavigate: (index) => setState(() => _selectedIndex = index),
      ),
      ResultsTab(userId: widget.userId),
      ScheduleTab(userId: widget.userId),
      const HealthTipsTab(),
      ProfileTab(userId: widget.userId),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: AppColors.primary),
        centerTitle: true,
        title: _selectedIndex == 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'SeniorSalud',
                    style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontSize: 22,
                    ),
                  ),
                ],
              )
            : Text(
                titles[_selectedIndex],
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontSize: 22,
                ),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: tabs[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.selectedItem,
          unselectedItemColor: AppColors.unselectedItem,
          selectedFontSize: 14,
          unselectedFontSize: 13,
          selectedLabelStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded, size: 32),
              activeIcon: Icon(Icons.home_rounded, size: 36),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded, size: 32),
              activeIcon: Icon(Icons.analytics_rounded, size: 36),
              label: 'Resultados',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded, size: 32),
              activeIcon: Icon(Icons.calendar_month_rounded, size: 36),
              label: 'Citas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb_rounded, size: 32),
              activeIcon: Icon(Icons.lightbulb_rounded, size: 36),
              label: 'Consejos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded, size: 32),
              activeIcon: Icon(Icons.person_rounded, size: 36),
              label: 'Mi Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
