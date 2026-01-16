import 'package:flutter/material.dart';

class AppColors {
  // PRIMARY - Clean modern teal (lighter, friendlier)
  static const primary = Color(0xFF14B8A6);
  static const primaryDark = Color(0xFF0D9488);
  static const primaryLight = Color(0xFF5EEAD4);

  // BACKGROUNDS - Clean whites
  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSecondary = Color(0xFFF5F5F5);

  // TEXT - High contrast, readable
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);

  // ACCENT COLORS - Vibrant, modern
  static const accentBlue = Color(0xFF3B82F6);
  static const accentPurple = Color(0xFF8B5CF6);
  static const accentPink = Color(0xFFEC4899);
  static const accentOrange = Color(0xFFF97316);
  static const accentGreen = Color(0xFF10B981);
  static const accentYellow = Color(0xFFFBBF24);

  // PRAYER COLORS - Distinct, beautiful
  static const fajr = Color(0xFF6366F1);
  static const sunrise = Color(0xFFFBBF24);
  static const dhuhr = Color(0xFF14B8A6);
  static const asr = Color(0xFFF97316);
  static const maghrib = Color(0xFFEC4899);
  static const isha = Color(0xFF8B5CF6);

  // STATES
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  // BORDERS & DIVIDERS - Subtle
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFF1F5F9);

  // --- COMPATIBILITY LAYER (Mapping old keys to new palette) ---

  // General aliasing
  static const stroke = border;
  static const textMuted = textTertiary;
  static const textDisabled = textTertiary;
  static const textOnPrimary = surface;
  static const clear = Colors.transparent;
  static const black = Colors.black;
  static const accent = accentOrange; // Replacing Gold with Orange
  static const secondary = primaryLight;
  static const surfaceElevated = surface;
  static const surfaceVariant = surfaceSecondary;

  // Dark Theme Mappings (Modern Slate)
  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);

  // Categories (Mapped to Accents)
  static const categoryAqidah = accentBlue;
  static const categoryFiqh = accentPurple;
  static const categoryHadith = accentGreen;
  static const categoryArabic = accentOrange;
  static const categoryQuran = accentPink;

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, surface],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceSecondary],
  );

  static const surfaceElevatedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceSecondary],
  );
}
