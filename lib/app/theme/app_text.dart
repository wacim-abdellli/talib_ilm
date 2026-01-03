import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.7,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.7,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.7,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.85,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.85,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.7,
    color: AppColors.textMuted,
  );

  static const TextStyle dhikrText = TextStyle(
    fontFamily: 'Amiri',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 2.4,
  );

  static const TextStyle counterText = TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 48,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle navigationLabel = TextStyle(
    fontFamily: 'Vazirmatn',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle headingXL = headlineLarge;
  static const TextStyle heading = sectionTitle;
  static const TextStyle athkarTitle = dhikrText;
  static const TextStyle athkarBody = dhikrText;
  static const TextStyle athkarCounter = counterText;
}
