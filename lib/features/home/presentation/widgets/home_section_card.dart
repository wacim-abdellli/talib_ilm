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
          shadowColor: AppColors.textPrimary.withOpacity(0.08),
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: AppColors.primary.withOpacity(0.12),
            highlightColor: AppColors.surfaceVariant,
            child: Container(
              padding: const EdgeInsets.all(AppUi.paddingMD),
              decoration: BoxDecoration(
                borderRadius: radius,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: AppUi.iconSizeLG,
                      color: accent,
                    ),
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
                        ),
                        const SizedBox(height: AppUi.gapXS),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
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
