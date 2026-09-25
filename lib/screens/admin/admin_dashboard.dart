import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'admin_stats_tab.dart';
import 'admin_users_tab.dart';
import 'admin_calendar_tab.dart';
import 'admin_readings_tab.dart';
import 'admin_alerts_tab.dart';

class AdminDashboard extends StatefulWidget {
  final String userId;
  const AdminDashboard({super.key, required this.userId});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _redirected = false;

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      if (!_redirected) {
        _redirected = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<String> titles = [
      'Panel', 'Pendientes', 'Usuarios', 'Citas', 'Lecturas', 'Mensajes',
    ];
    final List<Widget> tabs = [
      const AdminStatsTab(),
      const AdminUsersTab(key: ValueKey('pending'), showOnlyPending: true),
      const AdminUsersTab(key: ValueKey('all'), showOnlyPending: false),
      const AdminCalendarTab(),
      const AdminReadingsTab(),
      const AdminAlertsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        backgroundColor: AppColors.adminBackground,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
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
          selectedItemColor: Colors.red,
          unselectedItemColor: AppColors.unselectedItem,
          selectedFontSize: 13,
          unselectedFontSize: 12,
          selectedLabelStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view, size: 30),
              activeIcon: Icon(Icons.grid_view, size: 34),
              label: 'Panel',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_ind, size: 30),
              activeIcon: Icon(Icons.assignment_ind, size: 34),
              label: 'Pendientes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people, size: 30),
              activeIcon: Icon(Icons.people, size: 34),
              label: 'Usuarios',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today, size: 30),
              activeIcon: Icon(Icons.calendar_today, size: 34),
              label: 'Citas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt, size: 30),
              activeIcon: Icon(Icons.list_alt, size: 34),
              label: 'Lecturas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: 30),
              activeIcon: Icon(Icons.chat_bubble_outline, size: 34),
              label: 'Mensajes',
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: IndexedStack(
          index: _selectedIndex,
          children: tabs,
        ),
      ),
    );
  }
}
