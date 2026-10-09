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
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainerLight,
        onPrimaryContainer: AppColors.primaryDark,

        secondary: AppColors.accent,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.goldLight,
        onSecondaryContainer: Color(0xFF78350F),

        // M3 Surface Ladder (Crisp Snow & Pure White)
        surface: AppColors.background, // #F8FAFC
        surfaceContainerLowest: Color(0xFFF1F5F9),
        surfaceContainerLow: Color(0xFFF8FAFC),
        surfaceContainer: Colors.white,
        surfaceContainerHigh: Colors.white,
        surfaceContainerHighest: Colors.white,
        onSurface: AppColors.textPrimary, // #0F172A
        onSurfaceVariant: AppColors.textSecondary, // #475569

        outline: AppColors.border, // #E2E8F0
        outlineVariant: Color(0xFFEDF2F7),

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
          fontWeight: FontWeight.w700,
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
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
        primary: AppColors.darkPrimary, // #10B981 (Luminous Medina Emerald)
        onPrimary: Color(0xFF022C22),
        primaryContainer: AppColors.darkPrimaryContainer,
        onPrimaryContainer: AppColors.darkPrimary,

        secondary: AppColors.darkGold, // #FBBF24 (Andalusian Gold)
        onSecondary: Color(0xFF451A03),
        secondaryContainer: AppColors.darkGoldLight,
        onSecondaryContainer: AppColors.goldHighlight,

        // M3 Surface Ladder (Deep Midnight Obsidian & Layered Surfaces)
        surface: AppColors.darkBackground, // #0A0E13
        surfaceContainerLowest: Color(0xFF06090D),
        surfaceContainerLow: Color(0xFF0E1318),
        surfaceContainer: AppColors.darkSurfaceSecondary, // #12181F
        surfaceContainerHigh: AppColors.darkSurfaceElevated, // #1A232C
        surfaceContainerHighest: Color(0xFF222E3A),

        onSurface: AppColors.darkTextPrimary, // #F8FAFC
        onSurfaceVariant: AppColors.darkTextSecondary, // #94A3B8

        outline: AppColors.darkBorder, // #22303C
        outlineVariant: Color(0xFF1C2731),

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
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.darkTextSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurfaceSecondary,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextTertiary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: const Color(0xFF022C22),
          textStyle: AppTextStyles.button,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkSurfaceSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurfaceSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        contentTextStyle: TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.darkTextPrimary,
        ),
      ),
    );
  }
}
