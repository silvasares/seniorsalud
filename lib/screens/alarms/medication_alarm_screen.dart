import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../constants/app_colors.dart';

class MedicationAlarmScreen extends StatefulWidget {
  final String medicineName;
  final String dosage;
  final String frequency;
  final String time;
  final int? notificationId;

  const MedicationAlarmScreen({
    super.key,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.time,
    this.notificationId,
  });

  @override
  State<MedicationAlarmScreen> createState() => _MedicationAlarmScreenState();
}

class _MedicationAlarmScreenState extends State<MedicationAlarmScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showDismissConfirm();
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0061A6),
                Color(0xFF00467A),
                Color(0xFF002D52),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),
                _buildTopBar(),
                const Spacer(flex: 2),
                _buildPulseIcon(),
                const SizedBox(height: 16),
                _buildAlertTitle(),
                const SizedBox(height: 24),
                _buildMedicineInfo(),
                const Spacer(flex: 3),
                _buildButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Icon(Icons.medical_services, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Text(
            'SeniorSalud',
            style: GoogleFonts.lexend(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseIcon() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.medication,
          color: Colors.white.withValues(alpha: 0.9),
          size: 60,
        ),
      ),
    );
  }

  Widget _buildAlertTitle() {
    return Column(
      children: [
        Text(
          'HORA DE TU',
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 30,
            height: 1.1,
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'MEDICINA',
          style: GoogleFonts.lexend(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 38,
            height: 1.1,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMedicineInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            widget.medicineName,
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 34,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.dosage}  ·  ${widget.frequency}',
            style: GoogleFonts.lexend(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.time,
                style: GoogleFonts.lexend(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SizedBox(
        width: double.infinity,
        height: 76,
        child: ElevatedButton(
          onPressed: _onRegisterDose,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
          ),
          child: Text(
            'REGISTRAR TOMA',
            style: GoogleFonts.lexend(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  void _onRegisterDose() {
    _cancelNotification();
    Navigator.of(context).pop(true);
  }

  Future<void> _cancelNotification() async {
    if (widget.notificationId == null) return;
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.cancel(widget.notificationId!);
    } catch (_) {}
  }

  void _showDismissConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¿Seguro?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        content: const Text(
          'Si cierras esta alerta, el recordatorio no se repetirá hasta mañana.',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Seguir aquí',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop(false);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text(
              'Cerrar alerta',
              style: TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
