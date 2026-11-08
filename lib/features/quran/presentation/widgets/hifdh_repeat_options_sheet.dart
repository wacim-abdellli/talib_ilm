import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;

import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_ui.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../data/services/quran_audio_service.dart';

/// Interactive modal sheet providing scholarly Hifdh repetition tools:
/// 1. Single Ayah Repetitions (1x, 2x, 3x, 5x, 10x, ∞).
/// 2. Range Loop Engine (تكرار المقطع للحفظ بين آيتين محددتين مع عدد تكرارات).
/// 3. Educational & Scholarly Reciter switching.
class HifdhRepeatOptionsSheet extends StatefulWidget {
  final QuranAudioService audioService;
  final int surahNumber;
  final int currentAyah;

  const HifdhRepeatOptionsSheet({
    super.key,
    required this.audioService,
    required this.surahNumber,
    required this.currentAyah,
  });

  static Future<void> show(
    BuildContext context, {
    required QuranAudioService audioService,
    required int surahNumber,
    required int currentAyah,
  }) {
    return AppSheet.show<void>(
      context: context,
      maxHeightFactor: 0.88,
      enableDrag: true,
      builder: (_) => HifdhRepeatOptionsSheet(
        audioService: audioService,
        surahNumber: surahNumber,
        currentAyah: currentAyah,
      ),
    );
  }

  @override
  State<HifdhRepeatOptionsSheet> createState() =>
      _HifdhRepeatOptionsSheetState();
}

class _HifdhRepeatOptionsSheetState extends State<HifdhRepeatOptionsSheet> {
  late int _startAyah;
  late int _endAyah;
  int _rangeRepeatCount = 3;

  @override
  void initState() {
    super.initState();
    final activeRange = widget.audioService.hifdhRangeNotifier.value;
    final totalAyahs = quran.getVerseCount(widget.surahNumber);

    if (activeRange != null && activeRange.surah == widget.surahNumber) {
      _startAyah = activeRange.startAyah;
      _endAyah = activeRange.endAyah;
      _rangeRepeatCount = activeRange.repeatCount;
    } else {
      _startAyah = widget.currentAyah;
      _endAyah = (widget.currentAyah + 4).clamp(1, totalAyahs);
    }
  }

  void _onVerseRepeatSelected(int count) {
    HapticFeedback.selectionClick();
    widget.audioService.setVerseRepeatCount(count);

    final String message = switch (count) {
      0 => 'تم ضبط التكرار المستمر للآية (∞)',
      1 => 'تم إلغاء التكرار (تلاوة عادية)',
      2 => 'سيتم تكرار الآية مرتين',
      3 => 'سيتم تكرار الآية 3 مرات (سنة الحفظ)',
      5 => 'سيتم تكرار الآية 5 مرات',
      10 => 'سيتم تكرار الآية 10 مرات لتثبيت الحفظ',
      _ => 'تم ضبط تكرار الآية $count مرات',
    };
    AppSnackbar.info(context, message);
    setState(() {});
  }

  void _startRangePlayback() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    widget.audioService.playHifdhRange(
      surah: widget.surahNumber,
      startAyah: _startAyah,
      endAyah: _endAyah,
      repeatCount: _rangeRepeatCount,
    );
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    final countLabel =
        _rangeRepeatCount == 0 ? 'مستمر' : '$_rangeRepeatCount مرات';
    AppSnackbar.success(
      context,
      'بدء تكرار مقطع سورة $surahName (الآيات $_startAyah - $_endAyah) • $countLabel',
    );
  }

  void _stopRangePlayback() {
    HapticFeedback.mediumImpact();
    widget.audioService.clearHifdhRange();
    widget.audioService.stop();
    Navigator.of(context).pop();
    AppSnackbar.info(context, 'تم إيقاف تكرار المقطع');
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    final totalAyahs = quran.getVerseCount(widget.surahNumber);

    return Container(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpace.md,
        bottom: AppSpace.lg,
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
          // Drag Handle
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

          // Header Row
          Padding(
            padding:
                const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
            child: Row(
              children: [
                const IconBadge(icon: Icons.all_inclusive_rounded),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تكرار الحفظ والمراجعة',
                        style: textTheme.titleSmall.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'سورة $surahName • الآية ${widget.currentAyah}',
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpace.xs),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: AppSpace.md),

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Section 1: Verse Repetition (تكرار الآية الحالية) ───
                  Container(
                    padding: const EdgeInsetsDirectional.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: palette.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.repeat_one_rounded,
                              size: AppIcon.sm,
                              color: palette.gold,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              'تكرار الآية الواحدة',
                              style: textTheme.label.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          'تكرار الآية الحالية عدة مرات لتثبيتها قبل الانتقال للتالية:',
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        ValueListenableBuilder<int>(
                          valueListenable:
                              widget.audioService.verseRepeatTargetNotifier,
                          builder: (context, activeTarget, _) {
                            final repeatMode = widget
                                .audioService.repeatModeNotifier.value;
                            final currentCount =
                                repeatMode == AudioRepeatMode.infinite
                                    ? 0
                                    : activeTarget;

                            return Wrap(
                              spacing: AppSpace.xs,
                              runSpacing: AppSpace.xs,
                              children: [
                                _buildCountPill(
                                  label: 'معطل (1×)',
                                  count: 1,
                                  isSelected: currentCount == 1,
                                  palette: palette,
                                  textTheme: textTheme,
                                  onTap: () => _onVerseRepeatSelected(1),
                                ),
                                _buildCountPill(
                                  label: 'مرتان (2×)',
                                  count: 2,
                                  isSelected: currentCount == 2,
                                  palette: palette,
                                  textTheme: textTheme,
                                  onTap: () => _onVerseRepeatSelected(2),
                                ),
                                _buildCountPill(
                                  label: '3 مرات (سنة)',
                                  count: 3,
                                  isSelected: currentCount == 3,
                                  palette: palette,
                                  textTheme: textTheme,
                                  onTap: () => _onVerseRepeatSelected(3),
                                ),
                                _buildCountPill(
                                  label: '5 مرات',
                                  count: 5,
                                  isSelected: currentCount == 5,
                                  palette: palette,
                                  textTheme: textTheme,
                                  onTap: () => _onVerseRepeatSelected(5),
                                ),
                                _buildCountPill(
                                  label: '10 مرات (حفظ)',
                                  count: 10,
                                  isSelected: currentCount == 10,
                                  palette: palette,
                                  textTheme: textTheme,
                                  onTap: () => _onVerseRepeatSelected(10),
                                ),
                                _buildCountPill(
                                  label: 'مستمر (∞)',
                                  count: 0,
                                  isSelected: currentCount == 0,
                                  palette: palette,
                                  textTheme: textTheme,
                                  onTap: () => _onVerseRepeatSelected(0),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.md),

                  // ── Section 2: Range Loop (تكرار مقطع للحفظ) ─────────────
                  Container(
                    padding: const EdgeInsetsDirectional.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: palette.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.all_inclusive_rounded,
                              size: AppIcon.sm,
                              color: palette.primary,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              'تكرار مقطع كامل للحفظ (Range Loop)',
                              style: textTheme.label.copyWith(
                                color: palette.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Text(
                          'تكرار قراءة نطاق من الآيات لربط المحفوظ وتثبيته في الذاكرة:',
                          style: textTheme.caption.copyWith(
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),

                        // Range Selectors (From Ayah to Ayah)
                        Row(
                          children: [
                            // Start Ayah
                            Expanded(
                              child: _buildAyahStepper(
                                label: 'من الآية',
                                value: _startAyah,
                                min: 1,
                                max: _endAyah,
                                palette: palette,
                                textTheme: textTheme,
                                onChanged: (val) {
                                  setState(() => _startAyah = val);
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            // End Ayah
                            Expanded(
                              child: _buildAyahStepper(
                                label: 'إلى الآية',
                                value: _endAyah,
                                min: _startAyah,
                                max: totalAyahs,
                                palette: palette,
                                textTheme: textTheme,
                                onChanged: (val) {
                                  setState(() => _endAyah = val);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpace.md),

                        // Repetitions for the whole range
                        Text(
                          'عدد مرات تكرار المقطع:',
                          style: textTheme.captionBold.copyWith(
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Wrap(
                          spacing: AppSpace.xs,
                          runSpacing: AppSpace.xs,
                          children: [
                            _buildCountPill(
                              label: '1× (مرة)',
                              count: 1,
                              isSelected: _rangeRepeatCount == 1,
                              palette: palette,
                              textTheme: textTheme,
                              onTap: () =>
                                  setState(() => _rangeRepeatCount = 1),
                            ),
                            _buildCountPill(
                              label: '3× (مرات)',
                              count: 3,
                              isSelected: _rangeRepeatCount == 3,
                              palette: palette,
                              textTheme: textTheme,
                              onTap: () =>
                                  setState(() => _rangeRepeatCount = 3),
                            ),
                            _buildCountPill(
                              label: '5× (مرات)',
                              count: 5,
                              isSelected: _rangeRepeatCount == 5,
                              palette: palette,
                              textTheme: textTheme,
                              onTap: () =>
                                  setState(() => _rangeRepeatCount = 5),
                            ),
                            _buildCountPill(
                              label: '10× (تثبيت)',
                              count: 10,
                              isSelected: _rangeRepeatCount == 10,
                              palette: palette,
                              textTheme: textTheme,
                              onTap: () =>
                                  setState(() => _rangeRepeatCount = 10),
                            ),
                            _buildCountPill(
                              label: 'مستمر (∞)',
                              count: 0,
                              isSelected: _rangeRepeatCount == 0,
                              palette: palette,
                              textTheme: textTheme,
                              onTap: () =>
                                  setState(() => _rangeRepeatCount = 0),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpace.md),

                        // Active Range State or Start Button
                        ValueListenableBuilder<HifdhRangeConfig?>(
                          valueListenable:
                              widget.audioService.hifdhRangeNotifier,
                          builder: (context, activeRange, _) {
                            final isRangeActive = activeRange != null &&
                                activeRange.surah == widget.surahNumber;

                            if (isRangeActive) {
                              final iter = activeRange.currentIteration + 1;
                              final total = activeRange.isInfinite
                                  ? '∞'
                                  : '${activeRange.repeatCount}';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(
                                    padding: const EdgeInsetsDirectional.all(
                                        AppSpace.xs),
                                    decoration: BoxDecoration(
                                      color: palette.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: AppRadius.smRadius,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'المقطع قيد التكرار الآن: الآيات (${activeRange.startAyah} - ${activeRange.endAyah}) • دورة $iter من $total',
                                        style: textTheme.captionBold.copyWith(
                                          color: palette.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.sm),
                                  AppButton(
                                    label: 'إيقاف تكرار المقطع',
                                    icon: Icons.stop_rounded,
                                    variant: AppButtonVariant.outline,
                                    onPressed: _stopRangePlayback,
                                  ),
                                ],
                              );
                            }

                            return AppButton(
                              label:
                                  'بدء تكرار المقطع (${_endAyah - _startAyah + 1} آيات)',
                              icon: Icons.play_arrow_rounded,
                              onPressed: _startRangePlayback,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpace.sm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountPill({
    required String label,
    required int count,
    required bool isSelected,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillRadius,
        child: Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? palette.primary : palette.surfaceRaised,
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: isSelected ? palette.primary : palette.border,
            ),
          ),
          child: Text(
            label,
            style: textTheme.caption.copyWith(
              color: isSelected ? palette.surfaceRaised : palette.text,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAyahStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required AppPalette palette,
    required AppTextTheme textTheme,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: textTheme.caption.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: AppSpace.xxs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'إنقاص الآية',
                icon: const Icon(Icons.remove_circle_outline_rounded),
                iconSize: AppIcon.sm,
                color: value > min ? palette.primary : palette.textMuted,
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.xs),
                child: Text(
                  '$value',
                  style: textTheme.titleSmall.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'زيادة الآية',
                icon: const Icon(Icons.add_circle_outline_rounded),
                iconSize: AppIcon.sm,
                color: value < max ? palette.primary : palette.textMuted,
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
