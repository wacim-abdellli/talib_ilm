import 'package:flutter/material.dart';

class AppColors {
  // Primary (warm parchment golds)
  static const primary = Color(0xFFB8860B);
  static const primaryLight = Color(0xFFD4AF37);
  static const primaryDark = Color(0xFF8B7355);

  // Secondary (gold harmony)
  static const secondary = Color(0xFFD4AF37);
  static const secondaryLight = Color(0xFFD4AF37);
  static const secondaryDark = Color(0xFF8B7355);

  // Backgrounds / Surfaces
  static const borderSubtle = Color(0xFFE6E2DA);
  static const background = Color(0xFFFAF8F3);
  static const surface = Color(0xFFF5F1E8);
  static const surfaceVariant = Color(0xFFEFEBE0);
  static const surfaceElevated = Color(0xFFEFEBE0);

  // Text (rich browns)
  static const textPrimary = Color(0xFF2C1810);
  static const textSecondary = Color(0xFF5D4E37);
  static const textDisabled = Color(0xFF9E8B7B);

  // Accent / Status
  static const accent = Color(0xFF7D9B76);
  static const accentLight = Color(0xFFA8C5A0);
  static const success = Color(0xFF7D9B76);
  static const error = Color(0xFFC17F5E);
  static const warning = Color(0xFFDAA520);

  // Prayer time tones
  static const fajr = Color(0xFFE8A87C);
  static const dhuhr = Color(0xFFD4AF37);
  static const asr = Color(0xFFC19A6B);
  static const maghrib = Color(0xFFCD853F);
  static const isha = Color(0xFF6B7F99);

  static const clear = Color(0x00000000);

  // Dark palette (warm earth)
  static const darkBackground = Color(0xFF1A1512);
  static const darkSurface = Color(0xFF2C2520);
  static const darkSurfaceVariant = Color(0xFF2C2520);
  static const darkSurfaceElevated = Color(0xFF2C2520);
  static const darkTextPrimary = Color(0xFFF5F1E8);
  static const darkTextSecondary = Color(0xFFF5F1E8);
  static const darkTextDisabled = Color(0xFFF5F1E8);

  static const backgroundBottom = Color(0xFFEFEBE0);

  static Color get stroke => textPrimary.withValues(alpha: 0.12);
  static Color get divider => textPrimary.withValues(alpha: 0.16);
  static Color get overlay => textPrimary.withValues(alpha: 0.08);

  static Color get textMuted => textSecondary;

  // Accent roles
  static const prayerNext = primary;
  static const prayerCurrent = secondary;
  static const cardAccent = accent;

  // Gradients (light)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFAF8F3),
      Color(0xFFEFEBE0),
    ],
  );

  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFAF8F3),
      Color(0xFFEFEBE0),
    ],
  );

  static const LinearGradient vignetteGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00FAF8F3),
      Color(0x66EFEBE0),
    ],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF5F1E8),
      Color(0xFFEFEBE0),
    ],
  );

  static const LinearGradient surfaceElevatedGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF5F1E8),
      Color(0xFFEFEBE0),
    ],
  );

  static const LinearGradient glowGradient = LinearGradient(
    colors: [
      Color(0x26B8860B),
      Color(0x00B8860B),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB8860B),
      Color(0xFF8B7355),
      Color(0xFFD4AF37),
    ],
  );
}

class AppColorsDark {
  static const background = AppColors.darkBackground;
  static const surface = AppColors.darkSurface;
  static const surfaceVariant = AppColors.darkSurfaceVariant;
  static const surfaceElevated = AppColors.darkSurfaceElevated;

  static const textPrimary = AppColors.darkTextPrimary;
  static const textSecondary = AppColors.darkTextSecondary;
  static const textDisabled = AppColors.darkTextDisabled;

  static const primary = AppColors.primary;
  static const primaryLight = AppColors.primaryLight;
  static const primaryDark = AppColors.primaryDark;

  static const secondary = AppColors.secondary;
  static const secondaryLight = AppColors.secondaryLight;
  static const secondaryDark = AppColors.secondaryDark;

  static const accent = AppColors.accent;
  static const accentLight = AppColors.accentLight;
  static const success = AppColors.success;
  static const error = AppColors.error;
  static const warning = AppColors.warning;

  static Color get stroke => textPrimary.withValues(alpha: 0.12);
  static Color get divider => textPrimary.withValues(alpha: 0.16);
  static Color get overlay => textPrimary.withValues(alpha: 0.08);
  static Color get textMuted => textSecondary;
}
