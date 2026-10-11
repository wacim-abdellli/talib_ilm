import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/adhkar_models.dart';

/// Luxury presentation card for an AthkarItem in a recitation session.
class AdhkarSessionCard extends StatelessWidget {
  final AthkarItem item;
  final int repeat;
  final bool isDone;

  const AdhkarSessionCard({
    super.key,
    required this.item,
    required this.repeat,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.xs,
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: AppCard(
            padding: AppSpace.cardPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Target repetition badge
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isDone ? palette.primarySoft : palette.goldSoft,
                    borderRadius: AppRadius.pillRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDone ? Icons.check_circle_rounded : Icons.repeat_rounded,
                        size: AppIcon.sm,
                        color: isDone ? palette.success : palette.gold,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        item.countDescription.isNotEmpty
                            ? item.countDescription
                            : (repeat > 1 ? '$repeat مرات' : 'مرة واحدة'),
                        style: context.text.caption.copyWith(
                          color: isDone ? palette.success : palette.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),

                // Arabic Sacred Text
                Text(
                  item.arabic,
                  textAlign: TextAlign.center,
                  style: context.text.sacredLarge.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                    height: 1.85,
                  ),
                ),

                // Virtue / Fadl callout
                if (item.fadl.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.md),
                  Container(
                    padding: AppSpace.insetMd,
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: AppIcon.sm,
                          color: palette.gold,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(
                          child: Text(
                            item.fadl,
                            textAlign: TextAlign.right,
                            style: context.text.caption.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Hadith Source
                if (item.source.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: AppIcon.sm,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Flexible(
                        child: Text(
                          item.source,
                          textAlign: TextAlign.center,
                          style: context.text.caption.copyWith(
                            color: palette.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Meaning translation
                if (item.meaning.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.md),
                  Divider(color: palette.border),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    item.meaning,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall.copyWith(
                      color: palette.textMuted,
                      height: 1.55,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating circular chevron button flanking the dhikr card.
class FloatingChevronButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isHighlighted;
  final VoidCallback onTap;

  const FloatingChevronButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.isHighlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: isHighlighted ? palette.primary : palette.surface.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          elevation: isHighlighted ? 3 : 1,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isHighlighted ? palette.primary : palette.border,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: AppIcon.md,
                color: isHighlighted ? palette.onPrimary : palette.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ergonomic bottom navigation pill button with clear label and RTL arrow.
class NavigationPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLeadingIcon;
  final bool isHighlighted;
  final bool isEnabled;
  final VoidCallback? onTap;

  const NavigationPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isLeadingIcon,
    this.isHighlighted = false,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final bgColor = isHighlighted
        ? palette.primary
        : (isEnabled ? palette.surface : palette.surfaceMuted);
    final fgColor = isHighlighted
        ? palette.onPrimary
        : (isEnabled ? palette.text : palette.textMuted);
    final borderColor = isHighlighted
        ? palette.primary
        : (isEnabled ? palette.border : Colors.transparent);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: AppRadius.pillRadius,
        child: AnimatedContainer(
          duration: AppMotion.base,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.pillRadius,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLeadingIcon) ...[
                Icon(icon, size: AppIcon.sm, color: fgColor),
                const SizedBox(width: AppSpace.xs),
              ],
              Text(
                label,
                style: context.text.label.copyWith(
                  color: fgColor,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              if (!isLeadingIcon) ...[
                const SizedBox(width: AppSpace.xs),
                Icon(icon, size: AppIcon.sm, color: fgColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
