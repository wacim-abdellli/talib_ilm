import 'package:flutter/material.dart';
import 'app_text_styles.dart';
import 'app_colors.dart';

class AppText {
  static TextStyle? title;

  static TextStyle get headlineLarge => AppTextStyles.title;
  static TextStyle get headline => AppTextStyles.sectionTitle;
  static TextStyle get sectionTitle => AppTextStyles.sectionTitle;
  static TextStyle get body => AppTextStyles.body;
  static TextStyle get bodyMuted =>
      AppTextStyles.body.copyWith(color: AppColors.textSecondary);
  static TextStyle get caption =>
      AppTextStyles.meta.copyWith(color: AppColors.textSecondary);
  static TextStyle get dhikrText => AppTextStyles.dhikr;
  static TextStyle get counterText => AppTextStyles.counter;
  static TextStyle get navigationLabel =>
      AppTextStyles.meta.copyWith(fontWeight: FontWeight.w500);

  static TextStyle get headingXL => AppTextStyles.title;
  static TextStyle get heading => AppTextStyles.sectionTitle;
  static TextStyle get athkarTitle => AppTextStyles.dhikr;
  static TextStyle get athkarBody => AppTextStyles.dhikr;
  static TextStyle get athkarCounter => AppTextStyles.counter;
  static TextStyle get button => AppTextStyles.button;

}
