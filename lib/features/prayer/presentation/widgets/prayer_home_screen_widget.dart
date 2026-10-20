import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../home/presentation/widgets/home_hero_timeline_station.dart';
import '../../data/models/prayer_models.dart';

/// PrayerHomeScreenWidget - Exact High-Fidelity Representation of the
/// Talib Ilm Prayer Card / Widget (matching Pic 2).
///
/// Designed to be rendered:
/// 1) On the Android Phone Launcher Home Screen via `home_widget`
/// 2) Or directly inside the application as a standalone hero card.
class PrayerHomeScreenWidget extends StatelessWidget {
  final PrayerTimesDay? prayerDay;
  final DateTime? referenceTime;
  final String? nextPrayerName;
  final DateTime? nextPrayerTime;

  final double width;
  final double height;

  const PrayerHomeScreenWidget({
    super.key,
    this.prayerDay,
    this.referenceTime,
    this.nextPrayerName,
    this.nextPrayerTime,
    this.width = 380,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final now = referenceTime ?? DateTime.now();

    final all = prayerDay?.prayers ?? _buildFallbackPrayers(now);
    final eval = _evaluatePrayer(now, all);

    final prayerColor = palette.prayer(eval.activePrayerName);
    final nextTimeDisplay = formatPrayerTime12h(eval.nextPrayerTime);
    final contentWidth = width - (AppSpace.md * 2);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color: palette.border,
              width: 1.2,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: contentWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Row: [Adhan Time Pill] on Start (Left), [Prayer Medallion + Name] on End (Right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Next / Current Prayer Time Pill with Clock Icon
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: AppSpace.sm,
                          vertical: AppSpace.xs,
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
                              size: AppIcon.sm,
                              color: prayerColor,
                            ),
                            const SizedBox(width: AppSpace.xs),
                            Text(
                              nextTimeDisplay,
                              style: textTheme.label.copyWith(
                                fontWeight: FontWeight.w800,
                                color: palette.text,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: AppSpace.xs),

                      // Prayer Title & Celestial Medallion (Right in RTL)
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'صلاة ${eval.activePrayerName}',
                                style: textTheme.titleSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: palette.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpace.sm),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: prayerColor.withValues(alpha: 0.14),
                                borderRadius: AppRadius.mdRadius,
                                border: Border.all(
                                  color: prayerColor.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                iconForPrayer(eval.activePrayerName),
                                color: prayerColor,
                                size: AppIcon.md,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpace.xs),

                  // 2. Middle Row: Soft Sky Banner with Countdown Pill and Label
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.xs,
                    ),
                    decoration: BoxDecoration(
                      color: prayerColor.withValues(alpha: 0.10),
                      borderRadius: AppRadius.smRadius,
                      border: Border.all(
                        color: prayerColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Digital Countdown Badge (White Pill Box)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpace.sm,
                                vertical: AppSpace.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: palette.surfaceRaised,
                                borderRadius: AppRadius.smRadius,
                                border: Border.all(
                                  color: prayerColor.withValues(alpha: 0.30),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                eval.countdownFormatted,
                                style: textTheme.label.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: palette.text,
                                  letterSpacing: 1.1,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: AppSpace.sm),

                          // Label with Status Bullet
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
                                eval.isInPrayerTime ? 'وقت الصلاة الآن' : 'بقي على الأذان',
                                style: textTheme.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: prayerColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpace.xs),

                  // 3. Bottom Row: Warm Journey Strip of 5 Daily Prayers
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: AppSpace.xs,
                      horizontal: AppSpace.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(
                        color: palette.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: AppStrings.prayerOrder.map((prayerName) {
                        final isCurrent = eval.activePrayerName == prayerName;
                        final prayerTime = all[prayerName];
                        final isPast = eval.completedPrayerNames.contains(prayerName);

                        return _WidgetPrayerStation(
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
        ),
      ),
    );
  }

  static Map<String, DateTime> _buildFallbackPrayers(DateTime now) {
    final base = DateTime(now.year, now.month, now.day);
    return {
      AppStrings.prayerFajr: base.add(const Duration(hours: 5, minutes: 2)),
      AppStrings.prayerDhuhr: base.add(const Duration(hours: 12, minutes: 3)),
      AppStrings.prayerAsr: base.add(const Duration(hours: 15, minutes: 11)),
      AppStrings.prayerMaghrib: base.add(const Duration(hours: 17, minutes: 38)),
      AppStrings.prayerIsha: base.add(const Duration(hours: 19, minutes: 2)),
    };
  }

  _EvaluatedWidgetState _evaluatePrayer(
    DateTime now,
    Map<String, DateTime> all,
  ) {
    const iqamaWindow = Duration(minutes: 15);
    final entries = AppStrings.prayerOrder
        .where((p) => all.containsKey(p))
        .map((p) => MapEntry(p, all[p]!))
        .toList();

    // Check if in prayer time
    for (int i = entries.length - 1; i >= 0; i--) {
      final entry = entries[i];
      final pTime = entry.value;
      if (!now.isBefore(pTime)) {
        final elapsed = now.difference(pTime);
        if (elapsed < iqamaWindow) {
          final completed = entries.take(i).map((e) => e.key).toSet();
          return _EvaluatedWidgetState(
            activePrayerName: entry.key,
            nextPrayerTime: pTime,
            isInPrayerTime: true,
            countdownFormatted: '00 : 00 : 00',
            completedPrayerNames: completed,
          );
        }
      }
    }

    // Upcoming prayer today
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.value.isAfter(now)) {
        final diff = entry.value.difference(now);
        final completed = entries.take(i).map((e) => e.key).toSet();
        return _EvaluatedWidgetState(
          activePrayerName: entry.key,
          nextPrayerTime: entry.value,
          isInPrayerTime: false,
          countdownFormatted: _formatDuration(diff),
          completedPrayerNames: completed,
        );
      }
    }

    // Tomorrow's Fajr
    final fajrToday = all[AppStrings.prayerFajr] ??
        DateTime(now.year, now.month, now.day, 5, 0);
    final fajrTomorrow = fajrToday.add(const Duration(days: 1));
    final diff = fajrTomorrow.difference(now);
    final completed = entries.map((e) => e.key).toSet();
    return _EvaluatedWidgetState(
      activePrayerName: AppStrings.prayerFajr,
      nextPrayerTime: fajrTomorrow,
      isInPrayerTime: false,
      countdownFormatted: _formatDuration(diff),
      completedPrayerNames: completed,
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours : $minutes : $seconds';
  }
}

class _EvaluatedWidgetState {
  final String activePrayerName;
  final DateTime nextPrayerTime;
  final bool isInPrayerTime;
  final String countdownFormatted;
  final Set<String> completedPrayerNames;

  const _EvaluatedWidgetState({
    required this.activePrayerName,
    required this.nextPrayerTime,
    required this.isInPrayerTime,
    required this.countdownFormatted,
    required this.completedPrayerNames,
  });
}

class _WidgetPrayerStation extends StatelessWidget {
  final String prayerName;
  final DateTime? prayerTime;
  final bool isCurrent;
  final bool isPast;
  final bool isInPrayerTime;

  const _WidgetPrayerStation({
    required this.prayerName,
    required this.prayerTime,
    required this.isCurrent,
    required this.isPast,
    required this.isInPrayerTime,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final pColor = palette.prayer(prayerName);
    final timeStr = prayerTime != null ? formatPrayerTime12h(prayerTime!) : '';
    final icon = iconForPrayer(prayerName);

    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.xxs,
          vertical: AppSpace.xxs,
        ),
        decoration: isCurrent
            ? BoxDecoration(
                color: palette.surfaceRaised,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: pColor,
                  width: 1.5,
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Pip: Gold dot if current, green check if past, subtle dot if upcoming
            if (isCurrent)
              Container(
                width: AppSpace.sm - 2,
                height: AppSpace.sm - 2,
                margin: const EdgeInsets.only(bottom: AppSpace.xxs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.gold,
                ),
              )
            else if (isPast)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpace.xxs),
                child: Icon(
                  Icons.check_rounded,
                  size: AppIcon.xs,
                  color: palette.success,
                ),
              )
            else
              Container(
                width: AppSpace.xs,
                height: AppSpace.xs,
                margin: const EdgeInsets.only(bottom: AppSpace.xxs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pColor.withValues(alpha: 0.35),
                ),
              ),

            // Prayer Icon
            Icon(
              icon,
              size: isCurrent ? AppIcon.md : AppIcon.sm,
              color: isCurrent
                  ? pColor
                  : (isPast
                      ? pColor.withValues(alpha: 0.45)
                      : pColor.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: AppSpace.xxs),

            // Prayer Name
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                prayerName,
                style: textTheme.caption.copyWith(
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: isCurrent
                      ? pColor
                      : (isPast ? palette.textMuted : palette.text),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xxs),

            // Prayer Time with Western Digits
            if (timeStr.isNotEmpty)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  timeStr,
                  style: textTheme.caption.copyWith(
                    fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                    color: isCurrent
                        ? palette.text
                        : (isPast ? palette.textSubtle : palette.textMuted),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
