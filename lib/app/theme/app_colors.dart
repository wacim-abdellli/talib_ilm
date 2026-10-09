import 'package:flutter/material.dart';
import 'app_palette.dart';

export 'app_palette.dart';

/// Legacy color access shim.
/// Use [AppPalette] via `context.palette` instead.
@Deprecated('Use AppPalette via context.palette')
class AppColors {
  // Primary
  static const primary = Color(0xFF0F766E);
  static const primaryDark = Color(0xFF0F766E);
  static const primaryLight = Color(0xFF14B8A6);
  static const primaryContainerLight = Color(0xFFCCFBF1);

  static const darkPrimary = Color(0xFF10B981);
  static const darkPrimaryLight = Color(0xFF34D399);
  static const darkPrimaryContainer = Color(0xFF064E3B);

  // Gold / Accent
  static const accent = Color(0xFFF59E0B);
  static const accentGold = accent;
  static const gold = accent;
  static const goldLight = Color(0xFFFEF3C7);
  static const goldDark = Color(0xFFB45309);
  static const goldGlow = Color(0xFFFBBF24);

  static const divineGold = Color(0xFFFBBF24);
  static const darkGold = divineGold;
  static const darkGoldLight = Color(0xFF451A03);
  static const goldHighlight = Color(0xFFFDE68A);
  static const goldUndertone = Color(0xFF78350F);
  static const goldSurface = Color(0xFF1C1306);

  // Jewel Accents (Mapped to unified palette)
  static const jewelQuran = Color(0xFFF59E0B);
  static const jewelQuranDark = Color(0xFFB45309);
  static const jewelIlm = Color(0xFF0F766E);
  static const jewelIlmDark = Color(0xFF0F766E);
  static const royalViolet = Color(0xFF6D28D9);
  static const royalVioletLight = Color(0xFFA78BFA);
  static const jewelAdhkar = Color(0xFF047857);
  static const jewelAdhkarDark = Color(0xFF064E3B);
  static const jewelQibla = Color(0xFF0369A1);
  static const jewelQiblaDark = Color(0xFF082F49);

  // Light Canvas & Surfaces
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarmIvory = Color(0xFFF8FAFC);
  static const warmIvoryContainer = Color(0xFFF1F5F9);
  static const surfaceSecondary = Color(0xFFF1F5F9);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const surfaceHover = Color(0xFFE2E8F0);
  static const cardBackground = Color(0xFFFFFFFF);

  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFE2E8F0);
  static const separator = Color(0xFFE2E8F0);
  static const stroke = border;

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textTertiary = Color(0xFF64748B);
  static const textDisabled = Color(0x610F172A); // 38% opacity
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Dark Canvas & Surfaces
  static const darkBackground = Color(0xFF0A0E13);
  static const darkSurface = Color(0xFF12181F);
  static const darkSurfaceSecondary = Color(0xFF12181F);
  static const darkSurfaceContainer = Color(0xFF12181F);
  static const darkSurfaceElevated = Color(0xFF1A232C);
  static const darkSurfaceContainerHigh = Color(0xFF1A232C);
  static const darkSurfaceHover = Color(0xFF22303C);
  static const darkSurfaceQuote = Color(0xFF12181F);
  static const darkSurfaceLearning = Color(0xFF12181F);

  static const darkBorder = Color(0xFF22303C);
  static const darkDivider = Color(0xFF22303C);
  static const darkSeparator = Color(0xFF22303C);

  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);
  static const darkTextTertiary = Color(0xFF8A9BB0);
  static const darkTextDisabled = Color(0x61F8FAFC); // 38% opacity

  // Categories
  static const categoryAqidah = Color(0xFF0F766E);
  static const categoryQuran = Color(0xFF92400E);
  static const categoryHadith = Color(0xFF6D28D9);
  static const categoryFiqh = Color(0xFF047857);
  static const categorySeerah = Color(0xFF9A3412);
  static const categoryLanguage = Color(0xFF0369A1);
  static const categoryArabic = categoryLanguage;

  // Prayers
  static const fajr = Color(0xFF4F46E5);
  static const sunrise = Color(0xFFB45309);
  static const dhuhr = Color(0xFF0284C7);
  static const asr = Color(0xFFEA580C);
  static const maghrib = Color(0xFFE11D48);
  static const isha = Color(0xFF7C3AED);

  // States
  static const success = Color(0xFF047857);
  static const successLight = Color(0xFFDCFCE7);
  static const successMuted = Color(0xFF065F46);
  static const darkSuccess = Color(0xFF34D399);
  static const darkSuccessLight = Color(0xFF064E3B);

  static const error = Color(0xFFB91C1C);
  static const errorLight = Color(0xFFFEE2E2);
  static const errorMuted = Color(0xFF991B1B);

  static const warning = Color(0xFFB45309);
  static const warningLight = Color(0xFFFEF3C7);

  static const info = Color(0xFF0369A1);
  static const infoLight = Color(0xFFE0F2FE);

  // Aliases
  static const islamicGreenPrimary = primary;
  static const islamicGreenLight = Color(0xFF34D399);
  static const islamicGreenMuted = Color(0xFF047857);
  static const darkIslamicGreen = darkPrimary;
  static const islamicGreenDark = Color(0xFF064E3B);
  static const islamicGreenSurface = Color(0xFF022C22);

  static const celestialBlue = Color(0xFF0369A1);
  static const celestialBlueLight = Color(0xFF38BDF8);
  static const celestialBlueMuted = Color(0xFF0284C7);
  static const celestialBlueSurface = Color(0xFF082F49);

  // Shadows
  static const shadow = Color(0x0A000000);
  static const shadowMedium = Color(0x14000000);

  // Clear / Transparent
  static const clear = Colors.transparent;
  static const transparent = Colors.transparent;

  // Icons
  static const iconPrimary = primary;
  static const iconMuted = textSecondary;
  static const iconLight = textTertiary;

  // Shimmer
  static const shimmerBase = Color(0xFF12181F);
  static const shimmerHighlight = Color(0xFF1A232C);
  static const shimmerBaseLight = Color(0xFFF1F5F9);
  static const shimmerHighlightLight = Color(0xFFE2E8F0);

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF0F766E), Color(0xFF10B981)],
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
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
  );

  static const islamicGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF064E3B), Color(0xFF10B981)],
  );

  static const celestialGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF082F49), Color(0xFF0369A1)],
  );

  // Additional Compatibility Aliases
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

  static const black = textPrimary;
  static const secondary = primaryLight;
  static const surfaceVariant = surfaceSecondary;
  static const textMuted = textTertiary;
}
