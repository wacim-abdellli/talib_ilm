import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../core/utils/arabic_digits.dart';
import '../../../../shared/widgets/app_button.dart';
import 'quick_jump_sheet.dart';
import 'surah_objectives_sheet.dart';

export 'mushaf_reader_bottom_bar.dart';

class MushafReaderTopBar extends StatelessWidget {
  final int currentSurah;
  final int currentPage;
  final int currentAyah;
  final MushafThemeMode themeMode;
  final String? currentSurahTitle;
  final int? currentJuzNumber;
  final ValueChanged<int> onJumpToPage;
  final VoidCallback onOpenSettings;
  final VoidCallback? onToggleTheme;

  const MushafReaderTopBar({
    super.key,
    required this.currentSurah,
    required this.currentPage,
    required this.currentAyah,
    this.themeMode = MushafThemeMode.white,
    this.currentSurahTitle,
    this.currentJuzNumber,
    required this.onJumpToPage,
    required this.onOpenSettings,
    this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final surahTitle =
        currentSurahTitle ??
        getVocalizedSurahName(
          currentSurah,
          fallback: quran.getSurahNameArabic(currentSurah),
        );
    final juzNum =
        currentJuzNumber ?? quran.getJuzNumber(currentSurah, currentAyah);

    final barBg = MushafColors.overlayBgFor(themeMode, palette);
    final barBorder = MushafColors.overlayBorderFor(themeMode, palette);
    final textColor = MushafColors.overlayTextFor(themeMode, palette);
    final textMutedColor = MushafColors.overlayTextMutedFor(themeMode, palette);

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(bottom: BorderSide(color: barBorder)),
        boxShadow: palette.shadow,
      ),
      child: Row(
        children: [
          // Back button
          AppIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'رجوع',
            color: textColor,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: AppSpace.xs),

          // Surah & Page Title (Tap to Jump)
          Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                QuickJumpSheet.show(context, onJumpToPage: onJumpToPage);
              },
              borderRadius: AppRadius.smRadius,
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.xxs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              surahTitle,
                              style: textTheme.titleSmall.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: palette.gold,
                          size: AppIcon.sm,
                        ),
                      ],
                    ),
                    Text(
                      '${getArabicJuzName(juzNum)} • الصفحة $currentPage',
                      style: textTheme.caption.copyWith(color: textMutedColor),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Quick Jump Button
          AppIconButton(
            icon: Icons.explore_rounded,
            tooltip: 'انتقال سريع وفهرس السور',
            color: palette.gold,
            onPressed: () {
              HapticFeedback.lightImpact();
              QuickJumpSheet.show(context, onJumpToPage: onJumpToPage);
            },
          ),

          // Surah Objectives Info Button
          AppIconButton(
            icon: Icons.info_outline_rounded,
            tooltip: 'بطاقة السورة ومقاصدها',
            color: palette.gold,
            onPressed: () {
              HapticFeedback.lightImpact();
              SurahObjectivesSheet.show(
                context,
                surahNumber: currentSurah,
                onNavigateToVerse: (s, a) {
                  final p = quran.getPageNumber(s, a);
                  onJumpToPage(p);
                },
              );
            },
          ),

          // 1-Tap Theme Toggle Button (Day / Night)
          if (onToggleTheme != null)
            AppIconButton(
              icon: themeMode == MushafThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              tooltip: themeMode == MushafThemeMode.dark
                  ? 'الوضع الورقي'
                  : 'الوضع الليلي الداكن',
              color: palette.gold,
              onPressed: () {
                HapticFeedback.lightImpact();
                onToggleTheme!();
              },
            ),

          // Settings Button
          AppIconButton(
            icon: Icons.tune_rounded,
            tooltip: 'الإعدادات',
            color: textColor,
            onPressed: onOpenSettings,
          ),
        ],
      ),
    );
  }
}
