import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'app_colors.dart';

export 'app_palette.dart';

/// Legacy ThemeColors extension shim.
/// @Deprecated: Use `context.palette` instead.
@Deprecated('Use context.palette instead')
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  AppPalette get _p => palette;

  Color get surfaceColor => _p.surface;
  Color get surfaceLowest => _p.surfaceMuted;
  Color get surfaceLow => _p.surfaceMuted;
  Color get surfaceContainer => _p.surface;
  Color get surfaceHigh => _p.surfaceRaised;
  Color get surfaceHighest => _p.surfaceRaised;
  Color get surfaceContainerLowest => _p.surfaceMuted;
  Color get surfaceContainerLow => _p.surfaceMuted;
  Color get surfaceContainerHigh => _p.surfaceRaised;
  Color get surfaceContainerHighest => _p.surfaceRaised;

  Color get backgroundColor => _p.bg;
  Color get surfaceSecondaryColor => _p.surfaceMuted;
  Color get surfaceElevatedColor => _p.surfaceRaised;
  Color get surfaceHoverColor => _p.border;
  Color get cardColor => _p.surface;
  Color get surfaceQuoteColor => _p.surfaceMuted;
  Color get surfaceLearningColor => _p.surface;

  Color get textPrimaryColor => _p.text;
  Color get textSecondaryColor => _p.textMuted;
  Color get textTertiaryColor => _p.textSubtle;
  Color get textDisabledColor => _p.text.withAlpha(97);

  Color get primaryColor => _p.primary;
  Color get onPrimaryColor => _p.onPrimary;
  Color get primaryContainer => _p.primarySoft;
  Color get onPrimaryContainer => _p.onPrimarySoft;
  Color get primaryLightColor => _p.onPrimarySoft;

  Color get borderColor => _p.border;
  Color get outlineColor => _p.border;
  Color get outlineVariantColor => _p.border;
  Color get dividerColor => _p.border;

  Color get successColor => _p.success;
  Color get successLightColor => isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);

  Color get goldColor => _p.gold;
  Color get goldLightColor => _p.goldSoft;

  Color get surfaceAnchorColor => _p.surfaceRaised;

  Color get islamicGreenColor => _p.primary;
  Color get islamicGreenMutedColor => _p.primary;
  Color get islamicGreenLightColor => _p.onPrimarySoft;
  Color get islamicGreenSurfaceColor => _p.primarySoft;

  Color get celestialBlueColor => const Color(0xFF0369A1);
  Color get celestialBlueMutedColor => const Color(0xFF0369A1);
  Color get celestialBlueLightColor => const Color(0xFF38BDF8);
  Color get celestialBlueSurfaceColor => isDark ? const Color(0xFF082F49) : const Color(0xFFE0F2FE);

  Color get prayerUndertone => _p.surfaceMuted;
  Color get learningUndertone => _p.surfaceMuted;
  Color get quoteUndertone => _p.surfaceMuted;

  Color get goldRingColor => _p.gold;

  Color get shimmerBaseColor => _p.surfaceMuted;
  Color get shimmerHighlightColor => _p.border;

  Color get errorColor => _p.error;
  Color get errorLightColor => _p.errorSoft;
  Color get errorColorMuted => _p.error;

  static const goldRingOpacity = 1.0;
}
