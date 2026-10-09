import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_colors.dart';
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

/// Learning Pulse Card - REWARD-DRIVEN
class LearningPulseCard extends StatefulWidget {
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
  State<LearningPulseCard> createState() => _LearningPulseCardState();
}

class _LearningPulseCardState extends State<LearningPulseCard> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildShimmerCard(context);
    }
    return _buildContentCard(context);
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Container(
      height: 120, // Compact
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceContainer, // M3 Standard
        borderRadius: BorderRadius.circular(20),
      ),
      child: Shimmer.fromColors(
        baseColor: context.shimmerBaseColor,
        highlightColor: context.shimmerHighlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context) {
    final hasData = widget.data != null;
    final data = widget.data;
    final isDark = context.isDark;

    // Progress
    final progress = hasData
        ? ((data!.progressPercent ?? 0) / 100.0).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? AppColors.gold.withValues(alpha: 0.22)
                : AppColors.gold.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? 0.35 : 0.06,
              ),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
            if (isDark)
              BoxShadow(
                color: AppColors.jewelIlm.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Radiant Jewel Medallion + Title + Arrow
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.jewelIlm,
                        Color.lerp(AppColors.jewelIlm, Colors.black, isDark ? 0.3 : 0.15)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.jewelIlm.withValues(alpha: isDark ? 0.4 : 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    hasData ? Icons.menu_book_rounded : Icons.school_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasData ? 'متابعة التعلّم' : 'ابدأ رحلة طلب العلم',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.divineGold : AppColors.goldDark,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasData ? data!.book.title : 'استكشف المتون العلمية وشروحها',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? const Color(0xFFF8FAFC) : context.textPrimaryColor,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A242F) : context.surfaceSecondaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: isDark ? const Color(0xFF94A3B8) : context.textSecondaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Section or Discovery Roadmap
            if (hasData)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${data!.progressPercent}% مكتمل',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFCBD5E1) : context.textSecondaryColor,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (data.page != null)
                        Text(
                          'صفحة ${data.page}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textTertiaryColor,
                            fontFamily: 'Cairo',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(
                          height: 7,
                          width: double.infinity,
                          color: isDark ? const Color(0xFF0D141C) : context.surfaceElevatedColor,
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  context.primaryColor,
                                  context.goldColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Curriculum Roadmap Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildMilestonePill(
                        context: context,
                        label: 'المستوى الأول',
                        icon: Icons.stars_rounded,
                        color: AppColors.jewelQuran,
                        isDark: isDark,
                      ),
                      _buildMilestonePill(
                        context: context,
                        label: 'التأسيس والتأصيل',
                        icon: Icons.bookmark_added_rounded,
                        color: AppColors.jewelIlm,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Discovery CTA Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D141C)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.primaryColor.withValues(alpha: isDark ? 0.2 : 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.explore_outlined,
                          size: 18,
                          color: context.primaryColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'الأصول الثلاثة • القواعد الأربع • كتاب التوحيد',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFCBD5E1) : context.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                context.primaryColor,
                                Color.lerp(context.primaryColor, Colors.black, 0.2)!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: context.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Text(
                            'ابدأ الآن',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonePill({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}
