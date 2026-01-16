import 'package:flutter/material.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

class AppUi {
  static const double gapXXS = AppSpacing.gapXXS;
  static const double gapXXSPlus = AppSpacing.gapXXSPlus;
  static const double gapXS = AppSpacing.gapXS;
  static const double gapXSPlus = AppSpacing.gapXSPlus;
  static const double gapSM = AppSpacing.gapSM;
  static const double gapSMPlus = AppSpacing.gapSMPlus;
  static const double gapMD = AppSpacing.gapMD;
  static const double gapLG = AppSpacing.gapLG;
  static const double gapXL = AppSpacing.gapXL;
  static const double gapXXL = AppSpacing.gapXXL;
  static const double gapXXXL = AppSpacing.gapXXXL;

  static const double gridAspect = AppSpacing.gridAspect;
  static const double drawerWidthFactor = AppSpacing.drawerWidthFactor;
  static const double hadithCardHeightFactor =
      AppSpacing.hadithCardHeightFactor;
  static const double hadithCardMinHeight = AppSpacing.hadithCardMinHeight;
  static const double hadithCardMaxHeight = AppSpacing.hadithCardMaxHeight;
  static const double sheetHeightFactor = AppSpacing.sheetHeightFactor;
  static const double routeSlideOffset = AppSpacing.routeSlideOffset;
  static const double pressScale = AppSpacing.pressScale;
  static const double pulseScaleMin = AppSpacing.pulseScaleMin;
  static const double pulseScaleDelta = AppSpacing.pulseScaleDelta;
  static const double textScaleBaseWidth = AppSpacing.textScaleBaseWidth;
  static const double textScaleMin = AppSpacing.textScaleMin;
  static const double textScaleMax = AppSpacing.textScaleMax;
  static const double transitionCurveEnd = AppSpacing.transitionCurveEnd;

  static const double radiusXS = AppRadius.xs;
  static const double radiusSM = AppRadius.sm;
  static const double radiusSMPlus = AppRadius.smPlus;
  static const double radiusMD = AppRadius.md;
  static const double radiusCard = AppRadius.md;
  static const double radiusLG = AppRadius.lg;
  static const double radiusXL = AppRadius.xl;
  static const double radiusXXL = AppRadius.xxl;
  static const double radiusXXXL = AppRadius.xxl;
  static const double radiusPill = AppRadius.pill;

  static const double paddingSM = AppSpacing.paddingSM;
  static const double paddingMD = AppSpacing.paddingMD;
  static const double paddingLG = AppSpacing.paddingLG;
  static const double paddingCard = AppSpacing.paddingCard;

  static const double handleWidth = AppSpacing.handleWidth;
  static const double handleHeight = AppSpacing.handleHeight;
  static const double dividerThickness = AppSpacing.dividerThickness;
  static const double iconSizeSM = AppSpacing.iconSM;
  static const double iconSizeMD = AppSpacing.iconMD;
  static const double iconSizeXS = AppSpacing.iconXS;
  static const double iconSizeLG = AppSpacing.iconLG;
  static const double iconSizeXL = AppSpacing.iconXL;
  static const double appBarHeight = AppSpacing.appBarHeight;
  static const double tapTargetMin = AppSpacing.tapTargetMin;
  static const double buttonMinHeight = AppSpacing.buttonMinHeight;
  static const double sheetPlaceholderHeight =
      AppSpacing.sheetPlaceholderHeight;
  static const double progressBarHeight = AppSpacing.progressBarHeight;
  static const double progressRingSize = AppSpacing.progressRingSize;
  static const double progressRingStroke = AppSpacing.progressRingStroke;
  static const double maxContentWidth = AppSpacing.maxContentWidth;
  static const double iconBoxSize = AppSpacing.iconBoxSize;
  static const double emptyIllustrationSize = AppSpacing.emptyIllustrationSize;
  static const double emptyIllustrationInnerSize =
      AppSpacing.emptyIllustrationInnerSize;
  static const double skeletonLineShort = AppSpacing.skeletonLineShort;
  static const double skeletonLineMedium = AppSpacing.skeletonLineMedium;
  static const double skeletonLineLong = AppSpacing.skeletonLineLong;

  static const EdgeInsets screenPadding = AppSpacing.screenPadding;
  static const EdgeInsets screenPaddingCompact =
      AppSpacing.screenPaddingCompact;
  static const EdgeInsets cardPadding = AppSpacing.cardPadding;
  static const EdgeInsets buttonPadding = AppSpacing.buttonPadding;
  static const EdgeInsets buttonPaddingCompact =
      AppSpacing.buttonPaddingCompact;
  static const EdgeInsets screenPaddingTopLarge =
      AppSpacing.screenPaddingTopLarge;

  static const Duration animationQuick = AppSpacing.animQuick;
  static const Duration animationFast = AppSpacing.animFast;
  static const Duration animationShort = AppSpacing.animShort;
  static const Duration animationMedium = AppSpacing.animMedium;
  static const Duration animationNormal = AppSpacing.animNormal;
  static const Duration animationSlow = AppSpacing.animSlow;
  static const Duration animationSlowest = AppSpacing.animSlowest;
  static const Duration animationProgress = AppSpacing.animProgress;
  static const Duration animationPulse = AppSpacing.animPulse;
  static const Duration animationScroll = AppSpacing.animScroll;
  static const Duration snackDuration = AppSpacing.snack;
  static const Duration snackDurationLong = AppSpacing.snackLong;

  static const double lessonScrollExtent = AppSpacing.lessonScrollExtent;

  static List<BoxShadow> get cardShadow => AppShadows.card;
  static List<BoxShadow> get shadowMD => AppShadows.shadowMD;
  static EdgeInsets snackMargin(BuildContext context) {
    final media = MediaQuery.of(context);
    final topOffset = media.padding.top + appBarHeight + gapSM;

    return EdgeInsets.fromLTRB(paddingMD, topOffset, paddingMD, paddingMD);
  }
}
