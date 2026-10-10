import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_progress.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/app_tag.dart';
import '../../../ilm/data/models/mutun_models.dart';
import '../../../ilm/data/models/sharh_model.dart';

class ContinueData {
  final IlmBook book;
  final String tab;
  final String? sharhFile;
  final Sharh? sharh;
  final int? page;
  final int? total;
  final int? progressPercent;

  const ContinueData({
    required this.book,
    required this.tab,
    this.sharhFile,
    this.sharh,
    this.page,
    this.total,
    this.progressPercent,
  });
}

/// Continue Learning Card following the Calm Scholar design system
class LearningPulseCard extends StatelessWidget {
  final VoidCallback? onTap;
  final ContinueData? data;
  final bool isLoading;

  const LearningPulseCard({
    super.key,
    this.onTap,
    this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _ContinueLoadingCard();
    }
    return _buildContentCard(context);
  }

  Widget _buildContentCard(BuildContext context) {
    final palette = context.palette;
    final hasData = data != null;
    final catColors = palette.category(data?.book.subject);
    final progress = hasData
        ? ((data!.progressPercent ?? 0) / 100.0).clamp(0.0, 1.0)
        : 0.0;

    return Semantics(
      button: true,
      label: hasData ? 'متابعة التعلّم: ${data!.book.title}' : 'ابدأ رحلة طلب العلم',
      child: AppCard(
        onTap: onTap,
        color: palette.surfaceRaised,
        border: Border.all(
          color: catColors.fg.withValues(alpha: 0.28),
          width: 1.2,
        ),
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                catColors.fg.withValues(alpha: 0.10),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Category Medallion + Titles + Trailing Arrow
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          catColors.fg.withValues(alpha: 0.28),
                          catColors.fg.withValues(alpha: 0.10),
                        ],
                      ),
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: catColors.fg.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      hasData ? Icons.menu_book_rounded : Icons.school_rounded,
                      color: catColors.fg,
                      size: AppIcon.lg,
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpace.xs,
                          runSpacing: 2,
                          children: [
                            Text(
                              hasData ? 'متابعة التعلّم' : 'ابدأ رحلة طلب العلم',
                              style: context.text.caption.copyWith(
                                color: catColors.fg,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (hasData)
                              Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: catColors.fg.withValues(alpha: 0.14),
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Text(
                                  data!.book.subject,
                                  style: context.text.caption.copyWith(
                                    color: catColors.fg,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasData ? data!.book.title : 'استكشف المتون العلمية وشروحها',
                          style: context.text.titleSmall.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: catColors.fg.withValues(alpha: 0.10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: catColors.fg,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpace.md),

              if (hasData) ...[
                // Progress Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${data!.progressPercent}% مكتمل',
                      style: context.text.caption.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (data!.page != null)
                      Text(
                        'صفحة ${data!.page}',
                        style: context.text.caption.copyWith(
                          color: palette.textMuted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                AppProgress(
                  progress: progress,
                  color: catColors.fg,
                ),
              ] else ...[
              // Empty State Roadmap Tags
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                children: const [
                  AppTag(
                    label: 'المستوى الأول',
                  ),
                  AppTag(
                    label: 'التأسيس والتأصيل',
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),

              // Discovery CTA Strip
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.sm,
                ),
                decoration: BoxDecoration(
                  color: context.palette.surfaceMuted,
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: context.palette.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      size: AppIcon.md,
                      color: context.palette.primary,
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        'الأصول الثلاثة • القواعد الأربع • كتاب التوحيد',
                        style: context.text.caption.copyWith(
                          color: context.palette.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    AppButton(
                      label: 'ابدأ الآن',
                      size: AppButtonSize.sm,
                      variant: AppButtonVariant.primary,
                      onPressed: onTap,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}

class _ContinueLoadingCard extends StatelessWidget {
  const _ContinueLoadingCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsetsDirectional.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSkeleton(
                width: 44,
                height: 44,
                borderRadius: AppRadius.mdRadius,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(
                      width: 80,
                      height: 12,
                      borderRadius: AppRadius.smRadius,
                    ),
                    const SizedBox(height: AppSpace.sm),
                    AppSkeleton(
                      width: 160,
                      height: 16,
                      borderRadius: AppRadius.smRadius,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          AppSkeleton(
            width: double.infinity,
            height: 6,
            borderRadius: AppRadius.smRadius,
          ),
        ],
      ),
    );
  }
}
