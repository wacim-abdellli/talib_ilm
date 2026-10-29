import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';

/// Illuminated two-tone manuscript hero header card for first-run onboarding pages.
///
/// Features an upper parchment/obsidian crown band with a 12-point Islamic rosette
/// medallion, 40dp hero icon, and intrinsic-width capsule category badge, paired
/// with a lower pure-surface editorial title, diamond hairline ornament, and description.
class OnboardingHeroHeaderCard extends StatelessWidget {
  final String tag;
  final IconData icon;
  final String title;
  final String description;

  const OnboardingHeroHeaderCard({
    super.key,
    required this.tag,
    required this.icon,
    required this.title,
    required this.description,
  });

  static const double _medallionStageSize =
      AppSize.navH + AppSize.buttonSmallMinHeight + AppSpace.xs;
  static const double _medallionMiddleSize =
      AppSize.navH + AppSpace.xl + AppSpace.xxs;
  static const double _medallionCoreSize = AppSize.navH + AppSpace.xxs;
  static const double _ornamentDotSize = AppSpace.xs + AppSpace.xxs;
  static const double _dividerHairlineHeight = AppSpace.xxs / 2;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(
          color: palette.splashCardBorder,
          width: 1.2,
        ),
        boxShadow: palette.shadow,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.xlRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Upper Illuminated Parchment Crown Band
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.xl,
                vertical: AppSpace.lg,
              ),
              decoration: BoxDecoration(
                color: palette.splashCardBg,
                border: Border(
                  bottom: BorderSide(
                    color: palette.splashCardBorder,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 12-Point Sacred Rosette Medallion with Hero Icon
                  SizedBox(
                    width: _medallionStageSize,
                    height: _medallionStageSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _OnboardingRosettePainter(
                              goldColor: palette.gold,
                              strokeColor: palette.splashCardBorder,
                            ),
                          ),
                        ),
                        Container(
                          width: _medallionMiddleSize,
                          height: _medallionMiddleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.primarySoft,
                            border: Border.all(
                              color: palette.splashCardBorder,
                            ),
                          ),
                        ),
                        Container(
                          width: _medallionCoreSize,
                          height: _medallionCoreSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.surfaceRaised,
                            border: Border.all(
                              color: palette.gold.withValues(alpha: 0.45),
                              width: 1.4,
                            ),
                            boxShadow: palette.shadow,
                          ),
                          child: Icon(
                            icon,
                            size: AppIcon.hero,
                            color: palette.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),

                  // Intrinsic-Width Capsule Category Badge
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: AppSize.tagMinHeight,
                    ),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: palette.splashCardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: _ornamentDotSize,
                          height: _ornamentDotSize,
                          decoration: BoxDecoration(
                            color: palette.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Flexible(
                          child: Text(
                            tag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.captionBold.copyWith(
                              color: palette.onPrimarySoft,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Container(
                          width: _ornamentDotSize,
                          height: _ornamentDotSize,
                          decoration: BoxDecoration(
                            color: palette.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lower Editorial Title & Description Body
            Padding(
              padding: const EdgeInsetsDirectional.all(AppSpace.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: textTheme.titleHeavy.copyWith(
                        color: palette.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),

                  // Manuscript Hairline & Diamond Ornament
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: AppSpace.xxl,
                        height: _dividerHairlineHeight,
                        color: palette.splashCardBorder,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Transform.rotate(
                        angle: math.pi / 4,
                        child: Container(
                          width: _ornamentDotSize,
                          height: _ornamentDotSize,
                          decoration: BoxDecoration(
                            color: palette.gold,
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Container(
                        width: AppSpace.xxl,
                        height: _dividerHairlineHeight,
                        color: palette.splashCardBorder,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),

                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: textTheme.body.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Delicate 12-point Islamic rosette halo matching the Splash medallion craftsmanship.
class _OnboardingRosettePainter extends CustomPainter {
  final Color goldColor;
  final Color strokeColor;

  const _OnboardingRosettePainter({
    required this.goldColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4.0;

    final circlePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, circlePaint);

    final accentPaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 12; i++) {
      final angle = (i * math.pi) / 6.0;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i % 3 == 0) {
        final path = Path()
          ..moveTo(x, y - 3.2)
          ..lineTo(x + 2.8, y)
          ..lineTo(x, y + 3.2)
          ..lineTo(x - 2.8, y)
          ..close();
        canvas.drawPath(path, accentPaint);
      } else {
        canvas.drawCircle(Offset(x, y), 1.5, accentPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingRosettePainter oldDelegate) {
    return oldDelegate.goldColor != goldColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}

