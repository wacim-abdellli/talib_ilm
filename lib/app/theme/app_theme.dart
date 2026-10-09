import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() => lightTheme;

  static ThemeData dark() => darkTheme;

  static ThemeData get lightTheme => _buildTheme(AppPalette.light);

  static ThemeData get darkTheme => _buildTheme(AppPalette.dark);

  static ThemeData _buildTheme(AppPalette palette) {
    final text = AppTextTheme.fromPalette(palette);
    final brightness = palette.isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'Cairo',
      scaffoldBackgroundColor: palette.bg,
      extensions: [palette],

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.primary,
        onPrimary: palette.onPrimary,
        primaryContainer: palette.primarySoft,
        onPrimaryContainer: palette.onPrimarySoft,
        secondary: palette.gold,
        onSecondary: palette.onGold,
        secondaryContainer: palette.goldSoft,
        onSecondaryContainer: palette.gold,
        surface: palette.surface,
        onSurface: palette.text,
        surfaceContainerLowest: palette.surfaceMuted,
        surfaceContainerLow: palette.surfaceMuted,
        surfaceContainer: palette.surface,
        surfaceContainerHigh: palette.surfaceRaised,
        surfaceContainerHighest: palette.surfaceRaised,
        onSurfaceVariant: palette.textMuted,
        outline: palette.border,
        outlineVariant: palette.border,
        error: palette.error,
        onError: palette.onPrimary,
        errorContainer: palette.errorSoft,
        onErrorContainer: palette.error,
      ),

      textTheme: TextTheme(
        displayLarge: text.display,
        displayMedium: text.display,
        displaySmall: text.title,
        headlineLarge: text.title,
        headlineMedium: text.title,
        headlineSmall: text.titleSmall,
        titleLarge: text.title,
        titleMedium: text.titleSmall,
        titleSmall: text.titleSmall,
        bodyLarge: text.body,
        bodyMedium: text.body,
        bodySmall: text.bodySmall,
        labelLarge: text.label,
        labelMedium: text.label,
        labelSmall: text.caption,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: palette.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleSmall.copyWith(color: palette.text),
        iconTheme: IconThemeData(color: palette.text),
        shape: Border(bottom: BorderSide(color: palette.border, width: 1)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          elevation: 0,
          minimumSize: const Size(48, 48),
          textStyle: text.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          elevation: 0,
          minimumSize: const Size(48, 48),
          textStyle: text.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.text,
          elevation: 0,
          minimumSize: const Size(48, 48),
          textStyle: text.label,
          side: BorderSide(color: palette.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: text.label,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.text,
          minimumSize: const Size(48, 48),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: palette.surfaceMuted,
        labelStyle: text.caption.copyWith(color: palette.text),
        side: BorderSide(color: palette.border, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: palette.border, width: 1),
        ),
        titleTextStyle: text.title.copyWith(color: palette.text),
        contentTextStyle: text.body.copyWith(color: palette.textMuted),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.surfaceRaised,
        contentTextStyle: text.bodySmall.copyWith(color: palette.text),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: palette.border, width: 1),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        minLeadingWidth: 0,
        minVerticalPadding: 12,
        iconColor: palette.textMuted,
        textColor: palette.text,
        titleTextStyle: text.body.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: text.bodySmall,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.primary,
        linearTrackColor: palette.border,
        circularTrackColor: palette.border,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.onPrimary;
          }
          return palette.textSubtle;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary;
          }
          return palette.surfaceMuted;
        }),
        trackOutlineColor: WidgetStateProperty.all(palette.border),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: text.bodySmall.copyWith(color: palette.textSubtle),
        labelStyle: text.bodySmall.copyWith(color: palette.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.error, width: 2),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: palette.border, width: 1),
        ),
        textStyle: text.caption.copyWith(color: palette.text),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(palette.textSubtle.withAlpha(80)),
        radius: const Radius.circular(8),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
