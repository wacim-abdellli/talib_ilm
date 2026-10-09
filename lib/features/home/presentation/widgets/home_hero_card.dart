import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/icon_badge.dart';

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
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    final prayerTimeDisplay = intl.DateFormat.jm(
      'ar',
    ).format(widget.nextPrayerTime);
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      color: context.palette.primarySoft,
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: context.palette.border,
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
                                ? context.palette.gold
                                : context.palette.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Flexible(
                          child: Text(
                            nearnessLabel,
                            style: context.text.caption.copyWith(
                              color: context.palette.onPrimarySoft,
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
                // Icon Badge
                const IconBadge(
                  icon: Icons.mosque_rounded,
                ),
              ],
            ),

            const SizedBox(height: AppSpace.lg),

            // Next Prayer Name & Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.palette.gold,
                        ),
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Flexible(
                        child: Text(
                          widget.nextPrayerName,
                          style: context.text.title.copyWith(
                            color: context.palette.text,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xs,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceMuted,
                    borderRadius: AppRadius.smRadius,
                    border: Border.all(
                      color: context.palette.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: AppIcon.sm,
                        color: context.palette.textMuted,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Text(
                        prayerTimeDisplay,
                        style: context.text.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpace.md),

            // Countdown in display/text colour (not gold)
            Text(
              'الوقت المتبقي',
              style: context.text.caption.copyWith(
                color: context.palette.textSubtle,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _TimeDigitBadge(value: hours, label: 'ساعة'),
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.xs,
                    ),
                    child: Text(
                      ':',
                      style: context.text.title.copyWith(
                        color: context.palette.textMuted,
                      ),
                    ),
                  ),
                  _TimeDigitBadge(value: minutes, label: 'دقيقة'),
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.xs,
                    ),
                    child: Text(
                      ':',
                      style: context.text.title.copyWith(
                        color: context.palette.textMuted,
                      ),
                    ),
                  ),
                  _TimeDigitBadge(value: seconds, label: 'ثانية'),
                ],
              ),
            ),

            const SizedBox(height: AppSpace.lg),

            // 5 Daily Prayers Timeline Strip
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                vertical: AppSpace.sm,
                horizontal: AppSpace.xs,
              ),
              decoration: BoxDecoration(
                color: context.palette.surfaceMuted,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(
                  color: context.palette.border,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                  _buildTimelinePrayer(
                    AppStrings.prayerFajr,
                    Icons.nightlight_round,
                  ),
                  _buildTimelinePrayer(
                    AppStrings.prayerDhuhr,
                    Icons.wb_sunny_rounded,
                  ),
                  _buildTimelinePrayer(
                    AppStrings.prayerAsr,
                    Icons.wb_sunny_outlined,
                  ),
                  _buildTimelinePrayer(
                    AppStrings.prayerMaghrib,
                    Icons.wb_twilight_rounded,
                  ),
                  _buildTimelinePrayer(
                    AppStrings.prayerIsha,
                    Icons.bedtime_rounded,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTimelinePrayer(String prayerName, IconData icon) {
    final isCurrent = widget.nextPrayerName == prayerName;
    final prayerTime = widget.allPrayers?[prayerName];
    final timeStr = prayerTime != null
        ? intl.DateFormat.jm('ar').format(prayerTime)
        : '';

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      decoration: isCurrent
          ? BoxDecoration(
              color: context.palette.primarySoft,
              borderRadius: AppRadius.smRadius,
              border: Border.all(
                color: context.palette.border,
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCurrent) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.palette.gold,
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
              ],
              Icon(
                icon,
                size: AppIcon.sm,
                color: isCurrent
                    ? context.palette.primary
                    : context.palette.textSubtle,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            prayerName,
            style: context.text.caption.copyWith(
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent
                  ? context.palette.text
                  : context.palette.textMuted,
            ),
          ),
          if (timeStr.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              timeStr,
              style: context.text.caption.copyWith(
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                color: isCurrent
                    ? context.palette.textMuted
                    : context.palette.textSubtle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getNearnessLabel() {
    final minutes = _timeLeft.inMinutes;
    if (minutes <= 0) {
      return 'حان وقت الأذان';
    }
    if (minutes <= 5) {
      return 'يقترب جداً (٥ دقائق)';
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

class _TimeDigitBadge extends StatelessWidget {
  final String value;
  final String label;

  const _TimeDigitBadge({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.sm,
            vertical: AppSpace.xs,
          ),
          decoration: BoxDecoration(
            color: context.palette.surfaceMuted,
            borderRadius: AppRadius.smRadius,
            border: Border.all(
              color: context.palette.border,
            ),
          ),
          child: Text(
            value,
            style: context.text.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.palette.text,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          label,
          style: context.text.caption.copyWith(
            color: context.palette.textSubtle,
          ),
        ),
      ],
    );
  }
}
