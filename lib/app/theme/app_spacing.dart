import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double gapXXS = 2;
  static const double gapXXSPlus = 3;
  static const double gapXS = 4;
  static const double gapXSPlus = 6;
  static const double gapSM = 8;
  static const double gapSMPlus = 10;
  static const double gapMD = 12;
  static const double gapBetweenCards = 16;
  static const double gapLG = 20;
  static const double gapBetweenSections = 24;
  static const double gapXL = 24;
  static const double gapXXL = 28;
  static const double gapXXXL = 32;
  static const double gapHuge = 36;

  static const double paddingSM = 8;
  static const double paddingMD = 20; // Updated from 16 to 20
  static const double paddingLG =
      32; // Updated from 28 to 32 for bottom safe area
  static const double paddingCard = 20;

  static const double drawerWidthFactor = 0.7;
  static const double gridAspect = 0.86;
  static const double hadithCardHeightFactor = 0.18;
  static const double hadithCardMinHeight = 96;
  static const double hadithCardMaxHeight = 120;
  static const double sheetHeightFactor = 0.72;

  static const double handleWidth = 36;
  static const double handleHeight = 4;
  static const double dividerThickness = 1;
  static const double appBarHeight = 64;
  static const double tapTargetMin = 32;
  static const double buttonMinHeight = 44;
  static const double sheetPlaceholderHeight = 240;
  static const double progressBarHeight = 6;
  static const double progressRingSize = 46;
  static const double progressRingStroke = 5;
  static const double maxContentWidth = 520;
  static const double lessonScrollExtent = 96;
  static const double iconBoxSize = 44;
  static const double emptyIllustrationSize = 88;
  static const double emptyIllustrationInnerSize = 46;
  static const double skeletonLineShort = 110;
  static const double skeletonLineMedium = 140;
  static const double skeletonLineLong = 180;
  static const double routeSlideOffset = 0.03;
  static const double pressScale = 0.98;
  static const double pulseScaleMin = 0.95;
  static const double pulseScaleDelta = 0.1;
  static const double textScaleBaseWidth = 360;
  static const double textScaleMin = 0.95;
  static const double textScaleMax = 1.2;
  static const double transitionCurveEnd = 0.75;

  static const double iconXS = 14;
  static const double iconSM = 18;
  static const double iconMD = 20;
  static const double iconLG = 24;
  static const double iconXL = 28;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(
    paddingMD,
    paddingMD,
    paddingMD,
    paddingLG,
  );
  static const EdgeInsets screenPaddingCompact = EdgeInsets.all(paddingMD);
  static const EdgeInsets screenPaddingTopLarge = EdgeInsets.fromLTRB(
    paddingMD,
    paddingLG,
    paddingMD,
    paddingLG,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(paddingCard);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: paddingCard,
    vertical: gapMD,
  );
  static const EdgeInsets buttonPaddingCompact = EdgeInsets.symmetric(
    horizontal: paddingMD,
    vertical: gapMD,
  );

  static const Duration animQuick = Duration(milliseconds: 120);
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animShort = Duration(milliseconds: 180);
  static const Duration animMedium = Duration(milliseconds: 180);
  static const Duration animNormal = Duration(milliseconds: 180);
  static const Duration animSlow = Duration(milliseconds: 180);
  static const Duration animSlowest = Duration(milliseconds: 180);
  static const Duration animProgress = Duration(milliseconds: 180);
  static const Duration animPulse = Duration(milliseconds: 180);
  static const Duration animScroll = Duration(milliseconds: 180);
  static const Duration snack = Duration(milliseconds: 1500);
  static const Duration snackLong = Duration(seconds: 2);
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => const [
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMD => const [
    BoxShadow(
      color: Color(0x0D000000), // 5% opacity
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
