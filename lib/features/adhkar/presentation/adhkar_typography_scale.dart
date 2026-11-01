import 'package:flutter/foundation.dart';

abstract final class AdhkarTypographyScale {
  static const double minimum = 0.70;
  static const double maximum = 1.60;
  static const double step = 0.15;

  static const List<double> presets = [
    0.70,
    0.75,
    0.80,
    0.85,
    0.90,
    1.00,
    1.15,
    1.30,
    1.45,
    1.60,
  ];

  static double get defaultScale =>
      defaultTargetPlatform == TargetPlatform.iOS ? 0.70 : 0.85;
}
