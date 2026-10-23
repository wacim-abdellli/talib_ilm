import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhan_service.dart';
import '../../../../core/services/adhan_settings_service.dart';

class PrayerNotificationModePill extends StatelessWidget {
  final AppPalette palette;
  final AppTextTheme textTheme;
  final AdhanSettings settings;
  final AdhanService adhanService;
  final PrayerNotificationMode mode;
  final String title;
  final String subtitle;
  final IconData icon;
  final PrayerNotificationMode? previewingMode;
  final ValueChanged<AdhanSettings> onSettingsChanged;
  final ValueChanged<PrayerNotificationMode> onTogglePreview;

  const PrayerNotificationModePill({
    super.key,
    required this.palette,
    required this.textTheme,
    required this.settings,
    required this.adhanService,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.previewingMode,
    required this.onSettingsChanged,
    required this.onTogglePreview,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = settings.defaultMode == mode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.mdRadius,
        onTap: () {
          HapticFeedback.selectionClick();
          onSettingsChanged(
            settings.copyWith(
              defaultMode: mode,
              silentNotifications: mode == PrayerNotificationMode.silent,
            ),
          );
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? palette.primarySoft : palette.surfaceMuted,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: isSelected ? palette.primary : palette.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected ? palette.primary : palette.surfaceRaised,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: AppIcon.sm,
                  color: isSelected ? palette.onPrimary : palette.textMuted,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? palette.primary : palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.caption.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (mode == PrayerNotificationMode.takbeer ||
                  mode == PrayerNotificationMode.announcement) ...[
                const SizedBox(width: AppSpace.xs),
                StreamBuilder<PlayerState>(
                  stream: adhanService.playerStateStream,
                  builder: (context, _) {
                    final isAudioActive =
                        adhanService.isPlaying && previewingMode == mode;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onTogglePreview(mode),
                        borderRadius: AppRadius.smRadius,
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.sm,
                            vertical: AppSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: isAudioActive
                                ? palette.primary
                                : palette.surface,
                            borderRadius: AppRadius.smRadius,
                            border: Border.all(
                              color: palette.primary,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAudioActive
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                size: AppIcon.xs,
                                color: isAudioActive
                                    ? palette.onPrimary
                                    : palette.primary,
                              ),
                              const SizedBox(width: AppSpace.xxs),
                              Text(
                                isAudioActive ? 'إيقاف' : 'استمع',
                                style: textTheme.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isAudioActive
                                      ? palette.onPrimary
                                      : palette.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (isSelected) ...[
                const SizedBox(width: AppSpace.xs),
                Icon(
                  Icons.check_circle_rounded,
                  color: palette.primary,
                  size: AppIcon.sm,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
