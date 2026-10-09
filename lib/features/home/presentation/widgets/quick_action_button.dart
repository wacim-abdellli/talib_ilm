import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';

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
    return Semantics(
      button: true,
      label: label,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsetsDirectional.symmetric(
          vertical: AppSpace.md,
          horizontal: AppSpace.xs,
        ),
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconBadge(icon: icon),
              const SizedBox(height: AppSpace.sm),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xs,
                ),
                child: Text(
                  label,
                  style: context.text.label.copyWith(
                    color: context.palette.text,
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
