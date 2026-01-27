import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extension to get theme-aware colors based on current brightness
///
/// Semantic tokens for spiritual serenity palette:
/// - Islamic Green for prayer/sacred elements
/// - Celestial Blue for contemplation
/// - Divine Gold for spiritual light (rare, intentional)
/// Extension to get theme-aware colors based on current brightness
///
/// Semantic tokens for spiritual serenity palette:
/// - Islamic Green for prayer/sacred elements
/// - Celestial Blue for contemplation
/// - Divine Gold for spiritual light (rare, intentional)
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get _cs => Theme.of(this).colorScheme;

  // ═══════════════════════════════════════════════════════════════════════
  // MATERIAL 3 SURFACE LADDER (Use these for elevation)
  // ═══════════════════════════════════════════════════════════════════════

  /// Base surface (App Background)
  Color get surfaceColor => _cs.surface;

  /// Lowest surface (Quick Actions, recessed areas)
  Color get surfaceLowest => _cs.surfaceContainerLowest;

  /// Low surface (Quote cards, subtle cards)
  Color get surfaceLow => _cs.surfaceContainerLow;

  /// Standard container (Learning cards, primary content)
  Color get surfaceContainer => _cs.surfaceContainer;

  /// High container (Prayer Hero Anchor)
  Color get surfaceHigh => _cs.surfaceContainerHigh;

  /// Highest container (Dialogs, Floating sheets)
  Color get surfaceHighest => _cs.surfaceContainerHighest;

  // ═══════════════════════════════════════════════════════════════════════
  // LEGACY SURFACE MAPPINGS (For backward compatibility)
  // ═══════════════════════════════════════════════════════════════════════
  Color get backgroundColor => _cs.surface;
  Color get surfaceSecondaryColor => _cs.surfaceContainerLow;
  Color get surfaceElevatedColor => _cs.surfaceContainerHighest;
  Color get surfaceHoverColor =>
      isDark ? AppColors.darkSurfaceHover : AppColors.surfaceHover;
  Color get cardColor => _cs.surfaceContainer;

  Color get surfaceQuoteColor => _cs.surfaceContainerLow; // Mapped to Low
  Color get surfaceLearningColor => _cs.surfaceContainer; // Mapped to Standard

  // ═══════════════════════════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════════════════════════
  Color get textPrimaryColor => _cs.onSurface;
  Color get textSecondaryColor => _cs.onSurfaceVariant;
  Color get textTertiaryColor =>
      isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;
  Color get textDisabledColor =>
      isDark ? AppColors.darkTextDisabled : AppColors.textDisabled;

  // ═══════════════════════════════════════════════════════════════════════
  // PRIMARY COLORS
  // ═══════════════════════════════════════════════════════════════════════
  Color get primaryColor => _cs.primary;
  Color get onPrimaryColor => _cs.onPrimary;
  Color get primaryContainer => _cs.primaryContainer;
  Color get onPrimaryContainer => _cs.onPrimaryContainer;
  Color get primaryLightColor =>
      isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight;

  // ═══════════════════════════════════════════════════════════════════════
  // BORDERS
  // ═══════════════════════════════════════════════════════════════════════
  Color get borderColor => _cs.outline;
  Color get outlineVariantColor => _cs.outlineVariant;
  Color get dividerColor => _cs.outlineVariant;

  // ═══════════════════════════════════════════════════════════════════════
  // SUCCESS/COMPLETED
  // ═══════════════════════════════════════════════════════════════════════
  Color get successColor => isDark ? AppColors.darkSuccess : AppColors.success;
  Color get successLightColor =>
      isDark ? AppColors.darkSuccessLight : AppColors.successLight;

  // ═══════════════════════════════════════════════════════════════════════
  // GOLD/ACCENT - Divine Gold (Intentional, Rare)
  // ═══════════════════════════════════════════════════════════════════════
  Color get goldColor => isDark ? AppColors.darkGold : AppColors.gold;
  Color get goldLightColor =>
      isDark ? AppColors.darkGoldLight : AppColors.goldLight;

  // ═══════════════════════════════════════════════════════════════════════
  // HIERARCHY TOKENS - Wrapper for new M3 logic
  // ═══════════════════════════════════════════════════════════════════════

  /// Anchor surface - mapped to High container
  Color get surfaceAnchorColor => _cs.surfaceContainerHigh;

  // ═══════════════════════════════════════════════════════════════════════
  // ISLAMIC SACRED GREEN - Paradise & Life (Prayer/Sacred)
  // ═══════════════════════════════════════════════════════════════════════

  /// Primary Islamic green - for prayer indicators
  Color get islamicGreenColor => AppColors.islamicGreenPrimary;

  /// Muted green - for subtle undertones
  Color get islamicGreenMutedColor => AppColors.islamicGreenMuted;

  /// Light green - for highlights and accents
  Color get islamicGreenLightColor => AppColors.islamicGreenLight;

  /// Green surface - for green-tinted cards
  Color get islamicGreenSurfaceColor =>
      isDark ? AppColors.islamicGreenSurface : const Color(0xFFE8F5EE);

  // ═══════════════════════════════════════════════════════════════════════
  // CELESTIAL BLUE - Transcendence & Contemplation (Quote/Reflection)
  // ═══════════════════════════════════════════════════════════════════════

  /// Primary celestial blue
  Color get celestialBlueColor => AppColors.celestialBlue;

  /// Muted blue - for secondary elements
  Color get celestialBlueMutedColor => AppColors.celestialBlueMuted;

  /// Light blue - for highlights
  Color get celestialBlueLightColor => AppColors.celestialBlueLight;

  /// Blue surface - for blue-tinted cards
  Color get celestialBlueSurfaceColor =>
      isDark ? AppColors.celestialBlueSurface : const Color(0xFFF0F4FA);

  // ═══════════════════════════════════════════════════════════════════════
  // SEMANTIC UNDERTONES
  // ═══════════════════════════════════════════════════════════════════════

  /// Prayer undertone
  Color get prayerUndertone =>
      isDark ? AppColors.islamicGreenMuted : const Color(0xFFE8F5EE);

  /// Learning undertone
  Color get learningUndertone =>
      isDark ? AppColors.celestialBlue : const Color(0xFFF0F0FA);

  /// Quote undertone
  Color get quoteUndertone =>
      isDark ? AppColors.celestialBlueMuted : const Color(0xFFF5F5FB);

  // ═══════════════════════════════════════════════════════════════════════
  // GOLD RING
  // ═══════════════════════════════════════════════════════════════════════
  Color get goldRingColor => goldColor.withValues(alpha: isDark ? 0.8 : 0.7);

  // ═══════════════════════════════════════════════════════════════════════
  // SHIMMER COLORS
  // ═══════════════════════════════════════════════════════════════════════
  Color get shimmerBaseColor =>
      isDark ? AppColors.shimmerBase : AppColors.shimmerBaseLight;
  Color get shimmerHighlightColor =>
      isDark ? AppColors.shimmerHighlight : AppColors.shimmerHighlightLight;

  // ═══════════════════════════════════════════════════════════════════════
  // ERROR COLOR
  // ═══════════════════════════════════════════════════════════════════════
  Color get errorColor => _cs.error;
  Color get errorLightColor =>
      isDark ? const Color(0xFF3D1515) : AppColors.errorLight;
  Color get errorColorMuted =>
      isDark ? AppColors.errorMuted : const Color(0xFFE5BEBE);

  // ═══════════════════════════════════════════════════════════════════════
  // CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════
  static const goldRingOpacity = 1.0;
}
