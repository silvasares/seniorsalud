import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/readings_provider.dart';
import '../../constants/app_colors.dart';
import '../../widgets/app_input_field.dart';
import '../../services/local_notifications_service.dart';
import '../../models/medication.dart';

class MedicationScreen extends StatefulWidget {
  final String userId;
  const MedicationScreen({super.key, required this.userId});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final rp = context.read<ReadingsProvider>();
    await rp.loadMedications(widget.userId);

    for (final med in rp.medications) {
      final timeStr = _displayTime(med);
      if (timeStr != null) {
        LocalNotificationsService().scheduleMedicationReminder(
          id: med.id.hashCode.abs() % 100000,
          medicineName: med.name,
          dosage: med.dosage ?? '',
          frequency: med.frequency ?? '',
          timeStr: timeStr,
        );
      }
      for (final t in med.reminderTimes) {
        if (t != timeStr) {
          LocalNotificationsService().scheduleMedicationReminder(
            id: (med.id.hashCode.abs() + t.hashCode) % 100000,
            medicineName: med.name,
            dosage: med.dosage ?? '',
            frequency: med.frequency ?? '',
            timeStr: t,
          );
        }
      }
    }
  }

  String? _displayTime(Medication med) {
    return med.time ?? (med.reminderTimes.isNotEmpty ? med.reminderTimes.first : null);
  }

  String _displayTimeLabel(Medication med) {
    final times = <String>{};
    if (med.time != null) times.add(med.time!);
    times.addAll(med.reminderTimes);
    if (times.isEmpty) return '--:--';
    return times.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mi Medicación',
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
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: rp.medications.length,
            itemBuilder: (context, index) =>
                _buildMedCard(rp.medications[index], rp),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMedicationDialog(null),
        label: const Text(
          'Nueva Medicina',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        icon: const Icon(Icons.add, size: 28),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMedCard(Medication medication, ReadingsProvider rp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  medication.name,
                  style: GoogleFonts.lexend(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 24),
                    onPressed: () => _showMedicationDialog(medication),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.deleteRed, size: 24),
                    onPressed: () => _confirmDelete(medication, rp),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${medication.dosage ?? ''} ${medication.frequency ?? ''}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1, thickness: 0.5),
          ),
          Row(
            children: [
              const Icon(Icons.access_time, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Recordatorios:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _displayTimeLabel(medication),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Medication medication, ReadingsProvider rp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar medicamento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        content: Text('¿Eliminar "${medication.name}" de forma permanente?', style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await rp.deleteMedication(medication.id, widget.userId);
    }
  }

  static const _presetTimes = ['08:00', '12:00', '16:00', '20:00', '22:00'];

  void _showMedicationDialog(Medication? existing) {
    final isEdit = existing != null;
    final nameC = TextEditingController(text: existing?.name ?? '');
    final doseC = TextEditingController(text: existing?.dosage ?? '');
    final freqC = TextEditingController(text: existing?.frequency ?? '');
    String selectedTime = existing != null ? (_displayTime(existing) ?? '') : '';

    showDialog(
      context: context,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setDialogState) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                backgroundColor: const Color(0xFFF8F9FA),
                insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Editar Medicina' : 'Nueva Medicina',
                        style: GoogleFonts.lexend(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppInputField(
                        controller: nameC,
                        hint: 'Nombre (ej: Paracetamol)',
                        icon: Icons.medical_services,
                      ),
                      const SizedBox(height: 12),
                      AppInputField(
                        controller: doseC,
                        hint: 'Dosis (ej: 500mg)',
                        icon: Icons.science,
                      ),
                      const SizedBox(height: 12),
                      AppInputField(
                        controller: freqC,
                        hint: 'Frecuencia (ej: Cada 8h)',
                        icon: Icons.repeat,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Elige la hora del recordatorio',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _presetTimes.map((t) {
                          final isSelected = selectedTime == t;
                          return SizedBox(
                            width: (MediaQuery.of(ctx).size.width - 98) / 3,
                            child: Material(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  selectedTime = t;
                                  setDialogState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  child: Text(
                                    t,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: isSelected ? Colors.white : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.now(),
                              helpText: 'Otra hora',
                              cancelText: 'Cancelar',
                              confirmText: 'Confirmar',
                              builder: (context, child) {
                                return MediaQuery(
                                  data: MediaQuery.of(context).copyWith(
                                    textScaler: const TextScaler.linear(1.0),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              selectedTime =
                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              setDialogState(() {});
                            }
                          },
                          icon: const Icon(Icons.access_time, size: 22),
                          label: Text(
                            selectedTime.isNotEmpty && !_presetTimes.contains(selectedTime)
                                ? 'Cambiar hora ($selectedTime)'
                                : 'Elegir otra hora',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameC.text.trim().isEmpty) return;
                          final nav = Navigator.of(ctx);
                          final rp = context.read<ReadingsProvider>();
                          final time = selectedTime.isNotEmpty ? selectedTime : null;

                          if (isEdit) {
                            await rp.updateMedication(
                              id: existing.id,
                              userId: widget.userId,
                              name: nameC.text.trim(),
                              dosage: doseC.text.trim(),
                              frequency: freqC.text.trim(),
                              time: time,
                            );
                          } else {
                            await rp.addMedication(
                              userId: widget.userId,
                              name: nameC.text.trim(),
                              dosage: doseC.text.trim(),
                              frequency: freqC.text.trim(),
                              time: time,
                            );
                          }
                          if (mounted) {
                            nav.pop();
                            _load();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0056B3),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          isEdit ? 'Guardar Cambios' : 'Guardar Medicina',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }
}
