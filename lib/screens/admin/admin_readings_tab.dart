import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/insforge_service.dart';
import '../../utils/measurement_ranges.dart';
import '../../widgets/measurement_badge.dart';
import '../../widgets/confirm_dialog.dart';

class AdminReadingsTab extends StatefulWidget {
  const AdminReadingsTab({super.key});

  @override
  State<AdminReadingsTab> createState() => _AdminReadingsTabState();
}

class _AdminReadingsTabState extends State<AdminReadingsTab> {
  final _service = InsForgeService();
  List<Map<String, dynamic>> _allReadings = [];
  List<Map<String, dynamic>> _filteredReadings = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _selectedUserId = 'all';
  String _activeFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getAllReadings();
    final users = await _service.getApprovedUsers();
    if (mounted) {
      setState(() {
        _allReadings = data;
        _users = users;
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    _filteredReadings = _allReadings.where((r) {
      if (_selectedUserId != 'all' &&
          r['user_id'] != _selectedUserId) return false;
      if (_activeFilter == 'Presion' && r['systolic'] == null) return false;
      if (_activeFilter == 'Pulso' && r['heart_rate'] == null) return false;
      if (_activeFilter == 'Glucosa' && r['glucose'] == null) return false;
      if (_activeFilter == 'Peso' && r['weight'] == null) return false;
      return true;
    }).toList();
  }

  int? _getUserAge(String userId) {
    try {
      final user = _users.firstWhere(
        (u) => u['id'].toString() == userId,
        orElse: () => <String, dynamic>{},
      );
      return user['age'] as int?;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.adminBackground,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.list_alt,
                        color: AppColors.primary,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Todas las Lecturas',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Historial completo de mediciones de todos los usuarios',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_list,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Usuario:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedUserId,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.primary,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text(
                                    '👥 Todos los usuarios',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                ..._users.map(
                                  (u) => DropdownMenuItem(
                                    value: u['id'].toString(),
                                    child: Text(u['name'] ?? ''),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedUserId = val;
                                    _applyFilters();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Todos', 'Presion', 'Pulso', 'Glucosa', 'Peso'].map((f) {
                        final isSelected = _activeFilter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              f,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                _activeFilter = f;
                                _applyFilters();
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppColors.cardBorder,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (_filteredReadings.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No hay mediciones'),
                      ),
                    )
                  else
                    ..._filteredReadings.map((r) => _buildReadingCard(r)),
                ],
              ),
            ),
    );
  }

  Widget _buildReadingCard(Map<String, dynamic> r) {
    final date =
        r['created_at'].toString().split('.')[0].replaceAll('T', ' ');
    final hasPresion = r['systolic'] != null && r['diastolic'] != null;
    final hasPulso = r['heart_rate'] != null;
    final hasGlucosa = r['glucose'] != null;
    final hasPeso = r['weight'] != null;
    final hasNotes = r['notes'] != null && (r['notes'] as String).isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.blueLight,
                child: Icon(Icons.person, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['users']?['name'] ?? 'Usuario',
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDeleteConfirmDialog(
                    context,
                    title: '¿Eliminar Medición?',
                    content:
                        '¿Estás seguro de que deseas eliminar esta medición?',
                  );
                  if (confirm == true) {
                    final success =
                        await _service.deleteBloodPressureReading(
                      r['id'].toString(),
                    );
                    if (success) _load();
                  }
                },
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (hasPresion)
                _buildBadgeForReading(
                  r, 'Presión ', '${r['systolic']}/${r['diastolic']} mmHg',
                  (age) {
                    final sysSev = MeasurementRanges.getSystolicSeverity(
                      age,
                      r['systolic'],
                    );
                    final diaSev = MeasurementRanges.getDiastolicSeverity(
                      age,
                      r['diastolic'],
                    );
                    return (sysSev == MeasurementSeverity.critical ||
                            diaSev == MeasurementSeverity.critical)
                        ? MeasurementSeverity.critical
                        : (sysSev == MeasurementSeverity.warning ||
                                diaSev == MeasurementSeverity.warning)
                            ? MeasurementSeverity.warning
                            : MeasurementSeverity.normal;
                  },
                  Icons.monitor_heart,
                ),
              if (hasPulso)
                _buildBadgeForReading(
                  r, 'Pulso ', '${r['heart_rate']} lpm',
                  (age) => MeasurementRanges.getHeartRateSeverity(
                    age,
                    r['heart_rate'],
                  ),
                  Icons.favorite,
                ),
              if (hasGlucosa)
                _buildBadgeForReading(
                  r, 'Glucosa ', '${r['glucose']} mg/dL',
                  (age) => MeasurementRanges.getGlucoseSeverity(
                    age,
                    r['glucose'],
                  ),
                  Icons.water_drop,
                ),
              if (hasPeso)
                _buildBadgeForReading(
                  r, 'Peso ', '${r['weight']} kg',
                  (age) => MeasurementRanges.getWeightSeverity(
                    age,
                    (r['weight'] as num).toDouble(),
                  ),
                  Icons.monitor_weight,
                ),
            ],
          ),
          if (hasNotes) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r['notes'] as String,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeForReading(
    Map<String, dynamic> r,
    String label,
    String value,
    MeasurementSeverity Function(int? age) severityFn,
    IconData icon,
  ) {
    final age = _getUserAge(r['user_id']?.toString() ?? '');
    final sev = severityFn(age);
    return MeasurementBadge(
      icon: icon,
      label: label,
      value: value,
      severity: sev,
    );
  }
}
