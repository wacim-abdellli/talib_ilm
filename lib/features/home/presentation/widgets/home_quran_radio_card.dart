import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../radio/data/services/quran_radio_service.dart';
import '../../../radio/presentation/widgets/quran_radio_sheet.dart';

/// Flagship 24/7 Live Quran Radio Card for Home page.
///
/// Reacts to live playback state from [QuranRadioService] with visual live
/// pulse indicator, current station title, and quick play/pause or station sheet.
class HomeQuranRadioCard extends StatelessWidget {
  final VoidCallback onTap;

  const HomeQuranRadioCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final radioService = QuranRadioService();

    return ListenableBuilder(
      listenable: radioService,
      builder: (context, _) {
        final isPlaying = radioService.isPlaying;
        final isConnecting = radioService.isConnecting;
        final currentStation = radioService.currentStation;

        final title = (isPlaying && currentStation != null)
            ? currentStation.name
            : 'إذاعة القرآن الكريم';

        final subtitle = isPlaying
            ? 'انقر لتغيير المحطة • استماع مباشر'
            : 'بث مباشر 24/7 لأعذب التلاوات والمحطات';

        return AppCard(
          color: palette.surfaceRaised,
          border: Border.all(
            color: isPlaying
                ? palette.primary.withValues(alpha: 0.35)
                : palette.border,
            width: isPlaying ? 1.5 : 1.0,
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          onTap: onTap,
          child: Row(
            children: [
              // Radio / Audio Squircle Badge
              Container(
                width: AppSize.buttonH,
                height: AppSize.buttonH,
                decoration: BoxDecoration(
                  color: isPlaying ? palette.goldSoft : palette.primarySoft,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Center(
                  child: Icon(
                    isPlaying ? Icons.sensors_rounded : Icons.radio_rounded,
                    color: isPlaying ? palette.gold : palette.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),

              // Title, Live Tag, and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live Status Pill / Label
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: AppIcon.xs,
                          height: AppIcon.xs,
                          decoration: BoxDecoration(
                            color: isPlaying
                                ? palette.prayer('الفجر')
                                : palette.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          isPlaying ? 'جارٍ البث المباشر' : 'بث مباشر 24/7',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isPlaying
                                ? palette.prayer('الفجر')
                                : palette.gold,
                            fontFamily: AppTextStyles.cairo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xxs),

                    // Station / Card Title
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: palette.text,
                        fontFamily: AppTextStyles.cairo,
                      ),
                    ),

                    // Subtitle
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: palette.textMuted,
                        fontFamily: AppTextStyles.cairo,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),

              // Play / Pause / Loading button
              Semantics(
                button: true,
                label: isPlaying ? 'إيقاف مؤقت' : 'تشغيل إذاعة القرآن',
                child: Tooltip(
                  message: isPlaying ? 'إيقاف مؤقت' : 'تشغيل الإذاعة',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: AppRadius.pillRadius,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        if (isPlaying) {
                          await radioService.pause();
                        } else {
                          if (currentStation != null) {
                            await radioService.resume();
                          } else if (radioService.stations.isNotEmpty) {
                            await radioService
                                .playStation(radioService.stations.first);
                          } else {
                            QuranRadioSheet.show(context);
                          }
                        }
                      },
                      child: Container(
                        width: AppSize.buttonH,
                        height: AppSize.buttonH,
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? palette.primary
                              : palette.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isConnecting
                              ? SizedBox(
                                  width: AppIcon.md,
                                  height: AppIcon.md,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isPlaying
                                        ? palette.onPrimary
                                        : palette.primary,
                                  ),
                                )
                              : Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: isPlaying
                                      ? palette.onPrimary
                                      : palette.primary,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
