import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography system for Talib Ilm
///
/// **Design Principles:**
/// - Arabic content (Quran/Hadith): Amiri font, minimum 18sp
/// - UI text: Cairo font for consistency
/// - Heading scale: 24/20/18/16/14sp
/// - Line height: 1.5x minimum for readability
/// - No text smaller than 12sp for accessibility
///
/// **Font Families:**
/// - `Amiri`: Traditional Arabic serif font for religious content
/// - `Cairo`: Modern Arabic sans-serif for UI elements
class AppTextStyles {
  // ═══════════════════════════════════════════════════════════════════════════
  // FONT FAMILIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// UI font family - Cairo (modern Arabic sans-serif)
  static const String _uiFontFamily = 'Cairo';

  /// Content font family - Amiri (traditional Arabic serif)
  /// Used for Quran, Hadith, and other religious texts
  static const String _contentFontFamily = 'Amiri';

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADING STYLES - Scale: 24/20/18/16/14sp
  // ═══════════════════════════════════════════════════════════════════════════

  /// Heading 1 - 32sp (Page titles, major sections)
  static TextStyle get heading1 => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: -0.5,
  );

  /// Heading 2 - 24sp (Section headers)
  static TextStyle get heading2 => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: -0.3,
  );

  /// Heading 3 - 19sp (Card titles, subsection headers)
  static TextStyle get heading3 => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Heading 4 - 16sp (Minor headers, emphasized text)
  static TextStyle get heading4 => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Heading 5 - 14sp (Small headers, labels)
  static TextStyle get heading5 => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BODY TEXT STYLES - UI Content
  // ═══════════════════════════════════════════════════════════════════════════

  /// Body Large - 16sp (Primary body text, important content)
  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Body Medium - 14sp (Standard body text)
  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Caption - 13sp (Secondary text, captions)
  static TextStyle get bodySmall => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // ARABIC CONTENT STYLES - Amiri Font, Minimum 18sp
  // ═══════════════════════════════════════════════════════════════════════════

  /// Quran text - 24sp (Arabic, +2 from 22)
  static TextStyle get quranArabic => const TextStyle(
    fontFamily: _contentFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 2.0,
    letterSpacing: 0.3,
  );

  /// Hadith Arabic text - 22sp (Arabic, +2 from 20)
  static TextStyle get hadithArabic => const TextStyle(
    fontFamily: _contentFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 2.0,
    letterSpacing: 0.2,
  );

  /// Dhikr/Dua Arabic text - Large - 24sp (Emphasized prayers)
  static TextStyle get dhikrLarge => const TextStyle(
    fontFamily: _contentFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    height: 1.8,
    letterSpacing: 0.3,
  );

  /// Dhikr/Dua Arabic text - Medium - 20sp (Standard prayers)
  static TextStyle get dhikrMedium => const TextStyle(
    fontFamily: _contentFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.7,
    letterSpacing: 0.2,
  );

  /// Dhikr/Dua Arabic text - Small - 18sp (Compact prayers, minimum)
  static TextStyle get dhikrSmall => const TextStyle(
    fontFamily: _contentFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.7,
  );

  /// Book title Arabic - 18sp (Ilm content, minimum size)
  static TextStyle get bookTitleArabic => const TextStyle(
    fontFamily: _contentFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  /// Scholar name Arabic - 18sp (Author names, minimum size)
  static TextStyle get scholarNameArabic => const TextStyle(
    fontFamily: _contentFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSLATION & SECONDARY TEXT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hadith translation - 14sp
  static TextStyle get hadithTranslation => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  /// Hadith narrator/source - 12sp (minimum size)
  static TextStyle get hadithNarrator => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.accent,
    height: 1.5,
  );

  /// Quran translation - 14sp
  static TextStyle get quranTranslation => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
    fontStyle: FontStyle.italic,
  );

  /// Dhikr translation - 14sp
  static TextStyle get dhikrTranslation => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
    fontStyle: FontStyle.italic,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // UI COMPONENT STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  /// App bar title - 18sp
  static TextStyle get appBarTitle => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Card title - 19sp
  static TextStyle get cardTitle => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Card subtitle - 14sp
  static TextStyle get cardSubtitle => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  /// Button text - 16sp (increased for better tap targets)
  static TextStyle get button => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.5,
    letterSpacing: 0.5,
  );

  /// Button text small - 14sp
  static TextStyle get buttonSmall => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.5,
    letterSpacing: 0.3,
  );

  /// Label - 11sp (form labels, metadata, semi-bold)
  static TextStyle get label => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  /// Caption - 13sp (timestamps, helper text)
  static TextStyle get caption => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  /// Overline - 12sp (eyebrow text, categories)
  static TextStyle get overline => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.5,
    letterSpacing: 1.0,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // PRAYER TIME STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Prayer name - Large - 28sp (Current prayer display)
  static TextStyle get prayerNameLarge => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.5,
    letterSpacing: -0.5,
  );

  /// Prayer name - Medium - 20sp (Prayer list)
  static TextStyle get prayerNameMedium => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Prayer time - 18sp
  static TextStyle get prayerTime => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Prayer countdown - 16sp
  static TextStyle get prayerCountdown => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // NUMBER & STATISTIC STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Number - Extra Large - 48sp (Hero numbers, counters)
  static TextStyle get numberExtraLarge => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    height: 1.2,
    letterSpacing: -1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Number - Large - 36sp (Large counters)
  static TextStyle get numberLarge => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.2,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Number - Medium - 24sp (Standard counters)
  static TextStyle get numberMedium => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Number - Small - 18sp (Compact counters)
  static TextStyle get numberSmall => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Stat number - 20sp (Statistics display)
  static TextStyle get statNumber => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Stat label - 12sp (Statistics labels, minimum size)
  static TextStyle get statLabel => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BADGE & CHIP STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Badge text - 12sp (notification badges, status indicators)
  static TextStyle get badge => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    height: 1.5,
    letterSpacing: 0.3,
  );

  /// Chip text - 14sp (filter chips, tags)
  static TextStyle get chip => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SPECIAL PURPOSE STYLES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Link text - 14sp
  static TextStyle get link => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    height: 1.5,
    decoration: TextDecoration.underline,
  );

  /// Error text - 12sp
  static TextStyle get error => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
    height: 1.5,
  );

  /// Success text - 12sp
  static TextStyle get success => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
    height: 1.5,
  );

  /// Placeholder text - 14sp
  static TextStyle get placeholder => const TextStyle(
    fontFamily: _uiFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textDisabled,
    height: 1.5,
    fontStyle: FontStyle.italic,
  );
}
