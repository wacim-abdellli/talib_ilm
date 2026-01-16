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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: AppUi.gapXS),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
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
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: widget.variant == HomeLearningVariant.continueLearning
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.continueTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الكتاب: ${widget.bookTitle}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
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
                    color: Color(0xFF94A3B8),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.startTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.startSubtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
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
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
      ),
    );
  }
}
