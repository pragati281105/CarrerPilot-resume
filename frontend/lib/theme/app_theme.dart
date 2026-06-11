// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // =========================
  // COLORS
  // =========================

  static const Color bgColor = Color(0xFF080810);
  static const Color sidebarColor = Color(0xFF0C0C14);
  static const Color surfaceColor = Color(0xFF101018);

  // Accent
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberDark = Color(0xFFD97706);
  static const Color amberGlow = Color(0x33F59E0B);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = amber;
  static const Color danger = Color(0xFFEF4444);

  // Glass
  static const Color glassWhite = Color(0x14FFFFFF);
  static const Color glassBorder = Color(0x22FFFFFF);
  static const Color glassHover = Color(0x1FFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Colors.white;
  static const Color textMuted = Color(0xCCFFFFFF);
  static const Color textHint = Color(0x3DFFFFFF);

  // Radius
  static const double cardRadius = 24;

  // =========================
  // THEME
  // =========================

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgColor,

    colorScheme: const ColorScheme.dark(
      primary: amber,
      secondary: amberDark,
      surface: surfaceColor,

      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: textPrimary,

      error: danger,
      onError: Colors.white,
    ),

    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: textSecondary,
      displayColor: textPrimary,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(
        color: textSecondary,
      ),
      titleTextStyle: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),

    cardTheme: CardThemeData(
      color: glassWhite,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: const BorderSide(
          color: glassBorder,
          width: 1,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: amber,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF12121A),

      hintStyle: GoogleFonts.inter(
        color: textHint,
        fontSize: 14,
      ),

      labelStyle: GoogleFonts.inter(
        color: textMuted,
        fontSize: 14,
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: glassBorder,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: glassBorder,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: amber,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: danger,
          width: 1.5,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: danger,
          width: 1.5,
        ),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: glassBorder,
      thickness: 1,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: amber,
      linearTrackColor: Color(0xFF1B1B25),
      circularTrackColor: Color(0xFF1B1B25),
    ),

    iconTheme: const IconThemeData(
      color: textSecondary,
      size: 20,
    ),
  );
}