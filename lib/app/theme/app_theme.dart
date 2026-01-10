import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData light() {
    return _buildTheme(
      brightness: Brightness.light,
      scaffoldBackground: AppColors.background,
      surface: AppColors.surface,
      surfaceVariant: AppColors.surfaceVariant,
      surfaceElevated: AppColors.surfaceElevated,
      textPrimary: AppColors.textPrimary,
      textSecondary: AppColors.textSecondary,
      textDisabled: AppColors.textDisabled,
      onPrimary: AppColors.surface,
      onSecondary: AppColors.textPrimary,
    );
  }

  static ThemeData dark() {
    return _buildTheme(
      brightness: Brightness.dark,
      scaffoldBackground: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      surfaceVariant: AppColors.darkSurfaceVariant,
      surfaceElevated: AppColors.darkSurfaceElevated,
      textPrimary: AppColors.darkTextPrimary,
      textSecondary: AppColors.darkTextSecondary,
      textDisabled: AppColors.darkTextDisabled,
      onPrimary: AppColors.darkTextPrimary,
      onSecondary: AppColors.darkBackground,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color surface,
    required Color surfaceVariant,
    required Color surfaceElevated,
    required Color textPrimary,
    required Color textSecondary,
    required Color textDisabled,
    required Color onPrimary,
    required Color onSecondary,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    final textStyle =
        AppTextStyles.body.copyWith(fontWeight: FontWeight.w600);
    const minSize = Size(0, AppSpacing.buttonMinHeight);
    final dividerColor = textPrimary.withOpacity(0.16);

    final scheme = (brightness == Brightness.dark
            ? ColorScheme.dark(
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                background: scaffoldBackground,
                surface: surfaceElevated,
                onPrimary: onPrimary,
                onSecondary: onSecondary,
                onBackground: textPrimary,
                onSurface: textPrimary,
              )
            : ColorScheme.light(
                primary: AppColors.primary,
                secondary: AppColors.secondary,
                background: scaffoldBackground,
                surface: surfaceElevated,
                onPrimary: onPrimary,
                onSecondary: onSecondary,
                onBackground: textPrimary,
                onSurface: textPrimary,
              ))
        .copyWith(surfaceVariant: surfaceVariant);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBackground,
      canvasColor: surface,
      dialogBackgroundColor: surfaceElevated,
      primaryColor: AppColors.primary,
      fontFamily: AppTextStyles.fontFamily,
      splashFactory: NoSplash.splashFactory,
      splashColor: AppColors.clear,
      highlightColor: AppColors.clear,
      hoverColor: textPrimary.withOpacity(0.08),
      focusColor: AppColors.clear,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: textPrimary,
        centerTitle: true,
        elevation: 0,
        shadowColor: AppColors.clear,
        surfaceTintColor: AppColors.clear,
        iconTheme: IconThemeData(color: textSecondary),
        actionsIconTheme: IconThemeData(color: textSecondary),
      ),
      textTheme: AppTextStyles.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      disabledColor: textDisabled,
      cardTheme: CardThemeData(
        color: surfaceElevated,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerColor: dividerColor,
      iconTheme: IconThemeData(
        color: textSecondary,
        size: AppSpacing.iconMD,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(textSecondary),
          overlayColor: const WidgetStatePropertyAll(AppColors.clear),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: textPrimary,
        unselectedLabelColor: textSecondary,
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
          foregroundColor: WidgetStatePropertyAll(onPrimary),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 2 : 0,
          ),
          shadowColor: const WidgetStatePropertyAll(AppColors.primary),
          overlayColor: const WidgetStatePropertyAll(AppColors.clear),
          animationDuration: AppSpacing.animFast,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scaffoldBackground,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: textSecondary,
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
          foregroundColor: WidgetStatePropertyAll(onPrimary),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 2 : 0,
          ),
          shadowColor: const WidgetStatePropertyAll(AppColors.primary),
          overlayColor: const WidgetStatePropertyAll(AppColors.clear),
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
          foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 1 : 0,
          ),
          overlayColor: const WidgetStatePropertyAll(AppColors.clear),
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
          foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 1 : 0,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: AppColors.primary.withOpacity(0.6)),
          ),
          overlayColor: const WidgetStatePropertyAll(AppColors.clear),
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
