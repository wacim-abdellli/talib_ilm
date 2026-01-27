import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData light() => lightTheme;

  static ThemeData dark() => darkTheme;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: Color(0xFF002022), // Dark teal for contrast

        secondary: AppColors.accent,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.goldLight,
        onSecondaryContainer: Color(0xFF2B2100), // Dark gold for contrast
        // M3 Surface Ladder (Light)
        surface: Color(
          0xFFF9F9F9,
        ), // App background (slightly grey for contrast)
        surfaceContainerLowest: Color(0xFFFFFFFF), // Quick actions (pure white)
        surfaceContainerLow: Color(0xFFF5F5F0), // Quote card
        surfaceContainer: Color(0xFFF0F0EB), // Learning card
        surfaceContainerHigh: Color(0xFFEBEBE6), // Prayer hero anchor
        surfaceContainerHighest: Color(0xFFE6E6E1),

        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,

        outline: Color(0xFFB5B5B5),
        outlineVariant: Color(0xFFE8E6E3),

        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.heading1,
        displayMedium: AppTextStyles.heading2,
        displaySmall: AppTextStyles.heading3,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.label,
        labelSmall: AppTextStyles.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none, // Remove default borders, use container colors
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Cairo',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.darkPrimaryLight,
        onPrimaryContainer: Colors.white,

        secondary: AppColors.darkGold,
        onSecondary: Colors.black,
        secondaryContainer: AppColors.darkGoldLight,
        onSecondaryContainer: Color(0xFFFFD700),

        // M3 Surface Ladder (Dark)
        surface: AppColors.darkBackground, // #121212
        surfaceContainerLowest: Color(0xFF0A0A0A), // Deepest (Quick actions)
        surfaceContainerLow: Color(0xFF1E1E1E), // Quote card
        surfaceContainer: Color(0xFF252525), // Learning card
        surfaceContainerHigh: Color(0xFF2D2D2D), // Prayer hero
        surfaceContainerHighest: Color(0xFF353535),

        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,

        outline: Color(0xFF484848),
        outlineVariant: Color(0xFF2A2A2A),

        error: AppColors.error,
        onError: Colors.white,
      ),
      dividerColor: AppColors.darkDivider,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.heading1.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        displayMedium: AppTextStyles.heading2.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        displaySmall: AppTextStyles.heading3.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        labelLarge: AppTextStyles.button.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        labelMedium: AppTextStyles.label.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        labelSmall: AppTextStyles.caption.copyWith(
          color: AppColors.darkTextTertiary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.darkTextSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextTertiary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        contentTextStyle: TextStyle(color: AppColors.darkTextPrimary),
      ),
    );
  }
}
