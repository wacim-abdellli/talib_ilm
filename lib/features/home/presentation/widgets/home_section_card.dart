import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_ui.dart';

import '../../../../shared/widgets/pressable_scale.dart';
import '../../../../app/theme/theme_colors.dart';

/// Semantic intent for section cards
/// Widget receives intent, theme decides appearance
enum HomeSectionKind { prayer, adhkar, ilm, library }

/// HomeSectionCard - Section navigation card
///
/// Design Philosophy:
/// - Monochrome base, neutral icons by default
/// - Semantic undertones are barely perceptible (felt, not seen)
/// - No per-feature vivid colors
/// - Widget receives intent, consumes semantic tokens
class HomeSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final HomeSectionKind kind;
  final VoidCallback? onTap;

  const HomeSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.kind,
    this.onTap,
  });

  /// Returns a barely perceptible semantic undertone color
  /// These colors should be FELT, not SEEN (5-10% opacity application)
  Color _semanticUndertone(BuildContext context, HomeSectionKind kind) {
    final isDark = context.isDark;
    switch (kind) {
      case HomeSectionKind.prayer:
        // Deep muted green (prayer/sacred)
        return isDark ? const Color(0xFF3a5a4a) : const Color(0xFF5a8a7a);
      case HomeSectionKind.adhkar:
        // Neutral slate
        return isDark ? const Color(0xFF4a5a6a) : const Color(0xFF6a7a8a);
      case HomeSectionKind.ilm:
        // Deep indigo (learning)
        return isDark ? const Color(0xFF3a4a5a) : const Color(0xFF5a6a7a);
      case HomeSectionKind.library:
        // Neutral warm gray
        return isDark ? const Color(0xFF4a4a5a) : const Color(0xFF6a6a7a);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusSMPlus);
    final isDark = context.isDark;

    // Semantic undertone - very subtle, barely visible
    final undertone = _semanticUndertone(context, kind);

    // === RESTRAINED DESIGN ===
    // Icon is NEUTRAL by default, not colorful
    final iconColor = context.textSecondaryColor;
    // Icon background uses undertone at very low opacity
    final iconBgColor = undertone.withValues(alpha: isDark ? 0.15 : 0.08);

    return PressableScale(
      enabled: onTap != null,
      pressedScale: AppUi.pressScale,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 100),
        child: Material(
          color: context.surfaceColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onTap!();
                  },
            borderRadius: radius,
            splashColor: undertone.withValues(alpha: 0.08),
            highlightColor: context.surfaceSecondaryColor,
            child: Container(
              padding: const EdgeInsets.all(AppUi.paddingMD),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: context.borderColor, width: 1),
              ),
              child: Row(
                children: [
                  // Icon container - monochrome with subtle undertone
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: AppUi.iconSizeLG, color: iconColor),
                  ),
                  const SizedBox(width: AppUi.gapMD),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: AppUi.gapXS),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: context.textSecondaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppUi.gapSM),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: context.textTertiaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum HomeLearningVariant { continueLearning, startLearning }

/// HomeLearningCard - Continue/Start Learning Card
///
/// Design Philosophy:
/// - Visually quiet, black surface with depth
/// - NO gradients, NO color animation
/// - Typography does the work
/// - Monochrome with subtle learning undertone (deep indigo - felt, not seen)
class HomeLearningCard extends StatelessWidget {
  final HomeLearningVariant variant;
  final String continueTitle;
  final String bookTitle;
  final String progressLabel;
  final double progress;
  final String startTitle;
  final String startSubtitle;
  final String actionLabel;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;

  const HomeLearningCard({
    super.key,
    this.variant = HomeLearningVariant.continueLearning,
    this.continueTitle = 'واصل التعلم',
    this.bookTitle = 'الأصول الثلاثة',
    this.progressLabel = 'القسم المبين: صفحة ١٢/١٠',
    this.progress = 0,
    this.startTitle = 'ابدأ رحلة التعلم',
    this.startSubtitle = 'استكشف الكتب المتاحة',
    this.actionLabel = 'تصفح الكتب',
    this.onTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    // === RESTRAINED DESIGN - BLACK FIRST ===
    // No gradients, no flashy colors
    // Subtle deep indigo undertone for "learning" intent
    final containerBg = isDark
        ? const Color(0xFF0f0f1a) // Near-black with barely perceptible indigo
        : context.surfaceElevatedColor;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.5 : 0.08);

    // Text: white on dark surface
    final textColor = isDark ? Colors.white : context.textPrimaryColor;
    final subtextColor = isDark
        ? Colors.white.withValues(alpha: 0.7)
        : context.textSecondaryColor;

    // Icon: neutral, not colorful
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final iconColor = isDark
        ? Colors.white.withValues(alpha: 0.8)
        : context.textSecondaryColor;

    final isContinue = variant == HomeLearningVariant.continueLearning;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap!();
                },
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.02),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon - monochrome
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isContinue ? Icons.menu_book_rounded : Icons.school_rounded,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isContinue ? continueTitle : startTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isContinue ? 'الكتاب: $bookTitle' : startSubtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: subtextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
