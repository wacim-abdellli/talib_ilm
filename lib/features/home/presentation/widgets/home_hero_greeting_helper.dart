import 'package:flutter/material.dart';
import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../prayer/data/models/prayer_models.dart';
import 'continue_learning_card.dart';
import 'home_hero_card.dart';

class HomeHeroGreetingHelper {
  const HomeHeroGreetingHelper._();

  static String getGreeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'أصبحنا وأصبح الملك لله';
    if (hour >= 12 && hour < 17) return 'حيّاك الله يا طالب العلم';
    if (hour >= 17 && hour < 22) return 'أمسينا وأمسى الملك لله';
    return 'طابت ليلتك بذكر الله';
  }

  static String getGreetingSubtitle(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'طاب مسعاك في طلب العلم والخير';
    if (hour >= 12 && hour < 17) return 'بارك الله في وقتك وثبّت خطاك';
    if (hour >= 17 && hour < 22) return 'أنار الله دربك بنور العلم والهدى';
    return 'ألا بذكر الله تطمئن القلوب';
  }

  static Widget buildHeroGreetingCard({
    required BuildContext context,
    required DateTime effectiveNow,
    required PrayerTimesDay? prayerDay,
    required Map<String, int> iqamaOverrides,
    required VoidCallback onTap,
    DateTime? currentTime,
  }) {
    bool isEstimated = false;
    String nextPrayerName;
    DateTime nextPrayerTime;

    if (prayerDay != null) {
      nextPrayerName = prayerDay.nextPrayer;
      nextPrayerTime = prayerDay.nextPrayerTime ?? prayerDay.prayers[nextPrayerName] ?? effectiveNow;
      if (nextPrayerTime.isBefore(effectiveNow)) {
        if (nextPrayerName == AppStrings.prayerFajr) {
          nextPrayerTime = nextPrayerTime.add(const Duration(days: 1));
        }
      }
      isEstimated = false;
    } else {
      isEstimated = true;
      final (pName, pHour, dayOffset) = switch (effectiveNow.hour) {
        < 5 => (AppStrings.prayerFajr, 5, 0),
        < 12 => (AppStrings.prayerDhuhr, 12, 0),
        < 15 => (AppStrings.prayerAsr, 15, 0),
        < 18 => (AppStrings.prayerMaghrib, 18, 0),
        < 20 => (AppStrings.prayerIsha, 20, 0),
        _ => (AppStrings.prayerFajr, 5, 1),
      };
      nextPrayerName = pName;
      nextPrayerTime = DateTime(effectiveNow.year, effectiveNow.month, effectiveNow.day + dayOffset, pHour, 0);
    }

    return HomeHeroCard(
      nextPrayerName: nextPrayerName,
      nextPrayerTime: nextPrayerTime,
      currentTime: currentTime,
      isEstimated: isEstimated,
      allPrayers: prayerDay?.prayers,
      iqamaOverrides: iqamaOverrides,
      onTap: onTap,
    );
  }

  static Widget buildContinueSection({
    required BuildContext context,
    required bool isLoading,
    required ContinueData? data,
    required VoidCallback onOpenIlm,
    required void Function(ContinueData) onContinue,
  }) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
        child: LearningPulseCard(isLoading: true, data: null),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpace.xl),
      child: LearningPulseCard(
        isLoading: false,
        data: data,
        onTap: data == null
            ? onOpenIlm
            : () => onContinue(data),
      ),
    );
  }
}
