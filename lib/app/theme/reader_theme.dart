import 'package:flutter/material.dart';

/// Reading highlight accent palette for classical books and scholarly mutun.
enum ShamelaAccentColor {
  emerald, // أخضر زمردي وقور (Classic Islamic Green)
  ruby, // عنابي ملكي أصيل (Manuscript Crimson)
  navy, // كحلي أندلسي هادئ (Deep Andalusian Blue)
  amber, // عنبري دافئ مريح (Warm Terracotta)
  bronze, // برونزي كلاسيكي (Scholarly Bronze)
}

/// Resolved semantic color tokens for the selected reading accent.
class ReaderAccentTokens {
  final Color primary;
  final Color soft;
  final Color onSoft;
  final Color border;
  final String label;

  const ReaderAccentTokens({
    required this.primary,
    required this.soft,
    required this.onSoft,
    required this.border,
    required this.label,
  });
}

/// Reading surface environment presets for classical books and scholarly mutun.
enum ShamelaReaderSurface {
  normal, // الافتراضي (حسب سمة التطبيق)
  parchment, // ورق الشاموا البيج المريح للعين
  night, // داكن هادئ للقراءة الليلية
}

/// Resolved semantic color tokens for reading surface environment.
class ReaderSurfaceTokens {
  final Color bg;
  final Color surfaceRaised;
  final Color text;
  final Color textMuted;
  final Color hadithGreen;
  final Color citationBlue;
  final Color border;
  final String label;

  const ReaderSurfaceTokens({
    required this.bg,
    Color? surfaceRaised,
    required this.text,
    required this.textMuted,
    required this.hadithGreen,
    required this.citationBlue,
    required this.border,
    required this.label,
  }) : surfaceRaised = surfaceRaised ?? bg;
}

/// Extension for resolving effective dark mode on reading surfaces.
extension ShamelaReaderSurfaceX on ShamelaReaderSurface {
  bool isEffectiveDark(bool isAppDark) {
    return this == ShamelaReaderSurface.night ||
        (this == ShamelaReaderSurface.normal && isAppDark);
  }
}

/// Unified source of truth for reading surface tokens.
class ReaderSurfaceColors {
  const ReaderSurfaceColors._();

  static ReaderSurfaceTokens getTokens(
    ShamelaReaderSurface surface, {
    required bool isDark,
  }) {
    switch (surface) {
      case ShamelaReaderSurface.normal:
        return ReaderSurfaceTokens(
          bg: isDark ? const Color(0xFF161817) : const Color(0xFFFAF9F5),
          surfaceRaised: isDark ? const Color(0xFF1E2120) : const Color(0xFFF2EFE9),
          text: isDark ? const Color(0xFFF1F5F3) : const Color(0xFF1E2120),
          textMuted: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
          hadithGreen: isDark ? const Color(0xFF4ADE80) : const Color(0xFF1B6B3F),
          citationBlue: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
          border: isDark ? const Color(0xFF2C302E) : const Color(0xFFE2DFD6),
          label: 'الافتراضي',
        );
      case ShamelaReaderSurface.parchment:
        return const ReaderSurfaceTokens(
          bg: Color(0xFFFBF7EE), // Classic authentic Shamwa parchment beige
          surfaceRaised: Color(0xFFF3ECE0),
          text: Color(0xFF2B2520), // High-contrast classical dark sepia book ink
          textMuted: Color(0xFF786C5E),
          hadithGreen: Color(0xFF1E5E3A),
          citationBlue: Color(0xFF1E3A8A),
          border: Color(0xFFDFD4C4),
          label: 'ورق الشاموا (بيج)',
        );
      case ShamelaReaderSurface.night:
        return const ReaderSurfaceTokens(
          bg: Color(0xFF101114), // Deep soothing night surface
          surfaceRaised: Color(0xFF181A1F),
          text: Color(0xFFEAE5DC), // High-contrast soft cream night text
          textMuted: Color(0xFF94A3B8),
          hadithGreen: Color(0xFF4ADE80),
          citationBlue: Color(0xFF93C5FD),
          border: Color(0xFF2C3038),
          label: 'داكن هادئ',
        );
    }
  }
}

/// Unified source of truth for reader accent tokens across light and dark modes.
class ReaderAccentColors {
  const ReaderAccentColors._();

  static ReaderAccentTokens getTokens(
    ShamelaAccentColor accent, {
    required bool isDark,
  }) {
    if (isDark) {
      switch (accent) {
        case ShamelaAccentColor.emerald:
          return const ReaderAccentTokens(
            primary: Color(0xFF34D399),
            soft: Color(0xFF064E3B),
            onSoft: Color(0xFFA7F3D0),
            border: Color(0xFF065F46),
            label: 'أخضر',
          );
        case ShamelaAccentColor.ruby:
          return const ReaderAccentTokens(
            primary: Color(0xFFFB7185),
            soft: Color(0xFF4C0519),
            onSoft: Color(0xFFFECDD3),
            border: Color(0xFF881337),
            label: 'أحمر',
          );
        case ShamelaAccentColor.navy:
          return const ReaderAccentTokens(
            primary: Color(0xFF93C5FD),
            soft: Color(0xFF1E293B),
            onSoft: Color(0xFFBFDBFE),
            border: Color(0xFF1E3A8A),
            label: 'أزرق',
          );
        case ShamelaAccentColor.amber:
          return const ReaderAccentTokens(
            primary: Color(0xFFFB923C),
            soft: Color(0xFF431407),
            onSoft: Color(0xFFFED7AA),
            border: Color(0xFF7C2D12),
            label: 'برتقالي',
          );
        case ShamelaAccentColor.bronze:
          return const ReaderAccentTokens(
            primary: Color(0xFFFBBF24),
            soft: Color(0xFF451A03),
            onSoft: Color(0xFFFDE68A),
            border: Color(0xFF78350F),
            label: 'ذهبي',
          );
      }
    } else {
      switch (accent) {
        case ShamelaAccentColor.emerald:
          return const ReaderAccentTokens(
            primary: Color(0xFF0D5D3B),
            soft: Color(0xFFE6F4EA),
            onSoft: Color(0xFF0D5D3B),
            border: Color(0xFFA3D9B8),
            label: 'أخضر',
          );
        case ShamelaAccentColor.ruby:
          return const ReaderAccentTokens(
            primary: Color(0xFF881337),
            soft: Color(0xFFFFE4E6),
            onSoft: Color(0xFF881337),
            border: Color(0xFFFDA4AF),
            label: 'أحمر',
          );
        case ShamelaAccentColor.navy:
          return const ReaderAccentTokens(
            primary: Color(0xFF1E3A8A),
            soft: Color(0xFFEFF6FF),
            onSoft: Color(0xFF1E3A8A),
            border: Color(0xFFBFDBFE),
            label: 'أزرق',
          );
        case ShamelaAccentColor.amber:
          return const ReaderAccentTokens(
            primary: Color(0xFF9A3412),
            soft: Color(0xFFFFEDD5),
            onSoft: Color(0xFF9A3412),
            border: Color(0xFFFED7AA),
            label: 'برتقالي',
          );
        case ShamelaAccentColor.bronze:
          return const ReaderAccentTokens(
            primary: Color(0xFF78350F),
            soft: Color(0xFFFEF3C7),
            onSoft: Color(0xFF78350F),
            border: Color(0xFFFDE68A),
            label: 'ذهبي',
          );
      }
    }
  }
}
