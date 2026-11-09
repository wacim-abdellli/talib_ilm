import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'location_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/constants/app_strings.dart';
import '../../app/theme/app_palette.dart';
import '../../app/theme/app_theme.dart';
import '../../features/prayer/data/models/prayer_models.dart';
import '../../features/prayer/presentation/widgets/prayer_home_screen_widget.dart';
import '../../features/salaf_gems/data/repositories/salaf_gems_repository.dart';
import 'adhan_settings_service.dart';

import 'home_widget_pre_render.dart';
export 'home_widget_pre_render.dart';

/// Supported visual themes for the native Android and iOS home widgets.
enum WidgetThemeMode { dark, light, auto }

/// Manages native widget preference serialization, snapshot versioning, and
/// theme resolution to keep Android and iOS widget appearances in sync.
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot._();

  static const String themeModeKey = 'prayer_widget_theme_mode';
  static const String appGroupId = 'group.com.talibilm.app';
  static int _snapshotVersion = 0;
  static int get snapshotVersion => _snapshotVersion;
  static String? lastSyncError;

  /// Writes a value to both the shared App Group and standard storage to ensure
  /// seamless data delivery across normal, sideloaded, and test environments.
  static Future<void> writeWidgetValue<T>(String key, T value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
    } catch (_) {}

    try {
      await HomeWidget.saveWidgetData<T>(
        key,
        value,
        appGroupId: appGroupId,
      );
      try {
        await HomeWidget.saveWidgetData<T>(key, value);
      } catch (_) {}
      lastSyncError = null;
    } catch (error) {
      lastSyncError = error.toString();
      try {
        await HomeWidget.saveWidgetData<T>(key, value);
      } catch (_) {}
    }
  }

  static Future<bool> verifyAppGroup() async {
    final probe = DateTime.now().microsecondsSinceEpoch.toString();
    try {
      final saved = await HomeWidget.saveWidgetData<String>(
        'widget_app_group_probe',
        probe,
        appGroupId: appGroupId,
      );
      if (saved == true) {
        final readBack = await HomeWidget.getWidgetData<String>(
          'widget_app_group_probe',
          appGroupId: appGroupId,
        );
        if (readBack == probe) {
          lastSyncError = null;
          return true;
        }
      }
      return false;
    } catch (error) {
      lastSyncError = error.toString();
      return false;
    }
  }

  /// Resolves whether the widget should render in dark mode.
  static Future<bool> resolveWidgetIsDark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(themeModeKey);
      if (modeStr == 'light') return false;
      if (modeStr == 'dark') return true;

      final appTheme = prefs.getString('theme_mode');
      if (appTheme == 'light') return false;
      if (appTheme == 'dark') return true;
      if (appTheme == 'system') {
        return AppTheme.isSystemDark();
      }
    } catch (_) {}
    return true;
  }

  /// Saves the target prayer epoch timestamp and all visual attributes for the
  /// native Android Chronometer and providers. Writes an atomic snapshot version
  /// to eliminate mixed/stale preference reads across widget updates.
  static Future<void> savePrayerSnapshot(
    EvaluatedPrayerWidgetState eval, {
    Map<String, DateTime>? allPrayers,
    bool? preResolvedDark,
    String? cityName,
  }) async {
    lastSyncError = null;
    try {
      final adhanSettings = await AdhanSettingsService().getSettings();
      final int epochMs;
      final String countdownPrefix;
      switch (eval.phase) {
        case PrayerWidgetPhase.beforeAdhan:
        case PrayerWidgetPhase.postSalah:
          epochMs = eval.targetPrayerTime.millisecondsSinceEpoch;
          countdownPrefix = 'بعد ';
          break;
        case PrayerWidgetPhase.betweenAdhanAndIqama:
          final iqamaMinutes = PrayerWidgetStateEvaluator.getIqamaMinutes(
            eval.activePrayerName,
            isJumua:
                eval.targetPrayerTime.weekday == DateTime.friday &&
                eval.activePrayerName == AppStrings.prayerDhuhr,
            iqamaOverrides: adhanSettings.iqamaMinutesAfterAdhan,
          );
          final iqamaTime = eval.targetPrayerTime.add(
            Duration(minutes: iqamaMinutes),
          );
          epochMs = iqamaTime.millisecondsSinceEpoch;
          countdownPrefix = 'الإقامة بعد ';
          break;
        case PrayerWidgetPhase.atAdhan:
        case PrayerWidgetPhase.inSalah:
          epochMs =
              0; // Chronometer hidden during active adhan or congregational prayer
          countdownPrefix = '';
          break;
      }

      final isPrayerActive =
          eval.phase == PrayerWidgetPhase.atAdhan ||
          eval.phase == PrayerWidgetPhase.inSalah;

      final prefs = await SharedPreferences.getInstance();
      final useDark = preResolvedDark ?? await resolveWidgetIsDark();
      final palette = useDark ? AppPalette.dark : AppPalette.light;
      final selectedWidgetMode = prefs.getString(themeModeKey);
      final widgetMode = switch (selectedWidgetMode) {
        'dark' => 'dark',
        'light' => 'light',
        'auto' => 'auto',
        _ => useDark ? 'dark' : 'light',
      };
      final appThemeMode = prefs.getString('theme_mode') ?? 'system';
      final resolvedCity = cityName?.trim().isNotEmpty == true
          ? cityName!.trim()
          : LocationService.cachedLocation?.city.trim();
      final prayerColor = palette.prayer(eval.activePrayerName);
      final prayerColorInt = prayerColor.toARGB32();
      final textColorInt = palette.text.toARGB32();
      final version = ++_snapshotVersion;

      await prefs.setInt('next_prayer_epoch_ms', epochMs);
      await prefs.setString('next_prayer_name', eval.activePrayerName);
      await prefs.setString('prayer_display_title', eval.displayTitle);
      await prefs.setInt('prayer_color_value', prayerColorInt);
      await prefs.setInt('widget_text_color', textColorInt);
      await prefs.setBool('widget_is_dark', useDark);
      await prefs.setString(themeModeKey, widgetMode);
      await prefs.setString('countdown_prefix', countdownPrefix);
      await prefs.setString('prayer_status_label', eval.statusLabel);
      await prefs.setBool('is_prayer_active', isPrayerActive);
      await prefs.setInt('widget_snapshot_version', version);
      await prefs.remove('widget_ribbon_width');
      await prefs.remove('widget_ribbon_height');
      await prefs.remove('widget_large_width');
      await prefs.remove('widget_large_height');

      final nowDt = DateTime.now();
      final hijri = HijriCalendar.fromDate(nowDt);
      final hijriStr =
          '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ';

      String gemText = '';
      String gemAuthor = '';
      try {
        final gem = await SalafGemsRepository.instance.getDailyGem();
        gemText = gem.text;
        gemAuthor = gem.author;
        await prefs.setString('daily_gem_text', gemText);
        await prefs.setString('daily_gem_author', gemAuthor);
      } catch (_) {}

      // Write common attributes
      await writeWidgetValue<int>('next_prayer_epoch_ms', epochMs);
      await writeWidgetValue<String>('next_prayer_name', eval.activePrayerName);
      await writeWidgetValue<String>('prayer_display_title', eval.displayTitle);
      await writeWidgetValue<int>('prayer_color_value', prayerColorInt);
      await writeWidgetValue<int>('widget_text_color', textColorInt);
      await writeWidgetValue<bool>('widget_is_dark', useDark);
      await writeWidgetValue<String>(themeModeKey, widgetMode);
      await writeWidgetValue<String>('theme_mode', appThemeMode);
      await writeWidgetValue<String>('countdown_prefix', countdownPrefix);
      await writeWidgetValue<String>('prayer_status_label', eval.statusLabel);
      await writeWidgetValue<bool>('is_prayer_active', isPrayerActive);
      await writeWidgetValue<int>('widget_snapshot_version', version);
      await writeWidgetValue<String>('hijri_date', hijriStr);
      if (resolvedCity != null && resolvedCity.isNotEmpty) {
        await writeWidgetValue<String>('location_city', resolvedCity);
      }
      if (gemText.isNotEmpty) {
        await writeWidgetValue<String>('daily_gem_text', gemText);
        await writeWidgetValue<String>('daily_gem_author', gemAuthor);
      }

      final cachedLoc = LocationService.cachedLocation;
      if (cachedLoc != null) {
        await writeWidgetValue<double>('location_latitude', cachedLoc.latitude);
        await writeWidgetValue<double>('location_longitude', cachedLoc.longitude);
      }

      final prayersPayload = <String, dynamic>{};
      // Persist full 24-hour prayer schedule for autonomous native widget evaluation
      if (allPrayers != null && allPrayers.isNotEmpty) {
        final fajrTime = allPrayers[AppStrings.prayerFajr];
        final dhuhrTime = allPrayers[AppStrings.prayerDhuhr];
        final asrTime = allPrayers[AppStrings.prayerAsr];
        final maghribTime = allPrayers[AppStrings.prayerMaghrib];
        final ishaTime = allPrayers[AppStrings.prayerIsha];
        final tomorrowFajrTime = fajrTime != null
            ? DateTime(
                fajrTime.year,
                fajrTime.month,
                fajrTime.day + 1,
                fajrTime.hour,
                fajrTime.minute,
                fajrTime.second,
              )
            : null;

        final refTime = dhuhrTime ?? DateTime.now();
        final isFriday = refTime.weekday == DateTime.friday;

        final iqamaFajr = PrayerWidgetStateEvaluator.getIqamaMinutes(
          AppStrings.prayerFajr,
          iqamaOverrides: adhanSettings.iqamaMinutesAfterAdhan,
        );
        final iqamaDhuhr = PrayerWidgetStateEvaluator.getIqamaMinutes(
          AppStrings.prayerDhuhr,
          isJumua: isFriday,
          iqamaOverrides: adhanSettings.iqamaMinutesAfterAdhan,
        );
        final iqamaAsr = PrayerWidgetStateEvaluator.getIqamaMinutes(
          AppStrings.prayerAsr,
          iqamaOverrides: adhanSettings.iqamaMinutesAfterAdhan,
        );
        final iqamaMaghrib = PrayerWidgetStateEvaluator.getIqamaMinutes(
          AppStrings.prayerMaghrib,
          iqamaOverrides: adhanSettings.iqamaMinutesAfterAdhan,
        );
        final iqamaIsha = PrayerWidgetStateEvaluator.getIqamaMinutes(
          AppStrings.prayerIsha,
          iqamaOverrides: adhanSettings.iqamaMinutesAfterAdhan,
        );

        final fajrColor = palette.prayer(AppStrings.prayerFajr).toARGB32();
        final dhuhrColor =
            (isFriday
                    ? palette.success
                    : palette.prayer(AppStrings.prayerDhuhr))
                .toARGB32();
        final asrColor = palette.prayer(AppStrings.prayerAsr).toARGB32();
        final maghribColor = palette
            .prayer(AppStrings.prayerMaghrib)
            .toARGB32();
        final ishaColor = palette.prayer(AppStrings.prayerIsha).toARGB32();

        if (fajrTime != null) {
          final s = formatPrayerTime12h(fajrTime);
          await writeWidgetValue<int>(
            'prayer_fajr_epoch_ms',
            fajrTime.millisecondsSinceEpoch,
          );
          await writeWidgetValue<String>('prayer_fajr_time_str', s);
          prayersPayload['fajr'] = {
            'epoch_ms': fajrTime.millisecondsSinceEpoch,
            'time_str': s,
          };
        }
        if (dhuhrTime != null) {
          final s = formatPrayerTime12h(dhuhrTime);
          await writeWidgetValue<int>(
            'prayer_dhuhr_epoch_ms',
            dhuhrTime.millisecondsSinceEpoch,
          );
          await writeWidgetValue<String>('prayer_dhuhr_time_str', s);
          prayersPayload['dhuhr'] = {
            'epoch_ms': dhuhrTime.millisecondsSinceEpoch,
            'time_str': s,
          };
        }
        if (asrTime != null) {
          final s = formatPrayerTime12h(asrTime);
          await writeWidgetValue<int>(
            'prayer_asr_epoch_ms',
            asrTime.millisecondsSinceEpoch,
          );
          await writeWidgetValue<String>('prayer_asr_time_str', s);
          prayersPayload['asr'] = {
            'epoch_ms': asrTime.millisecondsSinceEpoch,
            'time_str': s,
          };
        }
        if (maghribTime != null) {
          final s = formatPrayerTime12h(maghribTime);
          await writeWidgetValue<int>(
            'prayer_maghrib_epoch_ms',
            maghribTime.millisecondsSinceEpoch,
          );
          await writeWidgetValue<String>('prayer_maghrib_time_str', s);
          prayersPayload['maghrib'] = {
            'epoch_ms': maghribTime.millisecondsSinceEpoch,
            'time_str': s,
          };
        }
        if (ishaTime != null) {
          final s = formatPrayerTime12h(ishaTime);
          await writeWidgetValue<int>(
            'prayer_isha_epoch_ms',
            ishaTime.millisecondsSinceEpoch,
          );
          await writeWidgetValue<String>('prayer_isha_time_str', s);
          prayersPayload['isha'] = {
            'epoch_ms': ishaTime.millisecondsSinceEpoch,
            'time_str': s,
          };
        }
        if (tomorrowFajrTime != null) {
          await writeWidgetValue<int>(
            'prayer_tomorrow_fajr_epoch_ms',
            tomorrowFajrTime.millisecondsSinceEpoch,
          );
          prayersPayload['tomorrow_fajr_epoch_ms'] =
              tomorrowFajrTime.millisecondsSinceEpoch;
        }

        await writeWidgetValue<bool>('is_friday', isFriday);
        await writeWidgetValue<int>('iqama_fajr_min', iqamaFajr);
        await writeWidgetValue<int>('iqama_dhuhr_min', iqamaDhuhr);
        await writeWidgetValue<int>('iqama_asr_min', iqamaAsr);
        await writeWidgetValue<int>('iqama_maghrib_min', iqamaMaghrib);
        await writeWidgetValue<int>('iqama_isha_min', iqamaIsha);

        await writeWidgetValue<int>('prayer_color_fajr', fajrColor);
        await writeWidgetValue<int>('prayer_color_dhuhr', dhuhrColor);
        await writeWidgetValue<int>('prayer_color_asr', asrColor);
        await writeWidgetValue<int>('prayer_color_maghrib', maghribColor);
        await writeWidgetValue<int>('prayer_color_isha', ishaColor);
      }

      // Write complete JSON snapshot for unified native Swift/Kotlin consumption
      final fullPayload = <String, dynamic>{
        'version': version,
        'city': resolvedCity ?? '',
        'latitude': cachedLoc?.latitude,
        'longitude': cachedLoc?.longitude,
        'hijri': hijriStr,
        'next_prayer_epoch_ms': epochMs,
        'next_prayer_name': eval.activePrayerName,
        'prayer_display_title': eval.displayTitle,
        'countdown_prefix': countdownPrefix,
        'is_prayer_active': isPrayerActive,
        'widget_is_dark': useDark,
        'daily_gem_text': gemText,
        'daily_gem_author': gemAuthor,
        'prayers': prayersPayload,
      };
      await writeWidgetValue<String>(
        'prayer_data_json',
        jsonEncode(fullPayload),
      );
    } catch (error) {
      lastSyncError = error.toString();
      debugPrint('Home widget snapshot sync failed: $error');
    }
  }

  /// Invalidates cached daily pre-rendered prayer state snapshots
  static void invalidateDailyCache() =>
      HomeWidgetPreRender.invalidateDailyCache();

  /// Pre-renders daily prayer state variations for Ribbon widget.
  static Future<void> preRenderDailyRibbonSnapshots({
    required PrayerTimesDay day,
    required bool useDark,
    required String hijriDate,
    bool force = false,
  }) =>
      HomeWidgetPreRender.preRenderDailyRibbonSnapshots(
        day: day,
        useDark: useDark,
        hijriDate: hijriDate,
        force: force,
      );

  /// Pre-renders daily prayer state variations for Large widget.
  static Future<void> preRenderDailyLargeSnapshots({
    required PrayerTimesDay day,
    required bool useDark,
    required String hijriDate,
    bool force = false,
  }) =>
      HomeWidgetPreRender.preRenderDailyLargeSnapshots(
        day: day,
        useDark: useDark,
        hijriDate: hijriDate,
        force: force,
      );
}
