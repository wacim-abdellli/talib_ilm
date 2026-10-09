import 'package:flutter/material.dart';

/// App Colors - Option 1: Celestial Oasis (Luxury Islamic Aesthetic)
///
/// Design Philosophy:
/// - Deep Midnight Obsidian (#0A0E13): OLED-grade contrast, allowing jewel tones to radiate.
/// - Luminous Medina Emerald (#10B981): Sacred vitality, life, peace, and serenity.
/// - Andalusian Honey Gold (#F59E0B / #FBBF24): Celestial halos, prayer rings, and Quranic bookmarks.
/// - Celestial Azure (#0EA5E9): Navigation, Qibla compass, and astrolabe sky.
/// - Royal Violet & Terracotta: Scholarly Mutun depth and Sandalwood warmth.
/// - High-Contrast Typographic Hierarchy: Pure glowing off-white in dark mode, crisp deep slate in light.
class AppColors {
  // ═══════════════════════════════════════════════════════════════════════
  // PRIMARY IDENTITY - Luminous Medina Emerald
  // ═══════════════════════════════════════════════════════════════════════
  static const primary = Color(0xFF0D9488); // Deep vibrant teal (Light mode)
  static const primaryDark = Color(0xFF0F766E);
  static const primaryLight = Color(0xFF14B8A6);
  static const primaryContainerLight = Color(0xFFCCFBF1);

  // Dark Mode Primary (Luminous Emerald - pops like a jewel)
  static const darkPrimary = Color(0xFF10B981);
  static const darkPrimaryLight = Color(0xFF34D399);
  static const darkPrimaryContainer = Color(0xFF064E3B);

  // ═══════════════════════════════════════════════════════════════════════
  // SECONDARY - Andalusian Honey Gold
  // ═══════════════════════════════════════════════════════════════════════
  static const accent = Color(0xFFF59E0B);
  static const accentGold = accent;
  static const gold = accent;
  static const goldLight = Color(0xFFFEF3C7);
  static const goldDark = Color(0xFFD97706);
  static const goldGlow = Color(0xFFFBBF24);

  // Dark Mode Gold
  static const divineGold = Color(0xFFFBBF24);
  static const darkGold = divineGold;
  static const darkGoldLight = Color(0xFF451A03);
  static const goldHighlight = Color(0xFFFDE68A);
  static const goldUndertone = Color(0xFF78350F);
  static const goldSurface = Color(0xFF1C1306);

  // ═══════════════════════════════════════════════════════════════════════
  // JEWEL ACCENTS (For Bento Quick Action Portals & Badges)
  // ═══════════════════════════════════════════════════════════════════════
  // 1. Holy Quran (Honey Gold)
  static const jewelQuran = Color(0xFFF59E0B);
  static const jewelQuranDark = Color(0xFFD97706);

  // 2. Sacred Ilm & Mutun (Royal Teal / Amethyst)
  static const jewelIlm = Color(0xFF0D9488);
  static const jewelIlmDark = Color(0xFF0F766E);
  static const royalViolet = Color(0xFF8B5CF6);
  static const royalVioletLight = Color(0xFFA78BFA);

  // 3. Adhkar & Remembrance (Luminous Emerald)
  static const jewelAdhkar = Color(0xFF10B981);
  static const jewelAdhkarDark = Color(0xFF059669);

  // 4. Qibla & Astrolabe (Celestial Azure)
  static const jewelQibla = Color(0xFF0EA5E9);
  static const jewelQiblaDark = Color(0xFF0284C7);

  // ═══════════════════════════════════════════════════════════════════════
  // LIGHT BACKGROUNDS & SURFACES - Clean Snow & Pure Alabaster
  // ═══════════════════════════════════════════════════════════════════════
  static const background = Color(0xFFF8FAFC); // Clean pale ice canvas
  static const surface = Color(0xFFF8FAFC);
  static const surfaceWarmIvory = Color(0xFFF8FAFC);
  static const warmIvoryContainer = Color(0xFFF1F5F9);
  static const surfaceSecondary = Color(0xFFF1F5F9); // Recessed areas
  static const surfaceElevated = Colors.white; // Crisp pure white cards
  static const surfaceHover = Color(0xFFE2E8F0);
  static const cardBackground = Colors.white;

  // Light Borders
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFE2E8F0);
  static const separator = Color(0xFFE2E8F0);
  static const stroke = border;

  // Light Text
  static const textPrimary = Color(0xFF0F172A); // Crisp deep slate
  static const textSecondary = Color(0xFF475569); // Readable medium slate
  static const textTertiary = Color(0xFF94A3B8); // Muted slate caption
  static const textDisabled = Color(0xFFCBD5E1);
  static const textOnPrimary = Colors.white;

  // ═══════════════════════════════════════════════════════════════════════
  // DARK THEME - DEEP MIDNIGHT OBSIDIAN & LAYERED JEWEL SURFACES
  // ═══════════════════════════════════════════════════════════════════════
  static const darkBackground = Color(0xFF0A0E13); // Deepest Midnight Obsidian
  static const darkSurface = Color(0xFF0A0E13);
  static const darkSurfaceSecondary = Color(0xFF12181F); // Card Container
  static const darkSurfaceContainer = Color(0xFF12181F);
  static const darkSurfaceElevated = Color(0xFF1A232C); // Sheets / Dialogs
  static const darkSurfaceContainerHigh = Color(0xFF1A232C);
  static const darkSurfaceHover = Color(0xFF222E3A);
  static const darkSurfaceQuote = Color(0xFF141F28);
  static const darkSurfaceLearning = Color(0xFF12181F);

  // Dark Borders
  static const darkBorder = Color(0xFF22303C); // Sleek subtle border
  static const darkDivider = Color(0xFF1C2731);
  static const darkSeparator = Color(0xFF22303C);

  // Dark Text (Luminous, Glowing Legibility)
  static const darkTextPrimary = Color(0xFFF8FAFC); // Crisp off-white
  static const darkTextSecondary = Color(0xFF94A3B8); // Silver slate
  static const darkTextTertiary = Color(0xFF64748B); // Muted caption
  static const darkTextDisabled = Color(0xFF475569);

  // ═══════════════════════════════════════════════════════════════════════
  // SCHOLARLY CATEGORIES (Classical Minerals with Radiant Punch)
  // ═══════════════════════════════════════════════════════════════════════
  static const categoryAqidah = Color(0xFF0D9488); // Teal
  static const categoryQuran = Color(0xFFF59E0B); // Honey Gold
  static const categoryHadith = Color(0xFF10B981); // Medina Emerald
  static const categoryFiqh = Color(0xFF8B5CF6); // Royal Violet
  static const categorySeerah = Color(0xFFF97316); // Sandalwood Terracotta
  static const categoryLanguage = Color(0xFF0EA5E9); // Celestial Azure

  // ═══════════════════════════════════════════════════════════════════════
  // CELESTIAL PRAYER COLORS
  // ═══════════════════════════════════════════════════════════════════════
  static const fajr = Color(0xFF6366F1); // Indigo dawn
  static const sunrise = Color(0xFFF59E0B); // Morning honey
  static const dhuhr = Color(0xFF0EA5E9); // Clear noon cyan
  static const asr = Color(0xFFF97316); // Afternoon amber
  static const maghrib = Color(0xFFE11D48); // Sunset rose
  static const isha = Color(0xFF8B5CF6); // Night sapphire violet

  // ═══════════════════════════════════════════════════════════════════════
  // STATES - Semantic Colors
  // ═══════════════════════════════════════════════════════════════════════
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFD1FAE5);
  static const successMuted = Color(0xFF059669);
  static const darkSuccess = Color(0xFF34D399);
  static const darkSuccessLight = Color(0xFF064E3B);

  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const errorMuted = Color(0xFFB91C1C);

  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);

  static const info = Color(0xFF0EA5E9);
  static const infoLight = Color(0xFFE0F2FE);

  // Sacred Green & Celestial Blue aliases
  static const islamicGreenPrimary = Color(0xFF10B981);
  static const islamicGreenLight = Color(0xFF34D399);
  static const islamicGreenMuted = Color(0xFF059669);
  static const darkIslamicGreen = Color(0xFF34D399);
  static const islamicGreenDark = Color(0xFF064E3B);
  static const islamicGreenSurface = Color(0xFF022C22);

  static const celestialBlue = Color(0xFF0EA5E9);
  static const celestialBlueLight = Color(0xFF38BDF8);
  static const celestialBlueMuted = Color(0xFF0284C7);
  static const celestialBlueSurface = Color(0xFF082F49);

  // ═══════════════════════════════════════════════════════════════════════
  // SHADOWS & AMBIENT GLOWS
  // ═══════════════════════════════════════════════════════════════════════
  static final shadow = Colors.black.withValues(alpha: 0.05);
  static final shadowMedium = Colors.black.withValues(alpha: 0.1);

  // ═══════════════════════════════════════════════════════════════════════
  // ICON COLORS
  // ═══════════════════════════════════════════════════════════════════════
  static const iconPrimary = primary;
  static const iconMuted = Color(0xFF94A3B8);
  static const iconLight = Color(0xFFCBD5E1);

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER COLORS
  // ═══════════════════════════════════════════════════════════════════════
  static const shimmerBase = Color(0xFF12181F);
  static const shimmerHighlight = Color(0xFF1A232C);
  static const shimmerBaseLight = Color(0xFFE2E8F0);
  static const shimmerHighlightLight = Color(0xFFF8FAFC);

  // ═══════════════════════════════════════════════════════════════════════
  // GRADIENTS
  // ═══════════════════════════════════════════════════════════════════════
  static const primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF0D9488), Color(0xFF10B981)],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  static const premiumDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF12181F), Color(0xFF1A232C)],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFF8FAFC)],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
  );

  static const surfaceElevatedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFF8FAFC)],
  );

  static const tealMintGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
  );

  static const islamicGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF064E3B), Color(0xFF10B981)],
  );

  static const celestialGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF082F49), Color(0xFF0EA5E9)],
  );

  // Compatibility aliases
  static const blueGray50 = Color(0xFFF8FAFC);
  static const blueGray100 = Color(0xFFE2E8F0);
  static const blueGray200 = Color(0xFFCBD5E1);
  static const blueGray300 = Color(0xFF94A3B8);
  static const blueGray400 = Color(0xFF64748B);
  static const blueGray500 = Color(0xFF475569);
  static const blueGray600 = Color(0xFF334155);
  static const blueGray700 = Color(0xFF1E293B);
  static const blueGray800 = Color(0xFF0F172A);
  static const blueGray900 = Color(0xFF020617);

  static const categoryArabic = categoryLanguage;
  static const black = textPrimary;
  static const secondary = primaryLight;
  static const surfaceVariant = surfaceSecondary;
  static const textMuted = textTertiary;
  static const clear = Colors.transparent;
}
