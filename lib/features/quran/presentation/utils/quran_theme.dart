import 'package:flutter/material.dart';

/// Centralized Quran typography and theme constants
///
/// Usage:
/// - QuranTheme.lightBackground
/// - QuranTypography.quranFontSize(context)
/// - QuranColors.accent(isDark)

// ══════════════════════════════════════════════════════════════════════════════
// COLORS
// ══════════════════════════════════════════════════════════════════════════════

class QuranColors {
  QuranColors._();

  // Light mode
  static const lightBackground = Color(0xFFFFF8F0); // Warm paper
  static const lightSurface = Color(0xFFF7F3E8);
  static const lightText = Color(0xFF2D2D2D);
  static const lightSubtle = Color(0xFF6B6B6B);
  static const lightAccent = Color(0xFFD4A853); // Gold

  // Dark mode
  static const darkBackground = Color(
    0xFF0F0F0F,
  ); // Deep charcoal (not pure black)
  static const darkSurface = Color(0xFF1A1A1A);
  static const darkText = Color(0xFFE8E8E8);
  static const darkSubtle = Color(0xFF8A8A8A);
  static const darkAccent = Color(0xFF00D9C0); // Teal

  // Semantic
  static Color background(bool isDark) =>
      isDark ? darkBackground : lightBackground;
  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color text(bool isDark) => isDark ? darkText : lightText;
  static Color subtle(bool isDark) => isDark ? darkSubtle : lightSubtle;
  static Color accent(bool isDark) => isDark ? darkAccent : lightAccent;

  // Borders
  static Color border(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.08);

  // Verse marker
  static Color verseMarker(bool isDark) => accent(isDark);
}

// ══════════════════════════════════════════════════════════════════════════════
// TYPOGRAPHY
// ══════════════════════════════════════════════════════════════════════════════

class QuranTypography {
  QuranTypography._();

  // Font families
  static const String quranFont = 'Amiri'; // Uthmanic-style
  static const String uiFont = 'Cairo'; // UI text

  // Default sizes
  static const double quranFontSize = 22.0;
  static const double quranLineHeight = 2.2;
  static const double uiFontSize = 14.0;
  static const double uiLineHeight = 1.5;

  // Quran text style
  static TextStyle quranText({
    required bool isDark,
    double fontSize = quranFontSize,
    double height = quranLineHeight,
  }) {
    return TextStyle(
      fontFamily: quranFont,
      fontSize: fontSize,
      height: height,
      color: QuranColors.text(isDark),
      letterSpacing: 0,
      wordSpacing: 2,
    );
  }

  // Bismillah style
  static TextStyle bismillah({required bool isDark, double fontSize = 24}) {
    return TextStyle(
      fontFamily: quranFont,
      fontSize: fontSize,
      height: 1.8,
      color: QuranColors.text(isDark),
      fontWeight: FontWeight.w500,
    );
  }

  // Surah header style
  static TextStyle surahHeader({required bool isDark}) {
    return TextStyle(
      fontFamily: quranFont,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : const Color(0xFF5A4A28),
    );
  }

  // UI text styles
  static TextStyle uiTitle({required bool isDark}) {
    return TextStyle(
      fontFamily: uiFont,
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: QuranColors.text(isDark),
    );
  }

  static TextStyle uiBody({required bool isDark}) {
    return TextStyle(
      fontFamily: uiFont,
      fontSize: 14,
      color: QuranColors.text(isDark),
      height: uiLineHeight,
    );
  }

  static TextStyle uiSubtle({required bool isDark}) {
    return TextStyle(
      fontFamily: uiFont,
      fontSize: 12,
      color: QuranColors.subtle(isDark),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// THEME DATA
// ══════════════════════════════════════════════════════════════════════════════

class QuranTheme {
  QuranTheme._();

  /// Light Quran theme
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: QuranColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: QuranColors.lightAccent,
        surface: QuranColors.lightSurface,
      ),
      fontFamily: QuranTypography.uiFont,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: QuranColors.lightText),
        titleTextStyle: TextStyle(
          fontFamily: QuranTypography.uiFont,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: QuranColors.lightText,
        ),
      ),
    );
  }

  /// Dark Quran theme
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: QuranColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: QuranColors.darkAccent,
        surface: QuranColors.darkSurface,
      ),
      fontFamily: QuranTypography.uiFont,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: QuranColors.darkText),
        titleTextStyle: TextStyle(
          fontFamily: QuranTypography.uiFont,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: QuranColors.darkText,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DECORATIONS
// ══════════════════════════════════════════════════════════════════════════════

class QuranDecorations {
  QuranDecorations._();

  /// Page container decoration
  static BoxDecoration pageContainer({required bool isDark}) {
    return BoxDecoration(
      color: QuranColors.surface(isDark),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: QuranColors.border(isDark), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Surah header decoration
  static BoxDecoration surahHeader({required bool isDark}) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [const Color(0xFF1A1A1A), const Color(0xFF252525)]
            : [
                QuranColors.lightAccent.withValues(alpha: 0.15),
                QuranColors.lightAccent.withValues(alpha: 0.05),
              ],
      ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isDark
            ? Colors.white12
            : QuranColors.lightAccent.withValues(alpha: 0.4),
      ),
    );
  }

  /// Card decoration
  static BoxDecoration card({required bool isDark}) {
    return BoxDecoration(
      color: QuranColors.surface(isDark),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: QuranColors.border(isDark)),
    );
  }
}
