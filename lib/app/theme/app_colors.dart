import 'package:flutter/material.dart';

/// App Colors - Spiritual Serenity Luxury Islamic Palette
///
/// Design Philosophy:
/// - Noble Emerald Teal: Wisdom, contemplation, serenity
/// - Andalusian Divine Gold: Celestial light, milestones, sacred borders
/// - Warm Medina Ivory (Light): Crisp alabaster sheets on warm parchment
/// - Twilight Sanctuary (Dark): Deep midnight slate-teal, reducing eye strain
/// - Classical Manuscript Pigments: Mineral tones (malachite, terracotta, ochre, lapis)
class AppColors {
  // ═══════════════════════════════════════════════════════════════════════
  // PRIMARY - Noble Emerald Teal
  // ═══════════════════════════════════════════════════════════════════════
  static const primary = Color(0xFF2C6B6B); // Deep noble teal (Light mode)
  static const primaryDark = Color(0xFF1E5252);
  static const primaryLight = Color(0xFF4A8E8E);
  static const primaryContainerLight = Color(0xFFE4F0F0);

  // ═══════════════════════════════════════════════════════════════════════
  // SECONDARY - Andalusian Divine Gold
  // ═══════════════════════════════════════════════════════════════════════
  static const accent = Color(0xFFC59533); // Rich honeyed gold (Light mode)
  static const accentGold = accent;
  static const gold = accent;
  static const goldLight = Color(0xFFFFF9EE); // Soft warm gold tint
  static const goldDark = Color(0xFF9E721D); // Rich antique gold
  static const goldGlow = Color(0xFFDDB455);

  // ═══════════════════════════════════════════════════════════════════════
  // LIGHT BACKGROUNDS - Warm Medina Ivory & Pure Alabaster
  // ═══════════════════════════════════════════════════════════════════════
  static const background = Color(0xFFFAF8F5); // Warm ivory canvas
  static const surface = Color(0xFFFAF8F5); // App base
  static const surfaceWarmIvory = Color(0xFFFAF8F5);
  static const warmIvoryContainer = Color(0xFFFFF9EE);
  static const surfaceSecondary = Color(0xFFF3EFE8); // Recessed areas
  static const surfaceElevated = Color(0xFFFFFFFF); // Pure crisp white cards
  static const surfaceHover = Color(0xFFF5F1E9);
  static const cardBackground = Color(0xFFFFFFFF); // Cards are crisp white

  // ═══════════════════════════════════════════════════════════════════════
  // SUCCESS - Refined Emerald (Never harsh green)
  // ═══════════════════════════════════════════════════════════════════════
  static const success = Color(0xFF2E8B57); // Sea emerald
  static const successLight = Color(0xFFEFF8F3);
  static const successMuted = Color(0xFF5B9974);

  // ═══════════════════════════════════════════════════════════════════════
  // TEXT - Slate Charcoal (Light Mode)
  // ═══════════════════════════════════════════════════════════════════════
  static const textPrimary = Color(0xFF1E2827); // Deep teal-slate charcoal
  static const textSecondary = Color(0xFF5E6B69); // Muted slate
  static const textTertiary = Color(0xFF8E9B99); // Caption grey
  static const textDisabled = Color(0xFFB5BEBC);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // ═══════════════════════════════════════════════════════════════════════
  // BORDERS (Light Mode) - Warm Sand
  // ═══════════════════════════════════════════════════════════════════════
  static const border = Color(0xFFE8E2D6);
  static const divider = Color(0xFFEFEBE2);
  static const separator = Color(0xFFE8E2D6);
  static const stroke = border;

  // ═══════════════════════════════════════════════════════════════════════
  // SCHOLARLY CATEGORY COLORS - Classical Mineral Pigments (No candy neon!)
  // ═══════════════════════════════════════════════════════════════════════
  static const categoryAqidah = Color(0xFF2C6B6B); // Noble Teal (عقيدة)
  static const categoryQuran = Color(0xFFC59533); // Andalusian Gold (قرآن وتفسير)
  static const categoryHadith = Color(0xFF2E8B57); // Medina Emerald (حديث)
  static const categoryFiqh = Color(0xFFB87333); // Warm Ochre (فقه)
  static const categorySeerah = Color(0xFF9E5A48); // Sandalwood Terracotta (سيرة)
  static const categoryLanguage = Color(0xFF3E6888); // Lapis Slate (لغة وأدب)

  // ═══════════════════════════════════════════════════════════════════════
  // PRAYER COLORS - Natural Atmospheric Tones
  // ═══════════════════════════════════════════════════════════════════════
  static const fajr = Color(0xFF5B7B9A); // Twilight slate blue
  static const sunrise = Color(0xFFD49D42); // Warm morning gold
  static const dhuhr = Color(0xFF3E8899); // Noon cyan teal
  static const asr = Color(0xFFC48448); // Golden afternoon amber
  static const maghrib = Color(0xFFA85C52); // Dusk terracotta
  static const isha = Color(0xFF4A5D80); // Night sapphire

  // ═══════════════════════════════════════════════════════════════════════
  // STATES - Semantic Colors
  // ═══════════════════════════════════════════════════════════════════════
  static const error = Color(0xFFC24136); // Muted crimson
  static const errorLight = Color(0xFFFDF2F1);
  static const warning = Color(0xFFD97706); // Amber
  static const warningLight = Color(0xFFFEF9EE);
  static const info = Color(0xFF2A7B9B); // Lapis
  static const infoLight = Color(0xFFF0F7FA);

  // ═══════════════════════════════════════════════════════════════════════
  // SHADOWS
  // ═══════════════════════════════════════════════════════════════════════
  static final shadow = const Color(0xFF1E2827).withValues(alpha: 0.04);
  static final shadowMedium = const Color(0xFF1E2827).withValues(alpha: 0.08);

  // ═══════════════════════════════════════════════════════════════════════
  // ICON COLORS
  // ═══════════════════════════════════════════════════════════════════════
  static const iconPrimary = primary;
  static const iconMuted = Color(0xFF8E9B99);
  static const iconLight = Color(0xFFB5BEBC);

  // ═══════════════════════════════════════════════════════════════════════
  // GRADIENTS - Light Mode
  // ═══════════════════════════════════════════════════════════════════════
  static const primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [primary, primaryLight],
  );

  static const tealMintGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF2C6B6B), Color(0xFF4A8E8E)],
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
    colors: [Colors.white, Color(0xFFFAF8F5)],
  );

  static const surfaceElevatedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFFAF8F5)],
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
  // DARK THEME - TWILIGHT SANCTUARY PALETTE
  // ═══════════════════════════════════════════════════════════════════════
  //
  // Design Philosophy:
  // - Deep midnight slate-teal #0F1717 base (NOT generic dead gray)
  // - Luminous Seafoam Teal #4DB6AC for calming, high-contrast actions
  // - Celestial Andalusian Gold #E5B95C for sacred accents
  // - Elevation expressed through layered midnight slate containers
  // ═══════════════════════════════════════════════════════════════════════

  // Dark Backgrounds (Midnight Slate-Teal Elevation Hierarchy)
  static const darkBackground = Color(0xFF0F1717); // Base Sanctuary
  static const darkSurface = Color(0xFF0F1717); // Scaffold base
  static const darkSurfaceSecondary = Color(0xFF162222); // Card surface
  static const darkSurfaceContainer = darkSurfaceSecondary;
  static const darkSurfaceElevated = Color(0xFF243636); // Dialogs / Sheets
  static const darkSurfaceContainerHigh = darkSurfaceElevated;
  static const darkSurfaceHover = Color(0xFF1E2D2D);
  static const darkSurfaceQuote = Color(0xFF142028); // Subtle lapis undertone
  static const darkSurfaceLearning = Color(0xFF162222);
  static const errorMuted = Color(0xFF9E3D35);

  // Primary Luminous Teal (Dark Mode)
  static const darkPrimary = Color(0xFF4DB6AC); // Luminous seafoam teal
  static const darkPrimaryLight = Color(0xFF234444); // Subdued container teal
  static const darkPrimaryContainer = Color(0xFF1A3838);

  // Sacred Emerald (Dark Mode)
  static const islamicGreenPrimary = Color(0xFF2E8B57); // Sea emerald
  static const islamicGreenMuted = Color(0xFF1D4D36);
  static const islamicGreenLight = Color(0xFF45A67D);
  static const darkIslamicGreen = islamicGreenLight;
  static const islamicGreenDark = Color(0xFF133624);
  static const islamicGreenSurface = Color(0xFF0E2218);

  // Celestial Blue / Lapis (Dark Mode)
  static const celestialBlue = Color(0xFF2E5370);
  static const celestialBlueMuted = Color(0xFF1F374A);
  static const celestialBlueLight = Color(0xFF588CAE);
  static const celestialBlueSurface = Color(0xFF0E1A22);

  // Divine Gold (Dark Mode)
  static const divineGold = Color(0xFFE5B95C); // Luminous celestial gold
  static const darkGold = divineGold;
  static const goldUndertone = Color(0xFF7A602B);
  static const goldHighlight = Color(0xFFF3CF7A);
  static const goldSurface = Color(0xFF282012); // Deep gold-tinted surface
  static const darkGoldLight = goldSurface;

  // Text Hierarchy (Dark Mode) - Crisp glowing off-white
  static const darkTextPrimary = Color(0xFFF1F5F4); // Crisp, non-blinding off-white
  static const darkTextSecondary = Color(0xFF98ACA9); // Soft sage-silver
  static const darkTextTertiary = Color(0xFF6B7E7B); // Muted caption text
  static const darkTextDisabled = Color(0xFF475654);

  // Borders (Dark Mode) - Luminous Midnight Slate
  static const darkBorder = Color(0xFF263939); // Subtle luminous edge
  static const darkDivider = Color(0xFF1E2D2D);
  static const darkSeparator = Color(0xFF263939);

  // Accent Mapping (Dark Mode)
  static const darkSuccess = islamicGreenLight;
  static const darkSuccessLight = islamicGreenSurface;

  // Shimmer Colors (for loading states)
  static const shimmerBase = Color(0xFF162222);
  static const shimmerHighlight = Color(0xFF223434);
  static const shimmerBaseLight = Color(0xFFF3EFE8);
  static const shimmerHighlightLight = Color(0xFFFAF8F5);

  // Gradients (Dark Mode)
  static const premiumDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkSurfaceSecondary, Color(0xFF1C2C2C)],
  );

  static const islamicGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D4D36), Color(0xFF2E8B57)],
  );

  static const celestialGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F374A), Color(0xFF2E5370)],
  );

  // Deprecated - kept for backwards compatibility
  @Deprecated('Use darkPrimary instead')
  static const primaryNeon = Color(0xFF4DB6AC);
  @Deprecated('Use celestialBlueLight instead')
  static const blueNeon = Color(0xFF588CAE);
  @Deprecated('Removed')
  static const purpleNeon = Color(0xFF2C6B6B);
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
