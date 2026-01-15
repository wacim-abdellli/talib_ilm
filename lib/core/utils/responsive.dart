import 'package:flutter/material.dart';

class Responsive {
  final BuildContext context;

  Responsive(this.context);

  // Screen dimensions
  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;

  // Responsive width (percentage of screen)
  double wp(double percentage) => width * percentage / 100;

  // Responsive height (percentage of screen)
  double hp(double percentage) => height * percentage / 100;

  // Responsive font size (scales with screen width)
  double sp(double size) {
    const baseWidth = 375.0; // iPhone 11 Pro width as base
    return (width / baseWidth) * size;
  }

  // Safe padding (never causes overflow)
  double get safePadding => wp(4); // 4% of width
  double get safeHorizontalPadding => wp(4.3); // ~16px on 375px width
  double get safeVerticalPadding => hp(2);

  // Responsive spacing
  double get smallGap => hp(1); // ~8px
  double get mediumGap => hp(2); // ~16px
  double get largeGap => hp(3); // ~24px

  // Check screen size
  bool get isSmallScreen => width < 360;
  bool get isMediumScreen => width >= 360 && width < 400;
  bool get isLargeScreen => width >= 400;

  // Responsive card width
  double get cardWidth => wp(90); // 90% of screen width

  // Icon sizes
  double get smallIcon => sp(16);
  double get mediumIcon => sp(20);
  double get largeIcon => sp(24);
}
