import 'package:flutter/material.dart';

/// Colors taken straight from the wireframes.
class AppColors {
  static const navy = Color(0xFF14213D);
  static const navyChip = Color(0xFF2B3A63);
  static const headerMuted = Color(0xFFC7D0E0);
  static const red = Color(0xFFB42318);
  static const redTint = Color(0xFFFDECEA);
  static const bg = Color(0xFFF6F7F9);
  static const border = Color(0xFFCBD2DC);
  static const divider = Color(0xFFE3E7EE);
  static const muted = Color(0xFF4B5563);
  static const selectedRow = Color(0xFFEFF3FA);

  // Status colors
  static const amberBg = Color(0xFFFEF3C7);
  static const amberFg = Color(0xFF78350F);
  static const amberBorder = Color(0xFFF5D77A);
  static const purpleBg = Color(0xFFEDE9FE);
  static const purpleFg = Color(0xFF4C1D95);
  static const purpleBorder = Color(0xFFC9BDF5);
  static const greenBg = Color(0xFFDCFCE7);
  static const greenFg = Color(0xFF14532D);
  static const greenBorder = Color(0xFF9ADBB0);
}

/// Short helper so screens stay readable.
TextStyle ts(
  double size,
  FontWeight weight, {
  Color color = AppColors.navy,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    // The wireframes use Inter. If you add the font (or google_fonts) it will
    // be picked up here; otherwise Flutter falls back to the system font.
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.red,
      primary: AppColors.red,
    ),
  );
}

OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 2),
    );

InputDecoration appInput({String? hint}) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: _inputBorder(AppColors.border),
      enabledBorder: _inputBorder(AppColors.border),
      focusedBorder: _inputBorder(AppColors.navy),
    );
