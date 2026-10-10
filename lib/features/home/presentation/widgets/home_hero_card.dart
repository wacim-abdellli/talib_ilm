import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';
import '../../../prayer/data/models/prayer_models.dart';

/// HomeHeroCard - Calm Scholar Prayer Time Centerpiece
class HomeHeroCard extends StatefulWidget {
  final String nextPrayerName;
  final DateTime nextPrayerTime;
  final bool isEstimated;
  final Map<String, DateTime>? allPrayers;
  final VoidCallback? onTap;

  const HomeHeroCard({
    super.key,
    required this.nextPrayerName,
    required this.nextPrayerTime,
    this.isEstimated = false,
    this.allPrayers,
    this.onTap,
  });

  @override
  State<HomeHeroCard> createState() => _HomeHeroCardState();
}

class _HomeHeroCardState extends State<HomeHeroCard> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(_getTimerDuration(), (_) {
      _updateTimeLeft();
      if (_timeLeft.inMinutes < 1 && _timer.tick % 60 != 0) {
        _resetTimer();
      }
    });
  }

  Duration _getTimerDuration() {
    return _timeLeft.inMinutes < 1
        ? const Duration(seconds: 1)
        : const Duration(minutes: 1);
  }

  void _resetTimer() {
    _timer.cancel();
    _startTimer();
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final diff = widget.nextPrayerTime.difference(now);
    if (mounted) {
      final newTime = diff.isNegative ? Duration.zero : diff;
      setState(() => _timeLeft = newTime);
    }
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    final prayerTimeDisplay = formatPrayerTime12h(widget.nextPrayerTime);
    final nearnessLabel = _getNearnessLabel();

    return Semantics(
      label: 'الصلاة القادمة: ${widget.nextPrayerName}',
      hint: 'المتبقي ${_getReadableDuration()}',
      button: true,
      onTapHint: 'اضغط لعرض تفاصيل الصلاة',
      child: AppCard(
        onTap: widget.onTap,
        padding: const EdgeInsetsDirectional.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Status Chip + Mosque Medallion
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Chip
                Flexible(
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.primarySoft,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: palette.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _timeLeft.inMinutes < 15
                                ? palette.gold
                                : palette.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Flexible(
                          child: Text(
                            nearnessLabel,
                            style: textTheme.caption.copyWith(
                              color: palette.onPrimarySoft,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                // Mosque Medallion
                const IconBadge(
                  icon: Icons.mosque_rounded,
                ),
              ],
            ),

            const SizedBox(height: AppSpace.lg),

            // Next Prayer Name & Time Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Prayer Name with Decorative Accent Dot
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: AppSpace.sm,
                        height: AppSpace.sm,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.gold,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Flexible(
                        child: Text(
                          widget.nextPrayerName,
                          style: textTheme.display.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpace.sm),

                // Adhan Time Capsule (Western Arabic numerals 123456)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: palette.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: AppIcon.sm,
                        color: palette.primary,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        prayerTimeDisplay,
                        style: textTheme.label.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpace.md),

            // Countdown Header
            Text(
              'الوقت المتبقي للأذان',
              style: textTheme.caption.copyWith(
                color: palette.textSubtle,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpace.xs),

            // Countdown Timer (In Left-to-Right order: Hours : Minutes : Seconds)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CountdownDigitCapsule(
                      value: hours,
                      label: 'ساعة',
                    ),
                    const _CountdownSeparator(),
                    _CountdownDigitCapsule(
                      value: minutes,
                      label: 'دقيقة',
                    ),
                    const _CountdownSeparator(),
                    _CountdownDigitCapsule(
                      value: seconds,
                      label: 'ثانية',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpace.lg),

            // 5 Daily Prayers Timeline Strip (Unique Journey Track)
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: AppStrings.prayerOrder.map((prayerName) {
                    final isCurrent = widget.nextPrayerName == prayerName;
                    final prayerTime = widget.allPrayers?[prayerName];
                    final isPast = prayerTime != null &&
                        prayerTime.isBefore(DateTime.now());

                    return _buildTimelineStation(
                      context: context,
                      prayerName: prayerName,
                      prayerTime: prayerTime,
                      isCurrent: isCurrent,
                      isPast: isPast,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStation({
    required BuildContext context,
    required String prayerName,
    required DateTime? prayerTime,
    required bool isCurrent,
    required bool isPast,
  }) {
    final palette = context.palette;
    final textTheme = context.text;
    final timeStr =
        prayerTime != null ? formatPrayerTime12h(prayerTime) : '';
    final icon = _iconForPrayer(prayerName);

    return Container(
      width: 68,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.xs,
        vertical: AppSpace.sm,
      ),
      margin: const EdgeInsetsDirectional.symmetric(horizontal: 2),
      decoration: isCurrent
          ? BoxDecoration(
              color: palette.surfaceRaised,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: palette.primary,
                width: 1.5,
              ),
              boxShadow: palette.shadow,
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active Indicator Dot
          if (isCurrent)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(bottom: AppSpace.xs),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.gold,
              ),
            )
          else
            const SizedBox(height: 6 + AppSpace.xs),

          // Icon
          Icon(
            isPast && !isCurrent ? Icons.check_circle_outline_rounded : icon,
            size: isCurrent ? AppIcon.md : AppIcon.sm,
            color: isCurrent
                ? palette.primary
                : (isPast ? palette.textSubtle : palette.textMuted),
          ),
          const SizedBox(height: AppSpace.xs),

          // Prayer Name
          Text(
            prayerName,
            style: isCurrent
                ? textTheme.label.copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                  )
                : textTheme.caption.copyWith(
                    color: isPast ? palette.textMuted : palette.text,
                    fontWeight: FontWeight.w600,
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Prayer Time with Western Arabic numerals (123456)
          if (timeStr.isNotEmpty)
            Text(
              timeStr,
              style: isCurrent
                  ? textTheme.caption.copyWith(
                      color: palette.text,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )
                  : textTheme.caption.copyWith(
                      color: isPast ? palette.textSubtle : palette.textMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  IconData _iconForPrayer(String name) {
    if (name.contains(AppStrings.prayerFajr) || name == 'الفجر') {
      return Icons.wb_twilight_rounded;
    }
    if (name == 'الشروق') {
      return Icons.wb_sunny_rounded;
    }
    if (name.contains(AppStrings.prayerDhuhr) || name == 'الظهر') {
      return Icons.wb_sunny_rounded;
    }
    if (name.contains(AppStrings.prayerAsr) || name == 'العصر') {
      return Icons.wb_sunny_outlined;
    }
    if (name.contains(AppStrings.prayerMaghrib) || name == 'المغرب') {
      return Icons.nights_stay_outlined;
    }
    if (name.contains(AppStrings.prayerIsha) || name == 'العشاء') {
      return Icons.bedtime_rounded;
    }
    return Icons.access_time_rounded;
  }

  String _getNearnessLabel() {
    final minutes = _timeLeft.inMinutes;
    if (minutes <= 0) {
      return 'حان وقت الأذان';
    }
    if (minutes <= 5) {
      return 'يقترب جداً (5 دقائق)';
    }
    if (minutes <= 15) {
      return 'يقترب وقت الصلاة';
    }
    if (minutes <= 30) {
      return 'خلال نصف ساعة';
    }
    return 'الصلاة القادمة';
  }

  String _getReadableDuration() {
    final hours = _timeLeft.inHours;
    final minutes = _timeLeft.inMinutes % 60;
    if (hours > 0) {
      return '$hours ساعة و $minutes دقيقة';
    }
    return '$minutes دقيقة';
  }
}

class _CountdownDigitCapsule extends StatelessWidget {
  final String value;
  final String label;

  const _CountdownDigitCapsule({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 42,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: palette.border,
            ),
            boxShadow: palette.shadow,
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: textTheme.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          label,
          style: textTheme.caption.copyWith(
            color: palette.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CountdownSeparator extends StatelessWidget {
  const _CountdownSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: Text(
              ':',
              style: context.text.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: context.palette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
