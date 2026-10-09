import 'package:flutter/material.dart';

/// App Colors - Material Blue Gray Core Design System
///
/// Designed around the Material Design Blue Gray color scale:
/// - 50:  #ECEFF1 (Light background & canvas, dark primary text)
/// - 100: #CFD8DC (Light borders & subtle dividers)
/// - 200: #B0BEC5 (Secondary borders, dark secondary text)
/// - 300: #90A4AE (Dark primary accent, high-contrast highlights)
/// - 400: #78909C (Muted text & subtle icons)
/// - 500: #607D8B (Medium slate branding & inactive states)
/// - 600: #546E7A (Light secondary text, dark disabled text)
/// - 700: #455A64 (Light primary branding, dark outline)
/// - 800: #37474F (Light primary dark, dark elevated surface / sheets)
/// - 900: #263238 (Light text primary, dark card container surface)
///
/// With complementary Islamic accents:
/// - Andalusian Divine Gold: Halos, bookmarks, active prayer ring
/// - Medina Emerald: Hadith & verified success
/// - Terracotta & Ochre: Seerah & Fiqh
class AppColors {
  // ═══════════════════════════════════════════════════════════════════════
  // BLUE GRAY CORE SCALE (Official Material Palette)
  // ═══════════════════════════════════════════════════════════════════════
  static const blueGray50 = Color(0xFFECEFF1);
  static const blueGray100 = Color(0xFFCFD8DC);
  static const blueGray200 = Color(0xFFB0BEC5);
  static const blueGray300 = Color(0xFF90A4AE);
  static const blueGray400 = Color(0xFF78909C);
  static const blueGray500 = Color(0xFF607D8B);
  static const blueGray600 = Color(0xFF546E7A);
  static const blueGray700 = Color(0xFF455A64);
  static const blueGray800 = Color(0xFF37474F);
  static const blueGray900 = Color(0xFF263238);

  // ═══════════════════════════════════════════════════════════════════════
  // PRIMARY - Blue Gray 700 / 800 / 500
  // ═══════════════════════════════════════════════════════════════════════
  static const primary = blueGray700; // #455A64
  static const primaryDark = blueGray800; // #37474F
  static const primaryLight = blueGray500; // #607D8B
  static const primaryContainerLight = blueGray50; // #ECEFF1

  // ═══════════════════════════════════════════════════════════════════════
  // SECONDARY - Andalusian Divine Gold (Harmonious with Slate)
  // ═══════════════════════════════════════════════════════════════════════
  static const accent = Color(0xFFC59533);
  static const accentGold = accent;
  static const gold = accent;
  static const goldLight = Color(0xFFFFF8EC);
  static const goldDark = Color(0xFF9E721D);
  static const goldGlow = Color(0xFFDDB455);

  // ═══════════════════════════════════════════════════════════════════════
  // LIGHT BACKGROUNDS & SURFACES - Blue Gray 50 Canvas & Pure White Cards
  // ═══════════════════════════════════════════════════════════════════════
  static const background = blueGray50; // #ECEFF1 (Cool, crisp Blue Gray canvas)
  static const surface = blueGray50;
  static const surfaceWarmIvory = blueGray50;
  static const warmIvoryContainer = blueGray50;
  static const surfaceSecondary = Color(0xFFE2E7EA); // Recessed areas
  static const surfaceElevated = Colors.white; // Crisp pure white cards
  static const surfaceHover = Color(0xFFE0E6E9);
  static const cardBackground = Colors.white;

  // ═══════════════════════════════════════════════════════════════════════
  // SUCCESS - Medina Emerald
  // ═══════════════════════════════════════════════════════════════════════
  static const success = Color(0xFF2E8B57);
  static const successLight = Color(0xFFEFF8F3);
  static const successMuted = Color(0xFF5B9974);

  // ═══════════════════════════════════════════════════════════════════════
  // TEXT - Blue Gray Hierarchy (Light Mode)
  // ═══════════════════════════════════════════════════════════════════════
  static const textPrimary = blueGray900; // #263238 (Deep, readable slate)
  static const textSecondary = blueGray600; // #546E7A (Clear medium slate)
  static const textTertiary = blueGray400; // #78909C (Muted caption slate)
  static const textDisabled = blueGray200; // #B0BEC5
  static const textOnPrimary = Colors.white;

  // ═══════════════════════════════════════════════════════════════════════
  // BORDERS (Light Mode) - Blue Gray 100
  // ═══════════════════════════════════════════════════════════════════════
  static const border = blueGray100; // #CFD8DC
  static const divider = blueGray100;
  static const separator = blueGray100;
  static const stroke = border;

  // ═══════════════════════════════════════════════════════════════════════
  // CATEGORIES - Harmonized Classical Minerals
  // ═══════════════════════════════════════════════════════════════════════
  static const categoryAqidah = blueGray700; // Slate (#455A64)
  static const categoryQuran = Color(0xFFC59533); // Gold
  static const categoryHadith = Color(0xFF2E8B57); // Emerald
  static const categoryFiqh = Color(0xFFB87333); // Ochre
  static const categorySeerah = Color(0xFF9E5A48); // Terracotta
  static const categoryLanguage = blueGray500; // Blue Gray (#607D8B)

  // ═══════════════════════════════════════════════════════════════════════
  // PRAYER COLORS
  // ═══════════════════════════════════════════════════════════════════════
  static const fajr = Color(0xFF5B7B9A);
  static const sunrise = Color(0xFFD49D42);
  static const dhuhr = Color(0xFF3E8899);
  static const asr = Color(0xFFC48448);
  static const maghrib = Color(0xFFA85C52);
  static const isha = Color(0xFF4A5D80);

  // ═══════════════════════════════════════════════════════════════════════
  // STATES - Semantic Colors
  // ═══════════════════════════════════════════════════════════════════════
  static const error = Color(0xFFC24136);
  static const errorLight = Color(0xFFFDF2F1);
  static const warning = Color(0xFFD97706);
  static const warningLight = Color(0xFFFEF9EE);
  static const info = blueGray600;
  static const infoLight = blueGray50;

  // ═══════════════════════════════════════════════════════════════════════
  // SHADOWS
  // ═══════════════════════════════════════════════════════════════════════
  static final shadow = blueGray900.withValues(alpha: 0.05);
  static final shadowMedium = blueGray900.withValues(alpha: 0.09);

  // ═══════════════════════════════════════════════════════════════════════
  // ICON COLORS
  // ═══════════════════════════════════════════════════════════════════════
  static const iconPrimary = primary;
  static const iconMuted = blueGray400;
  static const iconLight = blueGray200;

  // ═══════════════════════════════════════════════════════════════════════
  // GRADIENTS - Light Mode
  // ═══════════════════════════════════════════════════════════════════════
  static const primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [blueGray800, blueGray600],
  );

  static const tealMintGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [blueGray700, blueGray500],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, goldGlow],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [blueGray50, Color(0xFFE2E7EA)],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, blueGray50],
  );

  static const surfaceElevatedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, blueGray50],
  );

  // Compatibility
  static const categoryArabic = categoryLanguage;
  static const black = textPrimary;
  static const secondary = primaryLight;
  static const surfaceVariant = surfaceSecondary;
  static const textMuted = textTertiary;
  static const clear = Colors.transparent;

  // ═══════════════════════════════════════════════════════════════════════
  // DARK THEME - DEEP BLUE GRAY MIDNIGHT SANCTUARY
  // ═══════════════════════════════════════════════════════════════════════
  static const darkBackground = Color(0xFF1B2327); // 1 step deeper than 900
  static const darkSurface = Color(0xFF1B2327);
  static const darkSurfaceSecondary = blueGray900; // #263238 (Card surface)
  static const darkSurfaceContainer = blueGray900;
  static const darkSurfaceElevated = blueGray800; // #37474F (Sheets / Dialogs)
  static const darkSurfaceContainerHigh = blueGray800;
  static const darkSurfaceHover = Color(0xFF2E3C43);
  static const darkSurfaceQuote = Color(0xFF222D33);
  static const darkSurfaceLearning = blueGray900;
  static const errorMuted = Color(0xFF9E3D35);

  // Primary Luminous Slate (Dark Mode) - Blue Gray 300
  static const darkPrimary = blueGray300; // #90A4AE (Luminous, crisp slate)
  static const darkPrimaryLight = blueGray800; // #37474F
  static const darkPrimaryContainer = blueGray800; // #37474F

  // Sacred Emerald (Dark Mode)
  static const islamicGreenPrimary = Color(0xFF2E8B57);
  static const islamicGreenMuted = Color(0xFF1D4D36);
  static const islamicGreenLight = Color(0xFF45A67D);
  static const darkIslamicGreen = islamicGreenLight;
  static const islamicGreenDark = Color(0xFF133624);
  static const islamicGreenSurface = Color(0xFF0E2218);

  // Celestial Blue (Dark Mode)
  static const celestialBlue = blueGray600;
  static const celestialBlueMuted = blueGray800;
  static const celestialBlueLight = blueGray300;
  static const celestialBlueSurface = Color(0xFF1E282D);

  // Divine Gold (Dark Mode)
  static const divineGold = Color(0xFFE5B95C);
  static const darkGold = divineGold;
  static const goldUndertone = Color(0xFF7A602B);
  static const goldHighlight = Color(0xFFF3CF7A);
  static const goldSurface = Color(0xFF282012);
  static const darkGoldLight = goldSurface;

  // Text Hierarchy (Dark Mode)
  static const darkTextPrimary = blueGray50; // #ECEFF1 (Crisp off-white)
  static const darkTextSecondary = blueGray200; // #B0BEC5 (Soft silver slate)
  static const darkTextTertiary = blueGray400; // #78909C (Muted slate caption)
  static const darkTextDisabled = blueGray600; // #546E7A

  // Borders (Dark Mode)
  static const darkBorder = blueGray800; // #37474F
  static const darkDivider = Color(0xFF2E3C43);
  static const darkSeparator = blueGray800;

  // Accent Mapping (Dark Mode)
  static const darkSuccess = islamicGreenLight;
  static const darkSuccessLight = islamicGreenSurface;

  // Shimmer Colors
  static const shimmerBase = blueGray900;
  static const shimmerHighlight = blueGray800;
  static const shimmerBaseLight = blueGray100;
  static const shimmerHighlightLight = blueGray50;

  // Gradients (Dark Mode)
  static const premiumDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blueGray900, blueGray800],
  );

  static const islamicGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D4D36), Color(0xFF2E8B57)],
  );

  static const celestialGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blueGray900, blueGray700],
  );

  // Deprecated compatibility
  @Deprecated('Use darkPrimary instead')
  static const primaryNeon = blueGray300;
  @Deprecated('Use celestialBlueLight instead')
  static const blueNeon = blueGray300;
  @Deprecated('Removed')
  static const purpleNeon = blueGray700;
  @Deprecated('Removed')
  static const pinkNeon = Color(0xFF9E5A48);
  @Deprecated('Removed')
  static const orangeNeon = Color(0xFFB87333);
  @Deprecated('Use islamicGreenLight instead')
  static const greenNeon = Color(0xFF45A67D);
  @Deprecated('Use divineGold instead')
  static const yellowNeon = Color(0xFFE5B95C);

  @Deprecated('Use categoryLanguage instead')
  static const accentBlue = categoryLanguage;
  @Deprecated('Use success instead')
  static const accentGreen = success;
  @Deprecated('Use successMuted instead')
  static const accentSage = successMuted;
  @Deprecated('Use categoryFiqh instead')
  static const accentOrange = categoryFiqh;
  @Deprecated('Removed')
  static const accentPurple = categoryAqidah;
  @Deprecated('Use categorySeerah instead')
  static const accentPink = categorySeerah;
  @Deprecated('Use gold instead')
  static const accentYellow = gold;
}
