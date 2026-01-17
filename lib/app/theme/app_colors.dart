import 'package:flutter/material.dart';

class AppColors {
  // ═══════════════════════════════════════════════════════════════════════
  // PRIMARY - Muted Teal (main actions, progress, primary UI)
  // ═══════════════════════════════════════════════════════════════════════
  static const primary = Color(0xFF5A8A8A); // Calm teal
  static const primaryDark = Color(0xFF4A7A7A);
  static const primaryLight = Color(0xFF7AB5A8); // Mint teal

  // ═══════════════════════════════════════════════════════════════════════
  // SECONDARY - Soft Gold (achievements, motivation, rewards)
  // ═══════════════════════════════════════════════════════════════════════
  static const accent = Color(0xFFD4A853); // Warm gold
  static const accentGold = accent;
  static const gold = accent;
  static const goldLight = Color(0xFFFFF8E7); // Gold surface
  static const goldGlow = Color(0xFFE8C252);

  // ═══════════════════════════════════════════════════════════════════════
  // BACKGROUNDS - Warm Off-White (never pure white)
  // ═══════════════════════════════════════════════════════════════════════
  static const background = Color(0xFFFBFAF8); // Warm ivory
  static const surface = Color(0xFFFAFAF9); // Card background
  static const surfaceSecondary = Color(0xFFF5F3F0);
  static const surfaceElevated = Color(0xFFFFFFFF); // Dialogs/Modals
  static const surfaceHover = Color(0xFFF0EFE9); // Hover/Highlight
  static const cardBackground = surface;

  // ═══════════════════════════════════════════════════════════════════════
  // SUCCESS - Soft Green (completed states)
  // ═══════════════════════════════════════════════════════════════════════
  static const success = Color(0xFF22C55E);
  static const successLight = Color(0xFFF0FDF4);
  static const successMuted = Color(0xFF85A885);

  // ═══════════════════════════════════════════════════════════════════════
  // TEXT - Near-black titles, muted grey secondary
  // ═══════════════════════════════════════════════════════════════════════
  static const textPrimary = Color(0xFF3A3A3A); // Near-black (charcoal)
  static const textSecondary = Color(0xFF6E6E6E); // Muted grey
  static const textTertiary = Color(0xFF9A9A9A); // Light grey
  static const textDisabled = Color(0xFFB5B5B5);
  static const textOnPrimary = Color(0xFFFCFCFC); // White on dark

  // ═══════════════════════════════════════════════════════════════════════
  // BORDERS - Subtle warm grey
  // ═══════════════════════════════════════════════════════════════════════
  static const border = Color(0xFFE8E6E3);
  static const divider = Color(0xFFF2F0ED);
  static const separator = Color(0xFFEAE8E5);
  static const stroke = border;

  // ═══════════════════════════════════════════════════════════════════════
  // CATEGORY COLORS (Book subjects - no purple)
  // ═══════════════════════════════════════════════════════════════════════
  static const categoryAqidah = Color(0xFF5A8A8A); // Teal (عقيدة)
  static const categoryHadith = Color(0xFF6366F1); // Indigo (حديث)
  static const categoryFiqh = Color(0xFF10B981); // Emerald (فقه)
  static const categoryQuran = Color(0xFFD4A853); // Gold (قرآن)
  static const categoryLanguage = Color(0xFF0EA5E9); // Sky blue (لغة)
  static const categorySeerah = Color(0xFFEC4899); // Pink (سيرة)

  // ═══════════════════════════════════════════════════════════════════════
  // PRAYER COLORS - Muted, warm tones
  // ═══════════════════════════════════════════════════════════════════════
  static const fajr = Color(0xFF7585A8); // Soft blue
  static const sunrise = Color(0xFFD4B87A); // Gold
  static const dhuhr = Color(0xFF85A5B8); // Sky
  static const asr = Color(0xFFCBA580); // Amber
  static const maghrib = Color(0xFFA88585); // Rose
  static const isha = Color(0xFF6A7A95); // Slate blue

  // ═══════════════════════════════════════════════════════════════════════
  // STATES - Semantic colors
  // ═══════════════════════════════════════════════════════════════════════
  static const error = Color(0xFFDC2626);
  static const errorLight = Color(0xFFFEF2F2);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFFFBEB);
  static const info = Color(0xFF0EA5E9);
  static const infoLight = Color(0xFFF0F9FF);

  // ═══════════════════════════════════════════════════════════════════════
  // SHADOWS
  // ═══════════════════════════════════════════════════════════════════════
  static final shadow = const Color(0xFF3A3A3A).withValues(alpha: 0.05);
  static final shadowMedium = const Color(0xFF3A3A3A).withValues(alpha: 0.1);

  // ═══════════════════════════════════════════════════════════════════════
  // ICON COLORS
  // ═══════════════════════════════════════════════════════════════════════
  static const iconPrimary = primary;
  static const iconMuted = Color(0xFF9A9A9A);
  static const iconLight = Color(0xFFB5B5B5);

  // ═══════════════════════════════════════════════════════════════════════
  // GRADIENTS - Subtle, warm
  // ═══════════════════════════════════════════════════════════════════════
  static const primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [primary, primaryLight],
  );

  static const tealMintGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF5A8A8A), Color(0xFF7AB5A8)],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, goldGlow],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, surface],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceSecondary],
  );

  static const surfaceElevatedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceSecondary],
  );

  // Category alias for backwards compatibility
  static const categoryArabic = categoryLanguage;

  // ═══════════════════════════════════════════════════════════════════════
  // COMPATIBILITY (legacy names)
  // ═══════════════════════════════════════════════════════════════════════
  static const black = textPrimary;
  static const secondary = primaryLight;

  static const surfaceVariant = surfaceSecondary;
  static const textMuted = textTertiary;
  static const clear = Colors.transparent;

  // ═══════════════════════════════════════════════════════════════════════
  // DARK THEME COLORS (True Black & Neon)
  // ═══════════════════════════════════════════════════════════════════════

  // Backgrounds (OLED Black)
  static const darkBackground = Color(0xFF000000); // Pure black
  static const darkSurface = Color(0xFF0A0A0A); // Almost black
  static const darkSurfaceSecondary = Color(0xFF141414); // Slightly elevated
  static const darkSurfaceElevated = Color(0xFF141414); // Dialogs
  static const darkSurfaceHover = Color(0xFF1A1A1A); // Hover states

  // Text colors (High Contrast)
  static const darkTextPrimary = Color(0xFFFFFFFF); // Pure white
  static const darkTextSecondary = Color(0xFFA1A1A1); // Light grey
  static const darkTextTertiary = Color(0xFF666666); // Medium grey
  static const darkTextDisabled = Color(0xFF404040);

  // Borders
  static const darkBorder = Color(0xFF1F1F1F); // Dark grey
  static const darkDivider = Color(0xFF141414); // Subtle
  static const darkSeparator = Color(0xFF1F1F1F);

  // NEON ACCENTS (Vibrant)
  static const primaryNeon = Color(0xFF00D9C0); // Cyan-Teal
  static const blueNeon = Color(0xFF3B9EFF); // Electric Blue
  static const purpleNeon = Color(0xFFA855F7); // Vivid Purple
  static const pinkNeon = Color(0xFFFF4D9E); // Hot Pink
  static const orangeNeon = Color(0xFFFF8A3D); // Vibrant Orange
  static const greenNeon = Color(0xFF00E676); // Neon Green
  static const yellowNeon = Color(0xFFFFD600); // Bright Yellow

  // Mapping to Theme Roles
  static const darkPrimary = primaryNeon;
  static const darkPrimaryLight = Color(0xFF00B39E); // Slightly darker teal

  static const darkSuccess = greenNeon;
  static const darkSuccessLight = Color(0xFF00331A);

  static const darkGold = yellowNeon;
  static const darkGoldLight = Color(0xFF332B00);

  // Deprecated - kept for backwards compatibility
  @Deprecated('Use categoryLanguage instead')
  static const accentBlue = Color(0xFF7A9CB5);
  @Deprecated('Use success instead')
  static const accentGreen = Color(0xFF85A885);
  static const accentSage = successMuted;
  @Deprecated('Use accent instead')
  static const accentOrange = Color(0xFFCBA580);
  @Deprecated('Removed - not aligned with ilm theme')
  static const accentPurple = Color(0xFF9A8EB0);
  @Deprecated('Use categorySeerah instead')
  static const accentPink = Color(0xFFB8A0A0);
  @Deprecated('Use gold instead')
  static const accentYellow = Color(0xFFD4C08A);
}
