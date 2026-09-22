import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum MeasurementSeverity { normal, warning, critical }

class MeasurementRanges {
  static MeasurementSeverity getSystolicSeverity(int? age, int systolic) {
    if (systolic < 80 || systolic > 145) return MeasurementSeverity.critical;
    if (systolic < 90 || systolic > 130) return MeasurementSeverity.warning;
    return MeasurementSeverity.normal;
  }

  static MeasurementSeverity getDiastolicSeverity(int? age, int diastolic) {
    if (diastolic < 55 || diastolic > 90) return MeasurementSeverity.critical;
    if (diastolic < 60 || diastolic > 80) return MeasurementSeverity.warning;
    return MeasurementSeverity.normal;
  }

  static MeasurementSeverity getHeartRateSeverity(int? age, int heartRate) {
    if (heartRate < 50 || heartRate > 100) return MeasurementSeverity.critical;
    if (heartRate < 60 || heartRate > 90) return MeasurementSeverity.warning;
    return MeasurementSeverity.normal;
  }

  static MeasurementSeverity getGlucoseSeverity(int? age, int glucose) {
    if (glucose < 65 || glucose > 180) return MeasurementSeverity.critical;
    if (glucose < 75 || glucose > 140) return MeasurementSeverity.warning;
    return MeasurementSeverity.normal;
  }

  static MeasurementSeverity getWeightSeverity(int? age, double weight) {
    if (weight < 40 || weight > 130) return MeasurementSeverity.critical;
    if (weight < 48 || weight > 100) return MeasurementSeverity.warning;
    return MeasurementSeverity.normal;
  }

  static Color severityColor(MeasurementSeverity severity) {
    switch (severity) {
      case MeasurementSeverity.critical:
        return AppColors.critical;
      case MeasurementSeverity.warning:
        return AppColors.warning;
      case MeasurementSeverity.normal:
        return AppColors.normal;
    }
  }

  static Color severityBgColor(MeasurementSeverity severity) {
    switch (severity) {
      case MeasurementSeverity.critical:
        return AppColors.redLight;
      case MeasurementSeverity.warning:
        return AppColors.orangeLight;
      case MeasurementSeverity.normal:
        return AppColors.greenLight;
    }
  }

  static Color severityBorderColor(MeasurementSeverity severity, {double alpha = 0.3}) {
    return severityColor(severity).withValues(alpha: alpha);
  }

  static MeasurementSeverity getTemperatureSeverity(int? age, double temperature) {
    if (temperature < 35.0 || temperature > 38.5) return MeasurementSeverity.critical;
    if (temperature < 36.0 || temperature > 37.5) return MeasurementSeverity.warning;
    return MeasurementSeverity.normal;
  }

  static MeasurementSeverity getSpo2Severity(int? age, int spo2) {
    if (spo2 < 90) return MeasurementSeverity.critical;
    if (spo2 < 95) return MeasurementSeverity.warning;
    return MeasurementSeverity.normal;
  }

  static Color severityTextColor(MeasurementSeverity severity) {
    switch (severity) {
      case MeasurementSeverity.critical:
        return Colors.red[800]!;
      case MeasurementSeverity.warning:
        return Colors.orange[800]!;
      case MeasurementSeverity.normal:
        return Colors.green[800]!;
    }
  }
}
