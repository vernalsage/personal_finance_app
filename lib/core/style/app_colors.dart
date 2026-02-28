import 'package:flutter/material.dart';

class AppColors {
  // ─── Primary Palette ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF19AEA7);         // Teal
  static const Color primaryDark = Color(0xFF0D8A84);     // Teal dark
  static const Color primaryLight = Color(0xFF4DB6AC);    // Teal light
  static const Color primaryBg = Color(0xFFE6F7F7);       // Teal 10%

  // ─── Functional Colors ────────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);         // Green
  static const Color error = Color(0xFFDC2626);           // Red
  static const Color warning = Color(0xFFF59E0B);         // Amber
  static const Color info = Color(0xFF3B82F6);            // Blue

  // ─── Light Mode Palette ───────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardBgLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F1C2E);
  static const Color textSecondaryLight = Color(0xFF6B7A8D);
  static const Color borderLight = Color(0xFFE2E8F0);

  // ─── Dark Mode Palette ────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0B141D);
  static const Color surfaceDark = Color(0xFF15202B);
  static const Color cardBgDark = Color(0xFF192734);
  static const Color textPrimaryDark = Color(0xFFF7F9F9);
  static const Color textSecondaryDark = Color(0xFF8B98A5);
  static const Color borderDark = Color(0xFF2F3336);

  // Helper to get color based on brightness
  static Color background(bool isDark) => isDark ? backgroundDark : backgroundLight;
  static Color surface(bool isDark) => isDark ? surfaceDark : surfaceLight;
  static Color card(bool isDark) => isDark ? cardBgDark : cardBgLight;
  static Color textPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimaryLight;
  static Color textSecondary(bool isDark) => isDark ? textSecondaryDark : textSecondaryLight;
  static Color border(bool isDark) => isDark ? borderDark : borderLight;
}
