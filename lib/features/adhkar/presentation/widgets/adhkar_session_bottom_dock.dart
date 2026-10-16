import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import 'adhkar_session_card.dart';

/// Ergonomic bottom dock providing previous/next navigation and counter reset
/// for the Adhkar recitation session.
class AdhkarSessionBottomDock extends StatelessWidget {
  final bool hasPrev;
  final bool hasNext;
  final bool isComplete;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onReset;

  const AdhkarSessionBottomDock({
    super.key,
    required this.hasPrev,
    required this.hasNext,
    required this.isComplete,
    this.onPrev,
    this.onNext,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Dhikr Button (Right in RTL)
          NavigationPillButton(
            icon: Icons.chevron_left_rounded,
            label: 'السابق',
            isLeadingIcon: true,
            isEnabled: hasPrev,
            onTap: onPrev,
          ),

          // Reset Counter Button (Center)
          Tooltip(
            message: 'إعادة العداد',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onReset,
                borderRadius: AppRadius.pillRadius,
                child: Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: AppIcon.sm,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        'إعادة',
                        style: context.text.caption.copyWith(
                          color: palette.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Next Dhikr Button (Left in RTL)
          NavigationPillButton(
            icon: Icons.chevron_right_rounded,
            label: 'التالي',
            isLeadingIcon: false,
            isHighlighted: isComplete,
            isEnabled: hasNext,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}
