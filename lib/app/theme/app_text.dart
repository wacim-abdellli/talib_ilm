import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  /// UI text
  static const TextStyle ui = TextStyle(
    fontFamily: 'Vazirmatn',
    color: AppColors.textPrimary,
    fontSize: 14,
  );

  /// Headings
  static const TextStyle heading = TextStyle(
    fontFamily: 'Vazirmatn',
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  /// Reading text
  static const TextStyle reading = TextStyle(
    fontFamily: 'Amiri',
    color: AppColors.textPrimary,
    fontSize: 18,
    height: 1.9,
  );

  /// Secondary / muted text
  static const TextStyle secondary = TextStyle(
    fontFamily: 'Vazirmatn',
    color: AppColors.textSecondary,
    fontSize: 13,
  );
}
