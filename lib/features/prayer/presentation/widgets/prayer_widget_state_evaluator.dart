import 'package:flutter/material.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../home/presentation/widgets/home_hero_timeline_station.dart';
import '../../data/models/prayer_models.dart';

/// Active phase of the liturgical prayer lifecycle for the home widget.
enum PrayerWidgetPhase {
  beforeAdhan,
  atAdhan,
  betweenAdhanAndIqama,
  inSalah,
  postSalah,
}

/// Resolved runtime evaluation state for the home screen prayer widget.
class EvaluatedPrayerWidgetState {
  final String activePrayerName;
  final String displayTitle;
  final DateTime targetPrayerTime;
  final PrayerWidgetPhase phase;
  final String statusLabel;
  final String? subStatusText;
  final String timePillLabel;
  final IconData timePillIcon;
  final IconData statusIcon;
  final IconData prayerIcon;
  final String countdownFormatted;
  final Set<String> completedPrayerNames;

  final String? nextPrayerName;
  final DateTime? nextPrayerTime;

  const EvaluatedPrayerWidgetState({
    required this.activePrayerName,
    required this.displayTitle,
    required this.targetPrayerTime,
    required this.phase,
    required this.statusLabel,
    this.subStatusText,
    required this.timePillLabel,
    required this.timePillIcon,
    required this.statusIcon,
    required this.prayerIcon,
    required this.countdownFormatted,
    required this.completedPrayerNames,
    this.nextPrayerName,
    this.nextPrayerTime,
  });

  bool get isInPrayerTime =>
      phase == PrayerWidgetPhase.atAdhan ||
      phase == PrayerWidgetPhase.betweenAdhanAndIqama ||
      phase == PrayerWidgetPhase.inSalah;
}

/// Evaluates prayer times and determines active liturgical phase, countdown, and titles.
class PrayerWidgetStateEvaluator {
  PrayerWidgetStateEvaluator._();

  static EvaluatedPrayerWidgetState evaluate({
    required DateTime now,
    required Map<String, DateTime> all,
  }) {
    final entries = AppStrings.prayerOrder
        .where((p) => all.containsKey(p))
        .map((p) => MapEntry(p, all[p]!))
        .toList();

    final isFriday = now.weekday == DateTime.friday;

    final fajrToday = all[AppStrings.prayerFajr] ??
        DateTime(now.year, now.month, now.day, 5, 0);
    final fajrTomorrow = fajrToday.add(const Duration(days: 1));

    (String, DateTime) resolveUpcoming(int currentIndex) {
      if (currentIndex + 1 < entries.length) {
        return (entries[currentIndex + 1].key, entries[currentIndex + 1].value);
      }
      return (AppStrings.prayerFajr, fajrTomorrow);
    }

    // 1. Check if any prayer is currently within active Adhan, Iqama, or Salah window
    for (int i = entries.length - 1; i >= 0; i--) {
      final entry = entries[i];
      final pName = entry.key;
      final pTime = entry.value;

      if (!now.isBefore(pTime)) {
        final elapsed = now.difference(pTime);
        final isJumua = isFriday && pName == AppStrings.prayerDhuhr;
        final int iqamaMinutes = isJumua
            ? 25
            : (pName == AppStrings.prayerFajr
                ? 20
                : (pName == AppStrings.prayerMaghrib ? 10 : 15));
        final iqamaDuration = Duration(minutes: iqamaMinutes);
        final salahDuration = Duration(minutes: iqamaMinutes + 15);
        final postSalahDuration = Duration(minutes: iqamaMinutes + 25);

        final completed = entries.take(i).map((e) => e.key).toSet();
        final displayTitle = isJumua ? 'صلاة الجمعة' : 'صلاة $pName';
        final prayerIcon = isJumua ? Icons.mosque_rounded : iconForPrayer(pName);
        final upcoming = resolveUpcoming(i);

        // Phase A: Right at Adhan (first 2 minutes)
        if (elapsed < const Duration(minutes: 2)) {
          return EvaluatedPrayerWidgetState(
            activePrayerName: pName,
            displayTitle: isJumua ? 'أذان صلاة الجمعة' : 'أذان صلاة $pName',
            targetPrayerTime: pTime,
            phase: PrayerWidgetPhase.atAdhan,
            statusLabel: 'حان الآن وقت الأذان',
            subStatusText: 'حي على الصلاة • حي على الفلاح',
            timePillLabel: formatPrayerTime12h(pTime),
            timePillIcon: Icons.access_time_rounded,
            statusIcon: Icons.volume_up_rounded,
            prayerIcon: prayerIcon,
            countdownFormatted: 'الأذان الآن',
            completedPrayerNames: completed,
            nextPrayerName: upcoming.$1,
            nextPrayerTime: upcoming.$2,
          );
        }

        // Phase B: Between Adhan and Iqama
        if (elapsed < iqamaDuration) {
          final iqamaTime = pTime.add(iqamaDuration);
          final remainingToIqama = iqamaTime.difference(now);
          return EvaluatedPrayerWidgetState(
            activePrayerName: pName,
            displayTitle: displayTitle,
            targetPrayerTime: pTime,
            phase: PrayerWidgetPhase.betweenAdhanAndIqama,
            statusLabel: 'بقي على الإقامة',
            subStatusText: 'الدعاء مستجاب بين الأذان والإقامة',
            timePillLabel: 'الإقامة ${formatPrayerTime12h(iqamaTime)}',
            timePillIcon: Icons.mosque_rounded,
            statusIcon: Icons.access_time_filled_rounded,
            prayerIcon: prayerIcon,
            countdownFormatted: formatDuration(remainingToIqama),
            completedPrayerNames: completed,
            nextPrayerName: upcoming.$1,
            nextPrayerTime: upcoming.$2,
          );
        }

        // Phase C: During Congregational Salah
        if (elapsed < salahDuration) {
          return EvaluatedPrayerWidgetState(
            activePrayerName: pName,
            displayTitle: displayTitle,
            targetPrayerTime: pTime,
            phase: PrayerWidgetPhase.inSalah,
            statusLabel: 'تقام الصلاة الآن',
            subStatusText: 'أقم الصلاة لذكري • طمأنينة وخشوع',
            timePillLabel: 'وقت الصلاة',
            timePillIcon: Icons.mosque_rounded,
            statusIcon: Icons.people_alt_rounded,
            prayerIcon: prayerIcon,
            countdownFormatted: 'أداء الفريضة',
            completedPrayerNames: completed,
            nextPrayerName: upcoming.$1,
            nextPrayerTime: upcoming.$2,
          );
        }

        // Phase D: Post-salah dhikr window (before transition)
        if (elapsed < postSalahDuration) {
          final nextIndex = i + 1;
          if (nextIndex < entries.length) {
            final nextEntry = entries[nextIndex];
            final diff = nextEntry.value.difference(now);
            final nextIsJumua = isFriday && nextEntry.key == AppStrings.prayerDhuhr;
            final nextUpcoming = resolveUpcoming(nextIndex);
            return EvaluatedPrayerWidgetState(
              activePrayerName: nextEntry.key,
              displayTitle: nextIsJumua ? 'صلاة الجمعة' : 'صلاة ${nextEntry.key}',
              targetPrayerTime: nextEntry.value,
              phase: PrayerWidgetPhase.postSalah,
              statusLabel: 'أذكار ما بعد الصلاة',
              subStatusText: 'استغفار وتسبيح بعد الفريضة',
              timePillLabel: formatPrayerTime12h(nextEntry.value),
              timePillIcon: Icons.access_time_rounded,
              statusIcon: Icons.menu_book_rounded,
              prayerIcon: nextIsJumua ? Icons.mosque_rounded : iconForPrayer(nextEntry.key),
              countdownFormatted: formatDuration(diff),
              completedPrayerNames: entries.take(i + 1).map((e) => e.key).toSet(),
              nextPrayerName: nextUpcoming.$1,
              nextPrayerTime: nextUpcoming.$2,
            );
          }
        }
      }
    }

    // 2. Upcoming prayer today
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (entry.value.isAfter(now)) {
        final diff = entry.value.difference(now);
        final completed = entries.take(i).map((e) => e.key).toSet();
        final isJumua = isFriday && entry.key == AppStrings.prayerDhuhr;
        final upcoming = resolveUpcoming(i);
        return EvaluatedPrayerWidgetState(
          activePrayerName: entry.key,
          displayTitle: isJumua ? 'صلاة الجمعة' : 'صلاة ${entry.key}',
          targetPrayerTime: entry.value,
          phase: PrayerWidgetPhase.beforeAdhan,
          statusLabel: 'بقي على الأذان',
          subStatusText: 'وقت الاستعداد للقبلة والوضوء',
          timePillLabel: formatPrayerTime12h(entry.value),
          timePillIcon: Icons.access_time_rounded,
          statusIcon: Icons.schedule_rounded,
          prayerIcon: isJumua ? Icons.mosque_rounded : iconForPrayer(entry.key),
          countdownFormatted: formatDuration(diff),
          completedPrayerNames: completed,
          nextPrayerName: upcoming.$1,
          nextPrayerTime: upcoming.$2,
        );
      }
    }

    // 3. Tomorrow's Fajr (All today's prayers completed)
    final diff = fajrTomorrow.difference(now);
    final completed = entries.map((e) => e.key).toSet();

    final isLateNight = now.hour >= 0 && now.hour < 5;

    return EvaluatedPrayerWidgetState(
      activePrayerName: AppStrings.prayerFajr,
      displayTitle: 'صلاة الفجر',
      targetPrayerTime: fajrTomorrow,
      phase: PrayerWidgetPhase.beforeAdhan,
      statusLabel: 'بقي على الأذان',
      subStatusText: isLateNight
          ? 'قيام الليل • الثلث الأخير مستجاب الدعاء'
          : 'أذكار النوم والاستعداد لصلاة الفجر',
      timePillLabel: formatPrayerTime12h(fajrTomorrow),
      timePillIcon: Icons.nightlight_round,
      statusIcon: isLateNight ? Icons.nights_stay_rounded : Icons.schedule_rounded,
      prayerIcon: iconForPrayer(AppStrings.prayerFajr),
      countdownFormatted: formatDuration(diff),
      completedPrayerNames: completed,
      nextPrayerName: entries.length > 1 ? entries[1].key : AppStrings.prayerDhuhr,
      nextPrayerTime: entries.length > 1 ? entries[1].value.add(const Duration(days: 1)) : null,
    );
  }

  static String formatDuration(Duration d) {
    if (d.isNegative) return '00:00';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } else {
      final safeMinutes = minutes == 0 ? 1 : minutes;
      return '00:${safeMinutes.toString().padLeft(2, '0')}';
    }
  }
}
