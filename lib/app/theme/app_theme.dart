import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData dark() {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    final textStyle =
        AppTextStyles.body.copyWith(fontWeight: FontWeight.w600);
    const minSize = Size(0, AppSpacing.buttonMinHeight);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      fontFamily: AppTextStyles.fontFamily,
      splashFactory: NoSplash.splashFactory,
      splashColor: AppColors.clear,
      highlightColor: AppColors.clear,
      hoverColor: AppColors.overlay,
      focusColor: AppColors.clear,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surfaceElevated,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        shadowColor: AppColors.clear,
        surfaceTintColor: AppColors.clear,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
        actionsIconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      textTheme: AppTextStyles.textTheme,
      cardTheme: const CardThemeData(
        color: AppColors.surfaceElevated,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerColor: AppColors.divider,
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: AppSpacing.iconMD,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.textSecondary),
          overlayColor: WidgetStatePropertyAll(
            AppColors.clear,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        labelStyle: AppText.body.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppText.body.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minSize),
          padding: const WidgetStatePropertyAll(AppSpacing.buttonPadding),
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
            AppColors.clear,
          ),
          animationDuration: AppSpacing.animFast,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedIconTheme: const IconThemeData(size: AppSpacing.iconMD),
        unselectedIconTheme: const IconThemeData(size: AppSpacing.iconMD),
        selectedLabelStyle: AppText.navigationLabel,
        unselectedLabelStyle: AppText.navigationLabel,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minSize),
          padding: const WidgetStatePropertyAll(AppSpacing.buttonPadding),
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
            AppColors.clear,
          ),
          animationDuration: AppSpacing.animFast,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minSize),
          padding:
              const WidgetStatePropertyAll(AppSpacing.buttonPaddingCompact),
          shape: WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(textStyle),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.primary),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 1 : 0,
          ),
          overlayColor: WidgetStatePropertyAll(
            AppColors.clear,
          ),
          animationDuration: AppSpacing.animFast,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(minSize),
          padding:
              const WidgetStatePropertyAll(AppSpacing.buttonPaddingCompact),
          shape: WidgetStatePropertyAll(shape),
          textStyle: WidgetStatePropertyAll(textStyle),
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.primary),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 1 : 0,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
          ),
          overlayColor: WidgetStatePropertyAll(
            AppColors.clear,
          ),
          animationDuration: AppSpacing.animFast,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.iOS: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.fuchsia: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.linux: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.macOS: _SlideFadePageTransitionsBuilder(),
          TargetPlatform.windows: _SlideFadePageTransitionsBuilder(),
        },
      ),
    );
  }
}

class _SlideFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _SlideFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.isFirst) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(0, AppSpacing.transitionCurveEnd, curve: Curves.easeOut),
      reverseCurve:
          Interval(0, AppSpacing.transitionCurveEnd, curve: Curves.easeOut),
    );
    final offsetTween = Tween<Offset>(
      begin: Offset(0, AppSpacing.routeSlideOffset),
      end: Offset.zero,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: curved.drive(offsetTween),
        child: child,
      ),
    );
  }
}
