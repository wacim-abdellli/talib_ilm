import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/quran_tafsir_service.dart';
import 'mushaf_settings_widgets.dart';
// MushafThemeMode & QuranReadingMode enums live in app_palette.dart; re-export for compatibility.
export '../../../../app/theme/app_palette.dart' show MushafThemeMode, QuranReadingMode;

class MushafSettingsSheet extends StatefulWidget {
  final MushafThemeMode currentTheme;
  final bool isTajweedEnabled;
  final bool keepScreenAwake;
  final QuranReciter selectedReciter;
  final TafsirScholar selectedTafsir;
  final ValueChanged<MushafThemeMode> onThemeChanged;
  final ValueChanged<bool> onTajweedChanged;
  final ValueChanged<bool> onKeepScreenAwakeChanged;
  final ValueChanged<QuranReciter> onReciterChanged;
  final ValueChanged<TafsirScholar> onTafsirChanged;

  const MushafSettingsSheet({
    super.key,
    required this.currentTheme,
    required this.isTajweedEnabled,
    required this.keepScreenAwake,
    required this.selectedReciter,
    required this.selectedTafsir,
    required this.onThemeChanged,
    required this.onTajweedChanged,
    required this.onKeepScreenAwakeChanged,
    required this.onReciterChanged,
    required this.onTafsirChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required MushafThemeMode currentTheme,
    required bool isTajweedEnabled,
    required bool keepScreenAwake,
    required QuranReciter selectedReciter,
    required TafsirScholar selectedTafsir,
    required ValueChanged<MushafThemeMode> onThemeChanged,
    required ValueChanged<bool> onTajweedChanged,
    required ValueChanged<bool> onKeepScreenAwakeChanged,
    required ValueChanged<QuranReciter> onReciterChanged,
    required ValueChanged<TafsirScholar> onTafsirChanged,
  }) {
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.88,
      builder: (_) => MushafSettingsSheet(
        currentTheme: currentTheme,
        isTajweedEnabled: isTajweedEnabled,
        keepScreenAwake: keepScreenAwake,
        selectedReciter: selectedReciter,
        selectedTafsir: selectedTafsir,
        onThemeChanged: onThemeChanged,
        onTajweedChanged: onTajweedChanged,
        onKeepScreenAwakeChanged: onKeepScreenAwakeChanged,
        onReciterChanged: onReciterChanged,
        onTafsirChanged: onTafsirChanged,
      ),
    );
  }

  @override
  State<MushafSettingsSheet> createState() => _MushafSettingsSheetState();
}

class _MushafSettingsSheetState extends State<MushafSettingsSheet> {
  late MushafThemeMode _theme;
  late bool _tajweed;
  late bool _keepScreenAwake;
  late QuranReciter _reciter;
  late TafsirScholar _tafsir;

  @override
  void initState() {
    super.initState();
    _theme = widget.currentTheme;
    _tajweed = widget.isTajweedEnabled;
    _keepScreenAwake = widget.keepScreenAwake;
    _reciter = widget.selectedReciter;
    _tafsir = widget.selectedTafsir;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpace.md,
        bottom: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),

          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
            child: Row(
              children: [
                const IconBadge(icon: Icons.tune_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات وتخصيص المصحف',
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'نمط العرض، ألوان الصفحات، التجويد، والقارئ',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                AppIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'إغلاق',
                  color: palette.textMuted,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.sm),
          Divider(height: 1, color: palette.border),

          Flexible(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsetsDirectional.only(
                start: AppSpace.xl,
                end: AppSpace.xl,
                top: AppSpace.md,
                bottom: AppSpace.xxl + 48,
              ),
              children: [


                Text(
                  'لون صفحة المصحف',
                  style: textTheme.caption.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Row(
                  children: [
                    MushafThemeCard(
                      label: 'أبيض ناصع',
                      color: MushafColors.whiteBg,
                      textColor: MushafColors.whiteText,
                      mode: MushafThemeMode.white,
                      isSelected: _theme == MushafThemeMode.white,
                      onSelected: (mode) {
                        setState(() => _theme = mode);
                        widget.onThemeChanged(mode);
                      },
                    ),
                    const SizedBox(width: AppSpace.sm),
                    MushafThemeCard(
                      label: 'ورقي بيج',
                      color: MushafColors.sepiaBg,
                      textColor: MushafColors.sepiaText,
                      mode: MushafThemeMode.sepia,
                      isSelected: _theme == MushafThemeMode.sepia,
                      onSelected: (mode) {
                        setState(() => _theme = mode);
                        widget.onThemeChanged(mode);
                      },
                    ),
                    const SizedBox(width: AppSpace.sm),
                    MushafThemeCard(
                      label: 'ليلي داكن',
                      color: MushafColors.darkBg,
                      textColor: MushafColors.darkText,
                      mode: MushafThemeMode.dark,
                      isSelected: _theme == MushafThemeMode.dark,
                      onSelected: (mode) {
                        setState(() => _theme = mode);
                        widget.onThemeChanged(mode);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppSpace.xl),

                // Tajweed Toggle & Rules Legend
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette_rounded,
                            color: palette.primary,
                            size: AppIcon.md,
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تلوين أحكام التجويد',
                                  style: textTheme.body.copyWith(
                                    color: palette.text,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'تمييز الغنة، القلقلة، والمدود حرفياً في قائمة الآيات',
                                  style: textTheme.caption.copyWith(
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _tajweed,
                            activeColor: palette.onPrimary,
                            activeTrackColor: palette.primary,
                            inactiveThumbColor: palette.textMuted,
                            inactiveTrackColor: palette.surfaceMuted,
                            trackOutlineColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.selected)
                                  ? Colors.transparent
                                  : palette.border,
                            ),
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _tajweed = val);
                              widget.onTajweedChanged(val);
                            },
                          ),
                        ],
                      ),
                      if (_tajweed) ...[
                        const SizedBox(height: AppSpace.md),
                        Divider(height: 1, color: palette.border),
                        const SizedBox(height: AppSpace.sm),
                        const MushafTajweedLegendWidget(),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.md),

                // Keep Screen Awake Toggle
                AppCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.light_mode_rounded,
                        color: palette.gold,
                        size: AppIcon.md,
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إبقاء الشاشة مضاءة أثناء القراءة',
                              style: textTheme.body.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'منع قفل الشاشة تلقائياً أثناء تلاوة القرآن',
                              style: textTheme.caption.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _keepScreenAwake,
                        activeColor: palette.onPrimary,
                        activeTrackColor: palette.gold,
                        inactiveThumbColor: palette.textMuted,
                        inactiveTrackColor: palette.surfaceMuted,
                        trackOutlineColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? Colors.transparent
                              : palette.border,
                        ),
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _keepScreenAwake = val);
                          widget.onKeepScreenAwakeChanged(val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpace.md),

                MushafReciterDropdownCard(
                  selectedReciter: _reciter,
                  onSelected: (val) {
                    setState(() => _reciter = val);
                    widget.onReciterChanged(val);
                  },
                ),

                const SizedBox(height: AppSpace.md),

                MushafTafsirDropdownCard(
                  selectedTafsir: _tafsir,
                  onSelected: (val) {
                    setState(() => _tafsir = val);
                    widget.onTafsirChanged(val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
