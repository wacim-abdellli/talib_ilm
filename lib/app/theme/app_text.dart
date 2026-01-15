import 'package:flutter/material.dart';
import 'app_text_styles.dart';
import 'app_colors.dart';

class AppText {
  static TextStyle get headlineLarge => AppTextStyles.heading1;
  static TextStyle get headline => AppTextStyles.heading2;
  static TextStyle get sectionTitle => AppTextStyles.heading2;
  static TextStyle get heading => AppTextStyles.heading2;
  static TextStyle get body => AppTextStyles.bodyMedium;
  static TextStyle get bodyLarge => AppTextStyles.bodyLarge;
  static TextStyle get bodySmall => AppTextStyles.bodySmall;
  static TextStyle get bodyMuted =>
      AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get caption => AppTextStyles.caption;
  static TextStyle get label => AppTextStyles.label;
  static TextStyle get dhikr => AppTextStyles.dhikrMedium;
  static TextStyle get counter => AppTextStyles.numberMedium;
  static TextStyle get navigationLabel =>
      AppTextStyles.label.copyWith(fontWeight: FontWeight.w500);
  static TextStyle get button => AppTextStyles.button;
  static TextStyle get cardTitle => AppTextStyles.cardTitle;
  static TextStyle get cardSubtitle => AppTextStyles.cardSubtitle;
  static TextStyle get athkarTitle => AppTextStyles.cardTitle;
  static TextStyle get athkarBody => AppTextStyles.bodyMedium;
  static TextStyle get athkarCounter => AppTextStyles.numberSmall;
  static TextStyle get statLabel => AppTextStyles.statLabel;
  static TextStyle get statNumber => AppTextStyles.statNumber;
}
