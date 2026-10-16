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
            label: 'زمردي',
          );
        case ShamelaAccentColor.ruby:
          return const ReaderAccentTokens(
            primary: Color(0xFFFB7185),
            soft: Color(0xFF4C0519),
            onSoft: Color(0xFFFECDD3),
            border: Color(0xFF881337),
            label: 'عنابي',
          );
        case ShamelaAccentColor.navy:
          return const ReaderAccentTokens(
            primary: Color(0xFF93C5FD),
            soft: Color(0xFF1E293B),
            onSoft: Color(0xFFBFDBFE),
            border: Color(0xFF1E3A8A),
            label: 'كحلي',
          );
        case ShamelaAccentColor.amber:
          return const ReaderAccentTokens(
            primary: Color(0xFFFB923C),
            soft: Color(0xFF431407),
            onSoft: Color(0xFFFED7AA),
            border: Color(0xFF7C2D12),
            label: 'عنبري',
          );
        case ShamelaAccentColor.bronze:
          return const ReaderAccentTokens(
            primary: Color(0xFFFBBF24),
            soft: Color(0xFF451A03),
            onSoft: Color(0xFFFDE68A),
            border: Color(0xFF78350F),
            label: 'برونزي',
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
            label: 'زمردي',
          );
        case ShamelaAccentColor.ruby:
          return const ReaderAccentTokens(
            primary: Color(0xFF881337),
            soft: Color(0xFFFFE4E6),
            onSoft: Color(0xFF881337),
            border: Color(0xFFFDA4AF),
            label: 'عنابي',
          );
        case ShamelaAccentColor.navy:
          return const ReaderAccentTokens(
            primary: Color(0xFF1E3A8A),
            soft: Color(0xFFEFF6FF),
            onSoft: Color(0xFF1E3A8A),
            border: Color(0xFFBFDBFE),
            label: 'كحلي',
          );
        case ShamelaAccentColor.amber:
          return const ReaderAccentTokens(
            primary: Color(0xFF9A3412),
            soft: Color(0xFFFFEDD5),
            onSoft: Color(0xFF9A3412),
            border: Color(0xFFFED7AA),
            label: 'عنبري',
          );
        case ShamelaAccentColor.bronze:
          return const ReaderAccentTokens(
            primary: Color(0xFF78350F),
            soft: Color(0xFFFEF3C7),
            onSoft: Color(0xFF78350F),
            border: Color(0xFFFDE68A),
            label: 'برونزي',
          );
      }
    }
  }
}
