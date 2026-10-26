import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/services/adhan_service.dart';
import '../../../../core/services/adhan_settings_service.dart';

class VoiceOptionItem {
  final AdhanSound? sound;
  final PrayerNotificationMode mode;
  final String title;
  final String subtitle;
  final String tag;
  final IconData? tagIcon;
  final IconData icon;
  final bool isFullAdhan;

  const VoiceOptionItem({
    this.sound,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.tag,
    this.tagIcon,
    required this.icon,
    this.isFullAdhan = true,
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
  VoiceOptionItem? _activePlayingVoice;

  static const List<VoiceOptionItem> _fullAdhanVoices = [
    VoiceOptionItem(
      sound: AdhanSound.qatami,
      mode: PrayerNotificationMode.adhan,
      title: 'أذان الشيخ ناصر القطامي',
      subtitle: 'أذان ندي خاشع بمقام حجازي وقور',
      tag: 'الموصى به',
      tagIcon: Icons.star_rounded,
      icon: Icons.record_voice_over_rounded,
    ),
    VoiceOptionItem(
      sound: AdhanSound.makkah,
      mode: PrayerNotificationMode.adhan,
      title: 'أذان الحرم المكي الشريف',
      subtitle: 'الشيخ علي أحمد ملا (شيخ مؤذني المسجد الحرام)',
      tag: 'مكة المكرمة',
      tagIcon: Icons.location_on_outlined,
      icon: Icons.mosque_rounded,
    ),
    VoiceOptionItem(
      sound: AdhanSound.madinah,
      mode: PrayerNotificationMode.adhan,
      title: 'أذان المسجد النبوي الشريف',
      subtitle: 'الشيخ عصام بخاري (أذان المدينة المنورة الشجي)',
      tag: 'المدينة المنورة',
      tagIcon: Icons.location_on_outlined,
      icon: Icons.mosque_rounded,
    ),
    VoiceOptionItem(
      sound: AdhanSound.alafasy,
      mode: PrayerNotificationMode.adhan,
      title: 'أذان الشيخ مشاري راشد العفاسي',
      subtitle: 'تسجيل استوديو عالي النقاوة والوضوح الصوتي',
      tag: 'استوديو نقي',
      tagIcon: Icons.graphic_eq_rounded,
      icon: Icons.mic_none_rounded,
    ),
    VoiceOptionItem(
      sound: AdhanSound.abdulbasit,
      mode: PrayerNotificationMode.adhan,
      title: 'أذان الشيخ عبد الباسط عبد الصمد',
      subtitle: 'الأذان المصري التراثي النادر ذو النبرة الخاشعة',
      tag: 'تراث أصيل',
      tagIcon: Icons.history_edu_rounded,
      icon: Icons.auto_stories_rounded,
    ),
    VoiceOptionItem(
      sound: AdhanSound.aqsa,
      mode: PrayerNotificationMode.adhan,
      title: 'أذان المسجد الأقصى المبارك',
      subtitle: 'القدس الشريف (بصوت مؤذن الأقصى الشيخ ناجي قزاز)',
      tag: 'القدس الشريف',
      tagIcon: Icons.location_on_outlined,
      icon: Icons.place_outlined,
    ),
  ];

  static const List<VoiceOptionItem> _alternativeVoices = [
    VoiceOptionItem(
      sound: AdhanSound.takbeer,
      mode: PrayerNotificationMode.takbeer,
      title: 'تكبيرات الأذان فقط',
      subtitle: 'تكبيرات الأذان والتنبيه السريع (الله أكبر الله أكبر)',
      tag: 'سريع ومختصر',
      tagIcon: Icons.bolt_rounded,
      icon: Icons.campaign_outlined,
      isFullAdhan: false,
    ),
    VoiceOptionItem(
      sound: null,
      mode: PrayerNotificationMode.announcement,
      title: 'نداء وقت الصلاة الوقور',
      subtitle: 'نداء صوتي مسجل: "حان الآن وقت صلاة الفجر / الظهر..."',
      tag: 'نداء صوتي',
      tagIcon: Icons.record_voice_over_outlined,
      icon: Icons.hearing_outlined,
      isFullAdhan: false,
    ),
  ];

  bool _isOptionSelected(VoiceOptionItem item) {
    if (item.mode == PrayerNotificationMode.announcement) {
      return widget.settings.defaultMode == PrayerNotificationMode.announcement;
    }
    if (item.mode == PrayerNotificationMode.takbeer) {
      return widget.settings.defaultMode == PrayerNotificationMode.takbeer ||
          widget.settings.sound == AdhanSound.takbeer;
    }
    return widget.settings.defaultMode == PrayerNotificationMode.adhan &&
        widget.settings.effectiveMuezzinSound == item.sound;
  }

  void _selectOption(VoiceOptionItem item) {
    HapticFeedback.selectionClick();
    if (item.mode == PrayerNotificationMode.announcement) {
      widget.onSettingsChanged(
        widget.settings.copyWith(
          defaultMode: PrayerNotificationMode.announcement,
        ),
      );
    } else if (item.mode == PrayerNotificationMode.takbeer) {
      widget.onSettingsChanged(
        widget.settings.copyWith(
          sound: AdhanSound.takbeer,
          defaultMode: PrayerNotificationMode.takbeer,
        ),
      );
    } else {
      widget.onSettingsChanged(
        widget.settings.copyWith(
          sound: item.sound,
          defaultMode: PrayerNotificationMode.adhan,
        ),
      );
    }
  }

  Future<void> _togglePreview(VoiceOptionItem item) async {
    HapticFeedback.lightImpact();
    final isPlayingThis =
        widget.adhanService.isPlaying && _activePlayingVoice == item;

    if (isPlayingThis) {
      await widget.adhanService.stop();
      if (mounted) setState(() => _activePlayingVoice = null);
      return;
    }

    if (mounted) setState(() => _activePlayingVoice = item);
    await widget.adhanService.test(
      sound: item.sound ?? AdhanSound.qatami,
      mode: item.mode,
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
        final currentPlaying = isAudioPlaying ? _activePlayingVoice : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Volume and test card
            _buildVolumeCard(palette, textTheme, currentPlaying),
            const SizedBox(height: AppSpace.lg),

            // Section 1: Full Adhan Muezzins
            Row(
              children: [
                Icon(
                  Icons.mosque_rounded,
                  size: AppIcon.sm,
                  color: palette.primary,
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  'أصوات الأذان الكامل (كبار المؤذنين)',
                  style: textTheme.label.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              'اختر المؤذن المفضل لسماع الأذان كاملاً عند دخول وقت الصلاة:',
              style: textTheme.caption.copyWith(color: palette.textMuted),
            ),
            const SizedBox(height: AppSpace.sm),

            ..._fullAdhanVoices.map((item) {
              return _buildVoiceCard(
                item: item,
                palette: palette,
                textTheme: textTheme,
                isSelected: _isOptionSelected(item),
                isPlaying: currentPlaying == item,
              );
            }),

            const SizedBox(height: AppSpace.lg),

            // Section 2: Alternative Voices
            Row(
              children: [
                Icon(
                  Icons.campaign_rounded,
                  size: AppIcon.sm,
                  color: palette.primary,
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  'أصوات وتنبيهات بديلة',
                  style: textTheme.label.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              'خيارات صوتية سريعة أو وقورة بديلة عن الأذان الكامل:',
              style: textTheme.caption.copyWith(color: palette.textMuted),
            ),
            const SizedBox(height: AppSpace.sm),

            ..._alternativeVoices.map((item) {
              return _buildVoiceCard(
                item: item,
                palette: palette,
                textTheme: textTheme,
                isSelected: _isOptionSelected(item),
                isPlaying: currentPlaying == item,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildVolumeCard(
    AppPalette palette,
    AppTextTheme textTheme,
    VoiceOptionItem? currentPlaying,
  ) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.md),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      size: AppIcon.sm,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
                      child: Text(
                        'مستوى صوت الأذان والتنبيه',
                        style: textTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: palette.primary.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${widget.settings.volume.toInt()}%',
                  style: textTheme.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Row(
            children: [
              Icon(
                Icons.volume_mute_rounded,
                size: AppIcon.sm,
                color: palette.textMuted,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: palette.primary,
                    inactiveTrackColor: palette.border,
                    thumbColor: palette.primary,
                    overlayColor: palette.primarySoft,
                  ),
                  child: Slider(
                    value: widget.settings.volume,
                    min: 0,
                    max: 100,
                    onChanged: (val) {
                      widget.adhanService.setVolume(val);
                      widget.onSettingsChanged(
                        widget.settings.copyWith(volume: val),
                      );
                    },
                  ),
                ),
              ),
              Icon(
                Icons.volume_up_rounded,
                size: AppIcon.sm,
                color: palette.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCard({
    required VoiceOptionItem item,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required bool isSelected,
    required bool isPlaying,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpace.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectOption(item),
          borderRadius: AppRadius.mdRadius,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsetsDirectional.all(AppSpace.sm),
            decoration: BoxDecoration(
              color: isSelected ? palette.primarySoft : palette.surfaceRaised,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: isSelected ? palette.primary : palette.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Radio icon
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? palette.primary : palette.textSubtle,
                  size: AppIcon.md,
                ),
                const SizedBox(width: AppSpace.sm),

                // Icon indicator
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? palette.primary : palette.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    size: AppIcon.sm,
                    color: isSelected ? palette.onPrimary : palette.textMuted,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),

                // Title + Subtitle + Tag
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.title,
                              style: (isSelected
                                      ? textTheme.bodyHeavy
                                      : textTheme.bodyBold)
                                  .copyWith(
                                color: isSelected
                                    ? palette.onPrimarySoft
                                    : palette.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? palette.primary.withValues(alpha: 0.15)
                                  : palette.surfaceMuted,
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: isSelected
                                    ? palette.primary
                                    : palette.border,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (item.tagIcon != null) ...[
                                  Icon(
                                    item.tagIcon,
                                    size: AppIcon.xs,
                                    color: isSelected
                                        ? palette.primary
                                        : palette.textMuted,
                                  ),
                                  const SizedBox(width: AppSpace.xxs),
                                ],
                                Text(
                                  item.tag,
                                  style: textTheme.caption.copyWith(
                                    color: isSelected
                                        ? palette.primary
                                        : palette.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        item.subtitle,
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpace.xs),

                // Audio Preview Button
                IconButton(
                  tooltip: isPlaying ? 'إيقاف الاستماع' : 'استماع للصوت',
                  constraints: const BoxConstraints(
                    minWidth: AppSize.tap,
                    minHeight: AppSize.tap,
                  ),
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isPlaying ? palette.primary : palette.primarySoft,
                      shape: BoxShape.circle,
                      border: isPlaying
                          ? Border.all(
                              color: palette.primary.withValues(alpha: 0.5),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      color:
                          isPlaying ? palette.onPrimary : palette.primary,
                      size: AppIcon.sm,
                    ),
                  ),
                  onPressed: () => _togglePreview(item),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
