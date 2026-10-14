import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhan_service.dart';
import '../../../../core/services/adhan_settings_service.dart';

class MuezzinItem {
  final AdhanSound sound;
  final String title;
  final String subtitle;
  final String tag;

  const MuezzinItem({
    required this.sound,
    required this.title,
    required this.subtitle,
    required this.tag,
  });
}

class PrayerMuezzinSelector extends StatefulWidget {
  final AdhanSettings settings;
  final AdhanService adhanService;
  final ValueChanged<AdhanSettings> onSettingsChanged;

  const PrayerMuezzinSelector({
    super.key,
    required this.settings,
    required this.adhanService,
    required this.onSettingsChanged,
  });

  @override
  State<PrayerMuezzinSelector> createState() => _PrayerMuezzinSelectorState();
}

class _PrayerMuezzinSelectorState extends State<PrayerMuezzinSelector> {
  AdhanSound? _currentlyPlayingSound;

  static const List<MuezzinItem> _muezzins = [
    MuezzinItem(
      sound: AdhanSound.qatami,
      title: 'أذان الشيخ ناصر القطامي',
      subtitle: 'أذان ندي خاشع (الافتراضي)',
      tag: 'الموصى به ★',
    ),
    MuezzinItem(
      sound: AdhanSound.makkah,
      title: 'أذان الحرم المكي الشريف',
      subtitle: 'الشيخ علي أحمد ملا (شيخ مؤذني الحرم المكي)',
      tag: 'مكة المكرمة',
    ),
    MuezzinItem(
      sound: AdhanSound.madinah,
      title: 'أذان المسجد النبوي الشريف',
      subtitle: 'المدينة المنورة (أذان شجي ووقور)',
      tag: 'المدينة المنورة',
    ),
    MuezzinItem(
      sound: AdhanSound.alafasy,
      title: 'أذان الشيخ مشاري العفاسي',
      subtitle: 'تسجيل استوديو عالي النقاوة',
      tag: 'استوديو نقي',
    ),
    MuezzinItem(
      sound: AdhanSound.abdulbasit,
      title: 'أذان الشيخ عبد الباسط عبد الصمد',
      subtitle: 'الأذان المصري التراثي الخاشع',
      tag: 'تراث أصيل',
    ),
    MuezzinItem(
      sound: AdhanSound.aqsa,
      title: 'أذان المسجد الأقصى المبارك',
      subtitle: 'القدس الشريف (الشيخ ناجي قزاز)',
      tag: 'القدس الشريف',
    ),
  ];

  Future<void> _togglePlayMuezzin(AdhanSound sound) async {
    HapticFeedback.lightImpact();
    if (_currentlyPlayingSound == sound && widget.adhanService.isPlaying) {
      await widget.adhanService.stop();
      setState(() => _currentlyPlayingSound = null);
      return;
    }

    setState(() => _currentlyPlayingSound = sound);
    await widget.adhanService.test(
      sound: sound,
      mode: PrayerNotificationMode.adhan,
      volume: widget.settings.volume,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return StreamBuilder<PlayerState>(
      stream: widget.adhanService.playerStateStream,
      builder: (context, snapshot) {
        final isAudioPlaying = widget.adhanService.isPlaying;
        final activePlayingSound = isAudioPlaying ? _currentlyPlayingSound : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.record_voice_over_rounded,
                  size: AppIcon.sm,
                  color: palette.primary,
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  'اختيار صوت المؤذن للأذان الكامل',
                  style: textTheme.label.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              'استمع لكل صوت عبر زر الاستماع، ثم اختر المؤذن المفضل لديك:',
              style: textTheme.caption.copyWith(color: palette.textMuted),
            ),
            const SizedBox(height: AppSpace.sm),

            ..._muezzins.map((item) {
              final isSelected = widget.settings.sound == item.sound;
              final isPlayingThis = activePlayingSound == item.sound;

              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onSettingsChanged(
                        widget.settings.copyWith(sound: item.sound),
                      );
                    },
                    borderRadius: AppRadius.mdRadius,
                    child: Container(
                      padding: const EdgeInsetsDirectional.all(AppSpace.sm),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? palette.primarySoft
                            : palette.surfaceMuted,
                        borderRadius: AppRadius.mdRadius,
                        border: Border.all(
                          color: isSelected
                              ? palette.primary
                              : palette.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected
                                ? palette.primary
                                : palette.textSubtle,
                            size: AppIcon.md,
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.title,
                                        style: textTheme.body.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? palette.onPrimarySoft
                                              : palette.text,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpace.xs),
                                    Container(
                                      padding:
                                          const EdgeInsetsDirectional.symmetric(
                                        horizontal: AppSpace.xs,
                                        vertical: AppSpace.xxs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? palette.primary.withValues(alpha: 0.15)
                                            : palette.surface,
                                        borderRadius: AppRadius.smRadius,
                                        border: Border.all(
                                          color: isSelected
                                              ? palette.primary
                                              : palette.border,
                                        ),
                                      ),
                                      child: Text(
                                        item.tag,
                                        style: textTheme.caption.copyWith(
                                          color: isSelected
                                              ? palette.primary
                                              : palette.textMuted,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpace.xxs),
                                Text(
                                  item.subtitle,
                                  style: textTheme.caption.copyWith(
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          // Instant Listen / Stop button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _togglePlayMuezzin(item.sound),
                              borderRadius: AppRadius.smRadius,
                              child: Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: AppSpace.sm,
                                  vertical: AppSpace.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: isPlayingThis
                                      ? palette.goldSoft
                                      : palette.surfaceRaised,
                                  borderRadius: AppRadius.smRadius,
                                  border: Border.all(
                                    color: isPlayingThis
                                        ? palette.gold
                                        : palette.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPlayingThis
                                          ? Icons.stop_rounded
                                          : Icons.play_arrow_rounded,
                                      size: AppIcon.sm,
                                      color: isPlayingThis
                                          ? palette.gold
                                          : palette.primary,
                                    ),
                                    const SizedBox(width: AppSpace.xxs),
                                    Text(
                                      isPlayingThis ? 'إيقاف' : 'استمع',
                                      style: textTheme.caption.copyWith(
                                        color: isPlayingThis
                                            ? palette.gold
                                            : palette.text,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
