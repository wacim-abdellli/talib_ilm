import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppUi {
  static const double radiusSM = 10;
  static const double radiusMD = 16;
  static const double radiusLG = 22;

  static const double paddingSM = 8;
  static const double paddingMD = 16;
  static const double paddingLG = 24;

  static const Duration animationFast = Duration(milliseconds: 160);
  static const Duration animationNormal = Duration(milliseconds: 240);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.background.withValues(alpha: 0.28),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
}
