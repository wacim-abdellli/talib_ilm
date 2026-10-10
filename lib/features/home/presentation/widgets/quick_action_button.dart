import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';

/// QuickActionButton - Accessible Action Tile with AppCard and IconBadge
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double? width;
  final bool isEmphasized;
  final Color? accentColor;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.width,
    this.isEmphasized = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = accentColor ?? palette.primary;

    return Semantics(
      button: true,
      label: label,
      child: AppCard(
        onTap: onTap,
        color: palette.surfaceRaised,
        border: Border.all(
          color: color.withValues(alpha: 0.28),
          width: 1.2,
        ),
        padding: EdgeInsets.zero,
        child: Container(
          width: width,
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSpace.md,
            horizontal: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.10),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: AppIcon.md,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xs,
                ),
                child: Text(
                  label,
                  style: context.text.label.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
