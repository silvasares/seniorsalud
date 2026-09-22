import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/blood_pressure_reading.dart';

class ChartContainer extends StatelessWidget {
  final List<BloodPressureReading> readings;
  final String filter;

  const ChartContainer({
    super.key,
    required this.readings,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    String title = 'Presion Arterial';
    IconData icon = Icons.favorite;
    Color color = const Color(0xFF0061A6);

    if (filter == 'Pulso') {
      title = 'Pulso Cardíaco';
      icon = Icons.speed;
      color = const Color(0xFFD81B60);
    } else if (filter == 'Glucosa') {
      title = 'Glucosa';
      icon = Icons.water_drop;
      color = Colors.blue;
    } else if (filter == 'Peso') {
      title = 'Peso';
      icon = Icons.monitor_weight;
      color = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE3F2FD), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 200,
            child: readings.isEmpty
                ? const Center(child: Text('No hay datos suficientes para el gráfico'))
                : _buildPressureChart(),
          ),
          const SizedBox(height: 20),
          if (filter == 'Todos' || filter == 'Presion')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend('Sistólica', const Color(0xFF0061A6)),
                const SizedBox(width: 25),
                _buildLegend('Diastólica', Colors.orange),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildPressureChart() {
    final recent = readings.where((r) {
      if (filter == 'Pulso') return r.hasHeartRate;
      if (filter == 'Glucosa') return r.hasGlucose;
      if (filter == 'Peso') return r.hasWeight;
      return r.hasPressure;
    }).take(7).toList().reversed.toList();

    if (recent.isEmpty) {
      return const Center(child: Text('No hay datos suficientes'));
    }

    List<LineChartBarData> barData = [];

    if (filter == 'Pulso') {
      barData = [
        LineChartBarData(
          spots: List.generate(
            recent.length,
            (i) => FlSpot(i.toDouble(), (recent[i].heartRate ?? 0).toDouble()),
          ),
          isCurved: true,
          color: const Color(0xFFD81B60),
          barWidth: 4,
          dotData: const FlDotData(show: true),
        ),
      ];
    } else if (filter == 'Glucosa') {
      barData = [
        LineChartBarData(
          spots: List.generate(
            recent.length,
            (i) => FlSpot(i.toDouble(), (recent[i].glucose ?? 0).toDouble()),
          ),
          isCurved: true,
          color: Colors.blue,
          barWidth: 4,
          dotData: const FlDotData(show: true),
        ),
      ];
    } else if (filter == 'Peso') {
      barData = [
        LineChartBarData(
          spots: List.generate(
            recent.length,
            (i) => FlSpot(i.toDouble(), (recent[i].weight ?? 0).toDouble()),
          ),
          isCurved: true,
          color: Colors.green,
          barWidth: 4,
          dotData: const FlDotData(show: true),
        ),
      ];
    } else {
      barData = [
        LineChartBarData(
          spots: List.generate(
            recent.length,
            (i) => FlSpot(i.toDouble(), (recent[i].systolic ?? 0).toDouble()),
          ),
          isCurved: true,
          color: const Color(0xFF0061A6),
          barWidth: 4,
          dotData: const FlDotData(show: true),
        ),
        LineChartBarData(
          spots: List.generate(
            recent.length,
            (i) => FlSpot(i.toDouble(), (recent[i].diastolic ?? 0).toDouble()),
          ),
          isCurved: true,
          color: Colors.orange,
          barWidth: 4,
          dotData: const FlDotData(show: true),
        ),
      ];
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 40,
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: barData,
      ),
    );
  }
}
