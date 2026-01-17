import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extension to get theme-aware colors based on current brightness
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Backgrounds
  Color get backgroundColor =>
      isDark ? AppColors.darkBackground : AppColors.background;
  Color get surfaceColor => isDark ? AppColors.darkSurface : AppColors.surface;
  Color get surfaceSecondaryColor =>
      isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary;
  Color get surfaceElevatedColor =>
      isDark ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated;
  Color get surfaceHoverColor =>
      isDark ? AppColors.darkSurfaceHover : AppColors.surfaceHover;
  Color get cardColor =>
      isDark ? AppColors.darkSurface : AppColors.cardBackground;

  // Text colors
  Color get textPrimaryColor =>
      isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get textSecondaryColor =>
      isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get textTertiaryColor =>
      isDark ? AppColors.darkTextTertiary : AppColors.textTertiary;

  // Primary colors
  Color get primaryColor => isDark ? AppColors.darkPrimary : AppColors.primary;
  Color get primaryLightColor =>
      isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight;

  // Borders
  Color get borderColor => isDark ? AppColors.darkBorder : AppColors.border;
  Color get dividerColor => isDark ? AppColors.darkDivider : AppColors.divider;

  // Success/Completed
  Color get successColor => isDark ? AppColors.darkSuccess : AppColors.success;
  Color get successLightColor =>
      isDark ? AppColors.darkSuccessLight : AppColors.successLight;

  // Gold/Accent
  Color get goldColor => isDark ? AppColors.darkGold : AppColors.gold;
  Color get goldLightColor =>
      isDark ? AppColors.darkGoldLight : AppColors.goldLight;
}
