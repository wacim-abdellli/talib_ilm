import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../prayer/data/models/prayer_models.dart';
import '../../../prayer/presentation/widgets/prayer_widget_state_evaluator.dart';
import 'home_hero_timeline_station.dart';

/// HomeHeroCard - Calm Scholar Prayer Time Centerpiece
class HomeHeroCard extends StatefulWidget {
  final String nextPrayerName;
  final DateTime nextPrayerTime;
  final bool isEstimated;
  final Map<String, DateTime>? allPrayers;
  final Map<String, int> iqamaOverrides;
  final VoidCallback? onTap;
  final DateTime? currentTime;

  const HomeHeroCard({
    super.key,
    required this.nextPrayerName,
    required this.nextPrayerTime,
    this.isEstimated = false,
    this.allPrayers,
    this.iqamaOverrides = const {},
    this.onTap,
    this.currentTime,
  });

  @override
  State<HomeHeroCard> createState() => _HomeHeroCardState();
}

class _PrayerEvaluation {
  final String prayerName;
  final DateTime prayerTime;
  final bool isInPrayerTime;
  final bool isInIqamaCountdown;
  final Duration elapsedSinceAdhan;
  final Duration remainingUntilAdhan;
  final Duration remainingUntilIqama;
  final String activeHighlightPrayerName;
  final Set<String> completedPrayerNames;

  const _PrayerEvaluation({
    required this.prayerName,
    required this.prayerTime,
    required this.isInPrayerTime,
    this.isInIqamaCountdown = false,
    required this.elapsedSinceAdhan,
    required this.remainingUntilAdhan,
    this.remainingUntilIqama = Duration.zero,
    required this.activeHighlightPrayerName,
    required this.completedPrayerNames,
  });
}

class _HomeHeroCardState extends State<HomeHeroCard> {
  Timer? _timer;
  late _PrayerEvaluation _eval;

  @override
  void initState() {
    super.initState();
    _eval = _evaluatePrayer(widget.currentTime ?? DateTime.now());
    if (widget.currentTime == null) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(covariant HomeHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextPrayerTime != widget.nextPrayerTime ||
        oldWidget.nextPrayerName != widget.nextPrayerName ||
        oldWidget.allPrayers != widget.allPrayers ||
        oldWidget.iqamaOverrides != widget.iqamaOverrides ||
        oldWidget.currentTime != widget.currentTime) {
      _updateEvaluation();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(AppMotion.oneSecond, (_) {
      _updateEvaluation();
    });
  }

  void _updateEvaluation() {
    final now = widget.currentTime ?? DateTime.now();
    final newEval = _evaluatePrayer(now);
    if (mounted) {
      setState(() => _eval = newEval);
    }
  }

  _PrayerEvaluation _evaluatePrayer(DateTime now) {
    final all = widget.allPrayers;
    if (all != null && all.isNotEmpty) {
      final entries = AppStrings.prayerOrder
          .where((p) => all.containsKey(p))
          .map((p) => MapEntry(p, all[p]!))
          .toList();

      // 1. Check if the most recent prayer is currently within active Iqama or Salah window
      for (int i = entries.length - 1; i >= 0; i--) {
        final entry = entries[i];
        final pName = entry.key;
        final pTime = entry.value;
        if (!now.isBefore(pTime)) {
          final elapsed = now.difference(pTime);
          final isJumua = now.weekday == DateTime.friday && pName == AppStrings.prayerDhuhr;
          final iqamaMinutes = PrayerWidgetStateEvaluator.getIqamaMinutes(
            pName,
            isJumua: isJumua,
            iqamaOverrides: widget.iqamaOverrides,
          );
          final salahMinutes = PrayerWidgetStateEvaluator.getSalahDurationMinutes(pName, isJumua: isJumua);
          final iqamaDuration = Duration(minutes: iqamaMinutes);
          final salahDuration = Duration(minutes: iqamaMinutes + salahMinutes);

          if (elapsed < salahDuration) {
            final completed = entries.take(i).map((e) => e.key).toSet();
            final isIqama = elapsed < iqamaDuration;
            final remainingIqama = isIqama ? pTime.add(iqamaDuration).difference(now) : Duration.zero;
            return _PrayerEvaluation(
              prayerName: pName,
              prayerTime: pTime,
              isInPrayerTime: true,
              isInIqamaCountdown: isIqama,
              elapsedSinceAdhan: elapsed,
              remainingUntilAdhan: Duration.zero,
              remainingUntilIqama: remainingIqama,
              activeHighlightPrayerName: pName,
              completedPrayerNames: completed,
            );
          }
          break;
        }
      }

      // 2. Find next upcoming prayer today
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        if (entry.value.isAfter(now)) {
          final completed = entries.take(i).map((e) => e.key).toSet();
          return _PrayerEvaluation(
            prayerName: entry.key,
            prayerTime: entry.value,
            isInPrayerTime: false,
            elapsedSinceAdhan: Duration.zero,
            remainingUntilAdhan: entry.value.difference(now),
            activeHighlightPrayerName: entry.key,
            completedPrayerNames: completed,
          );
        }
      }

      // 3. All today's prayers completed: next prayer is tomorrow's Fajr
      final fajrToday = all[AppStrings.prayerFajr] ?? now;
      final fajrTomorrow = DateTime(
        now.year,
        now.month,
        now.day + 1,
        fajrToday.hour,
        fajrToday.minute,
      );
      final allCompleted = entries.map((e) => e.key).toSet();
      return _PrayerEvaluation(
        prayerName: AppStrings.prayerFajr,
        prayerTime: fajrTomorrow,
        isInPrayerTime: false,
        elapsedSinceAdhan: Duration.zero,
        remainingUntilAdhan: fajrTomorrow.difference(now),
        activeHighlightPrayerName: AppStrings.prayerFajr,
        completedPrayerNames: allCompleted,
      );
    }

    final diff = widget.nextPrayerTime.difference(now);
    final isJumua = now.weekday == DateTime.friday && widget.nextPrayerName == AppStrings.prayerDhuhr;
    final fallbackIqamaMin = PrayerWidgetStateEvaluator.getIqamaMinutes(
      widget.nextPrayerName,
      isJumua: isJumua,
      iqamaOverrides: widget.iqamaOverrides,
    );
    final fallbackSalahMin = PrayerWidgetStateEvaluator.getSalahDurationMinutes(widget.nextPrayerName, isJumua: isJumua);
    final fallbackIqamaDur = Duration(minutes: fallbackIqamaMin);
    final fallbackSalahDur = Duration(minutes: fallbackIqamaMin + fallbackSalahMin);

    if (diff.isNegative && (-diff) < fallbackSalahDur) {
      final elapsed = -diff;
      final isIqama = elapsed < fallbackIqamaDur;
      final remainingIqama = isIqama ? fallbackIqamaDur - elapsed : Duration.zero;
      return _PrayerEvaluation(
        prayerName: widget.nextPrayerName,
        prayerTime: widget.nextPrayerTime,
        isInPrayerTime: true,
        isInIqamaCountdown: isIqama,
        elapsedSinceAdhan: elapsed,
        remainingUntilAdhan: Duration.zero,
        remainingUntilIqama: remainingIqama,
        activeHighlightPrayerName: widget.nextPrayerName,
        completedPrayerNames: const {},
      );
    }

    return _PrayerEvaluation(
      prayerName: widget.nextPrayerName,
      prayerTime: widget.nextPrayerTime,
      isInPrayerTime: false,
      elapsedSinceAdhan: Duration.zero,
      remainingUntilAdhan: diff.isNegative ? Duration.zero : diff,
      activeHighlightPrayerName: widget.nextPrayerName,
      completedPrayerNames: const {},
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final eval = _eval;
    final prayerColor = palette.prayer(eval.prayerName);

    final hours = eval.remainingUntilAdhan.inHours.toString().padLeft(2, '0');
    final minutes = (eval.remainingUntilAdhan.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (eval.remainingUntilAdhan.inSeconds % 60).toString().padLeft(2, '0');

    final iqamaMinutesStr = (eval.remainingUntilIqama.inMinutes % 60).toString().padLeft(2, '0');
    final iqamaSecondsStr = (eval.remainingUntilIqama.inSeconds % 60).toString().padLeft(2, '0');

    final prayerTimeDisplay = formatPrayerTime12h(eval.prayerTime);
    final nearnessLabel = _getNearnessLabel(eval);

    return Semantics(
      label: eval.isInPrayerTime
          ? 'صلاة ${eval.prayerName} - ${eval.isInIqamaCountdown ? 'بقي على الإقامة' : 'تقام الصلاة الآن'}'
          : 'صلاة ${eval.prayerName}',
      hint: eval.isInPrayerTime
          ? (eval.isInIqamaCountdown
              ? 'بقي على الإقامة ${_getReadableDuration(eval.remainingUntilIqama)}'
              : 'تقام الصلاة الآن في المسجد')
          : 'المتبقي ${_getReadableDuration(eval.remainingUntilAdhan)}',
      button: true,
      onTapHint: 'اضغط لعرض تفاصيل الصلاة',
      child: AppCard(
        onTap: widget.onTap,
        color: palette.surfaceRaised,
        border: Border.all(
          color: palette.border,
          width: 1.2,
        ),
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Unified Single-Line Header: [Medallion + Prayer Name] on Start, [Adhan Time Jewel] on End
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Start: Prayer Medallion + Large Prayer Name
                  Expanded(
                    child: Row(
                      children: [
                        // Celestial Medallion with Luminous Tint & Border
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: prayerColor.withValues(alpha: eval.isInPrayerTime ? 0.22 : 0.14),
                            borderRadius: AppRadius.mdRadius,
                            border: Border.all(
                              color: prayerColor.withValues(alpha: eval.isInPrayerTime ? 0.55 : 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            iconForPrayer(eval.prayerName),
                            color: prayerColor,
                            size: AppIcon.md,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),

                        // Large Prayer Title (Uncluttered, Single Line)
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'صلاة ',
                                  style: textTheme.title.copyWith(
                                    color: palette.text,
                                  ),
                                ),
                                TextSpan(
                                  text: eval.prayerName,
                                  style: textTheme.title.copyWith(
                                    color: prayerColor,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpace.sm),

                  // End: Adhan Time Jewel Pill (Standard Arabic numerals 123456)
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: prayerColor.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: AppIcon.xs,
                          color: prayerColor,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          prayerTimeDisplay,
                          style: textTheme.label.copyWith(
                            color: palette.text,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpace.md),

              // 2. Horizon Countdown / Salat Time Banner
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.sm,
                ),
                decoration: BoxDecoration(
                  color: prayerColor.withValues(alpha: eval.isInPrayerTime ? 0.16 : 0.10),
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: prayerColor.withValues(alpha: eval.isInPrayerTime ? 0.35 : 0.22),
                    width: 1,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Start: Status / Nearness Indicator with Pulse Dot
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: AppSpace.sm,
                            height: AppSpace.sm,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: prayerColor,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            nearnessLabel,
                            style: textTheme.label.copyWith(
                              color: prayerColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpace.lg),

                      // End: Digital Precision Clock or Iqama / Salah Box
                      if (eval.isInPrayerTime)
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpace.md,
                            vertical: AppSpace.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: palette.surfaceRaised,
                            borderRadius: AppRadius.smRadius,
                            border: Border.all(
                              color: prayerColor.withValues(alpha: 0.45),
                              width: 1.2,
                            ),
                            boxShadow: palette.shadow,
                          ),
                          child: eval.isInIqamaCountdown
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.mosque_rounded,
                                      size: AppIcon.xs,
                                      color: prayerColor,
                                    ),
                                    const SizedBox(width: AppSpace.xs),
                                    Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            iqamaMinutesStr,
                                            style: textTheme.titleSmall.copyWith(
                                              color: prayerColor,
                                              fontFeatures: const [FontFeature.tabularFigures()],
                                            ),
                                          ),
                                          CountdownColon(color: prayerColor),
                                          Text(
                                            iqamaSecondsStr,
                                            style: textTheme.titleSmall.copyWith(
                                              color: prayerColor,
                                              fontFeatures: const [FontFeature.tabularFigures()],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.people_alt_rounded,
                                      size: AppIcon.xs,
                                      color: prayerColor,
                                    ),
                                    const SizedBox(width: AppSpace.xs),
                                    Text(
                                      'أداء الفريضة',
                                      style: textTheme.label.copyWith(
                                        color: prayerColor,
                                      ),
                                    ),
                                  ],
                                ),
                        )
                      else
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpace.md,
                              vertical: AppSpace.xs + 2,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceRaised,
                              borderRadius: AppRadius.smRadius,
                              border: Border.all(
                                color: prayerColor.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                              boxShadow: palette.shadow,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hours,
                                  style: textTheme.titleSmall.copyWith(
                                    color: palette.text,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                                CountdownColon(color: prayerColor),
                                Text(
                                  minutes,
                                  style: textTheme.titleSmall.copyWith(
                                    color: palette.text,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                                CountdownColon(color: prayerColor),
                                Text(
                                  seconds,
                                  style: textTheme.titleSmall.copyWith(
                                    color: prayerColor,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpace.md),

              // 3. Bottom: 5 Daily Prayers Journey Strip with Authentic Celestial Jewel Tones
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: AppSpace.sm,
                  horizontal: AppSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: AppRadius.lgRadius,
                  border: Border.all(
                    color: palette.border,
                  ),
                ),
                child: Row(
                  children: AppStrings.prayerOrder.map((prayerName) {
                    final isCurrent = eval.activeHighlightPrayerName == prayerName;
                    final prayerTime = widget.allPrayers?[prayerName];
                    final isPast = eval.completedPrayerNames.contains(prayerName);

                    return HomeHeroTimelineStation(
                      prayerName: prayerName,
                      prayerTime: prayerTime,
                      isCurrent: isCurrent,
                      isPast: isPast,
                      isInPrayerTime: isCurrent && eval.isInPrayerTime,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNearnessLabel(_PrayerEvaluation eval) {
    if (eval.isInPrayerTime) {
      if (eval.isInIqamaCountdown) {
        return 'بقي على الإقامة';
      }
      return 'تقام الصلاة الآن';
    }
    final minutes = eval.remainingUntilAdhan.inMinutes;
    if (minutes <= 5) {
      return 'يقترب وقت الصلاة';
    }
    return 'بقي على الأذان';
  }

  String _getReadableDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}
