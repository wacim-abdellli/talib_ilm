import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/services/quran_audio_service.dart';
import '../../data/services/quran_tafsir_service.dart';

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
                  style: (isSelected ? textTheme.captionHeavy : textTheme.captionBold).copyWith(
                    color: textColor,
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

  void _showPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    final palette = context.palette;
    final textTheme = context.text;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsetsDirectional.only(top: AppSpace.sm),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.all(AppSpace.md),
                child: Text(
                  'اختر القارئ',
                  style: textTheme.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(height: 1, color: palette.border),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: QuranAudioService.reciters.map((r) {
                    final isCurrent = r.id == selectedReciter.id;
                    return ListTile(
                      title: Text(
                        r.name,
                        style: textTheme.body.copyWith(
                          color: isCurrent ? palette.primary : palette.text,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isCurrent
                          ? Icon(Icons.check_circle_rounded, color: palette.primary, size: AppIcon.sm)
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(ctx);
                        onSelected(r);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      onTap: () => _showPicker(context),
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
                const SizedBox(height: AppSpace.xxs),
                Text(
                  selectedReciter.name,
                  style: textTheme.captionBold.copyWith(
                    color: palette.primary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: palette.textMuted,
            size: AppIcon.md,
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

  void _showPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    final palette = context.palette;
    final textTheme = context.text;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsetsDirectional.only(top: AppSpace.sm),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.all(AppSpace.md),
                child: Text(
                  'اختر كتاب التفسير',
                  style: textTheme.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(height: 1, color: palette.border),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: TafsirScholar.values.map((s) {
                    final isCurrent = s == selectedTafsir;
                    return ListTile(
                      title: Text(
                        QuranTafsirService.getScholarName(s),
                        style: textTheme.body.copyWith(
                          color: isCurrent ? palette.gold : palette.text,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isCurrent
                          ? Icon(Icons.check_circle_rounded, color: palette.gold, size: AppIcon.sm)
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(ctx);
                        onSelected(s);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return AppCard(
      onTap: () => _showPicker(context),
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
                const SizedBox(height: AppSpace.xxs),
                Text(
                  QuranTafsirService.getScholarName(selectedTafsir),
                  style: textTheme.captionBold.copyWith(
                    color: palette.gold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: palette.textMuted,
            size: AppIcon.md,
          ),
        ],
      ),
    );
  }
}
