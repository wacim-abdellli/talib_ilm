import 'dart:async';

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
import 'hifdh_repeat_controls.dart';

/// Interactive modal sheet providing scholarly Hifdh repetition tools:
/// 1. Single Ayah Repetitions (1x, 2x, 3x, 5x, 10x, ∞) for all reciters.
/// 2. Range Loop Engine (تكرار المقطع للحفظ بين آيتين محددتين مع عدد تكرارات)
///    working seamlessly with both verse-by-verse and full-surah reciters.
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
      maxHeightFactor: 0.90,
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
      _startAyah = activeRange.startAyah.clamp(1, totalAyahs);
      _endAyah = activeRange.endAyah.clamp(_startAyah, totalAyahs);
      _rangeRepeatCount = activeRange.repeatCount;
    } else {
      final safeCurrent = widget.currentAyah.clamp(1, totalAyahs);
      _startAyah = safeCurrent;
      _endAyah = (safeCurrent + 4).clamp(safeCurrent, totalAyahs);
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
    final start = _startAyah <= _endAyah ? _startAyah : _endAyah;
    final end = _endAyah >= _startAyah ? _endAyah : _startAyah;
    final repeatCount = _rangeRepeatCount;
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    final reciterName = widget.audioService.selectedReciter.name;
    final countLabel = repeatCount == 0 ? 'مستمر' : '$repeatCount مرات';

    Navigator.of(context).pop();
    unawaited(
      widget.audioService.playHifdhRange(
        surah: widget.surahNumber,
        startAyah: start,
        endAyah: end,
        repeatCount: repeatCount,
      ),
    );

    final rangeLabel =
        start == end ? 'الآية $start' : 'الآيات $start - $end';
    AppSnackbar.success(
      context,
      'بدء تكرار مقطع سورة $surahName ($rangeLabel) بصوت $reciterName • $countLabel',
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
    final reciterName = widget.audioService.selectedReciter.name;
    final safeCurrent = widget.currentAyah.clamp(1, totalAyahs);
    final fiveEnd = (safeCurrent + 4).clamp(safeCurrent, totalAyahs);

    return Container(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpace.md,
        bottom: AppSpace.lg,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceRaised,
        borderRadius: AppRadius.sheetTopRadius,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: AppSpace.xxl,
              height: AppSpace.xxs,
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
                        'سورة $surahName • الآية $safeCurrent • $reciterName',
                        style: textTheme.caption.copyWith(
                          color: palette.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                horizontal: AppSpace.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Section 1: Verse Repetition (تكرار الآية الواحدة) ───
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
                              color: palette.gold,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Expanded(
                              child: Text(
                                'تكرار الآية الواحدة',
                                style: textTheme.label.copyWith(
                                  color: palette.text,
                                  fontWeight: FontWeight.bold,
                                ),
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
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            widget.audioService.verseRepeatTargetNotifier,
                            widget.audioService.repeatModeNotifier,
                          ]),
                          builder: (context, _) {
                            final activeTarget = widget
                                .audioService.verseRepeatTargetNotifier.value;
                            final repeatMode =
                                widget.audioService.repeatModeNotifier.value;
                            final currentCount =
                                repeatMode == AudioRepeatMode.infinite
                                    ? 0
                                    : activeTarget;

                            return Wrap(
                              spacing: AppSpace.xs,
                              runSpacing: AppSpace.xs,
                              children: [
                                HifdhCountPill(
                                  label: 'معطل (1×)',
                                  count: 1,
                                  isSelected: currentCount == 1,
                                  onTap: () => _onVerseRepeatSelected(1),
                                ),
                                HifdhCountPill(
                                  label: 'مرتان (2×)',
                                  count: 2,
                                  isSelected: currentCount == 2,
                                  onTap: () => _onVerseRepeatSelected(2),
                                ),
                                HifdhCountPill(
                                  label: '3 مرات (سنة)',
                                  count: 3,
                                  isSelected: currentCount == 3,
                                  onTap: () => _onVerseRepeatSelected(3),
                                ),
                                HifdhCountPill(
                                  label: '5 مرات',
                                  count: 5,
                                  isSelected: currentCount == 5,
                                  onTap: () => _onVerseRepeatSelected(5),
                                ),
                                HifdhCountPill(
                                  label: '10 مرات (حفظ)',
                                  count: 10,
                                  isSelected: currentCount == 10,
                                  onTap: () => _onVerseRepeatSelected(10),
                                ),
                                HifdhCountPill(
                                  label: 'مستمر (∞)',
                                  count: 0,
                                  isSelected: currentCount == 0,
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

                  // ── Section 2: Range Loop (تكرار مقطع كامل للحفظ) ─────────
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
                              color: palette.primary,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Expanded(
                              child: Text(
                                'تكرار مقطع كامل للحفظ (Range Loop)',
                                style: textTheme.label.copyWith(
                                  color: palette.primary,
                                  fontWeight: FontWeight.bold,
                                ),
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
                        const SizedBox(height: AppSpace.sm),

                        // Quick Scope Presets
                        Wrap(
                          spacing: AppSpace.xs,
                          runSpacing: AppSpace.xs,
                          children: [
                            HifdhScopeChip(
                              label: 'الآية الحالية ($safeCurrent)',
                              isSelected: _startAyah == safeCurrent &&
                                  _endAyah == safeCurrent,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _startAyah = safeCurrent;
                                  _endAyah = safeCurrent;
                                });
                              },
                            ),
                            if (totalAyahs > 1)
                              HifdhScopeChip(
                                label: '5 آيات ($safeCurrent - $fiveEnd)',
                                isSelected: _startAyah == safeCurrent &&
                                    _endAyah == fiveEnd &&
                                    fiveEnd > safeCurrent,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _startAyah = safeCurrent;
                                    _endAyah = fiveEnd;
                                  });
                                },
                              ),
                            HifdhScopeChip(
                              label: 'السورة كاملة (1 - $totalAyahs)',
                              isSelected:
                                  _startAyah == 1 && _endAyah == totalAyahs,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _startAyah = 1;
                                  _endAyah = totalAyahs;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpace.sm),

                        // Range Selectors (From Ayah to Ayah — auto-adjusting bounds)
                        Row(
                          children: [
                            Expanded(
                              child: HifdhAyahStepper(
                                label: 'من الآية',
                                value: _startAyah,
                                min: 1,
                                max: totalAyahs,
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _startAyah = val.clamp(1, totalAyahs);
                                    if (_endAyah < _startAyah) {
                                      _endAyah = _startAyah;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(
                              child: HifdhAyahStepper(
                                label: 'إلى الآية',
                                value: _endAyah,
                                min: 1,
                                max: totalAyahs,
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _endAyah = val.clamp(1, totalAyahs);
                                    if (_startAyah > _endAyah) {
                                      _startAyah = _endAyah;
                                    }
                                  });
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
                            HifdhCountPill(
                              label: '1× (مرة)',
                              count: 1,
                              isSelected: _rangeRepeatCount == 1,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _rangeRepeatCount = 1);
                              },
                            ),
                            HifdhCountPill(
                              label: '3× (مرات)',
                              count: 3,
                              isSelected: _rangeRepeatCount == 3,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _rangeRepeatCount = 3);
                              },
                            ),
                            HifdhCountPill(
                              label: '5× (مرات)',
                              count: 5,
                              isSelected: _rangeRepeatCount == 5,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _rangeRepeatCount = 5);
                              },
                            ),
                            HifdhCountPill(
                              label: '10× (تثبيت)',
                              count: 10,
                              isSelected: _rangeRepeatCount == 10,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _rangeRepeatCount = 10);
                              },
                            ),
                            HifdhCountPill(
                              label: 'مستمر (∞)',
                              count: 0,
                              isSelected: _rangeRepeatCount == 0,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _rangeRepeatCount = 0);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpace.md),

                        // Active Range Status + Start/Update & Stop Buttons
                        ValueListenableBuilder<HifdhRangeConfig?>(
                          valueListenable:
                              widget.audioService.hifdhRangeNotifier,
                          builder: (context, activeRange, _) {
                            final isRangeActive = activeRange != null &&
                                activeRange.surah == widget.surahNumber;
                            final spanCount = _endAyah - _startAyah + 1;
                            final spanLabel = spanCount == 1
                                ? 'آية واحدة'
                                : '$spanCount آيات';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (isRangeActive) ...[
                                  Container(
                                    padding: const EdgeInsetsDirectional.all(
                                      AppSpace.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: palette.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: AppRadius.smRadius,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'المقطع قيد التكرار الآن: الآيات (${activeRange.startAyah} - ${activeRange.endAyah}) • دورة ${activeRange.currentIteration + 1} من ${activeRange.isInfinite ? "∞" : activeRange.repeatCount}',
                                        style: textTheme.captionBold.copyWith(
                                          color: palette.primary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.sm),
                                ],
                                AppButton(
                                  label:
                                      'بدء تكرار المقطع ($spanLabel)',
                                  icon: Icons.play_arrow_rounded,
                                  onPressed: _startRangePlayback,
                                ),
                                if (isRangeActive) ...[
                                  const SizedBox(height: AppSpace.xs),
                                  AppButton(
                                    label: 'إيقاف تكرار المقطع',
                                    icon: Icons.stop_rounded,
                                    variant: AppButtonVariant.outline,
                                    onPressed: _stopRangePlayback,
                                  ),
                                ],
                              ],
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
}
