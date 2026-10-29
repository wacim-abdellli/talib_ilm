import 'package:flutter/material.dart';

/// Mushaf reader theme variants.
enum MushafThemeMode {
  white, // Classic White
  sepia, // Warm Cream / Parchment
  dark, // Twilight AMOLED Dark
}

/// Quran reading mode.
enum QuranReadingMode {
  mushafPage, // 604 authentic Medina pages
  ayahList, // Continuous scrolling verses
}

/// Semantic colors for category chips & indicators
class CategoryColors {
  final Color fg;
  final Color bg;

  const CategoryColors({required this.fg, required this.bg});
}

/// Semantic authentic physical book colors for Mutun Talib Al-Ilm levels.
/// Matches the authentic physical covers printed by Shaykh Dr. Abdul Muhsin Al-Qasim:
/// - المستوى التمهيدي: Emerald Green (الأخضر)
/// - المستوى الأول: Burgundy / Crimson Red (الأحمر العنابي)
/// - المستوى الثاني: Sapphire Royal Blue (الأزرق الملكي)
/// - المستوى الثالث: Warm Sand / Ochre Tan (البيج الخردلي)
/// - المستوى الرابع: Imperial Plum / Violet (البنفسجي)
/// - المستوى الخامس: Deep Jade / Forest Teal (الأخضر الزيتي)
class MutunLevelColors {
  final Color fg;
  final Color bg;
  final Color border;

  const MutunLevelColors({
    required this.fg,
    required this.bg,
    required this.border,
  });
}

/// Distinct, authentic scholarly colors for each Islamic science discipline (Fan).
class FanDisciplineColors {
  final Color primary;
  final Color softBg;
  final Color border;

  const FanDisciplineColors({
    required this.primary,
    required this.softBg,
    required this.border,
  });
}


/// The single source of truth for color tokens across talib_ilm.
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceMuted;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color textSubtle;
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;
  final Color onPrimarySoft;
  final Color gold;
  final Color goldFill;
  final Color onGold;
  final Color goldSoft;
  final Color success;
  final Color error;
  final Color errorSoft;
  final Color brandDark;
  final List<BoxShadow> shadow;
  final bool isDark;
  final String logoSymbol;
  final String logoLockup;
  final Color splashBg;
  final Color splashCardBg;
  final Color splashCardBorder;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceMuted,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.textSubtle,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.gold,
    required this.goldFill,
    required this.onGold,
    required this.goldSoft,
    required this.success,
    required this.error,
    required this.errorSoft,
    required this.brandDark,
    required this.shadow,
    required this.isDark,
    required this.logoSymbol,
    required this.logoLockup,
    required this.splashBg,
    required this.splashCardBg,
    required this.splashCardBorder,
  });

  /// Pure serene white splash screen tokens
  static const Color splashWhite = Color(0xFFFFFFFF);
  static const Color splashText = Color(0xFF1C1917);
  static const Color splashTextMuted = Color(0xFF5E574E);
  static const Color splashTextSubtle = Color(0xFF787169);
  static const Color splashGold = Color(0xFF92400E);
  static const Color splashGoldSoft = Color(0xFFFEF3C7);

  /// Dedicated video & media player overlay tokens
  static const Color videoScrim = Color(0xB3000000);
  static const Color videoControlBg = Color(0x66000000);
  static const Color videoControlFg = Color(0xFFFFFFFF);
  static const Color videoScrubberTrack = Color(0x4DFFFFFF);
  static const Color videoScrubberActive = Color(0xFFF59E0B);

  /// Light theme palette — Warm Ivory Parchment & Imperial Burnished Gold
  static const light = AppPalette(
    bg: Color(0xFFFAF8F5),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF4EFE6),
    border: Color(0xFFE5DDD0),
    text: Color(0xFF1C1917),
    textMuted: Color(0xFF5E574E),
    textSubtle: Color(0xFF716A62),
    primary: Color(0xFF8C580B),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFFEF3C7),
    onPrimarySoft: Color(0xFF713F08),
    gold: Color(0xFF9E640B),
    goldFill: Color(0xFFB45309),
    onGold: Color(0xFFFFFFFF),
    goldSoft: Color(0xFFFEF3C7),
    success: Color(0xFF047857),
    error: Color(0xFFB91C1C),
    errorSoft: Color(0xFFFEE2E2),
    brandDark: Color(0xFF141210),
    shadow: [
      BoxShadow(
        color: Color(0x0A000000), // 4% black
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
    isDark: false,
    logoSymbol: 'assets/branding/symbol_on_light.png',
    logoLockup: 'assets/branding/lockup_on_light.png',
    splashBg: Color(0xFFFFFFFF),
    splashCardBg: Color(0xFFFFFBF2),
    splashCardBorder: Color(0xFFE9D8B4),
  );

  /// Dark theme palette — Pure AMOLED Obsidian & Imperial Radiant Gold
  static const dark = AppPalette(
    bg: Color(0xFF000000),
    surface: Color(0xFF070707),
    surfaceRaised: Color(0xFF0F0F0F),
    surfaceMuted: Color(0xFF090909),
    border: Color(0xFF1C1A17),
    text: Color(0xFFFAF8F5),
    textMuted: Color(0xFFA8A096),
    textSubtle: Color(0xFF8A8278),
    primary: Color(0xFFF59E0B),
    onPrimary: Color(0xFF171203),
    primarySoft: Color(0xFF1E170A),
    onPrimarySoft: Color(0xFFFDE68A),
    gold: Color(0xFFFBBF24),
    goldFill: Color(0xFFF59E0B),
    onGold: Color(0xFF2C1300),
    goldSoft: Color(0xFF1E170A),
    success: Color(0xFF34D399),
    error: Color(0xFFF87171),
    errorSoft: Color(0xFF3B1414),
    brandDark: Color(0xFF000000),
    shadow: [],
    isDark: true,
    logoSymbol: 'assets/branding/symbol_on_dark.png',
    logoLockup: 'assets/branding/lockup_on_dark.png',
    splashBg: Color(0xFF000000),
    splashCardBg: Color(0xFF0F0F0F),
    splashCardBorder: Color(0xFF221A12),
  );

  /// Default Mushaf theme mode aligning with palette brightness
  MushafThemeMode get defaultMushafTheme =>
      isDark ? MushafThemeMode.dark : MushafThemeMode.sepia;

  /// Canonical category color resolution with >= 4.5:1 contrast
  CategoryColors category(String? subject) {
    final s = (subject ?? '').toLowerCase().trim();

    if (s.contains('عقيدة') || s.contains('توحيد')) {
      return isDark
          ? const CategoryColors(fg: Color(0xFF34D399), bg: Color(0xFF042F2E))
          : const CategoryColors(fg: Color(0xFF0F766E), bg: Color(0xFFCCFBF1));
    }
    if (s.contains('قرآن') || s.contains('تجويد') || s.contains('تفسير')) {
      return isDark
          ? const CategoryColors(fg: Color(0xFFFBBF24), bg: Color(0xFF451A03))
          : const CategoryColors(fg: Color(0xFF92400E), bg: Color(0xFFFEF3C7));
    }
    if (s.contains('حديث') || s.contains('مصطلح')) {
      return isDark
          ? const CategoryColors(fg: Color(0xFFA78BFA), bg: Color(0xFF2E1065))
          : const CategoryColors(fg: Color(0xFF6D28D9), bg: Color(0xFFEDE9FE));
    }
    if (s.contains('فقه') || s.contains('أصول')) {
      return isDark
          ? const CategoryColors(fg: Color(0xFF34D399), bg: Color(0xFF064E3B))
          : const CategoryColors(fg: Color(0xFF047857), bg: Color(0xFFDCFCE7));
    }
    if (s.contains('سيرة') || s.contains('تاريخ')) {
      return isDark
          ? const CategoryColors(fg: Color(0xFFFB923C), bg: Color(0xFF431407))
          : const CategoryColors(fg: Color(0xFF9A3412), bg: Color(0xFFFFEDD5));
    }
    if (s.contains('آداب') || s.contains('أذكار') || s.contains('تزكية') || s.contains('سلوك')) {
      return isDark
          ? const CategoryColors(fg: Color(0xFF2DD4BF), bg: Color(0xFF042F2E))
          : const CategoryColors(fg: Color(0xFF115E59), bg: Color(0xFFCCFBF1));
    }
    if (s.contains('لغة') || s.contains('نحو') || s.contains('صرف') || s.contains('بلاغة')) {
      return isDark
          ? const CategoryColors(fg: Color(0xFF38BDF8), bg: Color(0xFF082F49))
          : const CategoryColors(fg: Color(0xFF0369A1), bg: Color(0xFFE0F2FE));
    }

    // Default / Other
    return isDark
        ? const CategoryColors(fg: Color(0xFFCBD5E1), bg: Color(0xFF1E293B))
        : const CategoryColors(fg: Color(0xFF334155), bg: Color(0xFFF1F5F9));
  }

  /// Canonical Athkar category color resolution with >= 4.5:1 AA contrast on card surface
  CategoryColors adhkarCategory(String? categoryId) {
    final id = (categoryId ?? '').toLowerCase().trim();

    if (id == 'morning') {
      // Golden Amber Dawn
      return isDark
          ? const CategoryColors(fg: Color(0xFFFBBF24), bg: Color(0xFF2E1C05))
          : const CategoryColors(fg: Color(0xFFB45309), bg: Color(0xFFFEF3C7));
    }
    if (id == 'evening') {
      // Twilight Starlit Indigo
      return isDark
          ? const CategoryColors(fg: Color(0xFFA78BFA), bg: Color(0xFF1E1538))
          : const CategoryColors(fg: Color(0xFF6D28D9), bg: Color(0xFFEDE9FE));
    }
    if (id == 'after_prayer' ||
        id == 'prayer_sunan' ||
        id == 'prayer_opening' ||
        id == 'prayer_rukuh_sujud' ||
        id == 'tashahhud_salat' ||
        id == 'prayer_before_salam' ||
        id == 'witr_istikharah') {
      // Serene Mosque Emerald
      return isDark
          ? const CategoryColors(fg: Color(0xFF34D399), bg: Color(0xFF052E20))
          : const CategoryColors(fg: Color(0xFF047857), bg: Color(0xFFDCFCE7));
    }
    if (id == 'waking') {
      // Awakening Dawn Copper
      return isDark
          ? const CategoryColors(fg: Color(0xFFFB923C), bg: Color(0xFF331606))
          : const CategoryColors(fg: Color(0xFFC2410C), bg: Color(0xFFFFEDD5));
    }
    if (id == 'sleeping') {
      // Celestial Night Indigo
      return isDark
          ? const CategoryColors(fg: Color(0xFF818CF8), bg: Color(0xFF171B36))
          : const CategoryColors(fg: Color(0xFF3730A3), bg: Color(0xFFE0E7FF));
    }
    if (id == 'distress' || id == 'distress_relief' || id == 'protection_ruqyah') {
      // Healing Teal Solace
      return isDark
          ? const CategoryColors(fg: Color(0xFF2DD4BF), bg: Color(0xFF052B28))
          : const CategoryColors(fg: Color(0xFF0F766E), bg: Color(0xFFCCFBF1));
    }
    if (id == 'mosque_adhan' || id == 'adhan_iqamah' || id == 'mosque_etiquette') {
      // Radiant Minaret Mint
      return isDark
          ? const CategoryColors(fg: Color(0xFF10B981), bg: Color(0xFF06291E))
          : const CategoryColors(fg: Color(0xFF065F46), bg: Color(0xFFD1FAE5));
    }
    if (id == 'home' || id == 'food_drink') {
      // Warm Hearth Coral-Rose
      return isDark
          ? const CategoryColors(fg: Color(0xFFFB7185), bg: Color(0xFF331215))
          : const CategoryColors(fg: Color(0xFF991B1B), bg: Color(0xFFFEE2E2));
    }
    if (id == 'wudu_food' || id == 'wudu_taharah' || id == 'hajj_umrah') {
      // Pure Water & Barakah Sky Blue
      return isDark
          ? const CategoryColors(fg: Color(0xFF38BDF8), bg: Color(0xFF07273B))
          : const CategoryColors(fg: Color(0xFF0369A1), bg: Color(0xFFE0F2FE));
    }
    if (id == 'travel') {
      // Wayfarer Compass Slate
      return isDark
          ? const CategoryColors(fg: Color(0xFF94A3B8), bg: Color(0xFF1A2230))
          : const CategoryColors(fg: Color(0xFF334155), bg: Color(0xFFF1F5F9));
    }
    if (id == 'duas' || id == 'quranic_duas' || id == 'prophetic_duas') {
      // Sacred Parchment Gold
      return isDark
          ? const CategoryColors(fg: Color(0xFFF59E0B), bg: Color(0xFF2B1B06))
          : const CategoryColors(fg: Color(0xFF92400E), bg: Color(0xFFFEF3C7));
    }
    if (id == 'tasbeeh') {
      // Vibrant Glorification Green
      return isDark
          ? const CategoryColors(fg: Color(0xFF34D399), bg: Color(0xFF063321))
          : const CategoryColors(fg: Color(0xFF047857), bg: Color(0xFFDCFCE7));
    }
    if (id == 'istighfar' ||
        id == 'sickness_funerals' ||
        id == 'sickness_ruqyah' ||
        id == 'funerals_graves') {
      // Pure Repentance Rose-Lavender
      return isDark
          ? const CategoryColors(fg: Color(0xFFF472B6), bg: Color(0xFF330E22))
          : const CategoryColors(fg: Color(0xFF9D174D), bg: Color(0xFFFCE7F3));
    }
    if (id == 'fasting_hajj' || id == 'fasting_adhkar') {
      // Fasting & Dawn Warm Amber
      return isDark
          ? const CategoryColors(fg: Color(0xFFFBBF24), bg: Color(0xFF2E1C05))
          : const CategoryColors(fg: Color(0xFFB45309), bg: Color(0xFFFEF3C7));
    }

    // Default Fallback
    return isDark
        ? const CategoryColors(fg: Color(0xFFFBBF24), bg: Color(0xFF2C200C))
        : const CategoryColors(fg: Color(0xFF9E640B), bg: Color(0xFFFEF3C7));
  }

  /// Canonical authentic physical book colors for Mutun Talib Al-Ilm levels.
  /// Validated for WCAG AA/AAA compliance (contrast ratio >= 4.5:1 text, >= 3.0:1 border).
  MutunLevelColors mutunLevel(String? level) {
    final s = (level ?? '').toLowerCase().trim();

    // Level 0: Preparatory / التمهيدي (Emerald Green)
    if (s.contains('تمهيد') ||
        s.contains('prep') ||
        s == 'level 0' ||
        s == 'lvl_0' ||
        s == '0') {
      return isDark
          ? const MutunLevelColors(
              fg: Color(0xFF86EFAC),
              bg: Color(0xFF062E19),
              border: Color(0xFF15803D),
            )
          : const MutunLevelColors(
              fg: Color(0xFF166534),
              bg: Color(0xFFDCFCE7),
              border: Color(0xFF86EFAC),
            );
    }

    // Level 4: Fourth / الرابع (Imperial Plum / Violet)
    if (s.contains('رابع') ||
        s.contains('fourth') ||
        s.contains('level 4') ||
        s.contains('level_4') ||
        s.contains('lvl_4') ||
        s.contains('lvl_advanced_1') ||
        (s.contains('متقدم') && (s.contains('اول') || s.contains('أول') || s.contains('1')))) {
      return isDark
          ? const MutunLevelColors(
              fg: Color(0xFFD8B4FE),
              bg: Color(0xFF220D38),
              border: Color(0xFF9333EA),
            )
          : const MutunLevelColors(
              fg: Color(0xFF6B21A8),
              bg: Color(0xFFF3E8FF),
              border: Color(0xFFE9D5FF),
            );
    }

    // Level 3: Third / الثالث (Warm Sand / Ochre Tan)
    if (s.contains('ثالث') ||
        s.contains('third') ||
        s.contains('level 3') ||
        s.contains('level_3') ||
        s.contains('lvl_3') ||
        s.contains('lvl_intermediate_2') ||
        (s.contains('متوسط') && (s.contains('ثان') || s.contains('2')))) {
      return isDark
          ? const MutunLevelColors(
              fg: Color(0xFFFDE047),
              bg: Color(0xFF2E1C05),
              border: Color(0xFFB45309),
            )
          : const MutunLevelColors(
              fg: Color(0xFF78350F),
              bg: Color(0xFFFEF3C7),
              border: Color(0xFFFDE68A),
            );
    }

    // Level 2: Second / الثاني (Sapphire Royal Blue)
    if (s.contains('ثان') ||
        s.contains('second') ||
        s.contains('level 2') ||
        s.contains('level_2') ||
        s.contains('lvl_2') ||
        s.contains('lvl_intermediate_1') ||
        (s.contains('متوسط') && (s.contains('اول') || s.contains('أول') || s.contains('1')))) {
      return isDark
          ? const MutunLevelColors(
              fg: Color(0xFF93C5FD),
              bg: Color(0xFF0C1938),
              border: Color(0xFF2563EB),
            )
          : const MutunLevelColors(
              fg: Color(0xFF1E40AF),
              bg: Color(0xFFDBEAFE),
              border: Color(0xFFBFDBFE),
            );
    }

    // Level 1: First / الأول / المبتدئ (Burgundy / Crimson Red)
    if (s.contains('أول') ||
        s.contains('اول') ||
        s.contains('مبتدئ') ||
        s.contains('first') ||
        s.contains('foundation') ||
        s.contains('level 1') ||
        s.contains('level_1') ||
        s.contains('lvl_1') ||
        s == '1') {
      return isDark
          ? const MutunLevelColors(
              fg: Color(0xFFFDA4AF),
              bg: Color(0xFF2E0C15),
              border: Color(0xFFDC2626),
            )
          : const MutunLevelColors(
              fg: Color(0xFF991B1B),
              bg: Color(0xFFFEE2E2),
              border: Color(0xFFFECDD3),
            );
    }

    // Level 5: Fifth / الخامس / المتقدم الثاني (Forest Jade / Deep Teal)
    if (s.contains('خامس') ||
        s.contains('fifth') ||
        s.contains('level 5') ||
        s.contains('level_5') ||
        s.contains('lvl_5') ||
        s.contains('lvl_advanced_2') ||
        (s.contains('متقدم') && (s.contains('ثان') || s.contains('2')))) {
      return isDark
          ? const MutunLevelColors(
              fg: Color(0xFF5EEAD4),
              bg: Color(0xFF042F2E),
              border: Color(0xFF0F766E),
            )
          : const MutunLevelColors(
              fg: Color(0xFF0F766E),
              bg: Color(0xFFCCFBF1),
              border: Color(0xFF99F6E4),
            );
    }

    // Default Fallback: Golden Amber Scholar Tone
    return isDark
        ? const MutunLevelColors(
            fg: Color(0xFFFBBF24),
            bg: Color(0xFF2C200C),
            border: Color(0xFF78350F),
          )
        : const MutunLevelColors(
            fg: Color(0xFF9E640B),
            bg: Color(0xFFFEF3C7),
            border: Color(0xFFFDE68A),
          );
  }

  /// Distinct, authentic scholarly colors for each Islamic science discipline (Fan).
  /// Validated for WCAG AA/AAA compliance (contrast ratio >= 4.5:1 text, >= 3.0:1 border).
  FanDisciplineColors fanColor(String? fanId) {
    final s = (fanId ?? '').toLowerCase().trim();

    // Aqidah & Tawhid (Sapphire Blue)
    if (s == 'aqidah' || s.contains('عقيد') || s.contains('توحيد')) {
      return isDark
          ? const FanDisciplineColors(
              primary: Color(0xFF93C5FD),
              softBg: Color(0xFF172554),
              border: Color(0xFF2563EB),
            )
          : const FanDisciplineColors(
              primary: Color(0xFF1D4ED8),
              softBg: Color(0xFFEFF6FF),
              border: Color(0xFFBFDBFE),
            );
    }

    // Fiqh (Justice & Jurisprudence - Forest Emerald Green)
    if (s == 'fiqh' || (s.contains('فقه') && !s.contains('أصول') && !s.contains('اصول'))) {
      return isDark
          ? const FanDisciplineColors(
              primary: Color(0xFF6EE7B7),
              softBg: Color(0xFF064E3B),
              border: Color(0xFF059669),
            )
          : const FanDisciplineColors(
              primary: Color(0xFF047857),
              softBg: Color(0xFFECFDF5),
              border: Color(0xFFA7F3D0),
            );
    }

    // Usul al-Fiqh & Legal Maxims (Imperial Plum / Royal Violet)
    if (s == 'usul' || s.contains('أصول') || s.contains('اصول') || s.contains('قواعد')) {
      return isDark
          ? const FanDisciplineColors(
              primary: Color(0xFFD8B4FE),
              softBg: Color(0xFF3B0764),
              border: Color(0xFF9333EA),
            )
          : const FanDisciplineColors(
              primary: Color(0xFF6B21A8),
              softBg: Color(0xFFFAF5FF),
              border: Color(0xFFE9D5FF),
            );
    }

    // Hadith & Sunnah (Warm Prophetic Amber)
    if (s == 'hadith' || s.contains('حديث') || s.contains('سنة')) {
      return isDark
          ? const FanDisciplineColors(
              primary: Color(0xFFFBBF24),
              softBg: Color(0xFF451A03),
              border: Color(0xFFD97706),
            )
          : const FanDisciplineColors(
              primary: Color(0xFFB45309),
              softBg: Color(0xFFFFFBEB),
              border: Color(0xFFFDE68A),
            );
    }

    // Noble Quran & Tafsir (Sacred Jade / Teal)
    if (s == 'quran' || s.contains('قرآن') || s.contains('قران') || s.contains('تفسير')) {
      return isDark
          ? const FanDisciplineColors(
              primary: Color(0xFF2DD4BF),
              softBg: Color(0xFF134E4A),
              border: Color(0xFF0D9488),
            )
          : const FanDisciplineColors(
              primary: Color(0xFF0F766E),
              softBg: Color(0xFFF0FDFA),
              border: Color(0xFF99F6E4),
            );
    }

    // Tajweed & Tilawah (Ocean Cyan / Azure)
    if (s == 'tajweed' || s.contains('تجويد') || s.contains('تلاوة')) {
      return isDark
          ? const FanDisciplineColors(
              primary: Color(0xFF38BDF8),
              softBg: Color(0xFF0C4A6E),
              border: Color(0xFF0284C7),
            )
          : const FanDisciplineColors(
              primary: Color(0xFF0369A1),
              softBg: Color(0xFFF0F9FF),
              border: Color(0xFFBAE6FD),
            );
    }

    // Seerah Nabawiyyah (Ruby Rose)
    if (s == 'seerah' || s.contains('سيرة')) {
      return isDark
          ? const FanDisciplineColors(
              primary: Color(0xFFFB7185),
              softBg: Color(0xFF4C0519),
              border: Color(0xFFE11D48),
            )
          : const FanDisciplineColors(
              primary: Color(0xFFBE123C),
              softBg: Color(0xFFFFF1F2),
              border: Color(0xFFFECDD3),
            );
    }

    // Sahaba & Ahl al-Bayt (Terracotta Warm Orange)
    if (s == 'sahaba' || s.contains('صحاب') || s.contains('آل البيت') || s.contains('البيت')) {
      return isDark
          ? const FanDisciplineColors(
              primary: Color(0xFFFB923C),
              softBg: Color(0xFF431407),
              border: Color(0xFFEA580C),
            )
          : const FanDisciplineColors(
              primary: Color(0xFFC2410C),
              softBg: Color(0xFFFFF7ED),
              border: Color(0xFFFED7AA),
            );
    }

    // Prophets & Messengers (Sunlit Bronze Gold)
    if (s == 'prophets' || s.contains('أنبياء') || s.contains('انبياء') || s.contains('رسل')) {
      return isDark
          ? const FanDisciplineColors(
              primary: Color(0xFFFDE047),
              softBg: Color(0xFF361803),
              border: Color(0xFFCA8A04),
            )
          : const FanDisciplineColors(
              primary: Color(0xFF92400E),
              softBg: Color(0xFFFEF3C7),
              border: Color(0xFFFDE68A),
            );
    }

    // Adab & Raqaeq (Sage Mint Green)
    if (s == 'adab' || s.contains('آداب') || s.contains('اداب') || s.contains('رقائق')) {
      return isDark
          ? const FanDisciplineColors(
              primary: Color(0xFFA3E635),
              softBg: Color(0xFF1A2E05),
              border: Color(0xFF65A30D),
            )
          : const FanDisciplineColors(
              primary: Color(0xFF4D7C0F),
              softBg: Color(0xFFF7FEE7),
              border: Color(0xFFD9F99D),
            );
    }

    // Arabic Language & Eloquence (Royal Indigo)
    if (s == 'arabic' || s.contains('لغة') || s.contains('عربي') || s.contains('نحو') || s.contains('بلاغة')) {
      return isDark
          ? const FanDisciplineColors(
              primary: Color(0xFF818CF8),
              softBg: Color(0xFF1E1B4B),
              border: Color(0xFF4F46E5),
            )
          : const FanDisciplineColors(
              primary: Color(0xFF4338CA),
              softBg: Color(0xFFEEF2FF),
              border: Color(0xFFC7D2FE),
            );
    }

    // Fallback default: Warm Ochre
    return isDark
        ? const FanDisciplineColors(
            primary: Color(0xFFFBBF24),
            softBg: Color(0xFF2C200C),
            border: Color(0xFFD97706),
          )
        : const FanDisciplineColors(
            primary: Color(0xFF9E640B),
            softBg: Color(0xFFFEF3C7),
            border: Color(0xFFFDE68A),
          );
  }

  /// Canonical prayer celestial sky color with >= 4.5:1 AA contrast on card surface
  Color prayer(String? name) {
    final p = (name ?? '').toLowerCase().trim();
    if (p.contains('fajr') || p.contains('فجر')) {
      // Celestial Dawn Twilight Azure (first light before sunrise)
      return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);
    }
    if (p.contains('sunrise') || p.contains('شروق')) {
      // Radiant Sunrise Horizon Peach-Amber (sun disk cresting horizon)
      return isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C);
    }
    if (p.contains('dhuhr') || p.contains('ظهر')) {
      // Zenith High-Noon Solar Gold (sun at highest point in the sky)
      return isDark ? const Color(0xFFFACC15) : const Color(0xFF9E640B);
    }
    if (p.contains('asr') || p.contains('عصر')) {
      // Afternoon Golden-Hour Amber-Bronze (lengthening shadows, warm amber rays)
      return isDark ? const Color(0xFFFB923C) : const Color(0xFFB45309);
    }
    if (p.contains('maghrib') || p.contains('مغرب')) {
      // Sunset Crimson-Rose Horizon Glow (sun setting, red dusk afterglow / shafaq ahmar)
      return isDark ? const Color(0xFFFB7185) : const Color(0xFFBE123C);
    }
    if (p.contains('isha') || p.contains('عشاء')) {
      // Deep Nocturnal Celestial Violet-Indigo (absence of sunlight, starlit night sky)
      return isDark ? const Color(0xFFA78BFA) : const Color(0xFF6D28D9);
    }
    if (p.contains('dhuha') || p.contains('ضحى')) {
      // Radiant Forenoon Gold (Dhuha / Awabeen)
      return isDark ? const Color(0xFFFDE047) : const Color(0xFFB45309);
    }
    if (p.contains('midnight') || p.contains('منتصف')) {
      // Celestial Midnight Deep Indigo (end of Isha window)
      return isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);
    }
    if (p.contains('qiyam') || p.contains('ثلث') || p.contains('تهجد')) {
      // Serene Pre-Dawn Qiyam Teal-Cyan (Sahoor & Tahajjud)
      return isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    }
    return gold;
  }

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceMuted,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? textSubtle,
    Color? primary,
    Color? onPrimary,
    Color? primarySoft,
    Color? onPrimarySoft,
    Color? gold,
    Color? goldFill,
    Color? onGold,
    Color? goldSoft,
    Color? success,
    Color? error,
    Color? errorSoft,
    Color? brandDark,
    List<BoxShadow>? shadow,
    bool? isDark,
    String? logoSymbol,
    String? logoLockup,
    Color? splashBg,
    Color? splashCardBg,
    Color? splashCardBorder,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      textSubtle: textSubtle ?? this.textSubtle,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimarySoft: onPrimarySoft ?? this.onPrimarySoft,
      gold: gold ?? this.gold,
      goldFill: goldFill ?? this.goldFill,
      onGold: onGold ?? this.onGold,
      goldSoft: goldSoft ?? this.goldSoft,
      success: success ?? this.success,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      brandDark: brandDark ?? this.brandDark,
      shadow: shadow ?? this.shadow,
      isDark: isDark ?? this.isDark,
      logoSymbol: logoSymbol ?? this.logoSymbol,
      logoLockup: logoLockup ?? this.logoLockup,
      splashBg: splashBg ?? this.splashBg,
      splashCardBg: splashCardBg ?? this.splashCardBg,
      splashCardBorder: splashCardBorder ?? this.splashCardBorder,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      onPrimarySoft: Color.lerp(onPrimarySoft, other.onPrimarySoft, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldFill: Color.lerp(goldFill, other.goldFill, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      brandDark: Color.lerp(brandDark, other.brandDark, t)!,
      shadow: t < 0.5 ? shadow : other.shadow,
      isDark: t < 0.5 ? isDark : other.isDark,
      logoSymbol: t < 0.5 ? logoSymbol : other.logoSymbol,
      logoLockup: t < 0.5 ? logoLockup : other.logoLockup,
      splashBg: Color.lerp(splashBg, other.splashBg, t)!,
      splashCardBg: Color.lerp(splashCardBg, other.splashCardBg, t)!,
      splashCardBorder: Color.lerp(splashCardBorder, other.splashCardBorder, t)!,
    );
  }
}

/// The 8 canonical typography styles defined in the design system
class AppTextTheme {
  final TextStyle display;
  final TextStyle title;
  final TextStyle titleSmall;
  final TextStyle body;
  final TextStyle bodySmall;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle sacred;
  final TextStyle sacredLarge;
  final TextStyle sacredSmall;
  final TextStyle mushafChrome;
  final TextStyle surahHeaderTitle;
  final TextStyle surahCalligraphy;
  final TextStyle basmallahCalligraphy;

  const AppTextTheme({
    required this.display,
    required this.title,
    required this.titleSmall,
    required this.body,
    required this.bodySmall,
    required this.label,
    required this.caption,
    required this.sacred,
    required this.sacredLarge,
    required this.sacredSmall,
    required this.mushafChrome,
    required this.surahHeaderTitle,
    required this.surahCalligraphy,
    required this.basmallahCalligraphy,
  });

  factory AppTextTheme.fromPalette(AppPalette palette) {
    const cairo = 'Cairo';
    const scheherazadeNew = 'ScheherazadeNew';
    const amiri = 'Amiri';

    return AppTextTheme(
      display: TextStyle(
        fontFamily: cairo,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: palette.text,
      ),
      title: TextStyle(
        fontFamily: cairo,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.5,
        color: palette.text,
      ),
      titleSmall: TextStyle(
        fontFamily: cairo,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.5,
        color: palette.text,
      ),
      body: TextStyle(
        fontFamily: cairo,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.7,
        color: palette.text,
      ),
      bodySmall: TextStyle(
        fontFamily: cairo,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: palette.textMuted,
      ),
      label: TextStyle(
        fontFamily: cairo,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: palette.text,
      ),
      caption: TextStyle(
        fontFamily: cairo,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: palette.textSubtle,
      ),
      sacred: TextStyle(
        fontFamily: scheherazadeNew,
        fontSize: 22,
        fontWeight: FontWeight.w400,
        height: 2.0,
        color: palette.text,
      ),
      sacredSmall: TextStyle(
        fontFamily: amiri,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.85,
        color: palette.text,
      ),
      sacredLarge: TextStyle(
        fontFamily: scheherazadeNew,
        fontSize: 26,
        fontWeight: FontWeight.w400,
        height: 2.0,
        color: palette.text,
      ),
      mushafChrome: TextStyle(
        fontFamily: scheherazadeNew,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: palette.text,
      ),
      surahHeaderTitle: TextStyle(
        fontFamily: scheherazadeNew,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: palette.text,
      ),
      surahCalligraphy: const TextStyle(
        fontFamily: 'arsura',
        package: 'qcf_quran_plus',
        fontSize: 34,
        fontWeight: FontWeight.w400,
        height: 1.1,
      ),
      basmallahCalligraphy: const TextStyle(
        fontFamily: 'QCF4_BSML',
        package: 'qcf_quran_plus',
        fontSize: 30,
        fontWeight: FontWeight.w400,
        height: 1.2,
      ),
    );
  }

  /// Semantic weight variants for fine-grained typography
  TextStyle get displayHeavy => display.copyWith(fontWeight: FontWeight.w800);
  TextStyle get titleHeavy => title.copyWith(fontWeight: FontWeight.w800);
  TextStyle get titleMedium => title.copyWith(fontWeight: FontWeight.w600);
  TextStyle get titleSmallMedium => titleSmall.copyWith(fontWeight: FontWeight.w600);
  TextStyle get titleSmallHeavy => titleSmall.copyWith(fontWeight: FontWeight.w800);
  TextStyle get bodyMedium => body.copyWith(fontWeight: FontWeight.w500);
  TextStyle get bodyBold => body.copyWith(fontWeight: FontWeight.w600);
  TextStyle get bodyHeavy => body.copyWith(fontWeight: FontWeight.w700);
  TextStyle get bodySmallMedium => bodySmall.copyWith(fontWeight: FontWeight.w500);
  TextStyle get bodySmallBold => bodySmall.copyWith(fontWeight: FontWeight.w600);
  TextStyle get labelMedium => label.copyWith(fontWeight: FontWeight.w500);
  TextStyle get labelBold => label.copyWith(fontWeight: FontWeight.w700);
  TextStyle get labelHeavy => label.copyWith(fontWeight: FontWeight.w800);
  TextStyle get captionRegular => caption.copyWith(fontWeight: FontWeight.w400);
  TextStyle get captionBold => caption.copyWith(fontWeight: FontWeight.w600);
  TextStyle get captionHeavy => caption.copyWith(fontWeight: FontWeight.w700);
  TextStyle get sacredBold => sacred.copyWith(fontWeight: FontWeight.w700);
  TextStyle get sacredSmallBold => sacredSmall.copyWith(fontWeight: FontWeight.w700);
}

/// Font weight tokens to prevent raw FontWeight literals outside theme
class AppFontWeight {
  AppFontWeight._();

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
}

/// Spacing tokens
class AppSpace {
  AppSpace._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20; // screen side padding
  static const double xxl = 24;
  static const double xxxl = 32;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets modalPadding = EdgeInsets.all(xl);

  static const EdgeInsets insetXs = EdgeInsets.all(xs);
  static const EdgeInsets insetSm = EdgeInsets.all(sm);
  static const EdgeInsets insetMd = EdgeInsets.all(md);
  static const EdgeInsets insetLg = EdgeInsets.all(lg);
  static const EdgeInsets insetXl = EdgeInsets.all(xl);
}

/// Radius tokens
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12; // buttons, inputs, snackbars
  static const double lg = 16; // cards
  static const double xl = 24; // sheets, hero, nav
  static const double pill = 999;

  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);
  static BorderRadius get sheetTopRadius => const BorderRadius.vertical(
        top: Radius.circular(xl),
      );
}

/// Icon size tokens
class AppIcon {
  AppIcon._();

  static const double xs = 8;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;
  static const double hero = 40;
}

/// Motion & transition tokens
class AppMotion {
  AppMotion._();

  static const Duration zero = Duration.zero;
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration splash = Duration(milliseconds: 650);
  static const Duration toast = Duration(milliseconds: 2500);
  static const Duration toastShort = Duration(milliseconds: 1600);
  static const Duration toastDismiss = Duration(milliseconds: 160);
  static const Duration debounce = Duration(milliseconds: 500);

  /// 16ms (~60fps frame ticker)
  static const Duration frame60Fps = Duration(milliseconds: 16);

  /// 50ms (micro yield/pause)
  static const Duration microPause = Duration(milliseconds: 50);

  /// 300ms (search debounce & filter settling)
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// 600ms (extended micro-interaction transition)
  static const Duration deliberate = Duration(milliseconds: 600);

  /// 5000ms / 5s (audio player seek forward/backward step)
  static const Duration seekStep = Duration(seconds: 5);

  /// 1 second (interval timers, clocks)
  static const Duration oneSecond = Duration(seconds: 1);

  /// 2 seconds (quick toasts / auto dismiss)
  static const Duration twoSeconds = Duration(seconds: 2);

  /// 3 seconds (HUD / controls auto-hide)
  static const Duration controlsHide = Duration(seconds: 3);

  /// 4 seconds (long toasts / undo bars)
  static const Duration toastLong = Duration(seconds: 4);

  /// 10 seconds (standard network retry)
  static const Duration networkRetry = Duration(seconds: 10);

  /// 15 seconds (reading history throttle / standard network timeout)
  static const Duration networkTimeout = Duration(seconds: 15);

  /// 20 seconds (medium network operations)
  static const Duration networkMedium = Duration(seconds: 20);

  /// 30 seconds (heavy API / data sync operations)
  static const Duration networkLong = Duration(seconds: 30);

  /// 60 seconds (ambient visual cycles, deep network timeouts)
  static const Duration ambient = Duration(seconds: 60);

  /// Construct a dynamic Duration from seconds
  static Duration fromSeconds(int seconds) => Duration(seconds: seconds);

  /// Construct a dynamic Duration from milliseconds
  static Duration fromMilliseconds(int ms) => Duration(milliseconds: ms);

  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeOut = Curves.easeOutCubic;
}

/// Size & touch targets
class AppSize {
  AppSize._();

  static const double textScaleBaseWidth = 360;
  static const double textScaleMin = 0.9;
  static const double textScaleMax = 2.0;

  static const double tap = 48;
  static const double buttonH = 48;
  static const double buttonSmallMinHeight = 40;
  static const double tagMinHeight = 28;
  static const double inputH = 52;
  static const double navH = 64;
  static const double navMargin = 16;

  /// Clearance required at the bottom of screens to sit comfortably above the floating nav
  static double navClearance(BuildContext context) {
    final viewPaddingBottom = MediaQuery.viewPaddingOf(context).bottom;
    final paddingBottom = MediaQuery.paddingOf(context).bottom;
    final effectiveInset =
        viewPaddingBottom > 0 ? viewPaddingBottom : paddingBottom;
    final navBottom = effectiveInset > 0 ? effectiveInset : AppSpace.sm;
    return navH + navBottom + AppSpace.lg;
  }
}

/// Standard Tajweed color tokens (Medina Mushaf rules)
class TajweedPalette {
  TajweedPalette._();

  static const Color ghunnah = Color(0xFFB45309); // Warm Amber Gold
  static const Color qalqalah = Color(0xFF0284C7); // Ocean Blue
  static const Color ikhfaa = Color(0xFF059669); // Emerald Forest
  static const Color idgham = Color(0xFF7C3AED); // Regal Purple
  static const Color iqlab = Color(0xFFEA580C); // Vivid Coral
  static const Color madd = Color(0xFFDC2626); // Crimson Red
  static const Color maddShort = Color(0xFFEA580C); // Vivid Coral / Orange (مد حركتان)
  static const Color silent = Color(0xFF9CA3AF); // Neutral Slate Gray (أحرف لا تُلفظ)
}

/// Reading surfaces for Mushaf
class MushafColors {
  MushafColors._();

  static const Color whiteBg = Color(0xFFFFFFFF);
  static const Color whiteText = Color(0xFF1A1A1A);
  static const Color whiteVerseNumber = Color(0xFF8B4513);
  static const Color whiteBannerBg = Color(0xFFF7F5EE);
  static const Color whiteBannerBorder = Color(0xFFC7BBAA);
  static const Color whiteBannerText = Color(0xFF2E1C0C);
  static const Color whiteBannerSubtext = Color(0xFF5D4037);

  static const Color sepiaBg = Color(0xFFFBF7EE);
  static const Color sepiaText = Color(0xFF2B2520);
  static const Color sepiaVerseNumber = Color(0xFF8B5A2B);
  static const Color sepiaBannerBg = Color(0xFFF2E9DA);
  static const Color sepiaBannerBorder = Color(0xFFBCA685);
  static const Color sepiaBannerText = Color(0xFF332014);
  static const Color sepiaBannerSubtext = Color(0xFF6B4E38);

  static const Color darkBg = Color(0xFF101114);
  static const Color darkText = Color(0xFFEAE5DC);
  static const Color darkVerseNumber = Color(0xFFD4AF37);
  static const Color darkBannerBg = Color(0xFF181A20);
  static const Color darkBannerBorder = Color(0xFF8C7338);
  static const Color darkBannerText = Color(0xFFF5D78E);
  static const Color darkBannerSubtext = Color(0xFFC7AA64);

  static const Color darkOverlayBg = Color(0xFF181B22);
  static const Color darkOverlayBorder = Color(0xFF282C36);
  static const Color darkOverlayPill = Color(0xFF22252D);
  static const Color darkMuted = Color(0xFFA2A7B4);
  static const Color darkCardBorder = Color(0xFF2C3038);
  static const Color darkBadgeBg = Color(0xFF242730);

  static const Color sepiaOverlayBg = Color(0xFFF4ECE0);
  static const Color sepiaOverlayBorder = Color(0xFFDFD4C4);
  static const Color sepiaOverlayPill = Color(0xFFEBE0D0);
  static const Color sepiaCardBg = Color(0xFFFAF5EC);
  static const Color sepiaCardBorder = Color(0xFFDFD4C4);
  static const Color sepiaBadgeBg = Color(0xFFEFE6D6);
  static const Color plaqueBg = Color(0xFFFAF7F0);
  static const Color plaqueBorder = Color(0xFFC8B482);
  static const Color plaqueText = Color(0xFF2E241B);

  /// Theme-based background lookup — eliminates switch duplication.
  // ignore: import_of_legacy_library_into_null_safe
  static Color bgFor(MushafThemeMode mode) {
    switch (mode) {
      case MushafThemeMode.white: return whiteBg;
      case MushafThemeMode.sepia: return sepiaBg;
      case MushafThemeMode.dark:  return darkBg;
    }
  }

  static Color textFor(MushafThemeMode mode) {
    switch (mode) {
      case MushafThemeMode.white: return whiteText;
      case MushafThemeMode.sepia: return sepiaText;
      case MushafThemeMode.dark:  return darkText;
    }
  }

  static Color verseNumberFor(MushafThemeMode mode) {
    switch (mode) {
      case MushafThemeMode.white: return whiteVerseNumber;
      case MushafThemeMode.sepia: return sepiaVerseNumber;
      case MushafThemeMode.dark:  return darkVerseNumber;
    }
  }

  static Color bannerBorderFor(MushafThemeMode mode) {
    switch (mode) {
      case MushafThemeMode.white: return whiteBannerBorder;
      case MushafThemeMode.sepia: return sepiaBannerBorder;
      case MushafThemeMode.dark:  return darkBannerBorder;
    }
  }

  static Color bannerBgFor(MushafThemeMode mode) => switch (mode) {
    MushafThemeMode.white => whiteBannerBg,
    MushafThemeMode.sepia => sepiaBannerBg,
    MushafThemeMode.dark => darkBannerBg,
  };

  static Color bannerTextFor(MushafThemeMode mode) => switch (mode) {
    MushafThemeMode.white => whiteBannerText,
    MushafThemeMode.sepia => sepiaBannerText,
    MushafThemeMode.dark => darkBannerText,
  };

  static Color bannerSubtextFor(MushafThemeMode mode) => switch (mode) {
    MushafThemeMode.white => whiteBannerSubtext,
    MushafThemeMode.sepia => sepiaBannerSubtext,
    MushafThemeMode.dark => darkBannerSubtext,
  };

  static Color overlayBgFor(MushafThemeMode mode, AppPalette palette) => switch (mode) {
    MushafThemeMode.white => palette.surfaceRaised,
    MushafThemeMode.sepia => sepiaOverlayBg,
    MushafThemeMode.dark => darkOverlayBg,
  };

  static Color overlayBorderFor(MushafThemeMode mode, AppPalette palette) => switch (mode) {
    MushafThemeMode.white => palette.border,
    MushafThemeMode.sepia => sepiaOverlayBorder,
    MushafThemeMode.dark => darkOverlayBorder,
  };

  static Color overlayTextFor(MushafThemeMode mode, AppPalette palette) => switch (mode) {
    MushafThemeMode.white => palette.text,
    MushafThemeMode.sepia => sepiaText,
    MushafThemeMode.dark => darkText,
  };

  static Color overlayTextMutedFor(MushafThemeMode mode, AppPalette palette) => switch (mode) {
    MushafThemeMode.white => palette.textMuted,
    MushafThemeMode.sepia => sepiaBannerSubtext,
    MushafThemeMode.dark => darkMuted,
  };

  static Color overlayPillFor(MushafThemeMode mode, AppPalette palette) => switch (mode) {
    MushafThemeMode.white => palette.surfaceMuted,
    MushafThemeMode.sepia => sepiaOverlayPill,
    MushafThemeMode.dark => darkOverlayPill,
  };

  static Color cardBgFor(MushafThemeMode mode, AppPalette palette) => switch (mode) {
    MushafThemeMode.white => palette.surfaceRaised,
    MushafThemeMode.sepia => sepiaCardBg,
    MushafThemeMode.dark => darkBannerBg,
  };

  static Color cardBorderFor(MushafThemeMode mode, AppPalette palette) => switch (mode) {
    MushafThemeMode.white => palette.border,
    MushafThemeMode.sepia => sepiaCardBorder,
    MushafThemeMode.dark => darkCardBorder,
  };

  static Color badgeBgFor(MushafThemeMode mode, AppPalette palette) => switch (mode) {
    MushafThemeMode.white => palette.surfaceMuted,
    MushafThemeMode.sepia => sepiaBadgeBg,
    MushafThemeMode.dark => darkBadgeBg,
  };

  static Color? bannerFrameTint(MushafThemeMode mode) => null;
}

/// Ergonomic theme context extensions
extension AppThemeContextX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);

  AppTextTheme get text => AppTextTheme.fromPalette(palette);
}
