import 'package:flutter/material.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/pressable_scale.dart';

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

  Color _accentFor(HomeSectionKind kind) {
    switch (kind) {
      case HomeSectionKind.prayer:
        return AppColors.primary;
      case HomeSectionKind.adhkar:
        return AppColors.secondary;
      case HomeSectionKind.ilm:
        return AppColors.accent;
      case HomeSectionKind.library:
        return const Color(0xFF6C63FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusSMPlus);
    final accent = _accentFor(kind);

    return PressableScale(
      enabled: onTap != null,
      pressedScale: AppUi.pressScale,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 100),
        child: Material(
          color: AppColors.surface,
          elevation: 1,
          shadowColor: AppColors.textPrimary.withValues(alpha: 0.08),
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: AppColors.primary.withValues(alpha: 0.12),
            highlightColor: AppColors.surfaceVariant,
            child: Container(
              padding: const EdgeInsets.all(AppUi.paddingMD),
              decoration: BoxDecoration(
                borderRadius: radius,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: AppUi.iconSizeLG,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: AppUi.gapMD),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppUi.gapXS),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppUi.gapSM),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textSecondary,
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

class _HomeLearningCardState extends State<HomeLearningCard> {
  bool _pressed = false;

  void _handleHighlight(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppUi.radiusMD);
    final borderColor = AppColors.primary.withValues(alpha: 0.2);
    final shadowColor = AppColors.primaryDark.withValues(
      alpha: _pressed ? 0.18 : 0.12,
    );
    final elevation = _pressed ? 3.0 : 1.0;

    return PressableScale(
      enabled: widget.onTap != null,
      pressedScale: AppUi.pressScale,
      child: Material(
        color: AppColors.surface,
        elevation: elevation,
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: _handleHighlight,
          borderRadius: radius,
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(AppUi.paddingCard),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: widget.variant == HomeLearningVariant.continueLearning
                  ? _ContinueLearningContent(
                      title: widget.continueTitle,
                      bookTitle: widget.bookTitle,
                      progressLabel: widget.progressLabel,
                      progress: widget.progress,
                    )
                  : _StartLearningContent(
                      title: widget.startTitle,
                      subtitle: widget.startSubtitle,
                      actionLabel: widget.actionLabel,
                      onActionTap: widget.onActionTap,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueLearningContent extends StatelessWidget {
  final String title;
  final String bookTitle;
  final String progressLabel;
  final double progress;

  const _ContinueLearningContent({
    required this.title,
    required this.bookTitle,
    required this.progressLabel,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _LearningIcon(icon: Icons.menu_book_rounded),
            const SizedBox(width: AppUi.gapMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppUi.gapXS),
                  Text(
                    bookTitle,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppUi.gapXS),
                  Text(
                    progressLabel,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppUi.gapSM),
        _LearningProgressBar(value: safeProgress),
      ],
    );
  }
}

class _StartLearningContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onActionTap;

  const _StartLearningContent({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _LearningIcon(icon: Icons.school_rounded),
            const SizedBox(width: AppUi.gapMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppUi.gapXS),
                  Text(
                    subtitle,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppUi.gapSM),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppUi.gapMD,
                vertical: AppUi.gapXSPlus,
              ),
              minimumSize: const Size(0, AppUi.tapTargetMin),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppUi.radiusPill),
              ),
            ),
            child: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}

class _LearningIcon extends StatelessWidget {
  final IconData icon;

  const _LearningIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: AppUi.iconSizeMD,
        color: AppColors.primary,
      ),
    );
  }
}

class _LearningProgressBar extends StatelessWidget {
  final double value;

  const _LearningProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();
    final radius = BorderRadius.circular(AppUi.radiusPill);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: AppUi.gapXS,
        color: AppColors.primary.withValues(alpha: 0.15),
        child: Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: safeValue,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: radius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
