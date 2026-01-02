import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  static const TextStyle headingXL = TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.6,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.6,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.7,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.7,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.textSecondary,
  );
}
