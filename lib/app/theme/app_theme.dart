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
        primary: AppColors.primary, // Blue Gray 700 #455A64
        onPrimary: Colors.white,
        primaryContainer: AppColors.blueGray100, // #CFD8DC
        onPrimaryContainer: AppColors.blueGray900, // #263238

        secondary: AppColors.accent, // Gold #C59533
        onSecondary: Colors.white,
        secondaryContainer: AppColors.goldLight,
        onSecondaryContainer: Color(0xFF5C4106),

        // M3 Surface Ladder (Blue Gray 50 Canvas & Pure White Cards)
        surface: AppColors.background, // 0xFFECEFF1
        surfaceContainerLowest: Color(0xFFE2E7EA),
        surfaceContainerLow: Color(0xFFEAEFF1),
        surfaceContainer: Colors.white, // Crisp pure white cards
        surfaceContainerHigh: Colors.white,
        surfaceContainerHighest: Colors.white,
        onSurface: AppColors.textPrimary, // #263238
        onSurfaceVariant: AppColors.textSecondary, // #546E7A

        outline: AppColors.blueGray200, // #B0BEC5
        outlineVariant: AppColors.blueGray100, // #CFD8DC

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
          side: const BorderSide(color: AppColors.blueGray100, width: 1),
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
        primary: AppColors.darkPrimary, // 0xFF90A4AE (Blue Gray 300)
        onPrimary: Color(0xFF1B2327),
        primaryContainer: AppColors.blueGray800, // 0xFF37474F
        onPrimaryContainer: AppColors.blueGray50, // 0xFFECEFF1

        secondary: AppColors.darkGold, // 0xFFE5B95C
        onSecondary: Color(0xFF281C06),
        secondaryContainer: AppColors.darkGoldLight,
        onSecondaryContainer: AppColors.goldHighlight,

        // M3 Surface Ladder (Deep Blue Gray Midnight)
        surface: AppColors.darkBackground, // 0xFF1B2327
        surfaceContainerLowest: Color(0xFF151C20),
        surfaceContainerLow: Color(0xFF1F282D),
        surfaceContainer: AppColors.blueGray900, // 0xFF263238
        surfaceContainerHigh: Color(0xFF2E3C43),
        surfaceContainerHighest: AppColors.blueGray800, // 0xFF37474F

        onSurface: AppColors.darkTextPrimary, // 0xFFECEFF1
        onSurfaceVariant: AppColors.darkTextSecondary, // 0xFFB0BEC5

        outline: AppColors.blueGray600, // 0xFF546E7A
        outlineVariant: AppColors.blueGray800, // 0xFF37474F

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
        backgroundColor: AppColors.blueGray900,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextTertiary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: const Color(0xFF1B2327),
          textStyle: AppTextStyles.button,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.blueGray900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: AppColors.blueGray800, width: 1),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.blueGray800,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.blueGray900,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.blueGray800,
        contentTextStyle: TextStyle(
          fontFamily: 'Cairo',
          color: AppColors.darkTextPrimary,
        ),
      ),
    );
  }
}
