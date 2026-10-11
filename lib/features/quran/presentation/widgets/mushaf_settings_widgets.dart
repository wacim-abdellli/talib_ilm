import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/quran_tafsir_service.dart';
import 'mushaf_settings_sheet.dart';

class MushafReadingModeCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final QuranReadingMode mode;
  final bool isSelected;
  final ValueChanged<QuranReadingMode> onSelected;

  const MushafReadingModeCard({
    super.key,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.mode,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onSelected(mode);
        },
        borderRadius: AppRadius.mdRadius,
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.md),
          decoration: BoxDecoration(
            color: isSelected ? palette.primarySoft.withValues(alpha: 0.15) : palette.surfaceMuted,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: isSelected ? palette.primary : palette.border,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? palette.primary : palette.textMuted,
                size: AppIcon.md,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                label,
                style: textTheme.caption.copyWith(
                  color: isSelected ? palette.primary : palette.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                sublabel,
                textAlign: TextAlign.center,
                style: textTheme.caption.copyWith(
                  color: palette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MushafTajweedLegendWidget extends StatelessWidget {
  const MushafTajweedLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final rules = [
      {'title': 'غنة مشددة', 'color': TajweedPalette.ghunnah},
      {'title': 'قلقلة', 'color': TajweedPalette.qalqalah},
      {'title': 'إخفاء', 'color': TajweedPalette.ikhfaa},
      {'title': 'إدغام', 'color': TajweedPalette.idgham},
      {'title': 'إقلاب', 'color': TajweedPalette.iqlab},
      {'title': 'مدود', 'color': TajweedPalette.madd},
    ];

    return Wrap(
      spacing: AppSpace.md,
      runSpacing: AppSpace.xs,
      children: rules.map((r) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: r['color'] as Color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Text(
              r['title'] as String,
              style: textTheme.caption.copyWith(
                color: palette.textMuted,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class MushafThemeCard extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final MushafThemeMode mode;
  final bool isSelected;
  final ValueChanged<MushafThemeMode> onSelected;

  const MushafThemeCard({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    required this.mode,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(mode);
          },
          borderRadius: AppRadius.mdRadius,
          child: Container(
            height: 64,
            padding: AppSpace.insetXs,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: isSelected ? palette.primary : palette.border,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: textTheme.caption.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                if (isSelected)
                  PositionedDirectional(
                    top: 2,
                    end: 2,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: palette.primary,
                      size: AppIcon.sm,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MushafReciterDropdownCard extends StatelessWidget {
  final QuranReciter selectedReciter;
  final ValueChanged<QuranReciter> onSelected;

  const MushafReciterDropdownCard({
    super.key,
    required this.selectedReciter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.record_voice_over_rounded,
            color: palette.primary,
            size: AppIcon.md,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'القارئ الافتراضي',
                  style: textTheme.body.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  selectedReciter.name,
                  style: textTheme.caption.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xs),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: palette.border, width: 0.8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<QuranReciter>(
                value: selectedReciter,
                icon: Icon(
                  Icons.unfold_more_rounded,
                  color: palette.primary,
                  size: AppIcon.sm,
                ),
                dropdownColor: palette.surfaceRaised,
                borderRadius: AppRadius.mdRadius,
                selectedItemBuilder: (_) => QuranAudioService.reciters
                    .map((r) => const SizedBox.shrink())
                    .toList(),
                items: QuranAudioService.reciters.map((r) {
                  return DropdownMenuItem<QuranReciter>(
                    value: r,
                    child: Text(
                      r.name,
                      style: textTheme.bodySmall.copyWith(
                        color: palette.text,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    HapticFeedback.selectionClick();
                    onSelected(val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MushafTafsirDropdownCard extends StatelessWidget {
  final TafsirScholar selectedTafsir;
  final ValueChanged<TafsirScholar> onSelected;

  const MushafTafsirDropdownCard({
    super.key,
    required this.selectedTafsir,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      child: Row(
        children: [
          Icon(
            Icons.auto_stories_rounded,
            color: palette.gold,
            size: AppIcon.md,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرجع التفسير المعتمد',
                  style: textTheme.body.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  QuranTafsirService.getScholarName(selectedTafsir),
                  style: textTheme.caption.copyWith(
                    color: palette.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xs),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: palette.border, width: 0.8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TafsirScholar>(
                value: selectedTafsir,
                icon: Icon(
                  Icons.unfold_more_rounded,
                  color: palette.gold,
                  size: AppIcon.sm,
                ),
                dropdownColor: palette.surfaceRaised,
                borderRadius: AppRadius.mdRadius,
                selectedItemBuilder: (_) => TafsirScholar.values
                    .map((s) => const SizedBox.shrink())
                    .toList(),
                items: TafsirScholar.values.map((s) {
                  return DropdownMenuItem<TafsirScholar>(
                    value: s,
                    child: Text(
                      QuranTafsirService.getScholarName(s),
                      style: textTheme.bodySmall.copyWith(
                        color: palette.text,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    HapticFeedback.selectionClick();
                    onSelected(val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
