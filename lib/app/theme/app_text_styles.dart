import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  static const String _uiFontFamily = 'Cairo';
  static const String _contentFontFamily = 'Amiri';

  static TextStyle get appBarTitle => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get heading1 => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get heading2 => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get heading3 => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.6,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get cardTitle => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get cardSubtitle => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get label => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.3,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.3,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get button => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.2,
      );

  static TextStyle get hadithArabic => const TextStyle(
        fontFamily: _contentFontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.9,
      );

  static TextStyle get hadithTranslation => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.6,
      );

  static TextStyle get hadithNarrator => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.accent,
        fontStyle: FontStyle.italic,
        height: 1.4,
      );

  static TextStyle get dhikrLarge => const TextStyle(
        fontFamily: _contentFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: AppColors.primary,
        height: 1.8,
      );

  static TextStyle get dhikrMedium => const TextStyle(
        fontFamily: _contentFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.7,
      );

  static TextStyle get prayerNameLarge => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        height: 1.2,
      );

  static TextStyle get prayerNameMedium => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get numberLarge => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 42,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        height: 1.0,
        letterSpacing: 0.5,
      );

  static TextStyle get numberMedium => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.0,
      );

  static TextStyle get numberSmall => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.0,
      );

  static TextStyle get statNumber => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  static TextStyle get statLabel => const TextStyle(
        fontFamily: _uiFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.3,
      );
}
