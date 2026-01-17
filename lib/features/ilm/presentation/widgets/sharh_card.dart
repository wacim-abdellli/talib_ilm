import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../app/theme/app_ui.dart';

class SharhCard extends StatelessWidget {
  final String title;
  final String scholar;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int? totalPages;
  final int? currentPage;

  // Visual cues from previous implementation (mapped to new design)
  final bool recommended;
  final bool isLastRead;
  final String? difficulty;

  const SharhCard({
    super.key,
    required this.title,
    required this.scholar,
    required this.onTap,
    this.onLongPress,
    this.totalPages,
    this.currentPage,
    this.recommended = false,
    this.isLastRead = false,
    this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    // Height: 120
    // BorderRadius: 16 (AppUi.radiusLG usually 16 or similar, or hardcoded)
    const double height = 120;
    const double radiusValue = 16;
    final borderRadius = BorderRadius.circular(radiusValue);

    // Determine subtitle text: Prefer explicit pages, fallback to scholar/difficulty
    String subtitleText;
    if (totalPages != null && totalPages! > 0) {
      subtitleText = '$totalPages صفحة';
    } else {
      subtitleText = scholar;
      if (difficulty != null) subtitleText += ' • $difficulty';
    }

    // Determine progress text
    String? progressText;
    if (currentPage != null && currentPage! > 0) {
      progressText = 'وصلت إلى صفحة $currentPage';
    } else if (isLastRead) {
      progressText = 'آخر قراءة';
    }

    return Container(
      height: height,
      margin: const EdgeInsets.only(
        bottom: AppUi.gapMD,
      ), // Use external margin if needed, or parent handles it
      decoration: BoxDecoration(
        color: context.surfaceColor, // White/Surface
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: borderRadius,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: context.goldColor, // Gold
                    width: 3,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppUi.paddingMD),
              child: Row(
                children: [
                  // 1. Left: Scholar icon circle (Leading in Row)
                  _ScholarIcon(),

                  const SizedBox(width: AppUi.gapMD),

                  // 2. Middle column
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          style: AppText.body.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Subtitle
                        Text(
                          subtitleText,
                          style: AppText.body.copyWith(
                            fontSize: 14,
                            color: context.textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (progressText != null) ...[
                          const SizedBox(height: 4),
                          // Progress
                          Text(
                            progressText,
                            style: AppText.body.copyWith(
                              fontSize: 12,
                              color: context.primaryColor, // Teal
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: AppUi.gapSM),

                  // 3. Right: arrow_forward_ios (Trailing)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: context.textTertiaryColor,
                    // Note: In RTL, this points Right (>).
                    // If visual matching "Right" is desired, this is correct placement (End).
                    // If direction is confusing, user can provide feedback.
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

class _ScholarIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient, // Gradient Teal
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_outline, // Scholar icon
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
