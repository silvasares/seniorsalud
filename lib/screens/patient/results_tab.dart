import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/readings_provider.dart';
import '../../models/blood_pressure_reading.dart';
import '../../utils/measurement_ranges.dart';
import '../../constants/app_colors.dart';
import '../../widgets/chart_container.dart';
import '../../widgets/measurement_badge.dart';
import '../../widgets/confirm_dialog.dart';

class ResultsTab extends StatefulWidget {
  final String userId;
  const ResultsTab({super.key, required this.userId});

  @override
  State<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<ResultsTab> {
  String _activeFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReadingsProvider>().loadReadings(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReadingsProvider>(
      builder: (context, rp, _) {
        final readings = rp.readings;
        final age = rp.profile?.age;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(Icons.analytics, color: AppColors.primary, size: 30),
                    const SizedBox(width: 12),
                    Text(
                      'Mis Resultados',
                      style: GoogleFonts.lexend(
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              if (_activeFilter != 'Todos') ...[
                ChartContainer(readings: readings, filter: _activeFilter),
                const SizedBox(height: 25),
              ],
              _buildFilters(),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 30, 24, 15),
                child: Text(
                  'Ultimas lecturas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (rp.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: readings.length,
                  itemBuilder: (context, index) =>
                      _buildTimelineCard(readings[index], age, rp),
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    final filters = ['Todos', 'Presion', 'Pulso', 'Glucosa', 'Peso'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _activeFilter == f;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceChip(
              label: Text(
                f,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              selected: isSelected,
              onSelected: (val) => setState(() => _activeFilter = f),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : const Color(0xFFE0E0E0),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineCard(
    BloodPressureReading reading,
    int? age,
    ReadingsProvider rp,
  ) {
    final dateStr = DateFormat('d/M/y H:mm', 'es_ES').format(reading.createdAt);
    final List<Widget> metricRows = [];

    if (reading.hasPressure &&
        (_activeFilter == 'Todos' || _activeFilter == 'Presion')) {
      final sysSev = MeasurementRanges.getSystolicSeverity(age, reading.systolic!);
      final diaSev = MeasurementRanges.getDiastolicSeverity(age, reading.diastolic!);
      final sev = (sysSev == MeasurementSeverity.critical ||
              diaSev == MeasurementSeverity.critical)
          ? MeasurementSeverity.critical
          : (sysSev == MeasurementSeverity.warning ||
                  diaSev == MeasurementSeverity.warning)
              ? MeasurementSeverity.warning
              : MeasurementSeverity.normal;

      metricRows.add(
        MetricRow(
          icon: Icons.favorite,
          label: 'Presión',
          value: '${reading.systolic}/${reading.diastolic}',
          unit: 'mmHg',
          severity: sev,
        ),
      );
    }

    if (reading.hasHeartRate &&
        (_activeFilter == 'Todos' || _activeFilter == 'Pulso')) {
      final sev = MeasurementRanges.getHeartRateSeverity(age, reading.heartRate!);
      metricRows.add(
        MetricRow(
          icon: Icons.speed,
          label: 'Pulso',
          value: '${reading.heartRate}',
          unit: 'lpm',
          severity: sev,
        ),
      );
    }

    if (reading.hasGlucose &&
        (_activeFilter == 'Todos' || _activeFilter == 'Glucosa')) {
      final sev = MeasurementRanges.getGlucoseSeverity(age, reading.glucose!);
      metricRows.add(
        MetricRow(
          icon: Icons.water_drop,
          label: 'Glucosa',
          value: '${reading.glucose}',
          unit: 'mg/dL',
          severity: sev,
        ),
      );
    }

    if (reading.hasWeight &&
        (_activeFilter == 'Todos' || _activeFilter == 'Peso')) {
      final sev = MeasurementRanges.getWeightSeverity(age, reading.weight!);
      metricRows.add(
        MetricRow(
          icon: Icons.monitor_weight,
          label: 'Peso',
          value: reading.weight!.toStringAsFixed(1),
          unit: 'kg',
          severity: sev,
        ),
      );
    }

    if (metricRows.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                Text(
                  dateStr,
                  style: GoogleFonts.lexend(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    final confirm = await showDeleteConfirmDialog(
                      context,
                      title: '¿Eliminar Medición?',
                      content:
                          '¿Estás seguro de que deseas eliminar esta medición de tu historial?',
                    );
                    if (confirm == true) {
                      await rp.deleteReading(reading.id, widget.userId);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(children: metricRows),
          ),
        ],
      ),
    );
  }
}
