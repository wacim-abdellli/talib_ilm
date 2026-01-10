import 'package:flutter/material.dart';

class AppColors {
  // Primary (Teal/Emerald)
  static const primary = Color(0xFF0D7377);
  static const primaryLight = Color(0xFF14FFEC);
  static const primaryDark = Color(0xFF05595B);

  // Secondary (Gold)
  static const secondary = Color(0xFFC9A962);
  static const secondaryLight = Color(0xFFE5D4A3);
  static const secondaryDark = Color(0xFFA08340);

  // Backgrounds / Surfaces
  static const background = Color(0xFFF8F6F3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEAE7E3);
  static const surfaceElevated = Color(0xFFEAE7E3);

  // Text
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textDisabled = Color(0xFF9E9E9E);

  // Accent / Status
  static const accent = Color(0xFF8B6F47);
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE53935);
  static const warning = Color(0xFFFB8C00);

  static const clear = Color(0x00000000);

  // Dark palette (compat)
  static const darkBackground = Color(0xFF0B1211);
  static const darkSurface = Color(0xFF121A19);
  static const darkSurfaceVariant = Color(0xFF1A2422);
  static const darkSurfaceElevated = Color(0xFF20302D);
  static const darkTextPrimary = Color(0xFFF2F0EB);
  static const darkTextSecondary = Color(0xFFC4BEB3);
  static const darkTextDisabled = Color(0xFF8A857B);

  static const backgroundBottom = Color(0xFFEAE7E3);

  static Color get stroke => textPrimary.withOpacity(0.12);
  static Color get divider => textPrimary.withOpacity(0.16);
  static Color get overlay => textPrimary.withOpacity(0.08);

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
      Color(0xFFF8F6F3),
      Color(0xFFEAE7E3),
    ],
  );

  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF8F6F3),
      Color(0xFFEAE7E3),
    ],
  );

  static const LinearGradient vignetteGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00F8F6F3),
      Color(0x66E0D8CC),
    ],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFEAE7E3),
    ],
  );

  static const LinearGradient surfaceElevatedGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF4F1EC),
      Color(0xFFEAE7E3),
    ],
  );

  static const LinearGradient glowGradient = LinearGradient(
    colors: [
      Color(0x260D7377),
      Color(0x000D7377),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D7377),
      Color(0xFF05595B),
      Color(0xFFE5D4A3),
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
  static const success = AppColors.success;
  static const error = AppColors.error;
  static const warning = AppColors.warning;

  static Color get stroke => textPrimary.withOpacity(0.12);
  static Color get divider => textPrimary.withOpacity(0.16);
  static Color get overlay => textPrimary.withOpacity(0.08);
  static Color get textMuted => textSecondary;
}
