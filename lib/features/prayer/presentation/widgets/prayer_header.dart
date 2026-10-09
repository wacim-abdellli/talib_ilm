import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/icon_badge.dart';

class PrayerHeader extends StatelessWidget {
  final String city;
  final String gregorianDate;
  final VoidCallback onOpenLocationSettings;
  final VoidCallback onOpenQibla;

  const PrayerHeader({
    super.key,
    required this.city,
    required this.gregorianDate,
    required this.onOpenLocationSettings,
    required this.onOpenQibla,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.xl,
        AppSpace.lg,
        AppSpace.xl,
        AppSpace.xl,
      ),
      decoration: BoxDecoration(
        color: context.palette.surfaceRaised,
        border: Border(
          bottom: BorderSide(
            color: context.palette.border,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top row: Title + Settings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const IconBadge(icon: Icons.mosque_rounded),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Text(
                          'مواقيت الصلاة',
                          style: context.text.titleSmall.copyWith(
                            color: context.palette.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: 'إعدادات الصلاة',
                  color: context.palette.textMuted,
                  onPressed: onOpenLocationSettings,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            // Chips: City, Date, Qibla
            Row(
              children: [
                // City Selector Chip
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onOpenLocationSettings,
                      borderRadius: AppRadius.mdRadius,
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.sm,
                        ),
                        constraints: const BoxConstraints(
                          minHeight: AppSize.tap,
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
                              Icons.location_on_rounded,
                              color: context.palette.primary,
                              size: AppIcon.md,
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: Text(
                                city,
                                style: context.text.label.copyWith(
                                  color: context.palette.text,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                // Date Chip
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                    constraints: const BoxConstraints(
                      minHeight: AppSize.tap,
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
                          Icons.calendar_today_rounded,
                          color: context.palette.textSubtle,
                          size: AppIcon.sm,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Text(
                          gregorianDate,
                          style: context.text.label.copyWith(
                            color: context.palette.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                // Qibla Button
                Semantics(
                  button: true,
                  label: 'القبلة',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onOpenQibla,
                      borderRadius: AppRadius.mdRadius,
                      child: Tooltip(
                        message: 'القبلة',
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: AppSize.tap,
                            minHeight: AppSize.tap,
                          ),
                          decoration: BoxDecoration(
                            color: context.palette.primarySoft,
                            borderRadius: AppRadius.mdRadius,
                            border: Border.all(
                              color: context.palette.border,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.explore_rounded,
                              color: context.palette.onPrimarySoft,
                              size: AppIcon.md,
                            ),
                          ),
                        ),
                      ),
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
}
