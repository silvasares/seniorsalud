import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: Colors.white,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.lexendTextTheme(),
    );
  }

  static TextStyle headerStyle({
    double size = 32,
    FontWeight weight = FontWeight.w900,
    Color color = Colors.black87,
  }) {
    return GoogleFonts.lexend(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  static TextStyle primaryText({
    double size = 22,
    FontWeight weight = FontWeight.w800,
  }) {
    return GoogleFonts.lexend(
      fontSize: size,
      fontWeight: weight,
      color: AppColors.primary,
    );
  }
}
