import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/measurement_ranges.dart';

class MeasurementBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final MeasurementSeverity severity;

  const MeasurementBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = MeasurementRanges.severityTextColor(severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MeasurementRanges.severityBgColor(severity),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: MeasurementRanges.severityBorderColor(severity),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: textColor, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final MeasurementSeverity severity;

  const MetricRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = MeasurementRanges.severityColor(severity);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 28),
          const SizedBox(width: 15),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              style: GoogleFonts.lexend(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
              children: [
                TextSpan(
                  text: '$value ',
                  style: TextStyle(fontSize: 24, color: statusColor),
                ),
                TextSpan(
                  text: unit,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
