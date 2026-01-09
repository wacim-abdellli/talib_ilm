import 'package:flutter/material.dart';

class AppColors {
  // ✅ Base palette (Warm, Quranly-inspired light theme)
  static const background = Color(0xFFF7F2E9);
  static const surface = Color(0xFFFFFDF8);
  static const primary = Color(0xFF5B4BB7);
  static const accent = Color(0xFF2AA79B);
  static const textPrimary = Color(0xFF1B1A16);
  static const textSecondary = Color(0xFF6B6257);
  static const clear = Color(0x00000000);

  // ✅ NEW: Elevated layer (cards that should feel above surface)
  // Slightly warmer tint than surface for separation
  static const surfaceElevated = Color(0xFFFFF4E8);

  // ✅ NEW: Border / stroke color (so cards don't look flat)
  static Color get stroke => textPrimary.withValues(alpha: 0.08);

  // ✅ NEW: Subtle divider
  static Color get divider => textPrimary.withValues(alpha: 0.10);

  // ✅ NEW: Overlay for pressed/hover states
  static Color get overlay => textPrimary.withValues(alpha: 0.06);

  // ✅ Text helpers
  static Color get textMuted => textSecondary;

  // ✅ NEW: Home hero gradient (for "alive" feeling)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF5B4BB7),
      Color(0xFF7B63E5),
    ],
  );
}
