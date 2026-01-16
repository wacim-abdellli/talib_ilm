import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text.dart';
import '../../../../shared/widgets/pressable_card.dart';

class VideoLessonCard extends StatelessWidget {
  final String title;
  final String sheikhName;
  final String duration;
  final String views;
  final String date;
  final String? thumbnailUrl;
  final bool isCompleted;
  final VoidCallback onTap;

  const VideoLessonCard({
    super.key,
    required this.title,
    required this.sheikhName,
    required this.duration,
    required this.views,
    required this.date,
    required this.onTap,
    this.thumbnailUrl,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    // Container: Height 200, BorderRadius 16
    const double cardHeight = 200;
    const double radiusValue = 16;
    final radius = BorderRadius.circular(radiusValue);

    return PressableCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: radius,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // black 5%
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: cardHeight,
        child: Column(
          children: [
            // Top Section (Thumbnail) - Flexible height based on remaining space or fixed ratio?
            // "Top section (16:9 aspect)" - if we enforce 16:9, height depends on width.
            // If we enforce card Height 200, we might run out of space.
            // Compromise: Use Expanded for image to fill top, or fixed height?
            // Let's try to respect 16:9 roughly by using a flexible flex or generic standard.
            // Given fixed height 200, typical split is 60% image / 40% texts.
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Thumbnail
                  thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                      ? Image.network(
                          thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _PlaceholderThumbnail(),
                        )
                      : const _PlaceholderThumbnail(),

                  // 2. Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),

                  // 3. Play Icon Center
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),

                  // 4. Duration Badge (Bottom-Right)
                  Positioned(
                    bottom: 8,
                    right:
                        8, // LTR: right. RTL: right? Absolute right relative to image.
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        duration,
                        style: AppText.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // 5. Watched Indicator (Top-Left)
                  if (isCompleted)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Section (Info)
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Sheikh Name
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sheikhName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body.copyWith(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: AppColors.primary, // Verified badge
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Views + Date
                    Text(
                      '$views views • $date',
                      style: AppText.caption.copyWith(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection:
                          TextDirection.ltr, // Ensure consistent formatting
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderThumbnail extends StatelessWidget {
  const _PlaceholderThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}
