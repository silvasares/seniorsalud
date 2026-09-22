import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/insforge_service.dart';
import '../../utils/measurement_ranges.dart';

class AdminStatsTab extends StatefulWidget {
  const AdminStatsTab({super.key});

  @override
  State<AdminStatsTab> createState() => _AdminStatsTabState();
}

class _AdminStatsTabState extends State<AdminStatsTab> {
  final _service = InsForgeService();
  int _approved = 0;
  int _pending = 0;
  int _critical = 0;
  List<String> _criticalUserNamesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final app = await _service.getApprovedUsers();
      final pend = await _service.getPendingUsers();
      final readings = await _service.getAllReadings();

      final Map<String, int?> userAgeMap = {
        for (var u in app) u['id'].toString(): u['age'] as int?
      };

      Set<String> criticalUserIds = {};
      Map<String, String> criticalUserNames = {};

      for (var r in readings) {
        final userId = r['user_id']?.toString() ?? '';
        final age = userAgeMap[userId];

        bool isCritical = false;
        List<String> criticalReasons = [];

        if (r['systolic'] != null) {
          final sysSev = MeasurementRanges.getSystolicSeverity(age, r['systolic']);
          if (sysSev == MeasurementSeverity.critical) {
            isCritical = true;
            criticalReasons.add('Sistólica (${r['systolic']})');
          }
        }
        if (r['diastolic'] != null) {
          final diaSev = MeasurementRanges.getDiastolicSeverity(age, r['diastolic']);
          if (diaSev == MeasurementSeverity.critical) {
            isCritical = true;
            criticalReasons.add('Diastólica (${r['diastolic']})');
          }
        }
        if (r['heart_rate'] != null) {
          final hrSev = MeasurementRanges.getHeartRateSeverity(age, r['heart_rate']);
          if (hrSev == MeasurementSeverity.critical) {
            isCritical = true;
            criticalReasons.add('Pulso (${r['heart_rate']})');
          }
        }
        if (r['glucose'] != null) {
          final gluSev = MeasurementRanges.getGlucoseSeverity(age, r['glucose']);
          if (gluSev == MeasurementSeverity.critical) {
            isCritical = true;
            criticalReasons.add('Glucosa (${r['glucose']})');
          }
        }
        if (r['weight'] != null) {
          final wtDouble = (r['weight'] as num).toDouble();
          final wtSev = MeasurementRanges.getWeightSeverity(age, wtDouble);
          if (wtSev == MeasurementSeverity.critical) {
            isCritical = true;
            criticalReasons.add('Peso (${r['weight']})');
          }
        }

        if (isCritical) {
          criticalUserIds.add(userId);
          final userName = r['user_name'] ??
              r['users']?['name'] ??
              'Usuario Desconocido';
          final userLogin = r['user_username'] ??
              r['users']?['username'] ??
              '';
          final reasonStr = criticalReasons.join(', ');

          final baseName =
              userLogin.isNotEmpty ? '$userName (@$userLogin)' : userName;
          final existing = criticalUserNames[userId];
          if (existing != null) {
            final Set<String> allReasons = {};
            final parts = existing.split(' - ');
            if (parts.length > 1) {
              allReasons.addAll(parts[1].split(', '));
            }
            allReasons.addAll(criticalReasons);
            criticalUserNames[userId] = '$baseName - ${allReasons.join(', ')}';
          } else {
            criticalUserNames[userId] = '$baseName - $reasonStr';
          }
        }
      }

      if (mounted) {
        setState(() {
          _approved = app.length;
          _pending = pend.length;
          _critical = criticalUserIds.length;
          _criticalUserNamesList = criticalUserNames.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading admin stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Container(
      color: AppColors.adminBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: AppColors.primary, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Resumen General',
                    style: GoogleFonts.lexend(
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Usuarios Aprobados',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$_approved',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pendientes',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$_pending',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.redLight,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$_critical usuario(s) con valores críticos',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_critical > 0 && _criticalUserNamesList.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(color: Colors.red[300], thickness: 0.5),
                    const SizedBox(height: 8),
                    const Text(
                      'Pacientes con lecturas críticas:',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._criticalUserNamesList.map(
                      (name) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                const Icon(Icons.delete_sweep, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Gestión de Datos',
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildDeleteCard(
              icon: Icons.monitor_heart,
              title: 'Eliminar todas las lecturas',
              subtitle: 'Presión, glucosa, peso, etc.',
              color: Colors.red,
              onDelete: () => _confirmDelete(
                '¿Eliminar todas las lecturas?',
                'Esta acción eliminará TODAS las lecturas de presión arterial, glucosa, peso y frecuencia cardíaca de todos los usuarios. Esta acción no se puede deshacer.',
                _service.deleteAllReadings,
              ),
            ),
            const SizedBox(height: 12),
            _buildDeleteCard(
              icon: Icons.notifications,
              title: 'Eliminar todas las alertas',
              subtitle: 'Mensajes y notificaciones',
              color: Colors.orange,
              onDelete: () => _confirmDelete(
                '¿Eliminar todas las alertas?',
                'Esta acción eliminará TODOS los mensajes y alertas de salud de todos los usuarios. Esta acción no se puede deshacer.',
                _service.deleteAllAlertsGlobal,
              ),
            ),
            const SizedBox(height: 12),
            _buildDeleteCard(
              icon: Icons.calendar_month,
              title: 'Eliminar todas las citas',
              subtitle: 'Citas agendadas',
              color: Colors.blue,
              onDelete: () => _confirmDelete(
                '¿Eliminar todas las citas?',
                'Esta acción eliminará TODAS las citas agendadas de todos los usuarios. Esta acción no se puede deshacer.',
                _service.deleteAllSchedules,
              ),
            ),
            const SizedBox(height: 12),
            _buildDeleteCard(
              icon: Icons.medication,
              title: 'Eliminar todas las medicaciones',
              subtitle: 'Medicamentos registrados',
              color: Colors.purple,
              onDelete: () => _confirmDelete(
                '¿Eliminar todas las medicaciones?',
                'Esta acción eliminará TODOS los medicamentos registrados de todos los usuarios. Esta acción no se puede deshacer.',
                _service.deleteAllMedications,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onDelete,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    String title,
    String message,
    Future<bool> Function() deleteFn,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar todo'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await deleteFn();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Datos eliminados correctamente' : 'Error al eliminar datos'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) _load();
    }
  }
}
