import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0E0F14);
  static const surface = Color(0xFF161822);

  static const primary = Color(0xFF6C5CE7);
  static const primaryAlt = Color(0xFF3B82F6);
  static const success = Color(0xFF2CBFA5);

  static const textPrimary = Color(0xFFE6E8F0);
  static const textSecondary = Color(0xFFA6A9B6);

  static const primaryGradient = LinearGradient(
    colors: [primary, primaryAlt],
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
  );
}
