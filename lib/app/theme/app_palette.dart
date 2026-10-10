import 'package:flutter/material.dart';

/// Semantic colors for category chips & indicators
class CategoryColors {
  final Color fg;
  final Color bg;

  const CategoryColors({required this.fg, required this.bg});
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
  });

  /// Light theme palette
  static const light = AppPalette(
    bg: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    text: Color(0xFF0F172A),
    textMuted: Color(0xFF475569),
    textSubtle: Color(0xFF64748B),
    primary: Color(0xFF0F766E),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFCCFBF1),
    onPrimarySoft: Color(0xFF0F766E),
    gold: Color(0xFFB45309),
    goldFill: Color(0xFFF59E0B),
    onGold: Color(0xFF451A03),
    goldSoft: Color(0xFFFEF3C7),
    success: Color(0xFF047857),
    error: Color(0xFFB91C1C),
    errorSoft: Color(0xFFFEE2E2),
    brandDark: Color(0xFF0A0E13),
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
  );

  /// Dark theme palette
  static const dark = AppPalette(
    bg: Color(0xFF0A0E13),
    surface: Color(0xFF12181F),
    surfaceRaised: Color(0xFF1A232C),
    surfaceMuted: Color(0xFF0E1318),
    border: Color(0xFF22303C),
    text: Color(0xFFF8FAFC),
    textMuted: Color(0xFF94A3B8),
    textSubtle: Color(0xFF8A9BB0),
    primary: Color(0xFF10B981),
    onPrimary: Color(0xFF022C22),
    primarySoft: Color(0xFF064E3B),
    onPrimarySoft: Color(0xFF34D399),
    gold: Color(0xFFFBBF24),
    goldFill: Color(0xFFF59E0B),
    onGold: Color(0xFF451A03),
    goldSoft: Color(0xFF451A03),
    success: Color(0xFF34D399),
    error: Color(0xFFF87171),
    errorSoft: Color(0xFF3B1414),
    brandDark: Color(0xFF0A0E13),
    shadow: [],
    isDark: true,
    logoSymbol: 'assets/branding/symbol_on_dark.png',
    logoLockup: 'assets/branding/lockup_on_dark.png',
  );

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

  /// Canonical prayer dot/ring color with >= 3.0:1 contrast on surface
  Color prayer(String? name) {
    final p = (name ?? '').toLowerCase().trim();
    if (p.contains('fajr') || p.contains('فجر')) {
      return isDark ? const Color(0xFF818CF8) : const Color(0xFF3730A3);
    }
    if (p.contains('sunrise') || p.contains('شروق')) {
      return isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E);
    }
    if (p.contains('dhuhr') || p.contains('ظهر')) {
      return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1);
    }
    if (p.contains('asr') || p.contains('عصر')) {
      return isDark ? const Color(0xFFFB923C) : const Color(0xFF9A3412);
    }
    if (p.contains('maghrib') || p.contains('مغرب')) {
      return isDark ? const Color(0xFFFB7185) : const Color(0xFF9F1239);
    }
    if (p.contains('isha') || p.contains('عشاء')) {
      return isDark ? const Color(0xFFA78BFA) : const Color(0xFF5B21B6);
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
  });

  factory AppTextTheme.fromPalette(AppPalette palette) {
    const cairo = 'Cairo';
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
        fontFamily: amiri,
        fontSize: 22,
        fontWeight: FontWeight.w400,
        height: 2.0,
        color: palette.text,
      ),
      sacredLarge: TextStyle(
        fontFamily: amiri,
        fontSize: 26,
        fontWeight: FontWeight.w400,
        height: 2.0,
        color: palette.text,
      ),
    );
  }
}

/// Spacing tokens
class AppSpace {
  AppSpace._();

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
}

/// Icon size tokens
class AppIcon {
  AppIcon._();

  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;
  static const double hero = 40;
}

/// Motion & transition tokens
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve easeIn = Curves.easeInCubic;
  static const Curve easeOut = Curves.easeOutCubic;
}

/// Size & touch targets
class AppSize {
  AppSize._();

  static const double tap = 48;
  static const double buttonH = 48;
  static const double inputH = 52;
  static const double navH = 64;
  static const double navMargin = 16;

  /// Clearance required at the bottom of screens to not be covered by floating nav
  static double navClearance(BuildContext context) {
    return navH + navMargin + MediaQuery.paddingOf(context).bottom;
  }
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
