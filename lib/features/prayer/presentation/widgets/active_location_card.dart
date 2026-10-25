import 'package:flutter/material.dart';

import '../../../../app/theme/app_ui.dart';
import '../../../../core/models/location_result.dart';
import '../../../../shared/widgets/app_card.dart';

class ActiveLocationCard extends StatelessWidget {
  final LocationResult? location;
  final VoidCallback? onClearManual;

  const ActiveLocationCard({
    super.key,
    required this.location,
    this.onClearManual,
  });

  @override
  Widget build(BuildContext context) {
    final loc = location;
    if (loc == null) return const SizedBox.shrink();

    final palette = context.palette;
    final isAccurate = loc.isAccurate;
    final sourceColor = isAccurate ? palette.primary : palette.gold;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: sourceColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: sourceColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAccurate
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      size: AppIcon.sm,
                      color: sourceColor,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Text(
                      loc.sourceLabel,
                      style: context.text.caption.copyWith(
                        color: sourceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (loc.source == LocationSource.manual && onClearManual != null)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onClearManual,
                    borderRadius: AppRadius.smRadius,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpace.xs,
                        vertical: AppSpace.xs / 2,
                      ),
                      child: Text(
                        'العودة للـ GPS',
                        style: context.text.caption.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            loc.city,
            style: context.text.title.copyWith(
              fontWeight: FontWeight.bold,
              color: palette.text,
            ),
          ),
          if (loc.province != null || loc.country != null) ...[
            const SizedBox(height: AppSpace.xs / 2),
            Text(
              [loc.province, loc.country].whereType<String>().join(' • '),
              style: context.text.caption.copyWith(
                color: palette.textMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpace.xs),
          Text(
            'الإحداثيات: ${loc.latitude.toStringAsFixed(4)}° N, ${loc.longitude.toStringAsFixed(4)}° E',
            style: context.text.caption.copyWith(
              color: palette.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}
