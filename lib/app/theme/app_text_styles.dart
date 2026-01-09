import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Cairo';

  // ─────────────────────────────
  // Titles / headings
  // ─────────────────────────────

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18, // ⬅ reduced (was heavy)
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.45,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────
  // Body
  // ─────────────────────────────

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textPrimary,
  );

  static const TextStyle meta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // ─────────────────────────────
  // Dhikr / Quran text (CRITICAL)
  // ─────────────────────────────

  static const TextStyle dhikr = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20, // ⬅ WAS TOO BIG → FIXED
    fontWeight: FontWeight.w500, // calmer
    height: 1.9, // reading comfort
    color: Color.fromARGB(255, 0, 0, 0),
  );

  // ─────────────────────────────
  // Counter
  // ─────────────────────────────

  static const TextStyle counter = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32, // ⬅ reduced
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────
  // Buttons
  // ─────────────────────────────

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // ─────────────────────────────
  // TextTheme (Material)
  // ─────────────────────────────

  static TextTheme get textTheme => const TextTheme(
        titleLarge: title,
        titleMedium: sectionTitle,
        bodyLarge: body,
        bodyMedium: body,
        labelLarge: button,
        labelMedium: meta,
        labelSmall: meta,
      );
}
