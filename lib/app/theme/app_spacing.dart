import 'package:flutter/material.dart';
import 'app_palette.dart';

export 'app_palette.dart';

/// Legacy spacing shim.
/// @Deprecated: Use [AppSpace], [AppMotion], [AppSize] instead.
@Deprecated('Use AppSpace, AppMotion, AppSize instead')
class AppSpacing {
  AppSpacing._();

  static const double gapXXS = AppSpace.xs;
  static const double gapXXSPlus = AppSpace.xs;
  static const double gapXS = AppSpace.xs;
  static const double gapXSPlus = AppSpace.sm;
  static const double gapSM = AppSpace.sm;
  static const double gapSMPlus = AppSpace.md;
  static const double gapMD = AppSpace.md;
  static const double gapBetweenCards = AppSpace.lg;
  static const double gapLG = AppSpace.lg;
  static const double gapBetweenSections = AppSpace.xxl;
  static const double gapXL = AppSpace.xxl;
  static const double gapXXL = AppSpace.xxl;
  static const double gapXXXL = AppSpace.xxxl;
  static const double gapHuge = AppSpace.xxxl;

  static const double paddingSM = AppSpace.sm;
  static const double paddingMD = AppSpace.xl;
  static const double paddingLG = AppSpace.xxxl;
  static const double paddingCard = AppSpace.lg;

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
  static const double tapTargetMin = AppSize.tap;
  static const double buttonMinHeight = AppSize.buttonH;
  static const double sheetPlaceholderHeight = 240;
  static const double progressBarHeight = 6;
  static const double progressRingSize = 46;
  static const double progressRingStroke = 5;
  static const double maxContentWidth = 520;
  static const double lessonScrollExtent = 96;
  static const double iconBoxSize = 44;
  static const double emptyIllustrationSize = 96;
  static const double emptyIllustrationInnerSize = 40;
  static const double skeletonLineShort = 110;
  static const double skeletonLineMedium = 140;
  static const double skeletonLineLong = 180;
  static const double routeSlideOffset = 0.03;
  static const double pressScale = 0.98;
  static const double pulseScaleMin = 0.95;
  static const double pulseScaleDelta = 0.1;
  static const double textScaleBaseWidth = 360;
  static const double textScaleMin = 0.9;
  static const double textScaleMax = 1.5;
  static const double transitionCurveEnd = 0.75;

  static const double iconXS = AppIcon.sm;
  static const double iconSM = AppIcon.sm;
  static const double iconMD = AppIcon.md;
  static const double iconLG = AppIcon.lg;
  static const double iconXL = AppIcon.xl;

  static const EdgeInsets screenPadding = AppSpace.screenPadding;
  static const EdgeInsets screenPaddingCompact = EdgeInsets.all(AppSpace.lg);
  static const EdgeInsets screenPaddingTopLarge = EdgeInsets.fromLTRB(
    AppSpace.xl,
    AppSpace.xxl,
    AppSpace.xl,
    AppSpace.xxxl,
  );
  static const EdgeInsets cardPadding = AppSpace.cardPadding;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: AppSpace.xl,
    vertical: AppSpace.md,
  );
  static const EdgeInsets buttonPaddingCompact = EdgeInsets.symmetric(
    horizontal: AppSpace.lg,
    vertical: AppSpace.sm,
  );

  static const Duration animQuick = AppMotion.fast;
  static const Duration animFast = AppMotion.fast;
  static const Duration animShort = AppMotion.base;
  static const Duration animMedium = AppMotion.base;
  static const Duration animNormal = AppMotion.base;
  static const Duration animSlow = AppMotion.slow;
  static const Duration animSlowest = AppMotion.slow;
  static const Duration animProgress = AppMotion.base;
  static const Duration animPulse = AppMotion.base;
  static const Duration animScroll = AppMotion.base;
  static const Duration snack = Duration(milliseconds: 1500);
  static const Duration snackLong = Duration(seconds: 2);
}

/// Legacy shadows shim
@Deprecated('Use AppPalette.light.shadow instead')
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => AppPalette.light.shadow;
  static List<BoxShadow> get shadowMD => AppPalette.light.shadow;
}
