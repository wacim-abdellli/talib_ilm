import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/app_card.dart';
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });
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
    final prayerColor = palette.prayer(widget.nextPrayerName);

    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    final prayerTimeDisplay = formatPrayerTime12h(widget.nextPrayerTime);
    final nearnessLabel = _getNearnessLabel();

    return Semantics(
      label: 'صلاة ${widget.nextPrayerName}',
      hint: 'المتبقي ${_getReadableDuration()}',
      button: true,
      onTapHint: 'اضغط لعرض تفاصيل الصلاة',
      child: AppCard(
        onTap: widget.onTap,
        color: palette.surfaceRaised,
        border: Border.all(
          color: prayerColor.withValues(alpha: 0.32),
          width: 1.5,
        ),
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                prayerColor.withValues(alpha: 0.10),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45],
            ),
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                prayerColor.withValues(alpha: 0.28),
                                prayerColor.withValues(alpha: 0.10),
                              ],
                            ),
                            borderRadius: AppRadius.mdRadius,
                            border: Border.all(
                              color: prayerColor.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            _iconForPrayer(widget.nextPrayerName),
                            color: prayerColor,
                            size: AppIcon.lg,
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),

                        // Large Prayer Title (Uncluttered, Single Line)
                        Expanded(
                          child: Text(
                            'صلاة ${widget.nextPrayerName}',
                            style: textTheme.title.copyWith(
                              color: palette.text,
                              fontWeight: FontWeight.w800,
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
                      vertical: AppSpace.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          prayerColor.withValues(alpha: 0.18),
                          prayerColor.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: prayerColor.withValues(alpha: 0.45),
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
                          prayerTimeDisplay,
                          style: textTheme.label.copyWith(
                            color: palette.text,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpace.md),

              // 2. Horizon Countdown Banner (Unified Single Line with Integrated Badges)
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpace.md,
                  vertical: AppSpace.sm,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      prayerColor.withValues(alpha: 0.12),
                      prayerColor.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: prayerColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Start: Nearness Indicator with Glowing Pulse Dot
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: prayerColor,
                            ),
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Text(
                            nearnessLabel,
                            style: textTheme.caption.copyWith(
                              color: prayerColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpace.lg),

                      // End: Digital Precision Countdown Clock (05 : 46 : 13)
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
                                  fontWeight: FontWeight.w800,
                                  color: palette.text,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              _CountdownColon(color: prayerColor),
                              Text(
                                minutes,
                                style: textTheme.titleSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: palette.text,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              _CountdownColon(color: prayerColor),
                              Text(
                                seconds,
                                style: textTheme.titleSmall.copyWith(
                                  fontWeight: FontWeight.w800,
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
                    final isSameDay = widget.nextPrayerTime.day == DateTime.now().day;
                    final isCurrent = widget.nextPrayerName == prayerName && isSameDay;
                    final prayerTime = widget.allPrayers?[prayerName];
                    final isPast = prayerTime != null &&
                        (prayerTime.isBefore(DateTime.now()) || !isSameDay);

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
            ],
          ),
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
    final pColor = palette.prayer(prayerName);
    final timeStr =
        prayerTime != null ? formatPrayerTime12h(prayerTime) : '';
    final icon = _iconForPrayer(prayerName);

    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpace.xs,
          vertical: AppSpace.xs,
        ),
        decoration: isCurrent
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    pColor.withValues(alpha: 0.22),
                    pColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: AppRadius.mdRadius,
                border: Border.all(
                  color: pColor,
                  width: 1.5,
                ),
                boxShadow: palette.shadow,
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Pip
            if (isCurrent)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(bottom: AppSpace.xs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.gold,
                ),
              )
            else if (isPast)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpace.xs),
                child: Icon(
                  Icons.check_rounded,
                  size: 8,
                  color: palette.success,
                ),
              )
            else
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpace.xs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pColor.withValues(alpha: 0.35),
                ),
              ),

            // Celestial Icon with individual prayer color
            Icon(
              icon,
              size: isCurrent ? AppIcon.md : AppIcon.sm,
              color: isCurrent
                  ? pColor
                  : (isPast
                      ? pColor.withValues(alpha: 0.45)
                      : pColor.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: AppSpace.xs),

            // Prayer Name
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                prayerName,
                style: isCurrent
                    ? textTheme.caption.copyWith(
                        color: pColor,
                        fontWeight: FontWeight.w800,
                      )
                    : textTheme.caption.copyWith(
                        color: isPast ? palette.textMuted : palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),

            // Prayer Time with Western Arabic numerals (123456)
            if (timeStr.isNotEmpty)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  timeStr,
                  style: isCurrent
                      ? textTheme.caption.copyWith(
                          color: palette.text,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )
                      : textTheme.caption.copyWith(
                          color: isPast ? palette.textSubtle : palette.textMuted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForPrayer(String name) {
    final p = name.trim();
    if (p.contains(AppStrings.prayerFajr) || p == 'الفجر') {
      return Icons.wb_twilight_rounded;
    }
    if (p == 'الشروق') {
      return Icons.wb_sunny_rounded;
    }
    if (p.contains(AppStrings.prayerDhuhr) || p == 'الظهر') {
      return Icons.wb_sunny_rounded;
    }
    if (p.contains(AppStrings.prayerAsr) || p == 'العصر') {
      return Icons.wb_sunny_outlined;
    }
    if (p.contains(AppStrings.prayerMaghrib) || p == 'المغرب') {
      return Icons.nights_stay_outlined;
    }
    if (p.contains(AppStrings.prayerIsha) || p == 'العشاء') {
      return Icons.bedtime_rounded;
    }
    return Icons.access_time_rounded;
  }

  String _getNearnessLabel() {
    final minutes = _timeLeft.inMinutes;
    final seconds = _timeLeft.inSeconds;
    if (minutes <= 0 && seconds <= 0) {
      return 'حان وقت الأذان';
    }
    if (minutes <= 5) {
      return 'يقترب وقت الصلاة';
    }
    return 'بقي على الأذان';
  }

  String _getReadableDuration() {
    final hours = _timeLeft.inHours;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _CountdownColon extends StatelessWidget {
  final Color color;

  const _CountdownColon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      child: Text(
        ':',
        style: context.text.titleSmall.copyWith(
          fontWeight: FontWeight.w800,
          color: color.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
