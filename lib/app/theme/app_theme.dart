import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text.dart';
import 'app_ui.dart';

class AppTheme {
  static ThemeData dark() {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppUi.radiusMD),
    );
    final textStyle = AppText.body.copyWith(fontWeight: FontWeight.w600);
    const minSize = Size(0, 44);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      fontFamily: 'Vazirmatn',
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: AppColors.primaryAlt.withValues(alpha: 0.06),
      hoverColor: AppColors.primaryAlt.withValues(alpha: 0.04),
      focusColor: AppColors.primaryAlt.withValues(alpha: 0.06),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryAlt,
        surface: AppColors.surface,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      textTheme: const TextTheme(
        titleLarge: AppText.headingXL,
        titleMedium: AppText.heading,
        bodyMedium: AppText.body,
        bodyLarge: AppText.body,
        labelLarge: AppText.body,
        labelMedium: AppText.caption,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerColor: const Color(0xFF252836),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.textPrimary),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primaryAlt.withValues(alpha: 0.08),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppUi.radiusSM),
            ),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primaryAlt,
        labelStyle: AppText.body.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppText.body.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minSize),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(textStyle),
          backgroundColor: const WidgetStatePropertyAll(AppColors.primary),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.textPrimary),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 2 : 0,
          ),
          shadowColor: const WidgetStatePropertyAll(AppColors.primary),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primaryAlt.withValues(alpha: 0.1),
          ),
          animationDuration: AppUi.animationFast,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primaryAlt,
        unselectedItemColor: AppColors.textSecondary,
        selectedIconTheme: const IconThemeData(size: 24),
        unselectedIconTheme: const IconThemeData(size: 22),
        selectedLabelStyle: AppText.caption.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppText.caption,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minSize),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(textStyle),
          backgroundColor: const WidgetStatePropertyAll(AppColors.primary),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.textPrimary),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 2 : 0,
          ),
          shadowColor: const WidgetStatePropertyAll(AppColors.primary),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primaryAlt.withValues(alpha: 0.1),
          ),
          animationDuration: AppUi.animationFast,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minSize),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(textStyle),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.primaryAlt),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 1 : 0,
          ),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primaryAlt.withValues(alpha: 0.08),
          ),
          animationDuration: AppUi.animationFast,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minSize),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          shape: WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(textStyle),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.primaryAlt),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 1 : 0,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: AppColors.primaryAlt.withValues(alpha: 0.6)),
          ),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primaryAlt.withValues(alpha: 0.08),
          ),
          animationDuration: AppUi.animationFast,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
