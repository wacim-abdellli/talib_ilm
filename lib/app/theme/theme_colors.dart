import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extension to get theme-aware colors based on current brightness
///
/// Semantic tokens for Spiritual Serenity luxury palette:
/// - Noble Emerald Teal for primary identity and navigation
/// - Andalusian Divine Gold for celestial halos and sacred milestones
/// - Warm Medina Ivory & Pure Alabaster for crisp light mode
/// - Twilight Sanctuary Midnight Slate-Teal for deep dark mode
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  ColorScheme get _cs => Theme.of(this).colorScheme;

  // ═══════════════════════════════════════════════════════════════════════
  // MATERIAL 3 SURFACE LADDER
  // ═══════════════════════════════════════════════════════════════════════

  /// Base surface (App Background)
  Color get surfaceColor => _cs.surface;

  /// Lowest surface (Recessed areas, search fields)
  Color get surfaceLowest => _cs.surfaceContainerLowest;

  /// Low surface (Recessed cards, quote cards)
  Color get surfaceLow => _cs.surfaceContainerLow;

  /// Standard container (Cards, lists, main content)
  Color get surfaceContainer => _cs.surfaceContainer;

  /// High container (Raised elements, hero cards)
  Color get surfaceHigh => _cs.surfaceContainerHigh;

  /// Highest container (Dialogs, floating sheets)
  Color get surfaceHighest => _cs.surfaceContainerHighest;

  /// Material 3 explicit container ladder aliases
  Color get surfaceContainerLowest => _cs.surfaceContainerLowest;
  Color get surfaceContainerLow => _cs.surfaceContainerLow;
  Color get surfaceContainerHigh => _cs.surfaceContainerHigh;
  Color get surfaceContainerHighest => _cs.surfaceContainerHighest;

  // ═══════════════════════════════════════════════════════════════════════
  // LEGACY SURFACE MAPPINGS (Backward compatibility)
  // ═══════════════════════════════════════════════════════════════════════
  Color get backgroundColor => _cs.surface;
  Color get surfaceSecondaryColor => _cs.surfaceContainerLow;
  Color get surfaceElevatedColor => _cs.surfaceContainerHighest;
  Color get surfaceHoverColor =>
      isDark ? AppColors.darkSurfaceHover : AppColors.surfaceHover;
  Color get cardColor => _cs.surfaceContainer;

  Color get surfaceQuoteColor => _cs.surfaceContainerLow;
  Color get surfaceLearningColor => _cs.surfaceContainer;

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
  // PRIMARY COLORS (Noble Emerald Teal)
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
  Color get outlineColor => _cs.outline;
  Color get outlineVariantColor => _cs.outlineVariant;
  Color get dividerColor => _cs.outlineVariant;

  // ═══════════════════════════════════════════════════════════════════════
  // SUCCESS / COMPLETED
  // ═══════════════════════════════════════════════════════════════════════
  Color get successColor => isDark ? AppColors.darkSuccess : AppColors.success;
  Color get successLightColor =>
      isDark ? AppColors.darkSuccessLight : AppColors.successLight;

  // ═══════════════════════════════════════════════════════════════════════
  // GOLD / ACCENT (Andalusian Divine Gold)
  // ═══════════════════════════════════════════════════════════════════════
  Color get goldColor => isDark ? AppColors.darkGold : AppColors.gold;
  Color get goldLightColor =>
      isDark ? AppColors.darkGoldLight : AppColors.goldLight;

  // ═══════════════════════════════════════════════════════════════════════
  // HIERARCHY TOKENS
  // ═══════════════════════════════════════════════════════════════════════
  Color get surfaceAnchorColor => _cs.surfaceContainerHigh;

  // ═══════════════════════════════════════════════════════════════════════
  // ISLAMIC SACRED GREEN
  // ═══════════════════════════════════════════════════════════════════════
  Color get islamicGreenColor =>
      isDark ? AppColors.islamicGreenLight : AppColors.islamicGreenPrimary;
  Color get islamicGreenMutedColor => AppColors.islamicGreenMuted;
  Color get islamicGreenLightColor => AppColors.islamicGreenLight;
  Color get islamicGreenSurfaceColor =>
      isDark ? AppColors.islamicGreenSurface : const Color(0xFFEFF8F3);

  // ═══════════════════════════════════════════════════════════════════════
  // CELESTIAL BLUE (Lapis / Night Reflection)
  // ═══════════════════════════════════════════════════════════════════════
  Color get celestialBlueColor => AppColors.celestialBlue;
  Color get celestialBlueMutedColor => AppColors.celestialBlueMuted;
  Color get celestialBlueLightColor => AppColors.celestialBlueLight;
  Color get celestialBlueSurfaceColor =>
      isDark ? AppColors.celestialBlueSurface : const Color(0xFFF0F5FA);

  // ═══════════════════════════════════════════════════════════════════════
  // SEMANTIC UNDERTONES
  // ═══════════════════════════════════════════════════════════════════════
  Color get prayerUndertone =>
      isDark ? AppColors.islamicGreenSurface : const Color(0xFFEFF8F3);
  Color get learningUndertone =>
      isDark ? const Color(0xFF142424) : const Color(0xFFF0F7F7);
  Color get quoteUndertone =>
      isDark ? AppColors.celestialBlueSurface : const Color(0xFFF2F6FA);

  // ═══════════════════════════════════════════════════════════════════════
  // GOLD RING & HIGHLIGHTS
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
      isDark ? const Color(0xFF321614) : AppColors.errorLight;
  Color get errorColorMuted =>
      isDark ? AppColors.errorMuted : const Color(0xFFE5BEBE);

  static const goldRingOpacity = 1.0;
}
