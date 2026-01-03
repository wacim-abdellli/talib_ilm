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
      highlightColor: AppColors.primary.withValues(alpha: 0.06),
      hoverColor: AppColors.primary.withValues(alpha: 0.04),
      focusColor: AppColors.primary.withValues(alpha: 0.06),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textSecondary),
        actionsIconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      textTheme: const TextTheme(
        titleLarge: AppText.headlineLarge,
        titleMedium: AppText.sectionTitle,
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
      dividerColor: AppColors.divider,
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.textSecondary),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primary.withValues(alpha: 0.08),
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
            AppColors.primary.withValues(alpha: 0.1),
          ),
          animationDuration: AppUi.animationFast,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedIconTheme: const IconThemeData(size: 22),
        unselectedIconTheme: const IconThemeData(size: 22),
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
            AppColors.primary.withValues(alpha: 0.1),
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
              const WidgetStatePropertyAll(AppColors.primary),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 1 : 0,
          ),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primary.withValues(alpha: 0.08),
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
              const WidgetStatePropertyAll(AppColors.primary),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 1 : 0,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
          ),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primary.withValues(alpha: 0.08),
          ),
          animationDuration: AppUi.animationFast,
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
      curve: const Interval(0, 0.75, curve: Curves.easeOut),
      reverseCurve: const Interval(0, 0.75, curve: Curves.easeIn),
    );
    final offsetTween =
        Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: curved.drive(offsetTween),
        child: child,
      ),
    );
  }
}
