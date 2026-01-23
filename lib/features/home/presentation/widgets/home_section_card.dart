import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_ui.dart';

import '../../../../shared/widgets/pressable_scale.dart';
import '../../../../app/theme/theme_colors.dart';

enum HomeSectionKind { prayer, adhkar, ilm, library }

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

  Color _accentFor(BuildContext context, HomeSectionKind kind) {
    switch (kind) {
      case HomeSectionKind.prayer:
        return context.primaryColor;
      case HomeSectionKind.adhkar:
        return context.primaryLightColor;
      case HomeSectionKind.ilm:
        return context.goldColor;
      case HomeSectionKind.library:
        return const Color(0xFF6C63FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusSMPlus);
    final accent = _accentFor(context, kind);

    return PressableScale(
      enabled: onTap != null,
      pressedScale: AppUi.pressScale,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 100),
        child: Material(
          color: context.surfaceColor,
          elevation: 1,
          shadowColor: context.textPrimaryColor.withValues(alpha: 0.08),
          borderRadius: radius,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onTap!();
                  },
            borderRadius: radius,
            splashColor: context.primaryColor.withValues(alpha: 0.12),
            highlightColor: context.surfaceSecondaryColor,
            child: Container(
              padding: const EdgeInsets.all(AppUi.paddingMD),
              decoration: BoxDecoration(borderRadius: radius),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: AppUi.iconSizeLG, color: accent),
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
                    color: context.textSecondaryColor,
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

class HomeLearningCard extends StatefulWidget {
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
  State<HomeLearningCard> createState() => _HomeLearningCardState();
}

class _HomeLearningCardState extends State<HomeLearningCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap == null
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        widget.onTap!();
                      },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: widget.variant == HomeLearningVariant.continueLearning
                      ? Row(
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.continueTitle,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'الكتاب: ${widget.bookTitle}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.startTitle,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.startSubtitle,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
