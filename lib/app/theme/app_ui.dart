import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

export 'app_palette.dart';

/// Legacy UI constants shim.
/// @Deprecated: Use [AppSpace], [AppRadius], [AppIcon], [AppMotion], [AppSize] instead.
@Deprecated('Use AppSpace, AppRadius, AppIcon, AppMotion, AppSize instead')
class AppUi {
  static const double gapXXS = AppSpace.xs;
  static const double gapXXSPlus = AppSpace.xs;
  static const double gapXS = AppSpace.xs;
  static const double gapXSPlus = AppSpace.sm;
  static const double gapSM = AppSpace.sm;
  static const double gapSMPlus = AppSpace.md;
  static const double gapMD = AppSpace.md;
  static const double gapLG = AppSpace.lg;
  static const double gapXL = AppSpace.xl;
  static const double gapXXL = AppSpace.xxl;
  static const double gapXXXL = AppSpace.xxxl;

  static const double gridAspect = 0.86;
  static const double drawerWidthFactor = 0.7;
  static const double hadithCardHeightFactor = 0.18;
  static const double hadithCardMinHeight = 96;
  static const double hadithCardMaxHeight = 120;
  static const double sheetHeightFactor = 0.72;
  static const double routeSlideOffset = 0.03;
  static const double pressScale = 0.98;
  static const double pulseScaleMin = 0.95;
  static const double pulseScaleDelta = 0.1;
  static const double textScaleBaseWidth = 360;
  static const double textScaleMin = 0.9;
  static const double textScaleMax = 1.5;
  static const double transitionCurveEnd = 0.75;

  static const double radiusXS = AppRadius.sm;
  static const double radiusSM = AppRadius.sm;
  static const double radiusSMPlus = AppRadius.md;
  static const double radiusMD = AppRadius.md;
  static const double radiusCard = AppRadius.lg;
  static const double radiusLG = AppRadius.lg;
  static const double radiusXL = AppRadius.xl;
  static const double radiusXXL = AppRadius.xl;
  static const double radiusXXXL = AppRadius.xl;
  static const double radiusPill = AppRadius.pill;

  static const double paddingSM = AppSpace.sm;
  static const double paddingMD = AppSpace.xl;
  static const double paddingLG = AppSpace.xxxl;
  static const double paddingCard = AppSpace.lg;

  static const double handleWidth = 36;
  static const double handleHeight = 4;
  static const double dividerThickness = 1;
  static const double iconSizeSM = AppIcon.sm;
  static const double iconSizeMD = AppIcon.md;
  static const double iconSizeXS = AppIcon.sm;
  static const double iconSizeLG = AppIcon.lg;
  static const double iconSizeXL = AppIcon.xl;
  static const double iconSizeHero = AppIcon.hero;
  static const double appBarHeight = 64;
  static const double tapTargetMin = AppSize.tap;
  static const double buttonMinHeight = AppSize.buttonH;
  static const double sheetPlaceholderHeight = 240;
  static const double progressBarHeight = 6;
  static const double progressRingSize = 46;
  static const double progressRingStroke = 5;
  static const double maxContentWidth = 520;
  static const double iconBoxSize = 44;
  static const double emptyIllustrationSize = 96;
  static const double emptyIllustrationInnerSize = 40;
  static const double skeletonLineShort = 110;
  static const double skeletonLineMedium = 140;
  static const double skeletonLineLong = 180;

  static const EdgeInsets screenPadding = AppSpace.screenPadding;
  static const EdgeInsets screenPaddingCompact = EdgeInsets.all(AppSpace.lg);
  static const EdgeInsets cardPadding = AppSpace.cardPadding;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: AppSpace.xl,
    vertical: AppSpace.md,
  );
  static const EdgeInsets buttonPaddingCompact = EdgeInsets.symmetric(
    horizontal: AppSpace.lg,
    vertical: AppSpace.sm,
  );
  static const EdgeInsets screenPaddingTopLarge = EdgeInsets.fromLTRB(
    AppSpace.xl,
    AppSpace.xxl,
    AppSpace.xl,
    AppSpace.xxxl,
  );

  static const Duration animationQuick = AppMotion.fast;
  static const Duration animationFast = AppMotion.fast;
  static const Duration animationShort = AppMotion.base;
  static const Duration animationMedium = AppMotion.base;
  static const Duration animationNormal = AppMotion.base;
  static const Duration animationSlow = AppMotion.slow;
  static const Duration animationSlowest = AppMotion.slow;
  static const Duration animationProgress = AppMotion.base;
  static const Duration animationPulse = AppMotion.base;
  static const Duration animationScroll = AppMotion.base;
  static const Duration snackDuration = Duration(milliseconds: 1500);
  static const Duration snackDurationLong = Duration(seconds: 2);

  static const double lessonScrollExtent = 96;

  static List<BoxShadow> get cardShadow => AppPalette.light.shadow;
  static List<BoxShadow> get shadowMD => AppPalette.light.shadow;

  static EdgeInsets snackMargin(BuildContext context) {
    return EdgeInsets.all(AppSpace.lg).copyWith(
      bottom: AppSize.navClearance(context),
    );
  }
}
